#
# $Id: Package.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# system::freebsd::package Brik
#
package Metabrik::System::Freebsd::Package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         search => [ qw(string) ],
         install => [ qw(package) ],
         update => [ ],
         upgrade => [ ],
         list => [ ],
         is_installed => [ qw(package|$package_list) ],
         which => [ qw(file) ],
         system_update => [ ],
         system_upgrade => [ qw(RELEASE|OPTIONAL) ],
      },
      require_binaries => {
         'pkg' => [ ],
         'freebsd-update' => [ ],
      },
   };
}

sub search {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('search', $package) or return;

   my $cmd = "pkg search $package";

   return $self->capture($cmd);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('install', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('install', $package, 'ARRAY', 'SCALAR')
      or return;

   my $r;
   if ($ref eq 'ARRAY') {
      for my $this (@$package) {
         $r = $self->sudo_system('pkg install '.$this);
      }
   }
   else {
      $r = $self->sudo_system('pkg install '.$package);
   }

   return $r;
}

sub update {
   my $self = shift;

   my $cmd = 'pkg update';

   return $self->sudo_system($cmd);
}

sub upgrade {
   my $self = shift;

   my $cmd = 'pkg upgrade';

   return $self->sudo_system($cmd);
}

sub list {
   my $self = shift;

   my $cmd = 'pkg info';

   return $self->sudo_system($cmd);
}

sub is_installed {
   my $self = shift;

   return $self->log->info("is_installed: not implemented on this system");
}

sub which {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('which', $file) or return;
   $self->brik_help_run_file_not_found('which', $file) or return;

   my $cmd = "pkg which $file";
   my $lines = $self->capture($cmd) or return;
   for my $line (@$lines) {
      my @toks = split(/\s+/, $line);
      if (defined($toks[0]) && ($toks[0] eq $file) && defined($toks[5])) {
         return $toks[5];
      }
   }

   return 'undef';
}

sub system_update {
   my $self = shift;

   my $cmd = 'freebsd-update fetch';

   return $self->sudo_system($cmd);
}

sub system_upgrade {
   my $self = shift;
   my ($release) = @_;

   my $cmd = 'freebsd-update';
   if (defined($release)) {
      $cmd .= ' upgrade -r '.$release;
      # We should also run a freebsd-update install after that
   }
   else {
      $cmd .= ' install';
   }


   return $self->sudo_system($cmd);
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Package - system::freebsd::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
