#
# $Id: Write.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# network::write Brik
#
package Metabrik::Network::Write;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable ethernet ip raw socket) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         device => [ qw(device) ],
         target => [ qw(ipv4_address|ipv6_address) ],
         family => [ qw(ipv4|ipv6) ],
         protocol => [ qw(tcp|udp) ],
         layer => [ qw(2|3|4) ],
         _fd => [ qw(INTERNAL) ],
      },
      commands => {
         open => [ qw(layer|OPTIONAL arg2|OPTIONAL arg3|OPTIONAL) ],
         send => [ qw($data) ],
         lsend => [ qw($data) ],
         nsend => [ qw($data) ],
         tsend => [ qw($data) ],
         fnsend_reply => [ qw($frame target_address|OPTIONAL) ],
         close => [ ],
      },
      require_modules => {
         'Net::Write::Layer' => [ ],
         'Net::Write::Layer2' => [ ],
         'Net::Write::Layer3' => [ ],
         'Net::Write::Layer4' => [ ],
         'Metabrik::Network::Read' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         layer => 2,
         device => $self->global->device,
         family => $self->global->family,
         protocol => $self->global->protocol,
      },
   };
}

sub open {
   my $self = shift;
   my ($layer, $arg2, $arg3) = @_;

   $self->brik_help_run_must_be_root('open') or return;

   $layer ||= $self->layer;

   my $family = $self->family eq 'ipv6'
      ? Net::Write::Layer::NW_AF_INET6()
      : Net::Write::Layer::NW_AF_INET();

   my $protocol = $self->protocol eq 'udp'
      ? Net::Write::Layer::NW_IPPROTO_UDP()
      : Net::Write::Layer::NW_IPPROTO_TCP();

   my $fd;
   if ($self->layer == 2) {
      $arg2 ||= $self->device;

      $fd = Net::Write::Layer2->new(
         dev => $arg2
      ) or return $self->log->error("open: layer2: error");

      $self->log->verbose("open: layer2: success. Will use device [$arg2]");
   }
   elsif ($self->layer == 3) {
      $arg2 ||= $self->target;
      if (! defined($arg2)) {
         return $self->log->error($self->brik_help_set('target'));
      }

      $fd = Net::Write::Layer3->new(
         dst => $arg2,
         protocol => Net::Write::Layer::NW_IPPROTO_RAW(),
         family => $family,
      ) or return $self->log->error("open: layer3: error");

      $self->log->verbose("open: layer3: success");
   }
   elsif ($self->layer == 4) {
      $arg2 ||= $self->target;
      if (! defined($self->target)) {
         return $self->log->error($self->brik_help_set('target'));
      }

      $fd = Net::Write::Layer4->new(
         dst => $arg2,
         protocol => $protocol,
         family => $family,
      ) or return $self->log->error("open: layer4: error");

      $self->log->verbose("open: layer4: success");
   }

   $fd->open or return $self->log->error("open: error");

   $self->_fd($fd);

   return $fd;
}

sub send {
   my $self = shift;
   my ($data) = @_;

   my $fd = $self->_fd;
   $self->brik_help_run_undef_arg('open', $fd) or return;
   $self->brik_help_run_undef_arg('send', $data) or return;

   $fd->send($data);

   return 1;
}

sub close {
   my $self = shift;

   my $fd = $self->_fd;
   if (! defined($fd)) {
      return 1;
   }

   $fd->close;
   $self->_fd(undef);

   return 1;
}

sub lsend {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('lsend', $data) or return;

   # Save state
   my $layer = $self->layer;
   $self->layer(2);

   $self->open or return;
   $self->send($data) or return;
   $self->close;

   # Restore state
   $self->layer($layer);

   return length($data);
}

sub nsend {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('nsend', $data) or return;

   # Save state
   my $layer = $self->layer;
   $self->layer(3);

   $self->open or return;
   $self->send($data) or return;
   $self->close;

   # Restore state
   $self->layer($layer);

   return length($data);
}

sub fnsend_reply {
   my $self = shift;
   my ($frame, $target) = @_;

   $self->brik_help_run_undef_arg('fnsend_reply', $frame) or return;
   $self->brik_help_run_invalid_arg('fnsend_reply', $frame, 'Net::Frame::Simple') or return;

   # Try to find the target by myself
   if (! defined($target)) {
      my $ip = $frame->ref->{'IPv4'} || $frame->ref->{'IPv6'};
      if (! defined($ip)) {
         return $self->log->error($self->brik_help_run('fnsend_reply'));
      }
      $target = $ip->dst;
   }

   my $nr = Metabrik::Network::Read->new_from_brik_init($self) or return;
   $nr->layer(2);
   $nr->device($self->device);
   $nr->rtimeout($self->global->rtimeout);

   $self->log->verbose("fnsend_reply: using device [".$nr->device."]");

   my $in = $nr->open or return;

   # Save state
   my $saved_layer = $self->layer;
   my $saved_target = $self->target;
   $self->layer(3);
   $self->target($target);

   my $out = $self->open or return;

   $frame->send($out) or return;

   my $reply;
   until ($in->timeout) {
      if ($reply = $frame->recv($in)) {
         last;
      }
   }

   $self->close;
   $nr->close;

   # Restore state
   $self->layer($saved_layer);
   $self->target($saved_target);

   return $reply;
}

sub tsend {
   my $self = shift;
}

1;

__END__

=head1 NAME

Metabrik::Network::Write - network::write Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
