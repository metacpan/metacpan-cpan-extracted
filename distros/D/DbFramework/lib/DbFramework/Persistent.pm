=head1 NAME

DbFramework::Persistent - Persistent Perl object base class

=head1 SYNOPSIS

  package Foo;
  use base qw(DbFramework::Persistent);

  package main;
  $foo = new Foo($table,$dbh,$catalog);
  $foo->attributes_h(\%foo};
  $foo->insert;
  $foo->attributes_h(\%new_foo);
  $foo->update(\%attributes);
  $foo->delete;
  $foo->init_pk;
  @foo     = $foo->select($condition,$order);
  $hashref = $foo->table_qualified_attribute_hashref;
  $code    = DbFramework::Persistent::make_class($name);

=head1 DESCRIPTION

Base class for persistent objects which use a DBI database for
storage.  To create your own persistent object classes subclass
B<DbFramework::Persistent> (see the make_class() class method.)

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::Persistent;
use strict;
use vars qw( $TABLE $_DEBUG $VERSION %ATTRIBUTES_H $CATALOG );
$VERSION = '1.10';
use base qw(DbFramework::Util);
use Alias;
use DbFramework::Table;

## CLASS DATA

my $Debugging = 0;

my %fields = (
	      TABLE        => undef,
	      ATTRIBUTES_H => undef,
	      CATALOG      => undef,
);

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($table,$dbh,$catalog)

Create a new persistent object. I<$table> is a B<DbFramework::Table>
object or the name of a database table.  I<$dbh> is a B<DBI> database
handle which refers to a database containing a table associated with
I<$table>.  I<$catalog> is a B<DbFramework::Catalog> object.

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my($table,$dbh,$catalog) = @_;
  my $self = bless { _PERMITTED => \%fields, %fields, }, $class;
  $table = new DbFramework::Table($table,undef,undef,$dbh)
    unless (ref($table) eq 'DbFramework::Table');
  $self->table($table->init_db_metadata($catalog));
  $self->catalog($catalog);
  return $self;
}

##-----------------------------------------------------------------------------

=head2 make_class($name)

Returns some Perl code which can be used with eval() to create a new
persistent object (sub)class called I<$name>.

=cut

