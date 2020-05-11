#
# $Id$
#
# perl::module Brik
#
package Metabrik::Perl::Module;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable build test install cpan cpanm) ],
      commands => {
         build => [ qw(directory|OPTIONAL) ],
         test => [ qw(directory|OPTIONAL) ],
         install => [ qw(module|$module_list|directory|OPTIONAL) ],
         dist => [ qw(directory|OPTIONAL) ],
         clean => [ qw(directory|OPTIONAL) ],
      },
      attributes => {
         use_test => [ qw(0|1) ],
         use_sudo => [ qw(0|1) ],
      },
      attributes_default => {
         use_test => 0,
         use_sudo => 1,
      },
      require_binaries => {
         'cpanm' => [ ],
      },
   };
}

sub build {
   my $self = shift;
   my ($directory) = @_;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   $directory ||= '';
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('build', $directory) or return;
      if (defined($self->shell)) {
         $self->shell->run_cd($directory) or return;
      }
      else {
         chdir($directory) or return $self->log->error("build: chdir: $!");
      }
   }

   my @cmd = ();
   if (-f 'Build.PL') {
      @cmd = ( 'perl Build.PL', 'perl Build' );
   }
   elsif (-f 'Makefile.PL') {
      @cmd = ( 'perl Makefile.PL', 'make' );
   }
   else {
      if (length($directory)) {
         if (defined($self->shell)) {
            $self->shell->run_cd($cwd) or return;
         }
         else {
            chdir($cwd) or return $self->log->error("build: chdir: $!");
         }
      }
      return $self->log->error("build: neither Build.PL nor Makefile.PL were found, abort");
   }

   my $r;
   $self->use_sudo(0);
   for (@cmd) {
      $r = $self->execute($_) or last; # Abord if one cmd failed
   }
   $self->use_sudo(1);

   if (length($directory)) {
      if (defined($self->shell)) {
         $self->shell->run_cd($cwd) or return;
      }
      else {
         chdir($cwd) or return $self->log->error("build: chdir: $!");
      }
   }

   return $r;
}

sub test {
   my $self = shift;
   my ($directory) = @_;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   $directory ||= '';
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('test', $directory) or return;
      if (defined($self->shell)) {
         $self->shell->run_cd($directory) or return;
      }
      else {
         chdir($directory) or return $self->log->error("test: chdir: $!");
      }
   }

   my $cmd;
   if (-f 'Build') {
      $cmd = 'perl Build test';
   }
   elsif (-f 'Makefile') {
      $cmd = 'make test';
   }
   else {
      if (length($directory)) {
         if (defined($self->shell)) {
            $self->shell->run_cd($cwd) or return;
         }
         else {
            chdir($cwd) or return $self->log->error("test: chdir: $!");
         }
      }
      return $self->log->error("test: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   if (length($directory)) {
      if (defined($self->shell)) {
         $self->shell->run_cd($cwd) or return;
      }
      else {
         chdir($cwd) or return $self->log->error("test: chdir: $!");
      }
   }

   return $r;
}

sub install {
   my $self = shift;
   my ($module) = @_;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   my $cmd;
   if ((defined($module) && -d $module) || (! defined($module))) {
      my $directory = $module || ''; # We consider there is only one arg: the directory where 
                                     # to find the module to install
      if (length($directory)) {
         $self->brik_help_run_directory_not_found('install', $directory) or return;
         if (defined($self->shell)) {
            $self->shell->run_cd($directory) or return;
         }
         else {
            chdir($directory) or return $self->log->error("install: chdir: $!");
         }
      }

      if (-f 'Build') {
         $cmd = 'perl Build install';
      }
      elsif (-f 'Makefile') {
         $cmd = 'make install';
      }
      else {
         if (length($directory)) {
            if (defined($self->shell)) {
               $self->shell->run_cd($cwd) or return;
            }
            else {
               chdir($cwd) or return $self->log->error("install: chdir: $!");
            }
         }
         return $self->log->error("install: neither Build nor Makefile were found, abort");
      }
   }
   else {
      my $ref = $self->brik_help_run_invalid_arg('install', $module, 'ARRAY', 'SCALAR')
         or return;

      $cmd = $self->use_test ? 'cpanm' : 'cpanm -n';
      if ($ref eq 'ARRAY') {
         $cmd = join(' ', $cmd, @$module);
      }
      else {
         $cmd = join(' ', $cmd, $module);
      }
   }

   my $r = $self->execute($cmd);

   if (defined($self->shell)) {
      $self->shell->run_cd($cwd) or return;
   }
   else {
      chdir($cwd) or return $self->log->error("install: chdir: $!");
   }

   return $r;
}

sub dist {
   my $self = shift;
   my ($directory) = @_;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   $directory ||= '';
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('dist', $directory) or return;
      if (defined($self->shell)) {
         $self->shell->run_cd($directory) or return;
      }
      else {
         chdir($directory) or return $self->log->error("dist: chdir: $!");
      }
   }

   my $cmd;
   if (-f 'Build') {
      $cmd = 'perl Build dist';
   }
   elsif (-f 'Makefile') {
      $cmd = 'make dist';
   }
   else {
      if (length($directory)) {
         if (defined($self->shell)) {
            $self->shell->run_cd($cwd) or return;
         }
         else {
            chdir($cwd) or return $self->log->error("dist: chdir: $!");
         }
      }
      return $self->log->error("dist: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   if (length($directory)) {
      if (defined($self->shell)) {
         $self->shell->run_cd($cwd) or return;
      }
      else {
         chdir($cwd) or return $self->log->error("dist: chdir: $!");
      }
   }

   return $r;
}

sub clean {
   my $self = shift;
   my ($directory) = @_;

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';

   $directory ||= '';
   if (length($directory)) {
      $self->brik_help_run_directory_not_found('clean', $directory) or return;
      if (defined($self->shell)) {
         $self->shell->run_cd($directory) or return;
      }
      else {
         chdir($directory) or return $self->log->error("clean: chdir: $!");
      }
   }

   my $cmd;
   if (-f 'Build') {
      $cmd = 'perl Build clean';
   }
   elsif (-f 'Makefile') {
      $cmd = 'make clean';
   }
   else {
      if (length($directory)) {
         if (defined($self->shell)) {
            $self->shell->run_cd($cwd) or return;
         }
         else {
            chdir($cwd) or return $self->log->error("clean: chdir: $!");
         }
      }
      return $self->log->error("clean: neither Build nor Makefile were found, abort");
   }

   $self->use_sudo(0);
   my $r = $self->execute($cmd);
   $self->use_sudo(1);

   if (length($directory)) {
      if (defined($self->shell)) {
         $self->shell->run_cd($cwd) or return;
      }
      else {
         chdir($cwd) or return $self->log->error("clean: chdir: $!");
      }
   }

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Perl::Module - perl::module Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
