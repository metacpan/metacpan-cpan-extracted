#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use Sub::Install qw/install_sub/;
use Benchmark    qw/cmpthese/;
use Unicode::Normalize ();

print "Perl Ver.: $^V\n";

my $text = 'トリ㌧';

install_sub({ code => 'NFKC', from => 'Unicode::Normalize', as => 'nfkc1' });

is(nfkc1($text), 'トリトン');
is(nfkc2($text), 'トリトン');

done_testing;

cmpthese(-1, {
    'subinstall'   => sub { nfkc1($text); },
    'redefinition' => sub { nfkc2($text); },
});

print "\n\n";

sub nfkc2 { Unicode::Normalize::NFKC(shift); }
