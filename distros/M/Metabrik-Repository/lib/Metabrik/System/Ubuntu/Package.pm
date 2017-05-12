#
# $Id: Package.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::ubuntu::package Brik
#
package Metabrik::System::Ubuntu::Package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes_default => {
         ignore_error => 0,
      },
      commands => {
         search => [ qw(string) ],
         install => [ qw(package|$package_list) ],
         remove => [ qw(package|$package_list) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
         is_installed => [ qw(package|$package_list) ],
         which => [ qw(file) ],
         system_update => [ ],
         system_upgrade => [ ],
      },
      optional_binaries => {
         aptitude => [ ],
      },
      require_binaries => {
         'apt-get' => [ ],
         dpkg => [ ],
      },
      need_packages => {
         ubuntu => [ qw(aptitude) ],
         debian => [ qw(aptitude) ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('search', $package) or return;

   if ($self->brik_has_binary('aptitude')) {
      my $cmd = "aptitude search $package";
      return $self->capture($cmd);
   }

   return $self->log->error("search: you have to install aptitude package");
}

sub install {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('install', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('install', $package, 'ARRAY', 'SCALAR')
      or return;

   my $cmd = 'apt-get install -y ';
   $ref eq 'ARRAY' ? ($cmd .= join(' ', @$package)) : ($cmd .= $package);

   my $r = $self->sudo_system($cmd);
   if ($r != 1) {
      return $self->log->error("install: unable to install: returned error code: [$r]");
   }

   return 1;
}

sub remove {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('remove', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('remove', $package, 'ARRAY', 'SCALAR')
      or return;

   my $cmd = 'apt-get remove -y ';
   $ref eq 'ARRAY' ? ($cmd .= join(' ', @$package)) : ($cmd .= $package);

   return $self->sudo_system($cmd);
}

sub update {
   my $self = shift;

   my $cmd = 'apt-get update';

   return $self->sudo_system($cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = 'apt-get dist-upgrade';

   return $self->sudo_system($cmd);
}

sub list {
   my $self = shift;

   return $self->log->info("list: not available on this system");
}

sub is_installed {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('is_installed', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_installed', $package, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my $installed = {};
      for my $p (@$package) {
         my $r = $self->is_installed($p);
         next unless defined($r);
         $installed->{$p} = $r;
      }
      return $installed;
   }
   else {
      my $r = $self->search($package) or return;
      for my $this (@$r) {
         my @toks = split(/\s+/, $this);
         if ($toks[1] eq $package && $toks[0] =~ m{^i}) {
            return 1;
         }
      }
   }

   return 0;
}

sub which {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('which', $file) or return;
   $self->brik_help_run_file_not_found('which', $file) or return;

   my $cmd = "dpkg -S $file";
   my $lines = $self->capture($cmd) or return;
   for my $line (@$lines) {
      my @toks = split(/\s*:\s*/, $line);
      if (defined($toks[0]) && defined($toks[1]) && ($toks[1] eq $file)) {
         return $toks[0];
      }
   }

   return 'undef';
}

sub system_update {
   my $self = shift;

   return 1;
}

sub system_upgrade {
   my $self = shift;

   my $cmd = 'do-release-upgrade';

   return $self->sudo_system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Ubuntu::Package - system::ubuntu::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