sub make_class {
  my($proto,$name) = @_;
  my $class = ref($proto) || $proto;

  my $code = qq{package $name;
use strict;
use base qw(DbFramework::Persistent);
};
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

Attributes in a persistent object which relate to columns in the
associated table are made available through the attribute
I<ATTRIBUTES_H>.  See L<DbFramework::Util/AUTOLOAD()> for the accessor
methods for this attribute.

=head2 delete()

Delete this object from the associated table based on the values of
it's primary key attributes.  Returns the number of rows deleted if
supplied by the DBI driver.

=cut

sub delete {
  my $self = attr shift;
  return $TABLE->delete($self->_pk_conditions);
}

#------------------------------------------------------------------------------

=head2 insert()

Insert this object in the associated table.  Returns the primary key
of the inserted row if it is a Mysql 'AUTO_INCREMENT' column or -1.

=cut

sub insert {
  my $self = attr shift;
  return $TABLE->insert($self->attributes_h);
}

#------------------------------------------------------------------------------

=head2 update(\%attributes)

Update this object in the associated table.  I<%attributes> is a hash
whose keys contain primary key column names and whose values will be
concatenated with 'ANDs' to form a SQL 'WHERE' clause.  The default
values of I<%attributes> is the hash returned by attributes_h().  Pass
the B<current> primary key attributes as an argument in I<%attributes>
when you need to update one or more primary key columns.  Returns the
number of rows updated if supplied by the DBI driver.

=cut

sub update {
  my $self = attr shift;
  my %attributes = defined($_[0]) ? %{$_[0]} : %{$self->attributes_h};
  # get pk attributes
  my %pk_attributes;
  for ( $TABLE->is_identified_by->attribute_names ) {
    $pk_attributes{$_} = $attributes{$_};
  }
  return $TABLE->update($self->attributes_h,$self->where_and(\%pk_attributes));
}

#------------------------------------------------------------------------------

=head2 select($conditions,$order)

Returns a list of objects of the same class as the object which
invokes it.  Each object in the list has its attributes initialised
from the values returned by selecting all columns from the associated
table matching I<$conditions> ordered by the list of columns in
I<$order>.

=cut

sub select {
  my $self = attr shift;

  my @things;
  my @columns = $TABLE->attribute_names;
  for ( $TABLE->select(\@columns,shift,shift) ) {
    print STDERR "\@{\$_} = @{$_}\n" if $_DEBUG;
    # pass Table *object* to new to retain any fk relationships
    my $thing = $self->new($TABLE,$TABLE->dbh,$CATALOG);
    my %attributes;
    for ( my $i = 0; $i <= $#columns; $i++ ) {
      print STDERR "assigning $columns[$i] = $_->[$i]\n" if $_DEBUG;
      $attributes{$columns[$i]} = $_->[$i];
    }
    $thing->attributes_h([%attributes]);
    push(@things,$thing);
  }
  return @things;
}

##-----------------------------------------------------------------------------

#=head2 validate_required()

#Returns a list of attribute names which must B<not> be NULL but are
#undefined.  If I<@attributes> is undefined, validates all attributes.

#=cut

#sub validate_required {
#  my $self  = attr shift; my $table = $self->table;
#  my($attribute,@invalid);

#  my @attributes = @_ ? @_ : sort keys(%STATE);
#  foreach $attribute ( @attributes ) {
#    my $column = $table->get_column($attribute);
#    if ( ! $column->null && ! defined($self->get_attribute($attribute)) ) {
#      my $heading = $column->heading;
#      if ( $heading ) {
#	push(@invalid,$heading)
#      } else {
#	push(@invalid,$attribute);
#      }
#    }
#  }   
#  return @invalid;
#}

##-----------------------------------------------------------------------------

# return a SQL 'WHERE' clause condition consisting of primary key
# attributes and their corresponding values joined by 'AND'

sub _pk_conditions {
  my $self       = attr shift;
  my @attributes = @{$TABLE->is_identified_by->incorporates_l};
  my %values     = %{$self->attributes_h};
  my %pk_attributes;
  for ( @attributes ) {
    my $column = $_->name;
    $pk_attributes{$column} = $values{$column};
  }
  return $self->where_and(\%pk_attributes);
}

##-----------------------------------------------------------------------------

# return a SQL 'WHERE' clause condition consisting of attributes named
# after keys in %attributes and their corresponding values joined by
# 'AND'
 
sub where_and {
  my $self       = attr shift;
  my %attributes = %{$_[0]};
  my $conditions;
  for ( keys %attributes ) {
    my($attribute) = $TABLE->get_attributes($_);
    $conditions .= ' AND ' if $conditions;
    my($name,$type) = ($attribute->name,$attribute->references->type);
    $conditions .= "$name = " . $TABLE->dbh->quote($attributes{$name},$type);
  }
  print STDERR "$conditions\n" if $_DEBUG;
  $conditions;
}

##-----------------------------------------------------------------------------

#=head2 fill_template($name)

#Returns the template named I<$name> in the table associated with this
#object filled with the object's attribute values.  See
#L<DbFramework::Table/"fill_template()">.

#=cut

sub fill_template {
  my($self,$name) = (attr shift,shift);
  $TABLE->fill_template($name,$self->attributes_h);
}

##-----------------------------------------------------------------------------

=head2 as_html_form()

Returns an HTML form representing the object, filled with the object's
attribute values.

=cut

sub as_html_form {
  my $self = attr shift;
  my %attributes = %{$self->attributes_h};
  my $html;
  for ( @{$self->table->contains_l} ) {
    next if $self->table->in_foreign_key($_);
    my $name = $_->name;
    $html .= "<TR><TD><STRONG>$name</STRONG></TD><TD>"
          . $_->as_html_form_field($attributes{$name})
          .  "</TD></TR>\n";
  }
  return $html;
}

#------------------------------------------------------------------------------

=head2 init_pk()

Initialise an object by setting its attributes based on the current
value of the its primary key attributes.

=cut

sub init_pk {
  my $self = attr shift;
  my @loh  = $TABLE->select_loh(undef,$self->_pk_conditions);
  $self->attributes_h([ %{$loh[0]} ]);
}

#------------------------------------------------------------------------------

=head2 table_qualified_attribute_hashref()

Returns a reference to a hash whose keys are the keys of
I<%ATTRIBUTES_H> with a prefix of I<$table>, where I<$table> is the
table associated with the object and whose values are values from
I<%ATTRIBUTES_H>.  This is useful for filling a template (see
L<DbFramework::Template/fill()>.)

=cut

sub table_qualified_attribute_hashref {
  my $self   = attr shift;
  my $t_name = $TABLE->name;
  my %tq;
  for ( keys %ATTRIBUTES_H ) { $tq{"$t_name.$_"} = $ATTRIBUTES_H{$_} }
  return \%tq;
}

1;

=head1 SEE ALSO

L<DbFramework::Util>, L<DbFramework::Table> and
L<DbFramework::Template>.

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1997,1998,1999 Paul Sharpe. England.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

