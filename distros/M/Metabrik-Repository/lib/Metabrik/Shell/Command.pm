#
# $Id$
#
# shell::command Brik
#
package Metabrik::Shell::Command;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(exec execute) ],
      attributes => {
         as_array => [ qw(0|1) ],
         as_matrix => [ qw(0|1) ],
         capture_stderr => [ qw(0|1) ],
         capture_mode => [ qw(0|1) ],
         capture_system => [ qw(0|1) ],
         ignore_error => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
         use_pager => [ qw(0|1) ],
         use_globbing => [ qw(0|1) ],
         sudo_args => [ qw(args) ],
      },
      attributes_default => {
         as_array => 1,
         as_matrix => 0,
         capture_stderr => 1,
         capture_mode => 0,
         capture_system => 0,
         ignore_error => 1,
         use_sudo => 0,
         use_pager => 0,
         use_globbing => 0,
         #sudo_args => '-E',  # Keep environment
         sudo_args => '',     # Do not keep env by default.
                              # Not needed anymore cause Metabrik is installed
                              # system-wide.
      },
      commands => {
         system => [ qw(command args|OPTIONAL) ],
         sudo_system => [ qw(command args|OPTIONAL) ],
         system_in_background => [ qw(command args|OPTIONAL) ],
         sudo_system_in_background => [ qw(command args|OPTIONAL) ],
         capture => [ qw(command args|OPTIONAL) ],
         sudo_capture => [ qw(command args|OPTIONAL) ],
         system_capture => [ qw(command args|OPTIONAL) ],
         sudo_system_capture => [ qw(command args|OPTIONAL) ],
         execute => [ qw(command args|OPTIONAL) ],
         sudo_execute => [ qw(command args|OPTIONAL) ],
      },
      require_binaries => {
         script => [ ],
      },
      require_modules => {
         'IPC::Run3' => [ ],
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Process' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(bsdutils) ],
         debian => [ qw(bsdutils) ],
         kali => [ qw(bsdutils) ],
      },
   };
}

sub system {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('system', $cmd) or return;

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("system: program [$bin] not found in PATH");
   }

   $command = join(' ', @toks);

   # Use sudo only when not root
   if ($self->use_sudo && $< != 0) {
      my @sudo = ( "sudo" );
      if (! ref($self->sudo_args) && length($self->sudo_args)) {
         my @args = split(/\s+/, $self->sudo_args);
         push @sudo, @args;
      }
      $command = join(' ', @sudo)." $command";
      @toks = ( @sudo, @toks );
   }

   if ($self->use_pager) {
      my $pager = $ENV{PAGER} || 'less';
      $command .= " | $pager";
   }

   # Also capture output to terminal to a file
   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   my $output_file = 'capture_system.script';
   if ($self->capture_system) {
      if ($so->is_freebsd) {
         $command = "script -q $output_file $command";
      }
      else {
         $command = "script -q --command '".$command."' $output_file";
      }
   }

   $self->log->verbose("system: command[$command]");

   my $r = CORE::system($command);

   $self->log->debug("system: command returned code [$r] with status [$?]");

   if (! $self->ignore_error && $? != 0) {
      $self->log->verbose("system: exit code[$?]");
      # Failure, we return the program exit code
      $self->log->debug("system: program exit code [$?]");
      return $?;
   }

   $self->log->debug("system: program exit with success");

   # Program succeeded, we only return full path to output file, 
   # maybe the caller will have some optimization to not process ths full 
   # file content afterwards.
   if ($self->capture_system) {
      my $pwd = defined($self->shell) && $self->shell->full_pwd || '/tmp';
      my $homedir = defined($self->global) && $self->global->homedir
         || defined($ENV{HOME}) && $ENV{HOME} || '/tmp';
      $pwd =~ s{^~}{$homedir};
      return $pwd.'/'.$output_file;
   }

   return 1;
}

sub sudo_system {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_system', $cmd) or return;

   my $prev = $self->use_sudo;
   $self->use_sudo(1);
   my $r = $self->system($cmd, @args);
   $self->use_sudo($prev);

   return $r;
}

sub system_in_background {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('system_in_background', $cmd) or return;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   $sp->close_output_on_start(1);

   $sp->start(sub {
      $self->system($cmd, @args);
   });

   return 1;
}

sub sudo_system_in_background {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_system_in_background', $cmd) or return;

   my $sp = Metabrik::System::Process->new_from_brik_init($self) or return;
   $sp->close_output_on_start(1);

   $sp->start(sub {
      $self->sudo_system($cmd, @args);
   });

   return 1;
}

