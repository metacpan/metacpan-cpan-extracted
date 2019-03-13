#
# $Id: Oneshot.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# server::logstash::oneshot Brik
#
package Metabrik::Server::Logstash::Oneshot;
use strict;
use warnings;

use base qw(Metabrik::Server::Logstash);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
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
         install => [ ],  # Inherited
         stdin_to_stdout => [ ],
         stdin_to_json => [ ],
         test_filter_against_string => [ qw(filter_file string|string_list) ],
         test_filter_against_logs => [ qw(filter_file input_file) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub stdin_to_stdout {
   my $self = shift;

   my $binary = $self->get_binary or return;

   my $cmd = "$binary -e 'input { stdin { } } output { stdout {} }'";

   $self->log->info("stdin_to_stdout: starting...");

   return $self->system($cmd);
}

sub stdin_to_json {
   my $self = shift;

   my $binary = $self->get_binary or return;

   my $cmd = "$binary -e 'input { stdin { } } output { stdout { codec => json } }'";

   $self->log->info("stdin_to_json: starting...");

   return $self->system($cmd);
}

sub test_filter_against_string {
   my $self = shift;
   my ($filter_file, $string) = @_;

   $self->brik_help_run_undef_arg('test_filter_against_string', $string) or return;
   my $ref = $self->brik_help_run_invalid_arg('test_filter_against_string', $string,
      'ARRAY', 'SCALAR') or return;
   $self->brik_help_run_undef_arg('test_filter_against_string', $filter_file) or return;
   $self->brik_help_run_file_not_found('test_filter_against_string', $filter_file) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->as_array(1);
   my $lines = $ft->read($filter_file) or return;

   if (@$lines == 0) {
      return $self->log->error("test_filter_against_string: file [$filter_file] is empty");
   }

   my @lines = ();
   for (@$lines) {
      push @lines, $_ unless $_ =~ m{^\s*#};  # Remove comments, as it is not supported.
   }

   my $binary = $self->get_binary or return;

   my $filter = join('', @lines);

   my $input =<<EOF
input {
   stdin { }
}
EOF
;

   my $output =<<EOF
output {
   if "_grokparsefailure" in [tags]
   or "_dateparsefailure" in [tags]
   {
      stdout {
         codec => rubydebug
      }
   }
   else {
      null {}
   }
}
EOF
;

   my $cmd;
   if ($ref eq 'ARRAY') {
      my $tmp_file = $self->datadir.'/logstash-test-filter-tmp.txt';
      $ft->write($string, $tmp_file) or return;
      $cmd = "$binary -e '$input filter { $filter } $' < $tmp_file";
   }
   else {
      $cmd = "echo \"$string\" | $binary -e '$input filter { $filter } $output'";
   }

   $self->log->info("test_filter_against_string: starting...");

   return $self->system($cmd);
}

sub test_filter_against_logs {
   my $self = shift;
   my ($filter_file, $input_file) = @_;

   $self->brik_help_run_undef_arg('test_filter_against_logs', $filter_file) or return;
   $self->brik_help_run_file_not_found('test_filter_against_logs', $filter_file) or return;
   $self->brik_help_run_undef_arg('test_filter_against_logs', $input_file) or return;
   $self->brik_help_run_file_not_found('test_filter_against_logs', $input_file) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->as_array(1);
   $ft->strip_crlf(1);
   my $lines = $ft->read($filter_file) or return;

   if (@$lines == 0) {
      return $self->log->error("test_filter_against_logs: file [$filter_file] is empty");
   }

   my @lines = ();
   for (@$lines) {
      push @lines, $_ unless $_ =~ m{^\s*#};  # Remove comments, as it is not supported.
   }

   my $filter_string = join('', @lines);

   my $conf =<<EOF
input { stdin {} }

filter { $filter_string }

output {
   if "_grokparsefailure" in [tags]
   or "_dateparsefailure" in [tags]
   {
      stdout {
         codec => rubydebug
      }
   }
   else {
      null {}
   }
}
EOF
;

   my @conf_lines = split(/\n/, $conf);
   my $conf_string = join('', @conf_lines);

   my $binary = $self->get_binary or return;

   my $cmd = "$binary -e '$conf_string' < $input_file";

   $self->log->info("test_filter_against_string: starting...");

   return $self->system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Server::Logstash::Oneshot - server::logstash::oneshot Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
