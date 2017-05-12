#!/usr/bin/perl
# $Id: 01run.t,v 1.2 2005/05/24 08:54:56 rousse Exp $

use Test::More tests => 7;
use File::Temp qw/tempfile/;
use Dict::FSA;
use strict;

# skip all tests if fsa is not available
SKIP: {
    skip "fsa is not available", 7 if system("fsa_ubuild -v /dev/null 2>/dev/null");
    my @words = map { chomp; $_} <DATA>;
    my ($hf, $file) = tempfile(CLEANUP => 1);
    Dict::FSA->create_dict(\@words, $file);

    ok(-f $file);

    my $dict = Dict::FSA->new(1, [ $file ]);
    isa_ok($dict, 'Dict::FSA');

    ok($dict->check("paume"));
    ok($dict->check("plume"));
    ok(!$dict->check("poume"));

    ok(eq_array([ $dict->suggest("poume") ], [ qw/plume paume/ ])); 
    ok(eq_array([ $dict->suggest("paume") ], [ qw/plume/ ])); 
}

__DATA__
paume
plume
