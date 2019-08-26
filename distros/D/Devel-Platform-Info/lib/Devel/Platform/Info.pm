package Devel::Platform::Info;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.00';

#----------------------------------------------------------------------------

my %map = (
    # Unix (and like) family OSes
    'freebsd'       => 'BSD',
    'openbsd'       => 'BSD',
    'netbsd'        => 'BSD',
    'mirbsd'        => 'BSD',
    'dragonfly'     => 'BSD',
    'midnightbsd'   => 'BSD',
    
    'irix'          => 'Irix',
    
    'linux'         => 'Linux',
    'aix'           => 'Linux',
    'bsdos'         => 'Linux',
    'dgux'          => 'Linux',
    'dynixptx'      => 'Linux',
    'hpux'          => 'Linux',
    'dec_osf'       => 'Linux',
    'svr4'          => 'Linux',
    'unicos'        => 'Linux',
    'unicosmk'      => 'Linux',
    'ultrix'        => 'Linux',
    
    'sco_sv'        => 'SCO',
    'sco3'          => 'SCO',
    'sco'           => 'SCO',

    'solaris'       => 'Solaris',
    'sunos'         => 'Solaris',

    'beos'          => 'BeOS',

    # Windows family OSes
    'dos'           => 'Win32',
    'os2'           => 'Win32',
    'mswin32'       => 'Win32',
    'netware'       => 'Win32',
    'cygwin'        => 'Win32',

    # Mac family OSes
    'macos'         => 'Mac',
    'rhapsody'      => 'Mac',
    'darwin'        => 'Mac',

    # Other OSes
    'vms'           => 'Linux',
    'vos'           => 'Linux',
    'os390'         => 'Linux',
    'vmesa'         => 'Linux',
    'riscos'        => 'Linux',
    'amigaos'       => 'Linux',
    'beos'          => 'Linux',
    'machten'       => 'Linux',
    'mpeix'         => 'Linux',
    'bitrig'        => 'Linux',
    'minix'         => 'Linux',
    'nto'           => 'Linux',
);

#----------------------------------------------------------------------------

sub new {
    my ($class) = @_;
    my $self    = {};
    bless  $self, $class;
    return $self;
}

sub get_info {
    my $self  = shift;
    my $data;

    my $plugin = $map{ lc $^O } || 'Linux';

    my $driver = 'Devel::Platform::Info::' . $plugin;
    my $require = "$driver.pm";
    $require =~ s!::!/!g;

    eval {
        require $require;
        $self->{driver} = $driver->new();
        $data = $self->{driver}->get_info();
    };

    $data->{error} = $@ if($@);

    return $data;
}

1;

__END__

=head1 NAME

Devel::Platform::Info - Unified framework for obtaining common platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info;
  my $info = Devel::Platform::Info->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a wrapper to the drivers which can determine platform metadata
regarding the currently running operating system.

The intention of this distribution is to provide key identifying components
regarding the platform currently being used, for the CPAN Testers test
reports. Currently the reports do not often contain enough information to help
authors understand specific failures, where the platform may be a factor.

However, it is hoped that this distribution will find more uses far beyond the
usage for CPAN Testers.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Simply constructs the object.

=back

=head2 Methods

=over 4

=item * get_info

Returns a hash reference to the platform metadata.

Returns at least the following keys:

  source
  archname
  osname
  osvers
  oslabel
  is32bit
  is64bit
  osflag

Note that the 'source' key returns the commands and output used to obtain the
metadata for possible future use.

Further keys may be available to provide additional information if applicable
to the specific operating system.

=back

=head1 REFERENCES

The following links were used to understand how to retrieve the metadata:

  * http://alma.ch/perl/perloses.htm

=head1 BUGS, PATCHES & FIXES

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties, that is not explained within the POD
documentation, please send bug reports and patches to the RT Queue (see below).

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
