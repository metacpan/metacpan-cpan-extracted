package Maypole::Model::CDBI::Base;
use strict;

=head1 NAME

Maypole::Model::CDBI::Base - Model base class based on Class::DBI

=head1 DESCRIPTION

This is a master model class which uses L<Class::DBI> to do all the hard
work of fetching rows and representing them as objects. It is a good
model to copy if you're replacing it with other database abstraction
modules.

It implements a base set of methods required for a Maypole Data Model.

It inherits accessor and helper methods from L<Maypole::Model::Base>.

=cut

use base qw(Maypole::Model::Base Class::DBI);
use Class::DBI::AbstractSearch;
use Class::DBI::Plugin::RetrieveAll;
use Class::DBI::Pager;
use Lingua::EN::Inflect::Number qw(to_PL);
use attributes ();
use Data::Dumper;

__PACKAGE__->mk_classdata($_) for (qw/COLUMN_INFO/);

=head2 add_model_superclass

Adds model as superclass to model classes (if necessary)

=cut

sub add_model_superclass {
  my ($class,$config) = @_;
  foreach my $subclass ( @{ $config->classes } ) {
    next if $subclass->isa("Maypole::Model::Base");
    no strict 'refs';
    push @{ $subclass . "::ISA" }, $config->model;
  }
  return;
}

=head1 Action Methods

Action methods are methods that are accessed through web (or other public) interface.

=head2 do_edit

If there is an object in C<$r-E<gt>objects>, then it should be edited
with the parameters in C<$r-E<gt>params>; otherwise, a new object should
be created with those parameters, and put back into C<$r-E<gt>objects>.
The template should be changed to C<view>, or C<edit> if there were any
errors. A hash of errors will be passed to the template.

=cut

sub do_edit : Exported {
  my ($self, $r, $obj) = @_;

  my $config   = $r->config;
  my $table    = $r->table;

  # handle cancel button hit
  if ( $r->{params}->{cancel} ) {
    $r->template("list");
    $r->objects( [$self->retrieve_all] );
    return;
  }

  my $required_cols = $config->{$table}{required_cols} || $self->required_columns;
  my $ignored_cols  = $config->{$table}{ignore_cols} || [];

  ($obj, my $fatal, my $creating) = $self->_do_update_or_create($r, $obj, $required_cols, $ignored_cols);

  # handle errors, if none, proceed to view the newly created/updated object
  my %errors = $fatal ? (FATAL => $fatal) : $obj->cgi_update_errors;

  if (%errors) {
    # Set it up as it was:
    $r->template_args->{cgi_params} = $r->params;

    # replace user unfriendly error messages with something nicer

    foreach (@{$config->{$table}->{required_cols}}) {
      next unless ($errors{$_});
      my $key = $_;
      s/_/ /g;
      $r->template_args->{errors}{ucfirst($_)} = 'This field is required, please provide a valid value';
      $r->template_args->{errors}{$key} = 'This field is required, please provide a valid value';
      delete $errors{$key};
    }

    foreach (keys %errors) {
      my $key = $_;
      s/_/ /g;
      $r->template_args->{errors}{ucfirst($_)} = 'Please provide a valid value for this field';
      $r->template_args->{errors}{$key} = 'Please provide a valid value for this field';
    }

    undef $obj if $creating;

    die "do_update failed with error : $fatal" if ($fatal);
    $r->template("edit");
  } else {
    $r->template("view");
  }

  $r->objects( $obj ? [$obj] : []);
}

# split out from do_edit to be reported by Mp::P::Trace
sub _do_update_or_create {
  my ($self, $r, $obj, $required_cols, $ignored_cols) = @_;

  my $fatal;
  my $creating = 0;

  my $h = $self->Untainter->new( %{$r->params} );

  # update or create
  if ($obj) {
    # We have something to edit
    eval { $obj->update_from_cgi( $h => {
					 required => $required_cols,
					 ignore => $ignored_cols,
					}); 
	   $obj->update(); # pos fix for bug 17132 'autoupdate required by do_edit'
	 };
    $fatal = $@;
  } else {
    	eval {
      	$obj = $self->create_from_cgi( $h => {
					    required => $required_cols,
					    ignore => $ignored_cols,
					   } );
    	};
    	$fatal = $@;
    	$creating++;
  }
  return $obj, $fatal, $creating;
}

=head2 view

This command shows the object using the view factory template.

=cut

