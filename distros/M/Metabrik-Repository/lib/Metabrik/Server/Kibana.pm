#
# $Id: Kibana.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# server::kibana Brik
#
package Metabrik::Server::Kibana;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable elk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         listen => [ qw(ip_address) ],
         port => [ qw(port) ],
         conf_file => [ qw(file) ],
         log_file => [ qw(file) ],
         version => [ qw(4.6.2|5.0.0|5.5.2) ],
         no_output => [ qw(0|1) ],
         es_nodes => [ qw(node|node_list) ],
         binary => [ qw(binary_path) ],
      },
      attributes_default => {
         listen => '127.0.0.1',
         port => 5601,
         version => '5.5.2',
         no_output => 1,
         es_nodes => 'http://localhost:9200',
      },
      commands => {
         install => [ ],
         start => [ qw(conf_file) ],
         stop => [ ],
         generate_conf => [ qw(conf|OPTIONAL) ],
         status => [ ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
         tar => [ ],
      },
      need_packages => {
         ubuntu => [ qw(tar openjdk-8-jre-headless) ],
         debian => [ qw(tar openjdk-8-jre-headless) ],
         kali => [ qw(tar openjdk-8-jre-headless) ],
         freebsd => [ qw(openjdk node012 kibana45) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $conf_file = $datadir."/kibana-$version.conf";
   my $log_file = $datadir."/kibana-$version.log";

   return {
      attributes_default => {
         conf_file => $conf_file,
         log_file => $log_file,
      },
   };
}

sub get_binary {
   my $self = shift;

   my $binary = $self->binary;
   if (! defined($binary)) {
      my $datadir = $self->datadir;
      my $version = $self->version;
      $binary = $datadir.'/kibana-'.$version.'-linux-x86_64/bin/kibana';
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
   my $listen = $self->listen;
   my $port = $self->port;
   my $es_nodes = $self->es_nodes;

   my $node = $es_nodes;
   if ($es_nodes eq 'ARRAY') {
      $node = $es_nodes->[0];
   }

   my $conf =<<EOF
server.port: $port
server.host: "$listen"
#server.basePath: ""
#server.name: "your-hostname"
elasticsearch.url: "$node"
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

   my $url = 'https://artifacts.elastic.co/downloads/kibana/kibana-5.5.2-linux-x86_64.tar.gz';
   if ($version eq '4.6.2') {
      $url = 'https://download.elastic.co/kibana/kibana/kibana-4.6.2-linux-x86_64.tar.gz';
   }
   elsif ($version eq '5.0.0') {
      $url = 'https://artifacts.elastic.co/downloads/kibana/kibana-5.0.0-linux-x86_64.tar.gz';
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/kibana.tar.gz") or return;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   if (defined($self->shell)) {
      $self->shell->run_cd($datadir) or return;
   }
   else {
      chdir($datadir) or return $self->log->error("install: chdir: $!");
   }

   my $cmd = "tar zxvf kibana.tar.gz";
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
   my ($conf_file) = @_;

   if ($self->status) {
      return $self->info_process_is_running;
   }

   $conf_file ||= $self->conf_file;

   $self->brik_help_run_undef_arg('start', $conf_file) or return;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   my $log_file = $self->log_file;
   my $no_output = $self->no_output;

   my $binary = $self->get_binary or return;

   $self->close_output_on_start($no_output);

   $self->use_pidfile(0);

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      # -p port, -l log-file -c config-file -e elasticsearch-uri
      my $cmd = "$binary -Q -l $log_file -c $conf_file";

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   return 1;
}

sub stop {
   my $self = shift;

   if (! $self->status) {
      return $self->info_process_is_not_running;
   }

   my $binary = $self->get_binary or return;

   my $log_file = $self->conf_file;
   my $conf_file = $self->conf_file;

   my $string = "-c $conf_file";
   my $pid = $self->get_pid_from_string($string) or return;

   return $self->kill($pid);
}

sub status {
   my $self = shift;

   my $log_file = $self->log_file;
   my $conf_file = $self->conf_file;

   my $string = "-c $conf_file";
   if ($self->is_running_from_string($string)) {
      $self->verbose_process_is_running;
      return 1;
   }

   $self->verbose_process_is_not_running;
   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Server::Kibana - server::kibana Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