sub capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('capture', $cmd) or return;

   # Remove undefined values from arguments
   my @new;
   for (@args) {
      if (defined($_)) {
         push @new, $_;
      }
   }

   my $command = join(' ', $cmd, @new);
   my @toks = split(/\s+/, $command);
   my $bin = $toks[0];

   my @path = split(':', $ENV{PATH});
   if (! -f $bin) {  # If file is not directly found
      for my $path (@path) {
         if (-f "$path/$bin") {
            $bin = "$path/$bin";
            last;
         }
      }
   }
   $toks[0] = $bin;

   if (! -f $bin) {
      return $self->log->error("capture: program [$bin] not found in PATH");
   }

   # Perform file globbing, if any
   if ($self->use_globbing) {
      my @globbed = ();
      for (@toks) {
         push @globbed, glob($_);
      }
      @toks = @globbed;
   }

   $command = join(' ', @toks);

   # Use sudo only when not root
   if ($self->use_sudo && $< != 0) {
      my @sudo = ( "sudo" );
      if (! ref($self->sudo_args) && length($self->sudo_args)) {
         my @args = split(/\s+/, $self->sudo_args);
         push @sudo, @args;
      }
      $command = join(' ', @sudo)." $command";
      @toks = ( @sudo, @toks );
   }

   my $out;
   my $err;
   eval {
      my $cmd = join(' ', @toks);
      $self->log->verbose("capture: command[$cmd]");
      IPC::Run3::run3($cmd, undef, \$out, \$err);
   };
   # Error in executing run3()
   if ($@) {
      chomp($@);
      return $self->log->error("capture: unable to execute command [$command]: $@");
   }
   # Error in command execution
   elsif ($?) {
      chomp($err);
      chomp($out);
      $err ||= $out; # Sometimes, the error is printed on stdout instead of stderr
      if ($self->ignore_error) {
         $self->log->warning("capture: command execution had errors [$command]: $err");
      }
      else {
         return $self->log->error("capture: command execution failed [$command]: $err");
      }
   }

   $out ||= 'undef';
   $err ||= 'undef';
   chomp($out);
   chomp($err);

   # If we also wanted stderr, we put it at the end of output
   if ($self->capture_stderr && $err ne 'undef') {
      $out .= "\n\nSTDERR:\n$err";
   }

   # as_matrix has precedence over as_array (because as_array is the default)
   if (! $self->as_matrix && $self->as_array) {
      $out = [ split(/\n/, $out) ];
   }
   elsif ($self->as_matrix) {
      my @matrix = ();
      for my $this (split(/\n/, $out)) {
         push @matrix, [ split(/\s+/, $this) ];
      }
      $out = \@matrix;
   }

   return $out;
}

sub sudo_capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_capture', $cmd) or return;

   my $prev = $self->use_sudo;
   $self->use_sudo(1);
   my $r = $self->capture($cmd, @args);
   $self->use_sudo($prev);

   return $r;
}

sub system_capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('system_capture', $cmd) or return;

   my $prev = $self->capture_system;
   $self->capture_system(1);
   my $r = $self->system($cmd, @args);
   $self->capture_system($prev);

   return $r;
}

sub sudo_system_capture {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_system_capture', $cmd) or return;

   my $prev = $self->capture_system;
   $self->capture_system(1);
   my $r = $self->sudo_system($cmd, @args);
   $self->capture_system($prev);

   return $r;
}

sub execute {
   my $self = shift;
   my ($cmd, @args) = @_;
   
   $self->brik_help_run_undef_arg('execute', $cmd) or return;

   if ($self->capture_system) {
      return $self->system_capture($cmd, @args);
   }
   elsif ($self->capture_mode) {
      return $self->capture($cmd, @args);
   }
   else {  # non-capture mode
      return $self->system($cmd, @args);
   }

   # Unknown error
   return;
}

sub sudo_execute {
   my $self = shift;
   my ($cmd, @args) = @_;

   $self->brik_help_run_undef_arg('sudo_execute', $cmd) or return;

   if ($self->capture_system) {
      return $self->sudo_system_capture($cmd, @args);
   }
   elsif ($self->capture_mode) {
      return $self->sudo_capture($cmd, @args);
   }
   else {  # non-capture mode
      return $self->sudo_system($cmd, @args);
   }

   # Unknown error
   return;
}

1;

__END__

=head1 NAME

Metabrik::Shell::Command - shell::command Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