sub view : Exported {
  my ($self, $r) = @_;
  $r->build_form_elements(0);
  return;
}


=head2 delete

Deprecated method that calls do_delete or a given classes delete method, please
use do_delete instead

=head2 do_delete

Unsuprisingly, this command causes a database record to be forever lost.

This method replaces the, now deprecated, delete method provided in prior versions

=cut

sub delete : Exported {
  my $self = shift;
  my ($sub) = (caller(1))[3];
  # So subclasses can still send delete down ...
  $sub =~ /^(.+)::([^:]+)$/;
  if ($1 ne "Maypole::Model::Base" && $2 ne "delete") {
    $self->SUPER::delete(@_);
  } else {
    warn "Maypole::Model::CDBI::Base delete method is deprecated\n";
    $self->do_delete(@_);
  }
}

sub do_delete : Exported {
  my ( $self, $r ) = @_;
  # FIXME: handle fatal error with exception
  $_->SUPER::delete for @{ $r->objects || [] };
#  $self->dbi_commit;
  $r->objects( [ $self->retrieve_all ] );
  $r->{template} = "list";
  $self->list($r);
}

=head2 search

Deprecated searching method - use do_search instead.

=head2 do_search

This action method searches for database records, it replaces
the, now deprecated, search method previously provided.

=cut

sub search : Exported {
  my $self = shift;
  my ($sub) = (caller(1))[3];
  # So subclasses can still send search down ...
  if ($sub =~ /^(.+)::([^:]+)$/) {
    return ($1 ne "Maypole::Model::Base" && $2 ne "search") ?
      $self->SUPER::search(@_) : $self->do_search(@_);
  } else {
    $self->SUPER::search(@_);
  }
}

sub do_search : Exported {
    my ( $self, $r ) = @_;
    my %fields = map { $_ => 1 } $self->columns;
    my $oper   = "like";                                # For now
    my %params = %{ $r->{params} };
    my %values = map { $_ => { $oper, $params{$_} } }
      grep { defined $params{$_} && length ($params{$_}) && $fields{$_} }
      keys %params;

    $r->template("list");
    if ( !%values ) { return $self->list($r) }
    my $order = $self->order($r);
    $self = $self->do_pager($r);

    # FIXME: use pager info to get slice of iterator instead of all the objects as array

    $r->objects(
        [
            $self->search_where(
                \%values, ( $order ? { order_by => $order } : () )
            )
        ]
    );
    $r->{template_args}{search} = 1;
}

=head2 list

The C<list> method fills C<$r-E<gt>objects> with all of the
objects in the class. The results are paged using a pager.

=cut

sub list : Exported {
    my ( $self, $r ) = @_;
    my $order = $self->order($r);
    $self = $self->do_pager($r);
    if ($order) {
        $r->objects( [ $self->retrieve_all_sorted_by($order) ] );
    }
    else {
        $r->objects( [ $self->retrieve_all ] );
    }
}

###############################################################################
# Helper methods

=head1 Helper Methods


=head2 adopt

This class method is passed the name of a model class that represents a table
and allows the master model class to do any set-up required.

=cut

sub adopt {
    my ( $self, $child ) = @_;
    $child->autoupdate(1);
    if ( my $col = $child->stringify_column ) {
        $child->columns( Stringify => $col );
    }
}


=head2 related

This method returns a list of has-many accessors. A brewery has many
beers, so C<BeerDB::Brewery> needs to return C<beers>.

=cut

sub related {
    my ( $self, $r ) = @_;
    return keys %{ $self->meta_info('has_many') || {} };
}


=head2 related_class

Given an accessor name as a method, this function returns the class this accessor returns.

=cut

sub related_class {
     my ( $self, $r, $accessor ) = @_;
     my $meta = $self->meta_info;
     my @rels = keys %$meta;
     my $related;
     foreach (@rels) {
         $related = $meta->{$_}{$accessor};
         last if $related;
     }
     return unless $related;

     my $mapping = $related->{args}->{mapping};
     if ( $mapping and @$mapping ) {
       return $related->{foreign_class}->meta_info('has_a')->{$$mapping[0]}->{foreign_class};
     }
     else {
         return $related->{foreign_class};
     }
 }

=head2 search_columns

  $class->search_columns;

Returns a list of columns suitable for searching - used in factory templates, over-ridden in
classes. Provides same list as display_columns unless over-ridden.

=cut

sub search_columns {
  my $class = shift;
  return $class->display_columns;
}


