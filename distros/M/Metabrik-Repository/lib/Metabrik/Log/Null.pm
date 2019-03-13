#
# $Id: Null.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# log::null Brik
#
package Metabrik::Log::Null;
use strict;
use warnings;

use base qw(Metabrik::Core::Log);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable logging) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         level => [ qw(0|1|2|3) ],
      },
      commands => {
         message => [ qw(string caller|OPTIONAL) ],
         info => [ qw(string caller|OPTIONAL) ],
         verbose => [ qw(string caller|OPTIONAL) ],
         warning => [ qw(string caller|OPTIONAL) ],
         error => [ qw(string caller|OPTIONAL) ],
         fatal => [ qw(string caller|OPTIONAL) ],
         debug => [ qw(string caller|OPTIONAL) ],
      },
   };
}

sub warning {
   my $self = shift;

   return 1;
}

sub error {
   my $self = shift;

   return;
}

sub fatal {
   my $self = shift;
   my ($msg, $caller) = @_;

   my $buffer = "[F] ".$self->message($msg, ($caller) ||= caller());

   die($buffer);
}

sub info {
   my $self = shift;

   return 1;
}

sub verbose {
   my $self = shift;

   return 1;
}

sub debug {
   my $self = shift;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Log::Null - log::null Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
