#
# $Id$
#
# system::package Brik
#
package Metabrik::System::Package;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         get_system_package => [ ],
         search => [ qw(string) ],
         install => [ qw(package|$package_list) ],
         remove => [ qw(package|$package_list) ],
         update => [ qw(version|OPTIONAL) ],
         upgrade => [ qw(version|OPTIONAL) ],
         is_os => [ qw(os) ],
         is_os_ubuntu => [ ],
         is_os_debian => [ ],
         is_os_kali => [ ],
         is_os_freebsd => [ ],
         is_os_centos => [ ],
         is_installed => [ qw(package|$package_list) ],
         my_os => [ ],
         which => [ qw(file) ],
         system_update => [ qw(version|OPTIONAL) ],
         system_upgrade => [ qw(version|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Ubuntu::Package' => [ ],
         'Metabrik::System::Debian::Package' => [ ],
         'Metabrik::System::Kali::Package' => [ ],
         'Metabrik::System::Freebsd::Package' => [ ],
         'Metabrik::System::Centos::Package' => [ ],
      },
   };
}

sub get_system_package {
   my $self = shift;

   my $os = $self->my_os or return;
   my $sudo_args = $self->sudo_args;

   my $sp;
   if ($os eq 'ubuntu') {
      $sp = Metabrik::System::Ubuntu::Package->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'debian') {
      $sp = Metabrik::System::Debian::Package->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'kali') {
      $sp = Metabrik::System::Kali::Package->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'freebsd') {
      $sp = Metabrik::System::Freebsd::Package->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'centos') {
      $sp = Metabrik::System::Centos::Package->new_from_brik_init($self) or return;
   }
   else {
      return $self->log->error("get_system_package: cannot determine package system for OS [$os]");
   }

   $sp->sudo_args($sudo_args);

   return $sp;
}

sub search {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('search', $package) or return;

   my $sp = $self->get_system_package or return;

   return $sp->search($package);
}

sub install {
   my $self = shift;
   my ($package) = @_;

   my $sp = $self->get_system_package or return;

   if (defined($package)) {
      return $sp->install($package);
   }
   elsif (! exists($self->brik_properties->{need_packages})) {
      #return $self->log->error($self->brik_help_run('install'));
      return 1;
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_packages}{$os})) {
         my $need_packages = $self->brik_properties->{need_packages}{$os};
         return $sp->install($need_packages);
      }
      else {
         return $self->log->error("install: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub remove {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('remove', $package) or return;

   my $sp = $self->get_system_package or return;

   return $sp->remove($package);
}

sub update {
   my $self = shift;

   my $sp = $self->get_system_package or return;

   return $sp->update(@_);
}

sub upgrade {
   my $self = shift;

   my $sp = $self->get_system_package or return;

   return $sp->upgrade(@_);
}

sub system_update {
   my $self = shift;

   my $sp = $self->get_system_package or return;

   return $sp->system_update(@_);
}

sub system_upgrade {
   my $self = shift;

   my $sp = $self->get_system_package or return;

   return $sp->system_upgrade(@_);
}

sub list {
   my $self = shift;

   my $sp = $self->get_system_package or return;

   return $sp->list;
}

sub is_os {
   my $self = shift;
   my ($os) = @_;

   $self->brik_help_run_undef_arg('is_os', $os) or return;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   return $so->is($os);
}

sub is_os_ubuntu {
   my $self = shift;

   return $self->is_os('ubuntu');
}

sub is_os_debian {
   my $self = shift;

   return $self->is_os('debian');
}

sub is_os_kali {
   my $self = shift;

   return $self->is_os('kali');
}

sub is_os_freebsd {
   my $self = shift;

   return $self->is_os('freebsd');
}

sub is_os_centos {
   my $self = shift;

   return $self->is_os('centos');
}

sub is_installed {
   my $self = shift;
   my ($package) = @_;

   $self->brik_help_run_undef_arg('is_installed', $package) or return;
   my $ref = $self->brik_help_run_invalid_arg('is_installed', $package, 'ARRAY', 'SCALAR')
      or return;

   my $sp = $self->get_system_package or return;

   return $sp->is_installed($package);
}

sub my_os {
   my $self = shift;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   return $so->my;
}

sub which {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('which', $file) or return;

   my $sp = $self->get_system_package or return;

   return $sp->which($file);
}

1;

__END__

=head1 NAME

Metabrik::System::Package - system::package Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