=head2 related_meta

  $class->related_meta($col);

Returns the hash ref of relationship meta info for a given column.

=cut

sub related_meta {
    my ($self,$r, $accssr) = @_;
    $self->_croak("You forgot to put the place holder for 'r' or forgot the accssr parameter") unless $accssr;
    my $class_meta = $self->meta_info;
    if (my ($rel_type) = grep { defined $class_meta->{$_}->{$accssr} }
        keys %$class_meta)
    { return  $class_meta->{$rel_type}->{$accssr} };
}



=head2 stringify_column

   Returns the name of the column to use when stringifying
   and object.

=cut

sub stringify_column {
    my $class = shift;
    return (
        $class->columns("Stringify"),
        ( grep { /^(name|title)$/i } $class->columns ),
        ( grep { /(name|title)/i } $class->columns ),
        ( grep { !/id$/i } $class->primary_columns ),
    )[0];
}

=head2 do_pager

   Sets the pager template argument ($r->{template_args}{pager})
   to a Class::DBI::Pager object based on the rows_per_page
   value set in the configuration of the application.

   This pager is used via the pager macro in TT Templates, and
   is also accessible via Mason.

=cut

sub do_pager {
    my ( $self, $r ) = @_;
    if ( my $rows = $r->config->rows_per_page ) {
        return $r->{template_args}{pager} =
          $self->pager( $rows, $r->query->{page} );
    }
    else { return $self }
}


=head2 order

    Returns the SQL order syntax based on the order parameter passed
    to the request, and the valid columns.. i.e. 'title ASC' or 'date_created DESC'.

    $sql .= $self->order($r);

    If the order column is not a column of this table,
    or an order argument is not passed, then the return value is undefined.

    Note: the returned value does not start with a space.

=cut

sub order {
    my ( $self, $r ) = @_;
    my %ok_columns = map { $_ => 1 } $self->columns;
    my $q = $r->query;
    my $order = $q->{order};
    return unless $order and $ok_columns{$order};
    $order .= ' DESC' if $q->{o2} and $q->{o2} eq 'desc';
    return $order;
}


=head2 fetch_objects

Returns 1 or more objects of the given class when provided with the request

=cut

sub fetch_objects {
    my ($class, $r)=@_;
    my @pcs = $class->primary_columns;
    if ( $#pcs ) {
    my %pks;
        @pks{@pcs}=(@{$r->{args}});
        return $class->retrieve( %pks );
    }
    return $class->retrieve( $r->{args}->[0] );
}


=head2 _isa_class

Private method to return the class a column 
belongs to that was inherited by an is_a relationship.
This should probably be public but need to think of API

=cut

sub _isa_class {
    my ($class, $col) = @_;
    $class->_croak( "Need a column for _isa_class." ) unless $col;
    my $isaclass;
    my $isa = $class->meta_info("is_a") || {};
    foreach ( keys %$isa ) {
        $isaclass = $isa->{$_}->foreign_class;
        return $isaclass if ($isaclass->find_column($col));
    }
    return; # col not in a is_a class
}


# Thanks to dave baird --  form builder for these private functions
# sub _column_info {
sub _column_info {
  my $self = shift;
  my $dbh = $self->db_Main;

  my $meta;			# The info we are after
  my ($catalog, $schema) = (undef, undef); 
  # Dave is suspicious this (above undefs) could 
  # break things if driver useses this info

  my $original_metadata;
  # '%' is a search pattern for columns - matches all columns
  if ( my $sth = $dbh->column_info( $catalog, $schema, $self->table, '%' ) ) {
    $dbh->errstr && die "Error getting column info sth: " . $dbh->errstr;
    $self->COLUMN_INFO ($self->_hash_type_meta( $sth ));
  } else {
    $self->COLUMN_INFO ($self->_hash_typeless_meta( ));
  }

  return $self->COLUMN_INFO;
}

