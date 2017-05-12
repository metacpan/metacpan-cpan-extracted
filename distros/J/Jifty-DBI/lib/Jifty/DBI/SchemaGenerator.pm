use strict;
use warnings;

package Jifty::DBI::SchemaGenerator;

use base qw(Class::Accessor::Fast);
use DBIx::DBSchema;
use DBIx::DBSchema::Column;
use DBIx::DBSchema::Table;
use Class::ReturnValue;
use version;

our $VERSION = '0.01';

# Public accessors
__PACKAGE__->mk_accessors(qw(handle));

# Internal accessors: do not use from outside class
__PACKAGE__->mk_accessors(qw(_db_schema));

=head1 NAME

Jifty::DBI::SchemaGenerator - Generate a table schema from Jifty::DBI records

=head1 DESCRIPTION

This module turns a Jifty::Record object into an SQL schema for your chosen
database. At the moment, your choices are MySQL, SQLite, or PostgreSQL.
Oracle might also work right, though it's untested.

=head1 SYNOPSIS

=head2 The Short Answer

See below for where we get the $handle and $model variables.

  use Jifty::DBI::SchemaGenerator;
  ...
  my $s_gen = Jifty::DBI::SchemaGenerator->new( $handle );
  $s_gen->add_model($model);

  my @statements = $s_gen->create_table_sql_statements;
  print join("\n", @statements, '');
  ...

=head2 The Long Version

See L<Jifty::DBI> for details about the first two parts.

=over

=item MyModel

  package MyModel; 
  # lib/MyModel.pm

  use warnings;
  use strict;

  use base qw(Jifty::DBI::Record);
  # your custom code goes here.
  1;

=item MyModel::Schema

  package MyModel::Schema;
  # lib/MyModel/Schema.pm

  use warnings;
  use strict;

  use Jifty::DBI::Schema;

  column foo => type is 'text';
  column bar => type is 'text';

  1;

=item myscript.pl

  #!/usr/bin/env perl
  # myscript.pl

  use strict;
  use warnings;

  use Jifty::DBI::SchemaGenerator;

  use Jifty::DBI::Handle;
  use MyModel;
  use MyModel::Schema;

  my $handle = Jifty::DBI::Handle->new();
  $handle->connect(
    driver   => 'SQLite',
    database => 'testdb',
  );

  my $model = MyModel->new($handle);
  my $s_gen = Jifty::DBI::SchemaGenerator->new( $handle );
  $s_gen->add_model($model);

  # here's the basic point of this module:
  my @statements = $s_gen->create_table_sql_statements;
  print join("\n", @statements, '');

  # this part is directly from Jifty::Script::Schema::create_all_tables()
  $handle->begin_transaction;
  for my $statement (@statements) {
    my $ret = $handle->simple_query($statement);
    $ret or die "error creating a table: " . $ret->error_message;
  }
  $handle->commit;

=back

=head1 CONFIGURATION AND ENVIRONMENT

Requires no configuration files or environment variables.


=head1 DEPENDENCIES

Class::Accessor::Fast

DBIx::DBSchema

Class::ReturnValue

=head1 METHODS

=head2 new HANDLE

Creates a new C<Jifty::DBI::SchemaGenerator> object.  The single
required argument is a C<Jifty::DBI::Handle>.

=cut

sub new {
    my $class  = shift;
    my $handle = shift;
    my $self   = $class->SUPER::new();

    $self->handle($handle);

    my $schema = DBIx::DBSchema->new();
    $self->_db_schema($schema);

    return $self;
}

=head2 add_model MODEL

Adds a new model class to the SchemaGenerator.  Model should be an
object which is an instance of C<Jifty::DBI::Record> or a subclass
thereof.  It may also be a string which is the name of such a
class/subclass; in the latter case, C<add_model> will instantiate an
object of the class.

The model must define the instance methods C<schema> and C<table>.

Returns true if the model was added successfully; returns a false
C<Class::ReturnValue> error otherwise.

=cut

