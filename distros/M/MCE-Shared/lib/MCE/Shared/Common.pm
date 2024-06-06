###############################################################################
## ----------------------------------------------------------------------------
## Common API for MCE::Shared::{ Array, Cache, Hash, Minidb, Ordhash }.
##
###############################################################################

use strict;
use warnings;

use 5.010001;

no warnings qw( threads recursion uninitialized numeric );

package MCE::Shared::Common;

our $VERSION = '1.888';

# pipeline ( [ func1, @args ], [ func2, @args ], ... )

sub pipeline {
   my $self = shift;
   my $tmp; $tmp = pop if ( defined wantarray );

   while ( @_ ) {
      my $cmd = shift; next unless ( ref $cmd eq 'ARRAY' );
      if ( my $code = $self->can(shift @{ $cmd }) ) {
         $code->($self, @{ $cmd });
      }
   }

   if ( defined $tmp ) {
      my $code;
      return ( ref $tmp eq 'ARRAY' && ( $code = $self->can(shift @{ $tmp }) ) )
         ? $code->($self, @{ $tmp })
         : undef;
   }

   return;
}

# pipeline_ex ( [ func1, @args ], [ func2, @args ], ... )

sub pipeline_ex {
   my $self = shift;
   my $code;

   map {
      ( ref $_ eq 'ARRAY' && ( $code = $self->can(shift @{ $_ }) ) )
         ? $code->($self, @{ $_ })
         : undef;
   } @_;
}

1;

__END__

###############################################################################
## ----------------------------------------------------------------------------
## Module usage.
##
###############################################################################

=head1 NAME

MCE::Shared::Common - Common API for data classes

=head1 VERSION

This document describes MCE::Shared::Common version 1.888

=head1 DESCRIPTION

Common functions for L<MCE::Shared>. There is no public API.

=head1 INDEX

L<MCE|MCE>, L<MCE::Hobo>, L<MCE::Shared>

=head1 AUTHOR

Mario E. Roy, S<E<lt>marioeroy AT gmail DOT comE<gt>>

=cut