sub _hash_type_meta {
  my ($self, $sth) = @_;
  my $meta;
  while ( my $row = $sth->fetchrow_hashref ) {
    my $colname = $row->{COLUMN_NAME} || $row->{column_name};

    # required / nullable
    $meta->{$colname}{nullable} = $row->{NULLABLE};
    $meta->{$colname}{required} = ( $meta->{$colname}{nullable} == 0 ) ? 1 : 0;

    # default
    if (defined $row->{COLUMN_DEF}) {
      my $default = $row->{COLUMN_DEF};
      $default =~ s/['"]?(.*?)['"]?::.*$/$1/;
      $meta->{$colname}{default} = $default;
    }else {
      $meta->{$colname}{default} = '';
    }

    # type
    my $type = $row->{mysql_type_name} || $row->{type};
    unless ($type) {
      $type =  $row->{TYPE_NAME};
      if ($row->{COLUMN_SIZE}) {
	$type .= "($row->{COLUMN_SIZE})";
      }
    }
    $type =~ s/['"]?(.*)['"]?::.*$/$1/;
    # Bool if tinyint
    if ($type and $type =~ /^tinyint/i and $row->{COLUMN_SIZE} == 1) { 
      $type = 'BOOL';
    }
    $meta->{$colname}{type} = $type;

    # order
    $meta->{$colname}{position} = $row->{ORDINAL_POSITION}
  }
  return $meta;
}

# typeless db e.g. sqlite
sub _hash_typeless_meta {
  my ( $self ) = @_;

  $self->set_sql( fb_meta_dummy => 'SELECT * FROM __TABLE__ WHERE 1=0' )
    unless $self->can( 'sql_fb_meta_dummy' );

  my $sth = $self->sql_fb_meta_dummy;

  $sth->execute or die "Error executing column info: "  . $sth->errstr;;

  # see 'Statement Handle Attributes' in the DBI docs for a list of available attributes
  my $cols  = $sth->{NAME};
  my $types = $sth->{TYPE};
  # my $sizes = $sth->{PRECISION};    # empty
  # my $nulls = $sth->{NULLABLE};     # empty

  # we haven't actually fetched anything from the sth, so need to tell DBI we're not going to
  $sth->finish;

  my $order = 0;
  my $meta;
  foreach my $col ( @$cols ) {
    my $col_meta;
    $col_meta->{nullable}    = 1;
    $col_meta->{required}    = 0;
    $col_meta->{default}     = '';
    $col_meta->{position} = $order++;
    # type_name is taken literally from the schema, but is not actually used by sqlite,
    # so it can be anything, e.g. varchar or varchar(xxx) or VARCHAR etc.
    my $type = shift( @$types );
    $col_meta->{type} = ($type =~ /(\w+)\((\w+)\)/) ? $1 :$type ;
    $meta->{$col} = $col_meta;
  }
  return $meta;
}

=head2 column_type

    my $type = $class->column_type('column_name');

This returns the 'type' of this column (VARCHAR(20), BIGINT, etc.)
For now, it returns "BOOL" for tinyints.

TODO :: TEST with enums

=cut

sub column_type {
  my $class = shift;
  my $colname = shift or die "Need a column for column_type";
  $class->_column_info() unless (ref $class->COLUMN_INFO);

  if ($class->_isa_class($colname)) {
    return $class->_isa_class($colname)->column_type($colname);
  }
  unless ( $class->find_column($colname) ) {
    warn "$colname is not a recognised column in this class ", ref $class || $class, "\n";
    return undef;
  }
  return $class->COLUMN_INFO->{$colname}{type};
}

=head2 required_columns

  Accessor to get/set required columns for forms, validation, etc.

  Returns list of required columns. Accepts an array ref of column names.

  $class->required_columns([qw/foo bar baz/]);

  Allows you to specify the required columns for a class, over-riding any
  assumptions and guesses made by Maypole.

  Any columns specified as required will no longer be 'nullable' or optional, and
  any columns not specified as 'required' will be 'nullable' or optional.

  The default for a column is nullable, or whatever is discovered from database
  schema.

  Use this instead of $config->{$table}{required_cols}

  Note : you need to setup the model class before calling this method.

=cut

sub required_columns {
  my ($class, $columns) = @_;
  $class->_column_info() unless (ref $class->COLUMN_INFO);
  my $column_info = $class->COLUMN_INFO;

  if ($columns) {
    # get the previously required columns
    my %previously_required = map { $_ => 1} grep($column_info->{$_}{required}, keys %$column_info);

    # update each specified column as required
    foreach my $colname ( @$columns ) {
      # handle C::DBI::Rel::IsA
      if ($class->_isa_class($colname)) {
	$class->_isa_class($colname)->COLUMN_INFO->{$colname}{required} = 1
	  unless ($class->_isa_class($colname)->column_required);
	next;
      }
      unless ( $class->find_column($colname) ) {
	warn "$colname is not a recognised column in this class ", ref $class || $class, "\n";
	next;
      }
      $column_info->{$colname}{required} = 1;
      delete $previously_required{$colname};
    }

    # no longer require any columns not specified
    foreach my $colname ( keys %previously_required ) {
      $column_info->{$colname}{required} = 0;
      $column_info->{$colname}{nullable} = 1;
    }

    # update column metadata
    $class->COLUMN_INFO($column_info);
  }

  return [ grep ($column_info->{$_}{required}, keys %$column_info) ] ;
}

=head2 column_required

  Returns true if a column is required

  my $required = $class->column_required($column_name);

  Columns can be required by the application but not the database, but not the other way around,
  hence there is also a column_nullable method which will tell you if the column is nullable
  within the database itself.

=cut

sub column_required {
  my ($class, $colname) = @_;
  $colname or $class->_croak( "Need a column for column_required" );
  $class->_column_info() unless ref $class->COLUMN_INFO;
  if ($class->_isa_class($colname)) {
    return $class->_isa_class($colname)->column_required($colname);
  }
  unless ( $class->find_column($colname) ) {
    # handle  non-existant columns
    warn "$colname is not a recognised column in this class ", ref $class || $class, "\n";
    return undef;
  }
  return $class->COLUMN_INFO->{$colname}{required} if ($class->COLUMN_INFO and $class->COLUMN_INFO->{$colname}); 
  return  0;
}

=head2 column_nullable

  Returns true if a column can be NULL within the underlying database and false if not.

  my $nullable = $class->column_nullable($column_name);

  Any columns that are not nullable will automatically be specified as required, you can
  also specify nullable columns as required within your application.

  It is recomended you use column_required rather than column_nullable within your
  application, this method is more useful if extending the model or handling your own
  validation.

=cut

sub column_nullable {
    my $class = shift;
    my $colname = shift or $class->_croak( "Need a column for column_nullable" );

  $class->_column_info() unless ref $class->COLUMN_INFO;
  if ($class->_isa_class($colname)) {
    return $class->_isa_class($colname)->column_nullable($colname);
  }
  unless ( $class->find_column($colname) ) {
    # handle  non-existant columns
    warn "$colname is not a recognised column in this class ", ref $class || $class, "\n";
    return undef;
  }
  return $class->COLUMN_INFO->{$colname}{nullable} if ($class->COLUMN_INFO and $class->COLUMN_INFO->{$colname}); 
  return  0;
}

=head2 column_default

Returns default value for column or the empty string. 
Columns with NULL, CURRENT_TIMESTAMP, or Zeros( 0000-00...) for dates and times
have '' returned.

=cut

sub column_default {
  my $class = shift;
  my $colname = shift or $class->_croak( "Need a column for column_default");
  $class->_column_info() unless (ref $class->COLUMN_INFO);
  if ($class->_isa_class($colname)) {
    return $class->_isa_class($colname)->column_default($colname);
  }
  unless ( $class->find_column($colname) ) {
    warn "$colname is not a recognised column in this class ", ref $class || $class, "\n";
    return undef;
  }

  return $class->COLUMN_INFO->{$colname}{default} if ($class->COLUMN_INFO and $class->COLUMN_INFO->{$colname}); 
  return; 
}

=head2 get_classmetadata

Gets class meta data *excluding cgi input* for the passed in class or the
calling class. *NOTE* excludes cgi inputs. This method is handy to call from 
templates when you need some metadata for a related class.

=cut

sub get_classmetadata {
    my ($self, $class) = @_; # class is class we want data for
    $class ||= $self;
    $class = ref $class || $class;

    my %res;
    $res{name}          = $class;
    $res{colnames}      = {$class->column_names};
    $res{columns}       = [$class->display_columns];
    $res{list_columns}  = [$class->list_columns];
    $res{moniker}       = $class->moniker;
    $res{plural}        = $class->plural_moniker;
    $res{table}         = $class->table;
    $res{column_metadata} = (ref $class->COLUMN_INFO) ? $class->COLUMN_INFO : $class->_column_info() ;
    return \%res;
}


=head1 SEE ALSO

L<Maypole>, L<Maypole::Model::Base>.

=head1 AUTHOR

Maypole is currently maintained by Aaron Trevena.

=head1 AUTHOR EMERITUS

Simon Cozens, C<simon#cpan.org>

Simon Flack maintained Maypole from 2.05 to 2.09

Sebastian Riedel, C<sri#oook.de> maintained Maypole from 1.99_01 to 2.04

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
