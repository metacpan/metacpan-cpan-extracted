#!/usr/bin/env perl
use strict;
use inc::Module::Install;

name 'Dezi-Client';
all_from 'lib/Dezi/Client.pm';
author q{Peter Karman <karman@cpan.org>};
license 'perl';
homepage 'https://github.com/karpet/dezi-client-perl';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Client';
repository 'git://github.com/karpet/dezi-client-perl.git';

build_requires 'Test::More';

# Dezi server not required for client, but
# should be at least version 0.001008 on server-side.

requires 'LWP::UserAgent';
requires 'LWP::MediaTypes';
requires 'Moo';
requires 'namespace::autoclean';
requires 'Type::Tiny';
requires 'HTTP::Request';
requires 'Search::Tools' => '1.000';
requires 'URI::Query';
requires 'JSON';
requires 'Carp';

install_script 'bin/dezi-client';

auto_install;

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean    => {
        FILES => join(
            ' ',
            qw(
                Dezi-Client-*
                )
        )
    }
);
