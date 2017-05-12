#!perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use Locale::Wolowitz;

my $w = Locale::Wolowitz->new;
isa_ok $w, 'Locale::Wolowitz';

$w->load_structure({
    'OMG' => {
        en => 'Oh My God',
        fr => 'Oh mon Dieu',
    },
    'Hi %1' => {
        fr => 'Bonjour %1',
    },
});

my $loc = $w->loc_for('fr');

is $loc->('OMG'), 'Oh mon Dieu', 'en -> fr';

is $loc->('Hi %1', 'Marcel' ), 'Bonjour Marcel', 'with args';

done_testing();
