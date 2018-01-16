#
# $Id: Smtp.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::smtp Brik
#
package Metabrik::Network::Smtp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         server => [ qw(server) ],
         port => [ qw(port) ],
         _smtp => [ qw(INTERNAL) ],
      },
      attributes_default => {
         server => 'localhost',
         port => 25,
      },
      commands => {
         open => [ qw(server|OPTIONAL port|OPTIONAL) ],
         close => [ ],
      },
      require_modules => {
         'Net::SMTP' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($server, $port) = @_;

   $server ||= $self->server;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('open', $server) or return;
   $self->brik_help_run_undef_arg('open', $port) or return;

   my $smtp = Net::SMTP->new(
      $server,
      Port => $port,
   );
   if (! defined($smtp)) {
      return $self->log->error("open: Net::SMTP new failed for server [$server] port [$port] with [$!]");
   }

   return $self->_smtp($smtp);
}

sub close {
   my $self = shift;

   my $smtp = $self->_smtp;
   if (defined($smtp)) {
      $smtp->quit;
      $self->_smtp(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Smtp - network::smtp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
