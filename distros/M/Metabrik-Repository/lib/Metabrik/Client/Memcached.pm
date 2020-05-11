#
# $Id$
#
# client::memcached Brik
#
package Metabrik::Client::Memcached;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         servers => [ qw(server|server_list) ],
         _c => [ qw(INTERNAL) ],
      },
      attributes_default => {
         servers => [ qw(127.0.0.1:11211) ],
      },
      commands => {
         open => [ qw(server|server_list|OPTIONAL) ],
         close => [ ],
         write => [ qw(key value) ],
         read => [ qw(key) ],
      },
      require_modules => {
         'Cache::Memcached' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   $self->open or return 0;

   return $self->SUPER::brik_init;
}

#
# run client::memcached open "[qw(127.0.0.1:11211)]"
#
sub open {
   my $self = shift;
   my ($servers) = @_;

   $servers ||= $self->servers;
   $self->brik_help_set_undef_arg('servers', $servers) or return;

   my $c = Cache::Memcached->new({
      servers => $servers,
   });
   if (!defined($c)) {
      return $self->log->error("open: memcached failed: $!");
   }
   $c->enable_compress(0);

   return $self->_c($c);
}

sub close {
   my $self = shift;

   my $c = $self->_c;
   if (defined($c)) {
      $c->disconnect_all;
      $self->_c(undef);
   }

   return 1;
}

sub write {
   my $self = shift;
   my ($k, $v) = @_;

   my $c = $self->_c;
   $self->brik_help_run_undef_arg('open', $c) or return;
   $self->brik_help_run_undef_arg('write', $k) or return;
   $self->brik_help_run_undef_arg('write', $v) or return;

   return $c->set($k, $v);
}

sub read {
   my $self = shift;
   my ($k) = @_;

   my $c = $self->_c;
   $self->brik_help_run_undef_arg('open', $c) or return;
   $self->brik_help_run_undef_arg('read', $k) or return;

   return $c->get($k);
}

1;

__END__

=head1 NAME

Metabrik::Client::Memcached - client::memcached Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
