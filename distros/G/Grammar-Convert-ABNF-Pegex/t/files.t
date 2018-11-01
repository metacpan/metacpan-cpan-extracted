#!/usr/bin/env perl

use v5.10;

use strict;
use warnings;

use Test::More;
use Path::Tiny;
use Grammar::Convert::ABNF::Pegex;

my %tests = map{
    my $basename = $_->basename('.abnf');

    "$_" => $_->sibling( "$basename.pegex" )->stringify;
}path(__FILE__)->sibling('data')->children(qr/\.abnf$/);

for my $abnf_file ( sort keys %tests ) {
    my $conv = Grammar::Convert::ABNF::Pegex->new( abnf => path( $abnf_file )->slurp );
    is $conv->pegex, path( $tests{$abnf_file} )->slurp, $abnf_file;
}

done_testing();