sub add_model {
    my $self  = shift;
    my $model = shift;

    # $model could either be a (presumably unfilled) object of a subclass of
    # Jifty::DBI::Record, or it could be the name of such a subclass.

    unless ( ref $model and UNIVERSAL::isa( $model, 'Jifty::DBI::Record' ) ) {
        my $new_model;
        eval { $new_model = $model->new; };

        if ($@) {
            return $self->_error("Error making new object from $model: $@");
        }

        unless ( UNIVERSAL::isa( $new_model, 'Jifty::DBI::Record' ) ) {
            return $self->_error(
                "Didn't get a Jifty::DBI::Record from $model, got $new_model"
            );
        }
        $model = $new_model;
    }

    my $table_obj = $self->_db_schema_table_from_model($model);

    $self->_db_schema->addtable($table_obj);

    return 1;
}

=head2 column_definition_sql TABLENAME COLUMNNAME

Given a table name and a column name, returns the SQL fragment 
describing that column for the current database.

=cut

sub column_definition_sql {
    my $self = shift;
    my $table = shift;
    my $col = shift;
    my $table_obj = $self->_db_schema->table($table);
    return $table_obj->column( $col )->line( $self->handle->dbh )
}

=head2 create_table_sql_statements

Returns a list of SQL statements (as strings) to create tables for all of
the models added to the SchemaGenerator.

=cut

sub create_table_sql_statements {
    my $self = shift;

    return  map { $self->_db_schema->table($_)->sql_create_table($self->handle->dbh) }
           sort { $a cmp $b }
                $self->_db_schema->tables;
}

=head2 create_table_sql_text

Returns a string containing a sequence of SQL statements to create tables for all of
the models added to the SchemaGenerator.

This is just a trivial wrapper around L</create_table_sql_statements>.

=cut

sub create_table_sql_text {
    my $self = shift;

    return join "\n", map {"$_ ;\n"} $self->create_table_sql_statements;
}

=head2 PRIVATE _db_schema_table_from_model MODEL

Takes an object of a subclass of Jifty::DBI::Record; returns a new
C<DBIx::DBSchema::Table> object corresponding to the model.

=cut

sub _db_schema_table_from_model {
    my $self  = shift;
    my $model = shift;

    my $table_name = $model->table;
    my @columns    = $model->columns;

    my @cols;
    my @indexes;

    for my $column (@columns) {

        # Skip "Virtual" columns - (foreign keys to collections)
        next if $column->virtual;

        # Skip computed columns
        next if $column->computed;

        # If schema_version is defined, make sure columns are for that version
        if ($model->can('schema_version') and defined $model->schema_version) {

            # Skip it if the app version is earlier than the column version
            next if defined $column->since 
                and $model->schema_version <  version->new($column->since);

            # Skip it if the app version is the same as or later than the 
            # column version
            next if defined $column->till
                and $model->schema_version >= version->new($column->till);

        }

        # Otherwise, assume the latest version and eliminate till columns
        next if (!$model->can('schema_version') or !defined $model->schema_version)
            and defined $column->till;

        # Encode default values
        my $default = $column->default;

        # Scalar::Defer-powered defaults do not get a default in the database
        if (ref($default) ne '0' && defined $default) {
            $model->_handle($self->handle);
            $model->_apply_input_filters(
                column    => $column,
                value_ref => \$default,
            );
            $default = \"''" if defined $default and not length $default;
            $model->_handle(undef);
        } else {
            $default = '';
        }

        push @cols,
            DBIx::DBSchema::Column->new(
            {   name     => $column->name,
                type     => $column->type,
                null     => $column->mandatory ? 0 : 1,
                default  => $default,
            }
            );

        if ($column->indexed) {
            push @indexes,[$column->name];
        }
    }

    my $index_count = 1;
    my $table = DBIx::DBSchema::Table->new(
        {   name        => $table_name,
            primary_key => "id",
            columns     => \@cols,
            (@indexes) ? (indices => [map {DBIx::DBSchema::Index->new(name => $table_name.$index_count++, columns => $_) } @indexes]) : ()
        }
    );

    return $table;
}

=head2 PRIVATE _error STRING

Takes in a string and returns it as a Class::ReturnValue error object.

=cut

sub _error {
    my $self    = shift;
    my $message = shift;

    my $ret = Class::ReturnValue->new;
    $ret->as_error( errno => 1, message => $message );
    return $ret->return_value;
}

1;    # Magic true value required at end of module

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-E<lt>RT NAMEE<gt>@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

David Glasser  C<< glasser@bestpractical.com >>

Some pod by Eric Wilhelm <ewilhelm at cpan dot org>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2005, Best Practical Solutions, LLC.  All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut

