#
# $Id: Telnet.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# client::telnet Brik
#
package Metabrik::Client::Telnet;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         prompt => [ qw(string_list) ],
         timeout => [ qw(seconds) ],
         _client => [ qw(INTERNAL) ],
      },
      attributes_default => {
         prompt => [ ':', '>', '$', '#', '%' ],
         timeout => 5,
      },
      commands => {
         connect => [ qw(host port username password) ],
         read_next => [ ],
      },
      require_modules => {
         'Metabrik::String::Regex' => [ ],
         'Net::Telnet' => [ ],
      },
   };
}

sub connect {
   my $self = shift;
   my ($host, $port, $username, $password) = @_;

   $self->brik_help_run_undef_arg('connect', $host) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;
   $self->brik_help_run_undef_arg('connect', $username) or return;
   $self->brik_help_run_undef_arg('connect', $password) or return;

   my $timeout = $self->timeout;
   my $prompt = $self->prompt;

   my $sr = Metabrik::String::Regex->new_from_brik_init($self) or return;

   my $re = $sr->encode($prompt) or return;

   my $t = Net::Telnet->new(
      Timeout => $timeout,
      Prompt => "/$re/",
      Port => $port,
   );

   eval {
      $t->open($host);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("connect: failed to host [$host] port [$port] with: [$@]");
   }

   eval {
      $t->login($username, $password);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("connect: login failed with username [$username]");
   }

   $self->_client($t);

   $self->log->verbose("connect: connection successful");

   return 1;
}

sub read_next {
   my $self = shift;

   my $client = $self->_client;
   $self->brik_help_run_undef_arg('connect', $client) or return;

   my $line;
   eval {
      $line = $client->getline;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("read_next: getline failed with: [$@]");
   }

   return $line;
}

1;

__END__

=head1 NAME

Metabrik::Client::Telnet - client::telnet Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
