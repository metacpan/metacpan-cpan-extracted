#
# $Id$
#
# network::sinfp3::arpdiscover Brik
#
package Metabrik::Network::Sinfp3::Arpdiscover;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable network sinfp scan arp arpscan ipv6) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         subnet => [ qw(target_subnet) ],
         use_ipv6 => [ qw(0|1) ],
      },
      attributes_default => {
         use_ipv6 => 0,
      },
      commands => {
         scan => [ qw(subnet) ],
      },
      require_modules => {
         'Net::SinFP3' => [ ],
         'Net::SinFP3::Log::Console' => [ ],
         'Net::SinFP3::Global' => [ ],
         'Net::SinFP3::Input::ArpDiscover' => [ ],
         'Net::SinFP3::DB::Null' => [ ],
         'Net::SinFP3::Mode::Null' => [ ],
         'Net::SinFP3::Search::Null' => [ ],
         'Net::SinFP3::Output::Null' => [ ],
      },
   };
}

sub scan {
   my $self = shift;
   my ($subnet) = @_;

   $subnet ||= $self->subnet;
   if (! defined($subnet)) {
      return $self->log->error($self->brik_help_set('subnet'));
   }

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      subnet => $subnet,
      ipv6 => $self->use_ipv6,
   ) or return $self->log->error("scan: global failed");

   my $input = Net::SinFP3::Input::ArpDiscover->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::Null->new(
      global => $global,
   );

   my $mode = Net::SinFP3::Mode::Null->new(
      global => $global,
   );

   my $search = Net::SinFP3::Search::Null->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Null->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   return $ret;
}

1;

__END__

=head1 NAME

Metabrik::Network::Sinfp3::Arpdiscover - network::sinfp3::arpdiscover Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
