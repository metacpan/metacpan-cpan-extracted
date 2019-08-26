package Devel::Platform::Info::BeOS;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.00';

#----------------------------------------------------------------------------

my %commands = (
    '_uname1'   => 'uname -a',
    '_uname2'   => 'uname -mrr',
    'kname'     => 'uname -s',
    'kvers'     => 'uname -r',
    'osname'    => 'uname -o',
    'archname'  => 'uname -m',
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

    $self->{info}{osflag}   = $^O;
    $self->{info}{kvers}    = lc $self->{info}{kvers};
    $self->{info}{kernel}   = lc($self->{info}{kname}) . '-' . $self->{info}{kvers};
    $self->{info}{osname}   = $self->{info}{kname};
    $self->{info}{oslabel}  = $self->{info}{kname};
    $self->{info}{osvers}   = $self->{info}{kvers};
    $self->{info}{osvers}   =~ s/-release.*//;
    $self->{info}{is32bit}  = $self->{info}{archname} !~ /(64|alpha)/ ? 1 : 0;
    $self->{info}{is64bit}  = $self->{info}{archname} =~ /(64|alpha)/ ? 1 : 0;

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

sub _beos_versions {
    return {
        'R4.5'  => 'Genki',
        'R5'    => 'Maui',
        'R5.1'  => 'Dano',
    };
}


#----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Devel::Platform::Info::BeOS - Retrieve BeOS platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::BeOS;
  my $info = Devel::Platform::Info::BeOS->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the BeOS
family of operating systems. It should be called indirectly via it's parent
Devel::Platform::Info.

Note that BeOS was last release in 2001, however deriatives have since been
release, most notably Haiku, which was last released in 2012. As such, this
module it experimental, and may be cloned to reference Haiku in the future.

=head1 INTERFACE

=head2 The Constructor

=over

=item * new

Simply constructs the object.

=back

=head2 Methods

=over 4

=item * get_info

Returns a hash reference to the BeOS platform metadata.

Returns the following keys:

  source
  archname
  osname
  osvers
  oslabel
  is32bit
  is64bit
  osflag

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

  Copyright (C) 2010-2019 Birmingham Perl Mongers

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
