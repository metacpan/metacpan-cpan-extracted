#!/usr/bin/perl
# $Id: 01run.t,v 1.7 2005/05/24 08:54:56 rousse Exp $

use Test::More tests => 7;
use File::Temp qw/tempdir/;
use Dict::Lexed;
use strict;

# skip all tests if lexed is not available
SKIP: {
    skip "lexed is not available", 7 if system("lexed -v 2>/dev/null");

    my @words = map { chomp; $_} <DATA>;
    my $dir = tempdir(CLEANUP => 1);
    Dict::Lexed->create_dict(\@words, "-d $dir");

    ok(
	-f "$dir/lexicon.fsa" && -f "$dir/lexicon.tbl"
    );


    my $dict = Dict::Lexed->new("-d $dir", "-s 1 -W 10");
    isa_ok($dict, 'Dict::Lexed');

    ok($dict->check("paume"));
    ok($dict->check("plume"));
    ok(!$dict->check("poume"));

    ok(eq_array([ $dict->suggest("poume") ], [ qw/paume plume/ ])); 
    ok(eq_array([ $dict->suggest("paume") ], [ qw/plume/ ])); 
}

__DATA__
paume
plume
