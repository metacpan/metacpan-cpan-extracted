#
# $Id: Whois.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# network::whois Brik
#
package Metabrik::Network::Whois;
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
         datadir => [ qw(datadir) ],
         rtimeout => [ qw(timeout) ],
         last_server => [ qw(server) ],
      },
      attributes_default => {
         rtimeout => 2,
      },
      commands => {
         target => [ qw(domain|ip_address) ],
         queried_server => [ ],
      },
      require_modules => {
         'Net::Whois::Raw' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

sub target {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('target', $target) or return;

   $Net::Whois::Raw::TIMEOUT = $self->rtimeout;
   $Net::Whois::Raw::CACHE_DIR = $self->datadir.'/cache';

   # Whois server custo
   #$Net::Whois::Raw::Data::servers{TLD} = SRV;

   my $info;
   my $server;
   eval {
      ($info, $server) = Net::Whois::Raw::whois($target)
         or return $self->log->error("target: whois for target [$target] failed");
   };
   if ($@) {
      chomp($@);
      if ($@ =~ /(Connection timeout to \S+)/) {
         $@ = $1;
      }
      elsif ($@ =~ /(\S+): Invalid argument: /) {
         $@ = "Invalid server $1";
      }
      elsif ($@ =~ /(\S+): Connection refused: /) {
         $@ = "Connection refused to $1";
      }

      return $self->log->error("target: failed target [$target]: [$@]");
   }

   if (! defined($info)) {
      return $self->log->error("target: whois returned nothing");
   }

   my $sp = Metabrik::String::Parse->new_from_brik_init($self) or return;
   my $lines = $sp->to_array($info) or return;

   for (@$lines) {
      if (/Whois Requests exceeded the allowed limit/i
      ||  /Your request cannot be completed at this time due to query limit controls/i
      ||  /Maximum Daily connection limit reached. Lookup refused/i
      ||  /database is contained within a list of IP addresses that may have failed/i
      ||  /Connection refused: exceeded maximum connection limit from /i
   ) {
         return $self->log->error("target: failed target [limit exceeded]");
      }
   }

   $self->last_server($server);

   return $lines;
}

sub queried_server {
   my $self = shift;

   return $self->last_server || 'undef';
}

1;

__END__

=head1 NAME

Metabrik::Network::Whois - network::whois Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
