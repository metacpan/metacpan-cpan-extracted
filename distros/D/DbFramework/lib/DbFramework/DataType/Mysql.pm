=head1 NAME

DbFramework::DataType::Mysql - Mysql data type class

=head1 SYNOPSIS

  use DbFramework::DataType::Mysql;
  $dt     = new DbFramework::DataType::ANSII($dm,$type,$ansii_type,$length);
  $name   = $dt->name($name);
  $type   = $dt->type($type);
  $length = $dt->length($length);
  $extra  = $dt->extra($extra);
  $ansii  = $dt->ansii_type;

=head1 DESCRIPTION

A B<DbFramework::DataType::Mysql> object represents a Mysql data type.

=head1 SUPERCLASSES

B<DbFramework::DefinitionObject>

=cut

package DbFramework::DataType::Mysql;
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

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

=head1 CLASS METHODS

=head2 new($dm,$type,$ansii_type,$length,$extra)

Create a new B<DbFramework::DataType> object.  I<$dm> is a
B<DbFramework::DataModle> object.  I<$type> is a numeric Mysql type
e.g. a type containd in the array reference returned by
$sth->{mysql_type}.  This method will die() unless I<$type> is a
member of the set of types supported by B<DBD::mysql>.  I<$ansii_type>
is the ANSII type that most closely resembles the native Mysql type.
I<$length> is the length of the data type.  I<$extra> is any extra
stuff which applies to the type e.g. 'AUTO_INCREMENT'.

=cut

sub new {
  my $_debug = 0;
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my($dm,$type,$ansii_type) = (shift,shift,shift);

  my(@types,@type_names);
  for my $t ( @{$dm->type_info_l} ) {
    $types[$t->{mysql_native_type}] = $t;
    $type_names[$t->{mysql_native_type}] = uc($t->{TYPE_NAME});
    print STDERR "$t->{mysql_native_type}, $type_names[$t->{mysql_native_type}]\n" if $_debug
  }
  $types[$type] || die "Invalid Mysql data type: $type\n";
  print STDERR "\ntype = $type ($type_names[$type])\n\n" if $_debug;

  my $self = bless($class->SUPER::new($type_names[$type]),$class);
  for my $element (keys %fields) {
    $self->{_PERMITTED}->{$element} = $fields{$element};
  }
  @{$self}{keys %fields} = values %fields;

  $self->type($type);
  $self->ansii_type($ansii_type);
  $self->types_l(\@types);
  $self->length(shift);
  $self->extra(shift);

  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head2 name($name)

If I<$name> is supplied sets the name of the Mysql data type.  Returns
the name of the data type.

=head2 type($type)

If I<$type> is supplied sets the number of the Mysql data type.
Returns the numeric data type.

=head2 ansii_type($ansii_type)

If I<$ansii_type> is supplied sets the number of the ANSII type which
most closely corresponds to the Mysql native type.  Returns the ANSII
type which most closely corresponds to the Mysql native type.

=head2 length($length)

If I<$length> is supplied sets the length of the data type.  Returns
the length of the data type.

=head2 extra($extra)

If I<$extra> is supplied sets any extra information which applies to
the data type e.g. I<AUTO_INCREMENT> in they case of a Mysql
I<INTEGER> data type.  Returns the extra information which applies to
the data type.

=cut

1;

=head1 SEE ALSO

L<DbFramework::DefinitionObject>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1999 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
