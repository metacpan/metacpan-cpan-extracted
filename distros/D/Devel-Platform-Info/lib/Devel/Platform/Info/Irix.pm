package Devel::Platform::Info::Irix;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '1.00';

#----------------------------------------------------------------------------

my %commands = (
    '_issue1'   => 'cat /etc/issue',
    '_issue2'   => 'cat /etc/.issue',
    '_uname'    => 'uname -a',
    'kname'     => 'uname -s',
    'kvers'     => 'uname -r',
    'osname'    => 'uname -o',
    'archname'  => 'uname -m',

    '_irix1'   => 'uname -R',   # IRIX specific
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
    $self->{info}{osname}   = 'IRIX';
    $self->{info}{oslabel}  = 'IRIX';
    $self->{info}{osvers}   = $self->{info}{kvers};
    $self->{info}{is32bit}  = $self->{info}{kname} !~ /64/ ? 1 : 0;
    $self->{info}{is64bit}  = $self->{info}{kname} =~ /64/ ? 1 : 0;

    $self->{info}{source}{$commands{$_}} = $self->{cmds}{$_}    for(keys %commands);
    return $self->{info};
}

#----------------------------------------------------------------------------

1;

__END__

=head1 NAME

Devel::Platform::Info::Irix - Retrieve Irix platform metadata

=head1 SYNOPSIS

  use Devel::Platform::Info::Irix;
  my $info = Devel::Platform::Info::Irix->new();
  my $data = $info->get_info();

=head1 DESCRIPTION

This module is a driver to determine platform metadata regarding the Irix
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

Returns a hash reference to the Irix platform metadata.

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

  * http://www.faqs.org/faqs/sgi/faq/admin/section-2.html

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
