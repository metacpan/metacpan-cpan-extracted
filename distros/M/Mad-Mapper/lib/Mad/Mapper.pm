package Mad::Mapper;

=encoding utf8

=head1 NAME

Mad::Mapper - Map Perl objects to PostgreSQL, MySQL or SQLite data

=head1 VERSION

0.09

=head1 DESCRIPTION

L<Mad::Mapper> is a base class for objects that should be stored in a
persistent SQL database. Currently the supported backends are L<Mojo::Pg>
L<Mojo::mysql> and L<Mojo::SQLite>. These backends need to be installed
separately.

  $ cpanm Mad::Mapper
  $ cpanm Mojo::Pg # Mad::Mapper now supports postgres!

THIS MODULE IS EXPERIMENTAL. It is in use in production though, so
big changes will not be made without extreme consideration.

=head1 SYNOPSIS

  package MyApp::Model::User;
  use Mad::Mapper -base;

  # Class attributes
  col id => undef;
  col email => '';

See also L<Mad::Mapper::Guides::Tutorial> for more details and
L<Mad::Mapper::Guides::Custom> if you want more control.

=head1 RELATIONSHIPS

See L<Mad::Mapper::Guides::HasMany> for example "has many" relationship.

TODO: C<belongs_to()> and maybe C<has_one()>.

=cut

use Mojo::Base -base;
use Mojo::IOLoop;
use Mojo::JSON ();
use Mojo::Loader 'load_class';
use Scalar::Util 'weaken';
use constant DEBUG => $ENV{MAD_DEBUG} || 0;

our $VERSION = '0.09';

my (%COLUMNS, %LOADED, %PK);

=head1 EXPORTED FUNCTIONS

=head2 col

Used to define a column. Follow the same rules as L</has>.

=head2 has

  has name => "Bruce";
  has [qw(name email)];
  has pet => sub { Cat->new };

Same as L<Mojo::Base/has>.

=head2 pk

Used to define a primary key. Follow the same rules as L</has>.

The primary key is used by default in L</load> and L</update> to update the
correct row. If omitted, the first L</col> will act as primary key.

Note that L</pk> is not returned by L</columns>.

=head2 table

Used to define a table name. The default is to decamelize the last part of the
class name and add "s" at the end, unless it already has "s" at the end.
Examples:

  .-------------------------------------.
  | Class name            | table       |
  |-----------------------|-------------|
  | App::Model::User      | users       |
  | App::Model::Users     | users       |
  | App::Model::Group     | groups      |
  | App::Model::UserAgent | user_agents |
  '-------------------------------------'

=head1 ATTRIBUTES

=head2 db

  $db = $self->db;
  $self->db($db_obj);

Need to hold either a L<Mojo::Pg::Database> or L<Mojo::mysql::Database> object.

=head2 in_storage

  $bool = $self->in_storage;
  $self = $self->in_storage($bool);

=cut

has db => sub { die "'db' is required in constructor." };
has in_storage => 0;

=head1 METHODS

=head2 expand_sql

  ($sql, @args) = $self->expand_sql($sql, @args);

Used to expand a given C<$sql> statement with variables defined by helpers.

=over 4

=item * %t

Will be replaced by L</table>. Example: "SELECT * FROM %t" becomes "SELECT * FROM users".

=item * %c

Will be replaced by L</columns>. Example: "name,email".

=item * %c=

Will be replaced by L</columns> assignment. Example: "name=?,email=?"

=item * %c?

Will be replaced by L</columns> placeholders. Example: "?,?,?"

=item * %pc

Include L</pk> in list of columns. Example: "id,name,email".

=item * \%c

Becomes a literal "%c".

=back

It is also possible to define aliases for "%t", "%c", "%c=" and "%pc". Example:

  %t.x = some_table as x
  %c.x = x.col1

=cut

