package Devel::Platform::Info::Win32;

use strict;
use warnings;
use POSIX;

use vars qw($VERSION);
$VERSION = '1.00';

#----------------------------------------------------------------------------

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;

    return $self;
}

sub get_info {
    my $self  = shift;

    $self->{info}{osflag}       = $^O;
    my $inf = $self->_GetArchName();
    $self->{info}{oslabel} = $inf->{osLabel};
    $self->{info}{osvers} = $inf->{version};
    $self->{info}{archname} = $inf->{archname};
    $self->{info}{is32bit} = $self->{info}{archname} !~ /64/ ? 1 : 0;
    $self->{info}{is64bit} = $self->{info}{archname} =~ /64/ ? 1 : 0;
    $self->{info}{source} = $inf->{source};
    $self->{info}{wow64} = $inf->{wow64};

    return $self->{info};
}

sub _GetArchName
{
    my $self = shift;
    my @uname = POSIX::uname();
    my @versions = Win32::GetOSVersion();
    my $info = $self->_InterpretWin32Info(@versions);
    $self->_AddPOSIXInfo($info, \@uname);
    return $info;
}

sub _AddPOSIXInfo
{
    my $self = shift;
    my $info = shift;
    my $uname = shift;
    my $arch = $uname->[4];
    $info->{archname} = $arch;
    $info->{source} = {
        uname => $uname,
        GetOSVersion => $info->{source},
    };
    # used the tip from David Wang's blog,
    # http://blogs.msdn.com/b/david.wang/archive/2006/03/26/howto-detect-process-bitness.aspx
    if($ENV{'PROCESSOR_ARCHITEW6432'})
    {
        $info->{wow64} = 1;
    }
    else
    {
        $info->{wow64} = 0;
    }
}

sub _InterpretWin32Info
{
    my $self = shift;
    my @versionInfo = @_;
    my ($string, $major, $minor, $build, $id, $spmajor, $spminor, $suitemask, $producttype, @extra) = @versionInfo;
    my ($osname);
    my $NTWORKSTATION = 1;
    if($major == 5 && $minor == 2 && $producttype == $NTWORKSTATION)
    {
        $osname = 'Windows XP Pro 64';
    } elsif($major == 5 && $minor == 2 && $producttype != $NTWORKSTATION)
    {
        # server 2003, win home server
        # server 2003 R2
        # I need more info from GetSystemMetrics
        # be sure about the exact details.
        $osname = 'Windows Server 2003';
    } elsif($major == 5 && $minor == 1)
    {
        $osname = 'Windows XP';
    } elsif($major == 5 && $minor == 0)
    {
        $osname = 'Windows 2000';
    } elsif($major == 6 && $minor == 1 && $producttype == $NTWORKSTATION)
    {
        $osname = 'Windows 7';
    } elsif($major == 6 && $minor == 1 && $producttype != $NTWORKSTATION)
    {
        $osname = 'Windows Server 2008 R2';
    } elsif($major == 6 && $minor == 0 && $producttype == $NTWORKSTATION)
    {
        $osname = 'Windows Vista';
    } elsif($major == 6 && $minor == 0 && $producttype != $NTWORKSTATION)
    {
        $osname = 'Windows Server 2008';
    } elsif($major == 4 && $minor == 0 && $id == 1)
    {
        $osname = "Windows 95";
    } elsif($major == 4 && $minor == 10)
    {
        $osname = "Windows 98";
    } elsif($major == 4 && $minor == 90)
    {
        $osname = "Windows Me";
    } elsif($major == 4 && $minor == 0)
    {
        $osname = 'Windows NT 4';
    } elsif($major == 3 && $minor == 51)
    {
        $osname = "Windows NT 3.51";
    } else
    {
        $osname = 'Unrecognised - please file an RT case';
    }
    my $info =
    {
        osName => 'Windows',
        osLabel => $osname,
        version => "$major.$minor.$build.$id",
        source => \@versionInfo,
    };
    return $info;
}


1;

__END__

=head1 NAME

Devel::Platform::Info::Win32 - Retrieve Windows platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::Win32;
  my $info = Devel::Platform::Info::Win32->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the Win32
operating system. It should be called indirectly via it's parent
Devel::Platform::Info

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Simply constructs the object.

=back

=head2 Methods

=over 4

=item * get_info

Returns a hash reference to the Win32 platform metadata.

Returns the following keys:

  source
  archname
  osname
  osvers
  oslabel
  is32bit
  is64bit
  osflag
  wow64

On a 64 bit Windows if you are running 32 bit perl the archname is likely to
indicate x86.  The wow64 variable will tell you if you are in fact running on
x64 Windows.

=back

=head1 BUGS, PATCHES & FIXES

The module cannot accurately tell the difference between the Windows Server
2003 and Windows Server 2003 R2.

The wow64 variable indicates whether or not you are running a 32 bit perl on a
64 bit windows.  It uses the environment variable PROCESSOR_ARCHITEW6432 rather
than the IsWow64Process call because it's simpler.

If you spot a bug or are experiencing difficulties, that is not explained
within the POD documentation, please send bug reports and patches to the RT
Queue (see below).

RT Queue: http://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Platform-Info

=head1 AUTHORS

  Barbie (BARBIE) <barbie@cpan.org>
  Brian McCauley (NOBULL) <nobull67@gmail.com>
  Colin Newell (NEWELL) <newellc@cpan.org>
  Jon 'JJ' Allen (JONALLEN) <jj@jonallen.info>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2010-2019 Birmingham Perl Mongers

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
