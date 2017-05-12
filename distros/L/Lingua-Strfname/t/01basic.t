#!/usr/bin/perl -w

use strict;
use Test::More;
use constant DEBUG => 0;
BEGIN { plan tests => 29 };
BEGIN { use_ok 'Lingua::Strfname' or die }

#########################

my @names = qw(Clinton William Jefferson Mr. JD III "Bill");

my %tests = (
    '%f% m% l'           => 'William Jefferson Clinton',
    '%p% f% M% l%, s'    => 'Mr. William J. Clinton, JD',
    '%p% f% M% l% g%, s' => 'Mr. William J. Clinton III, JD',
    '%f% a% l'           => 'William "Bill" Clinton',
    '%l,% F%M'           => 'Clinton, W.J.',
    '%a% l,% s'          => '"Bill" Clinton, JD',
    '%l%, f% m'          => 'Clinton, William Jefferson',
    '%l%, f% M'          => 'Clinton, William J.',
    '%l%, f'             => 'Clinton, William',
    '%l%, F% m'          => 'Clinton, W. Jefferson',
    '%f% l'              => 'William Clinton',
    '%f% M% l'           => 'William J. Clinton',
    '%F%M% l'            => 'W.J. Clinton',
    '%F% m% l'           => 'W. Jefferson Clinton',
);

while (my ($f, $r) = each %tests) {
    is strfname($f, @names), $r, "Testing '$f'";
}

@names[2,6] = ('', '');

%tests = (
    '%f% m% l'           => 'William Clinton',
    '%p% f% M% l%, s'    => 'Mr. William Clinton, JD',
    '%p% f% M% l% g%, s' => 'Mr. William Clinton III, JD',
    '%f% a% l'           => 'William Clinton',
    '%l,% F%M'           => 'Clinton, W.',
    '%a% l,% s'          => ' Clinton, JD',
    '%l%, f% m'          => 'Clinton, William',
    '%l%, f% M'          => 'Clinton, William',
    '%l%, f'             => 'Clinton, William',
    '%l%, F% m'          => 'Clinton, W.',
    '%f% l'              => 'William Clinton',
    '%f% M% l'           => 'William Clinton',
    '%F%M% l'            => 'W. Clinton',
    '%F% m% l'           => 'W. Clinton',
);

while (my ($f, $r) = each %tests) {
    is strfname($f, @names), $r, "Testing '$f'";
}

__END__
