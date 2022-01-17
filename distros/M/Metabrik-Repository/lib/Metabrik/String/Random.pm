#
# $Id$
#
# string::random Brik
#
package Metabrik::String::Random;
use strict;
use warnings;

use base qw(Metabrik::String::Password);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      attributes_default => {
         charset => [ 'A'..'K', 'M'..'Z', 'a'..'k', 'm'..'z', 2..9, '_', '-' ],
         length => 20,
         count => 1,
      },
      commands => {
         filename => [ qw(datadir|OPTIONAL) ],
      },
   };
}

sub filename {
   my $self = shift;
   my ($datadir) = @_;

   $datadir ||= $self->datadir;

   my $random = $self->generate;

   return "$datadir/".$random->[0];
}

1;

__END__

=head1 NAME

Metabrik::String::Random - string::random Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
