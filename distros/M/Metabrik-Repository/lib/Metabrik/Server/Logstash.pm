#
# $Id$
#
# server::logstash Brik
#
package Metabrik::Server::Logstash;
use strict;
use warnings;

use base qw(Metabrik::System::Process);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable elk) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         conf_file => [ qw(file) ],
         log_file => [ qw(file) ],
         version => [ qw(2.4.0|5.0.0|5.5.2) ],
         no_output => [ qw(0|1) ],
         binary => [ qw(binary_path) ],
      },
      attributes_default => {
         version => '5.5.2',
         no_output => 0,
         log_file => 'logstash.log',
      },
      commands => {
         install => [ ],
         get_binary => [ ],
         check_config => [ qw(conf_file) ],
         start => [ qw(conf_file|OPTIONAL) ],
         start_in_foreground => [ qw(conf_file|OPTIONAL) ],
         stop => [ ],
         generate_conf => [ qw(conf_file|OPTIONAL) ],
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
         freebsd => [ qw(openjdk logstash) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $conf_file = $datadir."/logstash-$version.conf";
   my $log_file = $datadir."/logstash-$version.log";

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
      $binary = $datadir.'/logstash-'.$version.'/bin/logstash';
   }

   $self->brik_help_run_file_not_found('get_binary', $binary) or return;

   $self->log->verbose("get_binary: found binary [$binary]");

   return $binary;
}

sub generate_conf {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;

   my $conf =<<EOF
input {
   file {
      type => "apache"
      path => "/var/log/www/example.com-access.log*"
      add_field => { "site" => "www.example.com" }
      start_position => "beginning" # Start from beginning of every files
      sincedb_path => "/dev/null"   # Read files entirely every times
      ignore_older => "0"           # Process every file, even older than 24 hours
   }
}

filter {
   if [message] =~ /: logfile turned over\$/ {
      drop {}
   }
   if [type] == "apache" {
      # Defining patterns:
      # https://www.elastic.co/guide/en/logstash/current/plugins-filters-grok.html
      grok {
         match => { "message" => "%{COMBINEDAPACHELOG}" }
         overwrite => [ "message" ]
      }
      geoip {
         source => "clientip"
         target => "geoip"
         add_tag => [ "apache-geoip" ]
      }
      date {
         match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
         remove_field => [ "timestamp" ]
      }
   }
}

output {
   if "_grokparsefailure" in [tags] {
      null {}
   }
   if [type] == "apache" {
      redis {
         host => "127.0.0.1"
         data_type => "list"
         key => "logstash"
         codec => json
         congestion_interval => 1
         congestion_threshold => 20000000
         # Batch processing requires redis >= 2.4.0
         batch => true
         batch_events => 50
         batch_timeout => 5
      }
   }
   else {
      stdout {
         codec => json
      }
   }
}
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

   my $url = 'https://artifacts.elastic.co/downloads/logstash/logstash-5.5.2.tar.gz';
   if ($version eq '2.4.0') {
      $url = 'https://download.elastic.co/logstash/logstash/logstash-2.4.0.tar.gz';
   }
   elsif ($version eq '5.0.0') {
      $url = 'https://artifacts.elastic.co/downloads/logstash/logstash-5.0.0.tar.gz';
   }

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->mirror($url, "$datadir/logstash.tar.gz") or return;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   if (defined($self->shell)) {
      $self->shell->run_cd($datadir) or return;
   }
   else {
      chdir($datadir) or return $self->log->error("install: chdir: $!");
   }

   my $cmd = "tar zxvf logstash.tar.gz";
   my $r = $self->execute($cmd) or return;

   if (defined($self->shell)) {
      $self->shell->run_cd($cwd) or return;
   }
   else {
      chdir($cwd) or return $self->log->error("install: chdir: $!");
   }

   return 1;
}

sub check_config {
   my $self = shift;
   my ($conf_file) = @_;

   $self->brik_help_run_undef_arg('start', $conf_file) or return;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   my $datadir = $self->datadir;
   my $version = $self->version;
   my $log_file = $self->log_file;

   my $binary = $self->get_binary or return;

   my $cmd = "$binary -t -f $conf_file -l $log_file";

   $self->log->info("check_config: started...");

   return $self->system($cmd);
}

#
# logstash -f <config_file> -l <log_file> --debug
#
sub start {
   my $self = shift;
   my ($conf_file) = @_;

   if ($self->status) {
      return $self->info_process_is_running;
   }

   $conf_file ||= $self->conf_file;
   $self->brik_help_run_undef_arg('start', $conf_file) or return;
   $self->brik_help_run_file_not_found('start', $conf_file) or return;

   # Make if a full path file
   if ($conf_file !~ m{^/}) {
      my $cwd = define($self->shell) && $self->shell->full_pwd || '/tmp';
      $conf_file = $cwd.'/'.$conf_file;
   }

   my $log_file = $self->log_file;
   my $no_output = $self->no_output;

   my $binary = $self->get_binary or return;

   $self->close_output_on_start($no_output);

   $self->SUPER::start(sub {
      $self->log->verbose("Within daemon");

      my $cmd = "$binary -f $conf_file -l $log_file";
      if ($self->log->level > 2) {
         $cmd .= ' --debug';
      }

      $self->system($cmd);

      $self->log->error("start: son failed to start");
      exit(1);
   });

   return 1;
}

sub start_in_foreground {
   my $self = shift;
   my ($conf_file) = @_;

   $conf_file ||= $self->conf_file;
   $self->brik_help_run_undef_arg('start_in_foreground', $conf_file) or return;
   $self->brik_help_run_file_not_found('start_in_foreground', $conf_file) or return;

   if ($self->status) {
      return $self->error_process_is_running;
   }

   my $log_file = $self->log_file;

   my $binary = $self->get_binary or return;

   my $cmd = "$binary -f $conf_file -l $log_file";
   if ($self->log->level > 2) {
      $cmd .= ' --debug';
   }

   return $self->system($cmd);
}

sub stop {
   my $self = shift;

   if (! $self->status) {
      return $self->info_process_is_not_running;
   }

   my $conf_file = $self->conf_file;

   my $string = "-f $conf_file";
   my $pid = $self->get_pid_from_string($string) or return;

   return $self->kill($pid);
}

sub status {
   my $self = shift;

   my $conf_file = $self->conf_file;

   my $string = "-f $conf_file";
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

Metabrik::Server::Logstash - server::logstash Brik

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
