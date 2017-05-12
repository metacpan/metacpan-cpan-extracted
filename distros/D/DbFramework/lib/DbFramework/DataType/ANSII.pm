=head1 NAME

DbFramework::DataType::ANSII - ANSII data type class

=head1 SYNOPSIS

  use DbFramework::DataType::ANSII;
  $dt     = new DbFramework::DataType::ANSII($dm,$type,$ansii_type,$length);
  $name   = $dt->name($name);
  $type   = $type($type);
  $length = $dt->length($length);
  $extra  = $dt->extra($extra);
  $ansii  = $dt->ansii_type;

=head1 DESCRIPTION

A B<DbFramework::DataType::ANSII> object represents an ANSII data type.

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

=cut

package DbFramework::DataType::ANSII;
use strict;
use base qw(DbFramework::DefinitionObject);
use Alias;
use vars qw();

## CLASS DATA

my %fields = (
              LENGTH  => undef,
	      EXTRA   => undef,
	      TYPES_L => undef,
	      TYPE    => undef,
	      ANSII_TYPE => undef,
	     );

# arbitrary number to add to SQL type numbers as they can be negative
# and we want to store them in an array
my $_sql_type_adjust = 1000;

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($dm,$type,$ansii_type,$length)

Create a new B<DbFramework::DataType> object.  I<$dm> is a
B<DbFramework::DataModle> object.  I<$type> is a numeric ANSII type
e.g. a type contained in the array reference returned by $sth->{TYPE}.
This method will die() unless I<$type> is a member of the set of ANSII
types supported by the DBI driver.  I<$ansii_type> is the same as
I<$type>.  I<$length> is the length of the data type.

=cut

sub new {
  my $_debug   = 0;
  my $proto    = shift;
  my $class    = ref($proto) || $proto;
  my $dm       = shift;
  my $realtype = shift;
  shift; # ansii_type is the same as type
  my $type     = $realtype + $_sql_type_adjust;

  my(@types,@type_names);
  print "type_info_l = ",@{$dm->type_info_l},"\n" if $_debug;
  for my $t ( @{$dm->type_info_l} ) {
    # first DATA_TYPE returned should be the ANSII type
    unless ( $types[$t->{DATA_TYPE} + $_sql_type_adjust] ) {
      $types[$t->{DATA_TYPE} + $_sql_type_adjust] = $t;
      $type_names[$t->{DATA_TYPE} + $_sql_type_adjust] = uc($t->{TYPE_NAME});
      print $type_names[$t->{DATA_TYPE} + $_sql_type_adjust],"\n" if $_debug;
    }
  }
  print STDERR "type = $type ($type_names[$type])\n" if $_debug;
  $types[$type] || die "Invalid ANSII data type: $type";

  my $self = bless($class->SUPER::new($type_names[$type]),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;

  $self->ansii_type($self->type($realtype));
  $self->types_l(\@types);
  $self->length(shift);
  $self->extra('IDENTITY(0,1)') if $self->types_l->[$type]->{AUTO_INCREMENT};
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head2 name($name)

If I<$name> is supplied, sets the name of the ANSII data type.
Returns the name of the data type.

=head2 type($type)

If I<$type> is supplied, sets the number of the ANSII data type.
Returns the numeric data type.

=head2 ansii_type($ansii_type)

Returns the same type as type().

=head2 length($length)

If I<$length> is supplied, sets the length of the data type.  Returns
the length of the data type.

=head2 extra($extra)

If I<$extra> is supplied, sets any extra information which applies to
the data type e.g. I<AUTO_INCREMENT>.  Returns the extra information
which applies to the data type.

=head1 SEE ALSO

L<DbFramework::DefinitionObject>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
