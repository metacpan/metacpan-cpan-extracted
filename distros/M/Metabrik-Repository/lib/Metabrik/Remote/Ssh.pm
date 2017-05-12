#
# $Id: Ssh.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# remote::ssh Brik
#
package Metabrik::Remote::Ssh;
use strict;
use warnings;

use base qw(Metabrik::Client::Ssh);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(integer) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         publickey => [ qw(file) ],
         privatekey => [ qw(file) ],
         use_publickey => [ qw(0|1) ],
      },
      attributes_default => {
         username => 'root',
         port => 22,
         use_publickey => 1,
      },
      commands => {
         my_os => [ qw(hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         list_processes => [ qw(hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         is_process_running => [ qw(process hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         execute => [ qw(command hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         execute_in_background => [ qw(command hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
         capture => [ qw(command hostname|OPTIONAL port|OPTIONAL username|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::Process' => [ ],
      },
   };
}

sub my_os {
   my $self = shift;
   my ($hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('my_os', $hostname) or return;
   $self->brik_help_run_undef_arg('my_os', $port) or return;
   $self->brik_help_run_undef_arg('my_os', $username) or return;

   my $cs = $self->connect($hostname, $port, $username) or return;
   my $lines = $self->capture('uname -s') or return;
   $self->disconnect;

   if (@$lines > 0) {
      return $lines->[0];
   }

   return 'undef';
}

sub list_processes {
   my $self = shift;
   my ($hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('list_processes', $hostname) or return;
   $self->brik_help_run_undef_arg('list_processes', $port) or return;
   $self->brik_help_run_undef_arg('list_processes', $username) or return;

   my $lines = $self->capture('ps awuxw') or return;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   return $sp->parse_ps_output($lines);
}

sub is_process_running {
   my $self = shift;
   my ($process, $hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;

   my $list = $self->list_processes($hostname, $port, $username) or return;

   for my $this (@$list) {
      my $command = $this->{COMMAND};
      my @toks = split(/\s+/, $command);
      $toks[0] =~ s/^.*\/(.*?)$/$1/;
      if ($toks[0] eq $process) {
         return 1;
      }
   }

   return 0;
}

sub execute {
   my $self = shift;
   my ($cmd, $hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('execute', $cmd) or return;
   $self->brik_help_run_undef_arg('execute', $hostname) or return;
   $self->brik_help_run_undef_arg('execute', $port) or return;
   $self->brik_help_run_undef_arg('execute', $username) or return;

   $self->connect($hostname, $port, $username) or return;
   my $ssh = $self->SUPER::execute($cmd) or return;
   $self->disconnect;

   return $ssh;
}

sub execute_in_background {
   my $self = shift;
   my ($cmd, $hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('execute_in_background', $cmd) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $hostname) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $port) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $username) or return;

   $self->connect($hostname, $port, $username) or return;
   my $r = $self->SUPER::execute_in_background($cmd) or return;
   $self->disconnect;

   return $r;
}

sub capture {
   my $self = shift;
   my ($cmd, $hostname, $port, $username) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $username ||= $self->username;
   $self->brik_help_run_undef_arg('capture', $cmd) or return;
   $self->brik_help_run_undef_arg('capture', $hostname) or return;
   $self->brik_help_run_undef_arg('capture', $port) or return;
   $self->brik_help_run_undef_arg('capture', $username) or return;

   $self->connect($hostname, $port, $username) or return;
   my $lines = $self->SUPER::capture($cmd) or return;
   $self->disconnect;

   return $lines;
}

1;

__END__

=head1 NAME

Metabrik::Remote::Ssh - remote::ssh Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
