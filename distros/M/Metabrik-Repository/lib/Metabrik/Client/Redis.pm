#
# $Id: Redis.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# client::redis Brik
#
package Metabrik::Client::Redis;
use strict;
use warnings;

use base qw(Metabrik::System::Service Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         server => [ qw(ip_address) ],
         port => [ qw(port) ],
         _redis => [ ],
      },
      attributes_default => {
         server => '127.0.0.1',
         port => 6379,
      },
      commands => {
         install => [ ], # Inherited
         start => [ ], # Inherited
         stop => [ ], # Inherited
         status => [ ], # Inherited
         connect => [ ],
         command => [ qw(command $arg1 $arg2 ... $argN) ],
         command_as_list => [ qw(command $arg1 $arg2 ... $argN) ],
         time => [ ],
         disconnect => [ ],
         quit => [ ],  # Same as disconnect
         dbsize => [ ],
         exists => [ qw(key) ],
         get => [ qw(key) ],
         set => [ qw(key value) ],
         del => [ qw(key) ],
         mget => [ qw($key_list) ],
         hset => [ qw(key $hash) ],
         hget => [ qw(key hash_field) ],
         hgetall => [ qw(key) ],
         client_list => [ ],
         client_getname => [ ],
         list_databases => [ qw(database) ],
         list_keys => [ qw(database keys|OPTIONAL) ],
      },
      require_modules => {
         'Redis' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(redis-server) ],
         debian => [ qw(redis-server) ],
         kali => [ qw(redis-server) ],
      },
      need_services => {
         ubuntu => [ qw(redis-server) ],
         debian => [ qw(redis-server) ],
      },
   };
}

sub connect {
   my $self = shift;

   my $redis = Redis->new(
      server => $self->server.':'.$self->port,
      name => 'redis_connection',
      cnx_timeout => defined($self->global) && $self->global->ctimeout || 3,
      read_timeout => defined($self->global) && $self->global->rtimeout || 3,
      write_timeout => defined($self->global) && $self->global->rtimeout || 3,
   ) or return $self->log->error("connect: redis connection error");

   return $self->_redis($redis);
}

sub _get_redis {
   my $self = shift;

   my $redis = $self->_redis;
   $self->brik_help_run_undef_arg('connect', $redis) or return;

   return $redis;
}

#
# Command list: http://redis.io/commands
#
# Or 'run client::redis command command'
#
sub command {
   my $self = shift;
   my ($cmd, @args) = @_;

   my $redis = $self->_get_redis or return;

   my $r = $redis->$cmd(@args);
   if (! defined($r)) {
      return $self->log->error("command: $cmd failed");
   }

   return $r;
}

#
# Dump content from db10:
#
# run client::redis command select 10
# run client::redis command_as_list keys *
#
sub command_as_list {
   my $self = shift;
   my ($cmd, @args) = @_;

   my $redis = $self->_get_redis or return;

   my @r = $redis->$cmd(@args);

   return \@r;
}

sub time {
   my $self = shift;

   return $self->command('time');
}

sub disconnect {
   my $self = shift;

   my $r = $self->command('quit') or return;
   $self->_redis(undef);

   return $r;
}

sub quit {
   my $self = shift;

   return $self->disconnect;
}

sub dbsize {
   my $self = shift;

   return $self->command('dbsize');
}

sub exists {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('exists', $key) or return;

   return $self->command('exists', $key);
}

sub get {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('get', $key) or return;

   return $self->command('get', $key);
}

sub set {
   my $self = shift;
   my ($key, $value) = @_;

   $self->brik_help_run_undef_arg('set', $key) or return;
   $self->brik_help_run_undef_arg('set', $value) or return;

   return $self->command('set', $key, $value);
}

sub del {
   my $self = shift;
   my ($key) = @_;

   $self->brik_help_run_undef_arg('del', $key) or return;

   return $self->command('del', $key);
}

sub mget {
   my $self = shift;
   my ($key_list) = @_;

   $self->brik_help_run_undef_arg('mget', $key_list) or return;
   $self->brik_help_run_invalid_arg('mget', $key_list, 'ARRAY') or return;

   return $self->command('mget', @$key_list);
}

sub hset {
   my $self = shift;
   my ($hashname, $hash) = @_;

   $self->brik_help_run_undef_arg('hset', $hashname) or return;
   $self->brik_help_run_undef_arg('hset', $hash) or return;
   $self->brik_help_run_invalid_arg('hset', $hash, 'HASH') or return;

   my $redis = $self->_get_redis or return;

   for (keys %$hash) {
      $redis->hset($hashname, $_, $hash->{$_}) or next;
   }

   $redis->wait_all_responses;

   return $hash;
}

sub hget {
   my $self = shift;
   my ($hashname, $field) = @_;

   $self->brik_help_run_undef_arg('hget', $hashname) or return;
   $self->brik_help_run_undef_arg('hget', $field) or return;

   return $self->command('hget', $hashname, $field);
}

sub hgetall {
   my $self = shift;
   my ($hashname) = @_;

   $self->brik_help_run_undef_arg('hgetall', $hashname) or return;

   my $r = $self->command('hgetall', $hashname) or return;

   my %h = @{$r};

   return \%h;
}

sub client_list {
   my $self = shift;

   my $r = $self->command('client_list') or return;

   return [ split(/\n/, $r) ];
}

sub client_getname {
   my $self = shift;

   my $r = $self->command('client_getname') or return;

   return [ split(/\n/, $r) ];
}

sub list_databases {
   my $self = shift;

   return $self->command('info', 'keyspace');
}

sub list_keys {
   my $self = shift;
   my ($database, $keys) = @_;

   $keys ||= '*';
   $self->brik_help_run_undef_arg('list_keys', $database) or return;

   my $r = $self->command('select', $database) or return;
   $self->log->info("list_keys: $r");

   my @r = $self->command_as_list('keys', $keys) or return;

   return \@r;
}

1;

__END__

=head1 NAME

Metabrik::Client::Redis - client::redis Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
