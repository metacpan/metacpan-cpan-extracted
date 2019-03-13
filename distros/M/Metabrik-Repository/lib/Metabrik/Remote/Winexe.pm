#
# $Id: Winexe.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# remote::winexe Brik
#
package Metabrik::Remote::Winexe;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
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
         kali => [  qw(build-essential autoconf) ],
      },
   };
}

#
# Compilation process
#
# http://techedemic.com/2014/09/17/installing-wmic-in-ubuntu-14-04-lts-64-bit/
# http://wiki.monitoring-fr.org/nagios/windows-client/superivision-wmi
#
# 2017-02-20: New compilation process for winexe 1.1:
#
# http://rand0m.org/2015/08/05/winexe-1-1-centos-6-and-windows-2012-r2/
# https://sourceforge.net/p/winexe/winexe-waf/ci/master/tree/
#
# sudo apt-get install gcc-mingw-w64 comerr-dev libpopt-dev libbsd-dev zlib1g-dev 
#    libc6-dev python-dev gnutls-dev acl-dev libldap-dev
# git clone git://git.code.sf.net/p/winexe/winexe-waf winexe-winexe-waf
# wget https://download.samba.org/pub/samba/stable/samba-4.1.23.tar.gz
# tar zxvf samba-4.1.23.tar.gz
# cd winexe-winexe-waf/source
# vi wscript_build
# -        stlib='smb_static bsd z resolv rt',
# -        lib='dl'
# +        stlib='smb_static z rt',
# +        lib='dl resolv bsd'
# ./waf --samba-dir=../../samba-4.1.23 configure build
# cp build/winexe-static /usr/local/bin/winexe11
#
sub install {
   my $self = shift;

   # Install needed packages
   $self->SUPER::install() or return;

   my $datadir = $self->datadir;

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

   my $cwd = defined($self->shell) && $self->shell->pwd || '/tmp';
   if (defined($self->shell)) {
      $self->shell->run_cd("$datadir/wmi-$version/Samba/source") or return;
   }
   else {
      chdir("$datadir/wmi-$version/Samba/source")
         or return $self->log->error("install: chdir: $!");
   }

   $self->system('./autogen.sh') or return;
   $self->system('./configure') or return;
   $self->system('make "CPP=gcc -E -ffreestanding"') or return;
   $self->system('make proto bin/wmic') or return;
   $self->system('make proto bin/winexe') or return;

   if (defined($self->shell)) {
      $self->shell->run_cd($cwd);
   }
   else {
      chdir($cwd) or return $self->log->error("install: chdir: $!");
   }

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->copy("$datadir/wmi-$version/Samba/source/bin/wmic", '/usr/local/bin/') or return;
   $sf->copy("$datadir/wmi-$version/Samba/source/bin/winexe", '/usr/local/bin/') or return;

   return 1;
}

#
# A. Activate file sharing on local network
#
# B. Instructions to activate WINEXESVC under Windows 7
#
# 1. Add LocalAccountTokenFilterPolicy registry key
#
#   runas administrator a cmd.exe
#
#   reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\system" 
#      /v LocalAccountTokenFilterPolicy /t REG_DWORD /d 1 /f
#
# 2. Add winexesvc service (update: not necessary since winexe 1.1, it installs the 
#    service by itself)
#
#   runas administrator a cmd.exe
#
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

   my $winexe = 'winexe';

   # If winexe 1.1 is available, we use it instead of venerable winexe from wmi package.
   if (-f '/usr/local/bin/winexe11') {
      $self->log->verbose("execute: winexe11 found, using it");
      $winexe = 'winexe11';
   }

   # Do not put $command between quotes, let user do it.
   my $cmd = "$winexe -U$user".'%'."$password //$host $command";

   $self->log->verbose("execute: cmd[$cmd]");

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

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
