#
# $Id: Elasticsearch.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::elasticsearch Brik
#
package Metabrik::Server::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable elk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         listen => [ qw(ip_address) ],
         port => [ qw(port) ],
         conf_file => [ qw(file) ],
         pidfile => [ qw(file) ],
         version => [ qw(2.4.1|5.0.0|5.5.2) ],
         no_output => [ qw(0|1) ],
         cluster_name => [ qw(name) ],
         node_name => [ qw(name) ],
         db_dir => [ qw(directory) ],
         log_dir => [ qw(directory) ],
         binary => [ qw(binary_path) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 9200,
         version => '5.5.2',
         no_output => 1,
         cluster_name => 'metabrik',
         node_name => 'metabrik-1',
      },
      commands => {
         install => [ ],
         get_binary => [ ],
         start => [ ],
         stop => [ ],
         generate_conf => [ qw(conf_file|OPTIONAL) ],
         # XXX: ./bin/plugin -install lmenezes/elasticsearch-kopf
         #install_plugin => [ qw(plugin) ],
         status => [ ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         tar => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tar openjdk-8-jre-headless) ],
         debian => [ qw(tar openjdk-8-jre-headless) ],
         freebsd => [ qw(openjdk elasticsearch2) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $pidfile = $datadir."/elasticsearch-$version.pid";
   my $conf_file = $datadir."/elasticsearch-$version/config/elasticsearch.yml";
   my $db_dir = $datadir."/db-$version";
   my $log_dir = $datadir."/log-$version";

   return {
      attributes_default => {
         conf_file => $conf_file,
         pidfile => $pidfile,
         db_dir => $db_dir,
         log_dir => $log_dir,
      },
   };
}

sub get_binary {
   my $self = shift;

   my $binary = $self->binary;
   if (! defined($binary)) {
      my $datadir = $self->datadir;
      my $version = $self->version;
      $binary = $datadir.'/elasticsearch-'.$version.'/bin/elasticsearch';
   }

   $self->brik_help_run_file_not_found('get_binary', $binary) or return;

   $self->log->verbose("get_binary: found binary [$binary]");

   return $binary;
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;

   my $version = $self->version;
   my $cluster_name = $self->cluster_name;
   my $node_name = $self->node_name;
   my $listen = $self->listen;
   my $port = $self->port;
   my $db_dir = $self->db_dir;
   my $log_dir = $self->log_dir;

   $self->log->debug("mkdir db_dir [$db_dir]");
   $self->log->debug("mkdir log_dir [$log_dir]");

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->mkdir($db_dir) or return;
   $sf->mkdir($log_dir) or return;

   (my $path_conf = $conf_file) =~ s{/elasticsearch.yml$}{};

   my $conf =<<EOF
#bootstrap.memory_lock: true
node.master: true
node.data: true
node.ingest: true
cluster.name: $cluster_name
node.name: $node_name
path.conf: $path_conf
path.data: $db_dir
path.logs: $log_dir
discovery.zen.minimum_master_nodes: 1
discovery.zen.ping.unicast.hosts: ["$listen"]
network.bind_host: ["$listen"]
network.publish_host: $listen
http.port: $port
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   return $conf_file;
}

sub install {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;

   my $url = 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.5.2.tar.gz';
   if ($version eq '2.4.1') {
      $url = 'https://download.elastic.co/elasticsearch/release/org/'.
             'elasticsearch/distribution/tar/elasticsearch/2.4.1/'.
             'elasticsearch-2.4.1.tar.gz';
   }
   elsif ($version eq '5.0.0') {
      $url = 'https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-5.0.0.tar.gz';
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/es.tar.gz") or return;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   if (defined($self->shell)) {
      $self->shell->run_cd($datadir) or return;
   }
   else {
      chdir($datadir) or return $self->log->error("install: chdir: $!");
   }

   my $cmd = "tar zxvf es.tar.gz";
   my $r = $self->execute($cmd) or return;

   if (defined($self->shell)) {
      $self->shell->run_cd($cwd) or return;
   }
   else {
      chdir($cwd) or return $self->log->error("install: chdir: $!");
   }

   return 1;
}

sub start {
   my $self = shift;

   if ($self->status) {
      return $self->info_process_is_running;
   }

   my $conf_file = $self->conf_file;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   my $no_output = $self->no_output;

   my $binary = $self->get_binary or return;

   $self->close_output_on_start($no_output);

   my $datadir = $self->datadir;
   my $pidfile = $self->pidfile;

   $self->use_pidfile(0);

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      my $cmd = "$binary -p $pidfile";

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   return $pidfile;
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

Metabrik::Server::Elasticsearch - server::elasticsearch Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
