#
# $Id: Winexe.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# remote::winexe Brik
#
package Metabrik::Remote::Winexe;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         host => [ qw(host) ],
         user => [ qw(username) ],
         password => [ qw(password) ],
      },
      attributes_default => {
      },
      commands => {
         install => [ ], # Inherited
         execute => [ qw(command host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         execute_in_background => [ qw(command host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         tar => [ ],
         winexe => [ ],
      },
      need_packages => {
         ubuntu => [  qw(build-essential autoconf) ],
         debian => [  qw(build-essential autoconf) ],
      },
   };
}

#
# Compilation process
# http://techedemic.com/2014/09/17/installing-wmic-in-ubuntu-14-04-lts-64-bit/
# http://wiki.monitoring-fr.org/nagios/windows-client/superivision-wmi
#
sub install {
   my $self = shift;

   # Install needed packages
   $self->SUPER::install() or return;

   my $datadir = $self->datadir;
   my $shell = $self->shell;

   my $version = '1.3.14';

   my $url = 'http://www.openvas.org/download/wmi/wmi-'.$version.'.tar.bz2';
   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror($url, "wmi-$version.tar.bz2", $datadir) or return;

   if (@$files > 0) {
      my $cmd = "tar jxvf $datadir/wmi-$version.tar.bz2 -C $datadir/";
      $self->SUPER::execute($cmd) or return;
   }

   # cd wmi-$version/Samba/source
   # ./autogen.sh
   # ./configure
   # make "CPP=gcc -E -ffreestanding"
   # make proto bin/wmic
   # make proto bin/winexe

   my $cwd = $shell->pwd;
   $shell->run_cd("$datadir/wmi-$version/Samba/source") or return;

   $self->system('./autogen.sh') or return;
   $self->system('./configure') or return;
   $self->system('make "CPP=gcc -E -ffreestanding"') or return;
   $self->system('make proto bin/wmic') or return;
   $self->system('make proto bin/winexe') or return;

   $shell->run_cd($cwd);

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->copy("$datadir/wmi-$version/Samba/source/bin/wmic", '/usr/local/bin/') or return;
   $sf->copy("$datadir/wmi-$version/Samba/source/bin/winexe", '/usr/local/bin/') or return;

   return 1;
}

#
# Instructions to activate WINEXESVC under Windows 7
#
# 1. Add LocalAccountTokenFilterPolicy registry key
#
# - Click start
# - Type: regedit
# - Press enter
# - In the left, browse to the following folder:
# HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\system\
# - Right-click a blank area in the right pane
# - Click New
# - Click DWORD Value
# - Type: LocalAccountTokenFilterPolicy
# - Double-click the item you just created
# - Type 1 into the box
# - Click OK
#
# 2. Add winexesvc service
# runas administrator a cmd.exe
# C:\> sc create winexesvc binPath= C:\WINDOWS\WINEXESVC.EXE start= auto DisplayName= winexesvc
# C:\> sc description winexesvc "Remote command provider"
#
sub execute {
   my $self = shift;
   my ($command, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('execute', $command) or return;
   $self->brik_help_run_undef_arg('execute', $host) or return;
   $self->brik_help_run_undef_arg('execute', $user) or return;
   $self->brik_help_run_undef_arg('execute', $password) or return;

   # Do not put $command between quotes, let user do it.
   my $cmd = "winexe -U$user".'%'."$password //$host $command";

   return $self->SUPER::execute($cmd);
}

sub execute_in_background {
   my $self = shift;
   my ($command, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('execute_in_background', $command) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $host) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $user) or return;
   $self->brik_help_run_undef_arg('execute_in_background', $password) or return;

   # Do not put $command between quotes, let user do it.
   my $cmd = "winexe -U$user".'%'."$password //$host $command &";

   return $self->SUPER::execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Remote::Winexe - remote::winexe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
