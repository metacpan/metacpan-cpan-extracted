package Devel::Platform::Info::SCO;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.16';

#----------------------------------------------------------------------------

my %commands = (
    '_uname'    => 'uname -a',
    '_lsb'      => 'uname -X',
    'kname'     => 'uname -s',
    'kvers'     => 'uname -r',
#    'osname'    => 'uname -o',
#    'osvers'    => 'uname -v',
    'archname'  => 'uname -m',
);

my %releases = (
    '3.2.0'     => { oslabel => 'SCO UNIX System V/386',    codename => '' },
    '3.2.1'     => { oslabel => 'Open Desktop 1.0',         codename => '' },
    '3.2v2.0'   => { oslabel => 'Open Desktop 1.1',         codename => '' },
    '3.2v4.0'   => { oslabel => 'SCO UNIX',                 codename => '' },
    '3.2v4.1'   => { oslabel => 'Open Desktop 2.0',         codename => 'Phoenix' },
    '3.2v4.2'   => { oslabel => 'Open Desktop/Server 3.0',  codename => 'Tbird' },
    '3.2v5.0'   => { oslabel => 'OpenServer 5.0',           codename => 'Everest' },
    '3.2v5.0.2' => { oslabel => 'OpenServer 5.0.2',         codename => '' },
    '3.2v5.0.4' => { oslabel => 'OpenServer 5.0.4',         codename => 'Comet' },
    '3.2v5.0.5' => { oslabel => 'OpenServer 5.0.5',         codename => 'Davenport' },
    '3.2v5.0.6' => { oslabel => 'OpenServer 5.0.6',         codename => 'Freedom' },
    '3.2v5.0.7' => { oslabel => 'OpenServer 5.0.7',         codename => 'Harvey West' },
    '5'         => { oslabel => 'OpenServer 6.0',           codename => 'Legend' },
);

#----------------------------------------------------------------------------

sub new {
    my ($class) = @_;
    my $self = {};
    bless $self, $class;

    return $self;
}

sub get_info {
    my $self  = shift;

    for my $cmd (keys %commands) {
        $self->{cmds}{$cmd} = `$commands{$cmd} 2>/dev/null`;
        $self->{cmds}{$cmd} =~ s/\s+$//s;
        $self->{info}{$cmd} = $self->{cmds}{$cmd}   if($cmd !~ /^_/);
    }

    $self->{info}{osflag}       = $^O;
    $self->{info}{osname}       = 'SCO';
    $self->{info}{kernel}       = lc($self->{info}{kname}) . '-' . $self->{info}{kvers};
    ($self->{info}{osvers})     = $self->{cmds}{'_lsb'} =~ /Release\s*=\s*(.*?)\n/s;
    ($self->{info}{oslabel})    = $releases{ $self->{info}{osvers} }->{oslabel};
    ($self->{info}{codename})   = $releases{ $self->{info}{osvers} }->{codename};

    $self->{info}{is32bit}      = $self->{info}{archname} !~ /_(64)$/ ? 1 : 0;
    $self->{info}{is64bit}      = $self->{info}{archname} =~ /_(64)$/ ? 1 : 0;

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

1;

__END__

=head1 NAME

Devel::Platform::Info::SCO - Retrieve SCO Unix platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::SCO;
  my $info = Devel::Platform::Info::SCO->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the SCO
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

Returns a hash reference to the SCO platform metadata.

Returns the following keys:

  source
  archname
  osname
  osvers
  oslabel
  is32bit
  is64bit
  osflag

  codename
  kernel
  kname
  kvers

=back

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

  Copyright (C) 2010-2016 Birmingham Perl Mongers

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
