#
# $Id: Kafka.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::kafka Brik
#
package Metabrik::Server::Kafka;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         conf_file => [ qw(file) ],
         conf_file_zookeeper => [ qw(file) ],
      },
      attributes_default => {
         conf_file => 'server.properties',
         conf_file_zookeeper => 'zookeeper.properties',
      },
      commands => {
         install => [ ],
         generate_conf => [ ],
         generate_conf_zookeeper => [ ],
         start => [ ],
         status => [ ],
         stop => [ ],
         start_zookeeper => [ ],
         status_zookeeper => [ ],
         stop_zookeeper => [ ],
      },
      require_modules => {
         'Metabrik::Devel::Git' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::System::Process' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
         ubuntu => [ qw(gradle openjdk-8-jdk) ],
         freebsd => [ qw(gradle openjdk8) ],
      },
   };
}

sub install {
   my $self = shift;

   $self->SUPER::install(@_) or return;

   my $datadir = $self->datadir;
   my $url = 'https://github.com/apache/kafka.git';

   my $dg = Metabrik::Devel::Git->new_from_brik_init($self) or return;
   $dg->datadir($datadir);

   my $output_dir = "$datadir/kafka";
   my $repo = $dg->update_or_clone($url, $output_dir) or return;

   #
   # Then build with gradle:
   #
   # cd ~/metabrik/server-kakfa/kafka
   # gradle
   # ./gradlew jar
   #

   return $repo;
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_set_undef_arg('generate_conf', $conf_file) or return;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   # https://kafka.apache.org/documentation/#configuration

   my $conf =<<EOF
# The id of the broker. This must be set to a unique integer for each broker.
broker.id=1

# Increase the message size limit
message.max.bytes=20000000
replica.fetch.max.bytes=30000000

# Retention time
log.retention.hours=24

log.dirs=$datadir/log
listeners=PLAINTEXT://127.0.0.1:9092

zookeeper.connect=localhost:2181

# For single instance of Kakfa (no cluster), default RF on creation
offsets.topic.replication.factor=1

# So we can actually delete topics
delete.topic.enable=true
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir("$datadir/log") or return;

   return $conf_file;
}

sub generate_conf_zookeeper {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file_zookeeper;
   $self->brik_help_set_undef_arg('generate_conf_zookeeper', $conf_file) or return;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   # https://kafka.apache.org/documentation/#configuration

   my $conf =<<EOF
# the directory where the snapshot is stored.
dataDir=$datadir/zookeeper
# the port at which the clients will connect
clientPort=2181
# disable the per-ip limit on the number of connections since this is a non-production config
maxClientCnxns=0
maxClientCnxns=0
server.1=localhost:2888:3888
initLimit=5
syncLimit=2
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir("$datadir/zookeeper") or return;

   return $conf_file;
}

sub start {
   my $self = shift;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   my $conf_file = $self->conf_file;

   my $cmd = "$basedir/bin/kafka-server-start.sh $basedir/config/$conf_file";

   return $self->system_in_background($cmd);
}

sub start_zookeeper {
   my $self = shift;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   my $conf_file = $self->conf_file_zookeeper;

   my $cmd = "$basedir/bin/zookeeper-server-start.sh $basedir/config/$conf_file";

   return $self->system_in_background($cmd);
}

sub status {
   my $self = shift;

   my $conf_file = $self->conf_file;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my $string = "kafka.Kafka $conf_file";
   if ($sp->is_running_from_string($string)) {
      $sp->verbose_process_is_running;
      return 1;
   }

   $sp->verbose_process_is_not_running;
   return 0;
}

sub status_zookeeper {
   my $self = shift;

   my $conf_file = $self->conf_file_zookeeper;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my $string = "org.apache.zookeeper.server.quorum.QuorumPeerMain $conf_file";
   if ($sp->is_running_from_string($string)) {
      $sp->verbose_process_is_running;
      return 1;
   }

   $sp->verbose_process_is_not_running;
   return 0;
}

sub stop {
   my $self = shift;

   if (! $self->status) {
      return $self->info_process_is_not_running;
   }

   my $conf_file = $self->conf_file;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my $string = "kafka.Kafka $conf_file";
   my $pid = $sp->get_pid_from_string($string) or return;

   return $sp->kill($pid);
}

sub stop_zookeeper {
   my $self = shift;

   if (! $self->status) {
      return $self->info_process_is_not_running;
   }

   my $conf_file = $self->conf_file_zookeeper;

   my $datadir = $self->datadir;
   my $basedir = "$datadir/kafka";
   $conf_file = "$basedir/config/$conf_file";

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;

   my $string = "org.apache.zookeeper.server.quorum.QuorumPeerMain $conf_file";
   my $pid = $sp->get_pid_from_string($string) or return;

   return $sp->kill($pid);
}

1;

__END__

=head1 NAME

Metabrik::Server::Kafka - server::kafka Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
