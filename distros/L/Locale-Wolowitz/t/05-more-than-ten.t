#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 1;
use Locale::Wolowitz;

my $w = Locale::Wolowitz->new;

$w->load_structure({
    'list' => {
        fr => '%1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11',
    },
});

is $w->loc('list', 'fr', 'a'..'z')
    => 'a b c d e f g h i j k',
    'more than 10 arguments';

done_testing();
