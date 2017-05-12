=head1 NAME

DbFramework::DefinitionObject - DefinitionObject class

=head1 SYNOPSIS

  use DbFramework::DefinitionObject;

=head1 DESCRIPTION

Abstract class for CDIF Definition Object objects.

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::DefinitionObject;
use strict;
use vars qw( $NAME $_DEBUG);
use base qw(DbFramework::Util);
use Alias;
use Carp;

## CLASS DATA

my %fields = (
	      NAME       => undef,
	      # DefinitionObject 0:1 Contains 0:N Attribute
	      CONTAINS_L => undef,
	      CONTAINS_H => undef,
	     );

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  $self->_init(shift);
  return $self;
}

##-----------------------------------------------------------------------------
## OBJECT METHODS
##-----------------------------------------------------------------------------

=head1 OBJECT METHODS

A definition object contains 0 or more B<DbFramework::Attribute>
objects.  These objects can be accessed using the attributes
I<CONTAINS_L> and I<CONTAINS_H>.  See L<DbFramework::Util/AUTOLOAD()>
for the accessor methods for these attributes.

=cut

#------------------------------------------------------------------------------

sub _init {
  my $self = attr shift;
  my @by_name;
  for ( @{$self->contains_l(shift)} ) { push(@by_name,($_->name,$_)) }
  $self->contains_h(\@by_name);
  return $self;
}

#------------------------------------------------------------------------------

1;

=head1 SEE ALSO

L<DbFramework::Util>

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
