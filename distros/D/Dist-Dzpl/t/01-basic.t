#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
plan 'no_plan';

use Dist::Dzpl;

my $dzpl = Dist::Dzpl->from_arguments(
    name => 'Dist-Dzpl',
    version => '0.001',
    author => 'J.A. Perl Hacker <japh@example.org>',
    license => 'Perl-5',
    copyright => 'J.A. Perl Hacker',
);

is( $dzpl->zilla->name, 'Dist-Dzpl' );
is( $dzpl->zilla->version, '0.001' );
is( $dzpl->zilla->copyright_holder, 'J.A. Perl Hacker' );
