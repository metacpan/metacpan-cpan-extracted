package Devel::Platform::Info::BSD;

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

    # NOTE: 'sparc64' (64bit) and 'sparc' (32bit) both look like they identify
    # themselves as archname = 'sparc'. If true, is there any other way to
    # easily distinguish the difference?

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

#----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Devel::Platform::Info::BSD - Retrieve BSD platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::BSD;
  my $info = Devel::Platform::Info::BSD->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the BSD
family of operating systems. It should be called indirectly via it's parent
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

Returns a hash reference to the BSD platform metadata.

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

=head1 REFERENCES

The following links were used to understand how to retrieve the metadata:

  * https://www.cyberciti.biz/faq/how-to-find-out-freebsd-version-and-patch-level-number/
  * http://www.netbsd.org/ports/

Thanks to Chris 'BINGOS' Williams for the pointers to the appropriate links.

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
