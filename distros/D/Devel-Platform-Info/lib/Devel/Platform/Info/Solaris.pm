package Devel::Platform::Info::Solaris;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.16';

#----------------------------------------------------------------------------

my %commands = (
    '_uname1'   => 'uname -a',
    '_showrev'  => 'showrev -a | grep -v "^Patch"',
    '_release'  => 'cat /etc/release',
    '_isainfo'  => '/usr/bin/isainfo -kv',
    'kname'     => 'uname -s',
    'kvers'     => 'uname -r',
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
    $self->{info}{kernel}   = lc($self->{info}{kname}) . '-' . $self->{info}{kvers};
    $self->{info}{is32bit}  = $self->{cmds}{_isainfo} !~ /64-bit/s ? 1 : 0;
    $self->{info}{is64bit}  = $self->{cmds}{_isainfo} =~ /64-bit/s ? 1 : 0;

    ($self->{info}{osname}) = $self->{cmds}{_release} =~ /((?:Open)?Solaris|SunOS|OpenIndiana)/is;
    $self->{info}{oslabel}  = $self->{info}{osname};
    $self->{info}{osvers}   = $self->{info}{kvers};

    # Solaris versions are based on SunOS, but just slightly different!
    if($self->{info}{osname} =~ /Solaris/) {
        $self->{info}{osvers} =~ s/^5\.([0123456]\b)/2.$1/;
        $self->{info}{osvers} =~ s/^5\.(\d+)/$1/;
    }

    # Question: Anyone know how to get the real version number for OpenSolaris?
    # i.e. "2008.05" or "2009.06"

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

#----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Devel::Platform::Info::Solaris - Retrieve Solaris platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::Solaris;
  my $info = Devel::Platform::Info::Solaris->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the Solaris
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

Returns a hash reference to the Solaris platform metadata.

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

  * http://www.symantec.com/connect/blogs/commands-find-out-solaris-os-version-ralus-rmal-issues
  * http://docs.sun.com/app/docs/doc/816-0211/6m6nc676p?a=view
  * http://docs.sun.com/app/docs/doc/816-5138/6mba6ua58?a=view

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
