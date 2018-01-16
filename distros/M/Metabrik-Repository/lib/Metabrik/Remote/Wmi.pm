#
# $Id: Wmi.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# remote::wmi Brik
#
package Metabrik::Remote::Wmi;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
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
         as_array => 1,
         capture_mode => 1,
         use_globbing => 0,
      },
      commands => {
         install => [ ], # Inherited
         request => [ qw(query host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         get_win32_operatingsystem => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
         get_win32_process => [ qw(host|OPTIONAL user|OPTIONAL password|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::System::File' => [ ],
         'Metabrik::String::Psv' => [ ],
      },
      require_binaries => {
         tar => [ ],
         wmic => [ ],
      },
      need_packages => {
         ubuntu => [ qw(build-essential autoconf) ],
         debian => [ qw(build-essential autoconf) ],
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
   # On Ubuntu 16.10, we have to comment line 583 from wmi-1.3.14/Samba/source/pidl/pidl
   #   Error message was:
   #   Can't use 'defined(@array)' (Maybe you should just omit the defined()?) at ./pidl/pidl line 583.
   #   Makefile:28886: recipe for target 'idl' failed
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
   $sf->sudo_copy("$datadir/wmi-$version/Samba/source/bin/wmic", '/usr/local/bin/') or return;
   $sf->sudo_copy("$datadir/wmi-$version/Samba/source/bin/winexe", '/usr/local/bin/') or return;

   return 1;
}

#
# Must add specific user everywhere
#
# Howto enable WMI on a Windows machine
# http://community.zenoss.org/docs/DOC-4517
#
# Troubleshoot WMI connexion issues:
# wbemtest.exe + https://msdn.microsoft.com/en-us/library/windows/desktop/aa394603(v=vs.85).aspx
#
# dcomcnfg => DCOM permission for user
# Computer/Manage/Properties => 'WMI Control/Properties/Security'
#
# Open firewall for DCOM service
# http://www.returnbooleantrue.com/2014/10/enabling-wmi-on-windows-azure.html
#
sub request {
   my $self = shift;
   my ($query, $host, $user, $password) = @_;

   $host ||= $self->host;
   $user ||= $self->user;
   $password ||= $self->password;
   $self->brik_help_run_undef_arg('request', $query) or return;
   $self->brik_help_run_undef_arg('request', $host) or return;
   $self->brik_help_run_undef_arg('request', $user) or return;
   $self->brik_help_run_undef_arg('request', $password) or return;

   my $cmd = "wmic -U$user".'%'."$password //$host \"$query\"";

   my $r = $self->SUPER::execute($cmd) or return;
   #return $r;
   if (@$r > 1) {
      # First line is useless for us. Example: "CLASS: Win32_OperatingSystem"
      shift @$r;
      my $sp = Metabrik::String::Psv->new_from_brik_init($self) or return;
      $sp->first_line_is_header(1);
      # Need to desactivate double-quote parsing we may find in a process name
      $sp->quote("'");
      my $data = join("\n", @$r);
      return $sp->decode($data);
   }

   return $r;
}

#
# More requests:
# http://wiki.monitoring-fr.org/nagios/windows-client/superivision-wmi
#
sub get_win32_operatingsystem {
   my $self = shift;

   return $self->request('SELECT * FROM Win32_OperatingSystem', @_);
}

sub get_win32_process {
   my $self = shift;

   return $self->request('SELECT * FROM Win32_Process', @_);
}

1;

__END__

=head1 NAME

Metabrik::Remote::Wmi - remote::wmi Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