sub expand_sql {
  my ($self, $sql, @args) = @_;
  my $p;

  $sql =~ s|(?<!\\)\%c(?:\.(\w+))?\=|{$p = $1 ? "$1." : ""; join ',', map {"$p$_=?"} $self->columns}|ge;
  $sql =~ s|(?<!\\)\%c\?|{join ',', map {"?"} $self->columns}|ge;
  $sql =~ s|(?<!\\)\%c(?:\.(\w+))?|{$p = $1 ? "$1." : ""; join ',', map {"$p$_"} $self->columns}|ge;
  $sql =~ s|(?<!\\)\%pc(?:\.(\w+))?|{$p = $1 ? "$1." : ""; join ',', map {"$p$_"} $self->pk, $self->columns}|ge;
  $sql =~ s|(?<!\\)\%t(?:\.(\w+))?|{$self->table. ($1 ? " $1" : "")}|ge;
  $sql =~ s|\\%|%|g;

  return $sql, @args;
}

=head2 expand_sst

DEPRECATED in favor of L</expand_sql>.

=cut

sub expand_sst {
  Mojo::Util::deprecated("expand_sst() is deprecated in favor of expand_sql()");
  shift->expand_sql(@_);
}

=head2 columns

  @str = $self->columns;

Returns a list of columns, defined by L</col>.

=head2 delete

  $self = $self->delete;
  $self = $self->delete(sub { my ($self, $err) = @_, ... });

Will delete the object from database if L</in_storage>.

=cut

sub delete {
  my $self = shift;
  $self->_delete(@_) if $self->in_storage;
  $self;
}

=head2 fresh

  $self = $self->fresh;

Will mark the next relationship accessor to fetch new data from database,
instead of using the cached data on C<$self>.

=cut

sub fresh { $_[0]->{fresh}++; $_[0] }

=head2 load

  $self = $self->load;
  $self = $class->load(sub { my ($self, $err) = @_; });

Used to fetch data from storage and update the object attributes.

=cut

sub load {
  my $self = shift;
  $self->_find(@_);
  $self;
}

=head2 save

  $self = $self->save;
  $self = $self->save(sub { my ($self, $err) = @_, ... });

Will update the object in database if L</in_storage> or insert it if not.

=cut

sub save {
  my $self = shift;
  $self->in_storage ? $self->_update(@_) : $self->_insert(@_);
  $self;
}

=head2 import

Will set up the caller class with L<Mad::Mapper> functionality if "-base"
is given as argument. See L</SYNOPSIS> for example.

=cut

# Most of this code is copy/paste from Mojo::Base
sub import {
  my $class = shift;
  return unless my $flag = shift;

  if    ($flag eq '-base')   { $flag = $class }
  elsif ($flag eq '-strict') { $flag = undef }
  elsif ((my $file = $flag) && !$flag->can('new')) {
    $file =~ s!::|'!/!g;
    require "$file.pm";
  }

  if ($flag) {
    my $caller = caller;
    my $table = Mojo::Util::decamelize((split /::/, $caller)[-1]);
    $table =~ s!s?$!s!;    # user => users
    Mojo::Util::monkey_patch($caller, col      => sub { $caller->_define_col(@_) });
    Mojo::Util::monkey_patch($caller, columns  => sub { @{$COLUMNS{$caller} || []} });
    Mojo::Util::monkey_patch($caller, has      => sub { Mojo::Base::attr($caller, @_) });
    Mojo::Util::monkey_patch($caller, has_many => sub { $caller->_define_has_many(@_) });
    Mojo::Util::monkey_patch($caller,
      pk => sub { return UNIVERSAL::isa($_[0], $caller) ? $PK{$caller} : $caller->_define_pk(@_) });
    Mojo::Util::monkey_patch($caller, table => sub { $table = $_[0] unless UNIVERSAL::isa($_[0], $caller); $table });
    no strict 'refs';
    push @{"${caller}::ISA"}, $flag;
  }

  $_->import for qw(strict warnings utf8);
  feature->import(':5.10');
}

