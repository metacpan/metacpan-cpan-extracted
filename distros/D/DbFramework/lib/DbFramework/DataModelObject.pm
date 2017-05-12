=head1 NAME

DbFramework::DataModelObject - DataModelObject class

=head1 SYNOPSIS

  use DbFramework::DataModelObject;

=head1 DESCRIPTION

Abstract class for CDIF Data Model objects.

=head1 SUPERCLASSES

B<DbFramework::Util>

=cut

package DbFramework::DataModelObject;
use strict;
use vars qw( $NAME );
use base qw(DbFramework::Util);
use Alias;

## CLASS DATA

my %fields = (
	      # DataModelObject 1:1 ActsAs 0:N RolePlayer
              ACTS_AS => undef,
	     );

##-----------------------------------------------------------------------------
## CLASS METHODS
##-----------------------------------------------------------------------------

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = bless { _PERMITTED => \%fields, %fields, }, $class;
  $self->name(shift);
  return $self;
}

1;

=head1 AUTHOR

Paul Sharpe E<lt>paul@miraclefish.comE<gt>

=head1 COPYRIGHT

Copyright (c) 1998 Paul Sharpe. England.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
