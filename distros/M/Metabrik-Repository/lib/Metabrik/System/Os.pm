#
# $Id: Os.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# system::os brik
#
package Metabrik::System::Os;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable uname linux freebsd distribution) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         _uname => [ qw(INTERNAL) ],
      },
      commands => {
         name => [ ],
         release => [ ],
         version => [ ],
         hostname => [ ],
         arch => [ ],
         distribution => [ ],
         is => [ qw(os) ],
         is_ubuntu => [ ],
         is_debian => [ ],
         is_linux => [ ],
         is_freebsd => [ ],
         is_centos => [ ],
         my => [ ],
      },
      require_modules => {
         'POSIX' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();

   $self->_uname({
      name => $sysname,
      hostname => $nodename,
      release => $release,
      version => $version,
      arch => $machine,
   });

   return $self->SUPER::brik_init(@_);
}

sub name {
   my $self = shift;

   return $self->_uname->{name};
}

sub release {
   my $self = shift;

   return $self->_uname->{release};
}

sub version {
   my $self = shift;

   return $self->_uname->{version};
}

sub hostname {
   my $self = shift;

   return $self->_uname->{hostname};
}

sub arch {
   my $self = shift;

   my $x86_64 = [ qw(x86 64) ];
   my $x86_32 = [ qw(x86 32) ];

   # Possible other values:
   # ia64, pc98, powerpc, powerpc64, sparc64

   my $arch = $self->_uname->{arch};
   if ($arch eq 'amd64' || $arch eq 'x86_64') {
      return $x86_64;
   }
   elsif ($arch eq 'i386' || $arch eq 'i685') {
      return $x86_32;
   }
   else {
      # We don't know, return raw result
      return [ $arch ];
   }

   # Error
   return;
}

sub distribution {
   my $self = shift;

   my $name = $self->name;
   my $release = $self->release;

   if ($name eq 'Linux') {
      my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
      $ft->as_array(1);
      $ft->strip_crlf(1);

      # Ubuntu case
      if (-f '/etc/lsb-release') {
         my $lines = $ft->read('/etc/lsb-release')
            or return $self->log->error("distribution: read failed");

         my %info = ();
         for my $line (@$lines) {
            my ($k, $v) = split('\s*=\s*', $line);
            $info{$k} = $v;
         }

         $info{DISTRIB_DESCRIPTION} =~ s/^"//;
         $info{DISTRIB_DESCRIPTION} =~ s/"$//;

         return {
            name => $info{DISTRIB_ID},                 # Ubuntu
            release => $info{DISTRIB_RELEASE},         # 14.10
            codename => $info{DISTRIB_CODENAME},       # utopic
            description => $info{DISTRIB_DESCRIPTION}, # Ubuntu 14.10
         };
      }
      elsif (-f '/etc/debian_version' && -f '/etc/os-release') {
         my $lines = $ft->read('/etc/os-release')
            or return $self->log->error("distribution: read failed");

         # /etc/os-release
         # PRETTY_NAME="Raspbian GNU/Linux 8 (jessie)"
         # NAME="Raspbian GNU/Linux"
         # VERSION_ID="8"
         # VERSION="8 (jessie)"
         # ID=raspbian
         # ID_LIKE=debian
         # HOME_URL="http://www.raspbian.org/"
         # SUPPORT_URL="http://www.raspbian.org/RaspbianForums"
         # BUG_REPORT_URL="http://www.raspbian.org/RaspbianBugs"

         my %info = ();
         for my $line (@$lines) {
            my ($k, $v) = split('\s*=\s*', $line);
            $v =~ s{^"*}{};
            $v =~ s{"*$}{};
            $info{$k} = $v;
         }

         $lines = $ft->read('/etc/debian_version')
            or return $self->log->error("distribution: read2 failed");

         my $release = '0.0';
         if (@$lines > 0) {
            chomp($release = $lines->[0]);
         }

         my ($codename) = $info{VERSION} =~ m{\(([^)]+)\)};

         return {
            name => 'Debian',  # Debian
            full_name => $info{NAME},           # Raspbian GNU/Linux
            release => $release,                # 8.0
            codename => $codename,              # jessis
            description => $info{PRETTY_NAME},  # Raspbian GNU/Linux 8 (jessie)
         };
      }
      elsif (-f '/etc/centos-release') {
         return {
            name => 'CentOS',  # CentOS
         };
      }
      elsif (-f '/etc/redhat-release') {
         return {
            name => 'RedHat',  # RedHat
         };
      }
      elsif (-f '/etc/os-release') {
         return {
            name => 'OpenSUSE',  # OpenSUSE
         };
      }
      elsif (-f '/etc/arch-release') {
         return {
            name => 'ArchLinux',  # ArchLinux
         };
      }
      elsif (-f '/etc/manjaro-release') {
         return {
            name => 'Manjaro Linux',  # Manjaro Linux
         };
      }
      elsif (-f '/etc/gentoo-release') {
         return {
            name => 'Gentoo',  # Gentoo
         };
      }
   }

   # Default
   return {
      name => $name,
      release => $release,
      codename => $name,
      description => "$name $release",
   };
}

sub is {
   my $self = shift;
   my ($os) = @_;

   $self->brik_help_run_undef_arg('is', $os) or return;

   $os = lc($os);

   my $name = $self->name or return;
   my $distrib = $self->distribution or return;
   if (exists($distrib->{name})) {
      my $this = lc($distrib->{name});
      if ($this eq $os) {
         return 1;
      }
   }
   if (defined($name)) {
      my $this = lc($name);
      if ($this eq $os) {
         return 1;
      }
   }

   return 0;
}

sub is_ubuntu {
   my $self = shift;

   return $self->is('ubuntu');
}

sub is_debian {
   my $self = shift;

   return $self->is('debian');
}

sub is_linux {
   my $self = shift;

   return $self->is('linux');
}

sub is_freebsd {
   my $self = shift;

   return $self->is('freebsd');
}

sub is_centos {
   my $self = shift;

   return $self->is('centos');
}

sub my {
   my $self = shift;

   my $name = $self->name or return;
   my $distrib = $self->distribution or return;
   if (exists($distrib->{name})) {
      my $this = lc($distrib->{name});
      return $this;
   }
   if (defined($name)) {
      my $this = lc($name);
      return $this;
   }

   return 'undef';
}

1;

__END__

=head1 NAME

Metabrik::System::os - system::os Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