sub _delete {
  my ($self, $cb) = @_;
  my @sql = $self->_delete_sql;

  warn "[Mad::Mapper::delete] ", Mojo::JSON::encode_json(\@sql), "\n" if DEBUG;

  if ($cb) {
    weaken $self;
    $self->db->query(
      @sql,
      sub {
        my ($db, $err, $res) = @_;
        warn "[Mad::Mapper::delete] err=$err\n" if DEBUG and $err;
        $self->in_storage(0) unless $err;
        $self->$cb($err);
      }
    );
  }
  else {
    $self->db->query(@sql);
    $self->in_storage(0);
  }
}

sub _delete_sql {
  my $self = shift;
  my $pk   = $self->_pk_or_first_column;

  $self->expand_sql("DELETE FROM %t WHERE $pk=?"), $self->$pk;
}

sub _delete_sst {
  Mojo::Util::deprecated("_delete_sst() is deprecated in favor of _delete_sql()");
  shift->_delete_sql(@_);
}

sub _define_col {
  my $class = ref($_[0]) || $_[0];
  push @{$COLUMNS{$class}}, ref $_[0] eq 'ARRAY' ? @{$_[1]} : $_[1];
  Mojo::Base::attr(@_);
}

sub _define_has_many {
  my ($class, $method, $related_class, $related_col) = @_;
  my $pk         = $class->_pk_or_first_column;
  my $sql_method = $class->can("_has_many_${method}_sql");

  Mojo::Util::monkey_patch(
    $class => $method => sub {
      my $cb    = ref $_[-1] eq 'CODE' ? pop : undef;
      my $self  = shift;
      my $err   = $LOADED{$related_class}++ ? 0 : load_class $related_class;
      my $fresh = delete $self->{fresh};
      my $ck    = join ':', $method, grep { $_ // '' } @_;
      my @sql;

      die ref $err ? "Exception: $err" : "Could not find class $related_class!" if $err;

      @sql
        = $sql_method
        ? $self->$sql_method($related_class, @_)
        : $related_class->expand_sql("SELECT %pc FROM %t WHERE $related_col=?", $self->$pk);

      warn sprintf "[Mad::Mapper::has_many::$method] %s\n",
        (!$fresh and $self->{cache}{$ck}) ? 'CACHED' : Mojo::JSON::encode_json(\@sql)
        if DEBUG;

      if ($cb) {
        if ($fresh or !$self->{cache}{$ck}) {
          $self->db->query(
            @sql,
            sub {
              my ($db, $err, $res) = @_;
              warn "[Mad::Mapper::has_many::$method] err=$err\n" if DEBUG and $err;
              $self->{cache}{$ck} = $res->hashes->map(sub { $related_class->new($_)->in_storage(1) });
              $self->$cb($err, $self->{cache}{$ck});
            }
          );
        }
        else {
          $self->$cb('', $self->{cache}{$ck});
        }
        return $self;
      }
      else {
        delete $self->{cache}{$ck} if $fresh;
        return $self->{cache}{$ck}
          ||= $self->db->query(@sql)->hashes->map(sub { $related_class->new($_)->in_storage(1) });
      }
    }
  );

  my $add_method = "add_$method";
  $add_method =~ s!s?$!!;
  Mojo::Util::monkey_patch(
    $class => $add_method => sub {
      my $self = shift;
      my $err = $LOADED{$related_class}++ ? 0 : load_class $related_class;
      $related_class->new(db => $self->db, @_, $related_col => $self->$pk);
    }
  );
}

sub _define_pk {
  my $class = ref($_[0]) || $_[0];
  $PK{$class} = $_[1];
  Mojo::Base::attr(@_);
}

sub _find {
  my ($self, $cb) = @_;
  my @sql = $self->_find_sql;

  warn "[Mad::Mapper::find] ", Mojo::JSON::encode_json(\@sql), "\n" if DEBUG;
  if ($cb) {
    weaken $self;
    $self->db->query(
      @sql,
      sub {
        my ($db, $err, $res) = @_;
        warn "[Mad::Mapper::find] err=$err\n" if DEBUG and $err;
        $res = $err ? {} : $res->hash || {};
        $self->in_storage(1) if %$res and !$err;
        $self->{$_} = $res->{$_} for keys %$res;
        $self->$cb($err);
      }
    );
  }
  else {
    my $res = $self->db->query(@sql)->hash || {};
    $self->in_storage(1) if keys %$res;
    $self->{$_} = $res->{$_} for keys %$res;
  }
}

sub _find_sql {
  my $self = shift;
  my $pk   = $self->_pk_or_first_column;

  $self->expand_sql("SELECT %pc FROM %t WHERE $pk=?"), $self->$pk;
}

sub _find_sst {
  Mojo::Util::deprecated("_find_sst() is deprecated in favor of _find_sql()");
  shift->_find_sql(@_);
}

sub _insert {
  my ($self, $cb) = @_;
  my $pk  = $self->_pk_or_first_column;
  my $db  = $self->db;
  my @sql = $self->_insert_sql;

  warn "[Mad::Mapper::insert] ", Mojo::JSON::encode_json(\@sql), "\n" if DEBUG;

  if ($cb) {
    weaken $self;
    $db->query(
      @sql,
      sub {
        my ($db, $err, $res) = @_;
        warn "[Mad::Mapper::insert] err=$err\n" if DEBUG and $err;
        $res = eval { $res->hash } || {};

        if ($pk) {
          $res->{$pk} ||= $db->dbh->last_insert_id(undef, undef, $self->table, $self->pk);
          $res->{$pk} ||= eval { $res->sth->mysql_insertid };    # can probably be removed
        }

        $self->in_storage(1) if keys %$res;
        $self->$_($res->{$_}) for grep { $self->can($_) } keys %$res;
        $self->$cb($err);
      }
    );
  }
  else {
    my $res = $db->query(@sql);
    $res = eval { $res->hash } || {};

    if ($pk) {
      $res->{$pk} ||= $db->dbh->last_insert_id(undef, undef, $self->table, $self->pk);
      $res->{$pk} ||= eval { $res->sth->mysql_insertid }    # can probably be removed;
    }

    $self->in_storage(1) if keys %$res;
    $self->$_($res->{$_}) for grep { $self->can($_) } keys %$res;    # used with Mojo::Pg and RETURNING
  }
}

sub _insert_sql {
  my $self = shift;
  my $pk   = $self->pk;
  my $sql  = "INSERT INTO %t (%c) VALUES (%c?)";

  $sql .= " RETURNING $pk" if $pk and UNIVERSAL::isa($self->db, 'Mojo::Pg::Database');
  $self->expand_sql($sql), map { $self->$_ } $self->columns;
}

sub _insert_sst {
  Mojo::Util::deprecated("_insert_sst() is deprecated in favor of _insert_sql()");
  shift->_insert_sql(@_);
}

sub _pk_or_first_column { $_[0]->pk || ($_[0]->columns)[0] }

sub _update {
  my ($self, $cb) = @_;
  my @sql = $self->_update_sql;

  warn "[Mad::Mapper::update] ", Mojo::JSON::encode_json(\@sql), "\n" if DEBUG;

  if ($cb) {
    weaken $self;
    $self->db->query(
      @sql,
      sub {
        my ($db, $err, $res) = @_;
        warn "[Mad::Mapper::update] err=$err\n" if DEBUG and $err;
        $self->$cb($err);
      }
    );
  }
  else {
    $self->db->query(@sql);
  }
}

sub _update_sql {
  my $self = shift;
  my $pk   = $self->_pk_or_first_column;

  $self->expand_sql("UPDATE %t SET %c= WHERE $pk=?"), (map { $self->$_ } $self->columns), $self->$pk;
}

sub _update_sst {
  Mojo::Util::deprecated("_update_sst() is deprecated in favor of _update_sql()");
  shift->_update_sql(@_);
}

sub TO_JSON {
  my $self = shift;
  my $pk   = $self->pk;
  return {$pk ? ($pk => $self->$pk) : (), map { ($_ => $self->$_) } $self->columns};
}

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=head1 AUTHOR

Jan Henning Thorsen - C<jhthorsen@cpan.org>

Красимир Беров - C<berov@cpan.org>

Stefan Adams - C<sadams@cpan.org>

=cut

1;
