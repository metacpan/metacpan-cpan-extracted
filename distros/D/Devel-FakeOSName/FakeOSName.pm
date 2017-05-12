package Devel::FakeOSName;

use strict;
use warnings;

require Config;

$Devel::FakeOSName::VERSION = '0.01';

{
    my $orig_STORE = *Config::STORE{CODE};
    undef &Config::STORE;
    *Config::STORE = sub {
        goto &$orig_STORE unless defined $_[1] && $_[1] eq 'osname';
        die "an osname string must be passed" unless defined $_[2];

        # modify it once and immediately reset to the normal read-only state
        $_[0]->{osname} = $_[2];
        #undef &Config::STORE; # can't undef an active sub
        no warnings 'redefine';
        *Config::STORE = $orig_STORE;
        return $_[2];
    };
}

sub import {
    my($package, $os) = @_;

    return unless $os;

    # read/write
    $^O = $Config::Config{osname} = $os;
}


1;

=pod

=head1 NAME

Devel::FakeOSName - Make Perl think it runs on a different OS

=head1 SYNOPSIS

  # build us Makefile for aix
  perl -MDevel::FakeOSName=aix Makefile.PL

=head1 DESCRIPTION

Sometimes your code includes code specific to an OS that you don't
have an access to, but you want to see what happens if it was to run
on that other OS.

Currently mostly useful for looking at generated Makefiles. Needs much
more work to be really useful.

=head1 TODO

Currently the module just modifies $^O and $Config{osname}. Could
probably somehow supply overrides for other %Config::Config values and
ExtUtils::Embed.

Patches are welcome.

=cut

