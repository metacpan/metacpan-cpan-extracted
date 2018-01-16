#
# $Id: Redis.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::redis Brik
#
package Metabrik::Server::Redis;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         version => [ qw(version) ],
         conf_file => [ qw(file) ],
         listen => [ qw(address) ],
         port => [ qw(port) ],
         pidfile => [ qw(pidfile) ],
         log_file => [ qw(log_file) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 6379,
      },
      commands => {
         install => [ ],  # Inherited
         generate_conf => [ qw(conf|OPTIONAL port|OPTIONAL listen|OPTIONAL) ],
         start => [ qw(port|OPTIONAL listen|OPTIONAL) ],
         stop => [ ],
         status => [ ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'redis-server' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(redis-server) ],
         debian => [ qw(redis-server) ],
         freebsd => [ qw(redis) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $conf_file = $datadir.'/redis.conf';
   my $log_file = $datadir.'/redis.log';
   my $pidfile = $datadir.'/redis.pid';

   return {
      attributes_default => {
         conf_file => $conf_file,
         log_file => $log_file,
         pidfile => $pidfile,
      },
   };
}

sub generate_conf {
   my $self = shift;
   my ($conf_file, $port, $listen) = @_;

   $conf_file ||= $self->conf_file;
   $port ||= $self->port;
   $listen ||= $self->listen;

   my $datadir = $self->datadir;
   my $log_file = $self->log_file;
   my $pidfile = $self->pidfile;

   my $lib_dir = 'var/lib/redis';

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($datadir.'/'.$lib_dir) or return;

   my $dir = $self->datadir.'/'.$lib_dir;

   my $params = {
      "daemonize" => "yes",
      "bind" => $listen,
      "dir" => $dir,
      "logfile" => $log_file,
      "pidfile" => $pidfile,
      "port" => $port,
      "client-output-buffer-limit" => [
         'normal 0 0 0',
         'slave 256mb 64mb 60',
         'pubsub 32mb 8mb 60',
      ],
      "databases" => 16,
      "activerehashing" => "yes",
      "aof-load-truncated" => "yes",
      "aof-rewrite-incremental-fsync" => "yes",
      "appendfilename" => "\"appendonly.aof\"",
      "appendfsync" => "everysec",
      "appendonly" => "no",
      "auto-aof-rewrite-min-size" => "64mb",
      "auto-aof-rewrite-percentage" => 100,
      "dbfilename" => "dump.rdb",
      "hash-max-ziplist-entries" => 512,
      "hash-max-ziplist-value" => 64,
      "hll-sparse-max-bytes" => 3000,
      "hz" => 10,
      "latency-monitor-threshold" => 0,
      "list-max-ziplist-entries" => 512,
      "list-max-ziplist-value" => 64,
      "loglevel" => "notice",
      "lua-time-limit" => 5000,
      "no-appendfsync-on-rewrite" => "no",
      "notify-keyspace-events" => "\"\"",
      "rdbchecksum" => "yes",
      "rdbcompression" => "yes",
      "repl-disable-tcp-nodelay" => "no",
      "repl-diskless-sync" => "no",
      "repl-diskless-sync-delay" => 5,
      "save" => 60,
      "set-max-intset-entries" => 512,
      "slave-priority" => 100,
      "slave-read-only" => "yes",
      "slave-serve-stale-data" => "yes",
      "slowlog-log-slower-than" => 10000,
      "slowlog-max-len" => 128,
      "stop-writes-on-bgsave-error" => "yes",
      "tcp-backlog" => 511,
      "tcp-keepalive" => 0,
      "timeout" => 0,
      "zset-max-ziplist-entries" => 128,
      "zset-max-ziplist-value" => 64,
   };

   my @lines = ();
   for my $k (keys %$params) {
      if (ref($params->{$k}) eq 'ARRAY') {
         for my $this (@{$params->{$k}}) {
            push @lines, "$k $this";
         }
      }
      else {
         push @lines, "$k ".$params->{$k};
      }
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);
   $ft->write(\@lines, $conf_file) or return;

   return $conf_file;
}

#
# redis-server --port 9999 --slaveof 127.0.0.1 6379
# redis-server /etc/redis/6379.conf --loglevel debug
#
sub start {
   my $self = shift;
   my ($port, $listen) = @_;

   if ($self->status) {
      return $self->info_process_is_running;
   }

   $port ||= $self->port;
   $listen ||= $self->listen;

   my $conf_file = $self->conf_file;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   my $cmd = "redis-server $conf_file";
   if ($port) {
      $cmd .= " --port $port";
   }
   if ($listen) {
      $cmd .= " --bind $listen";
   }
   if ($self->log->level > 2) {
      $cmd .= " --loglevel debug";
   }

   return $self->system($cmd);
}

sub stop {
   my $self = shift;

   if (! $self->status) {
      return $self->info_process_is_not_running;
   }

   my $pidfile = $self->pidfile;

   return $self->kill_from_pidfile($pidfile);
}

sub status {
   my $self = shift;

   my $pidfile = $self->pidfile;

   if ($self->is_running_from_pidfile($pidfile)) {
      $self->verbose_process_is_running;
      return 1;
   }

   $self->verbose_process_is_not_running;
   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Server::Redis - server::redis Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
