use strict;
use warnings;
use Test::More qw(no_plan);

use Games::Nonogram::Line;

my $line = Games::Nonogram::Line->new( size => 4 );

# default is all clear

ok $line->as_string eq '____';

# bit on

$line->on(1);

ok $line->as_string eq 'X___';

# bit off

$line->off(2);

ok $line->as_string eq 'X.__';

# bit on with ->value

$line->value(3 => 1);

ok $line->as_string eq 'X.X_';

# get value

ok $line->value(4) == -1;

# clear bit (to ambiguous state)

$line->clear(3);

ok $line->as_string eq 'X.__';

# clear without arg is all clear

$line->clear;

ok $line->as_string eq '____';

# multiple bits on

$line->on( from => 2, to => 4 );

ok $line->as_string eq '_XXX';

# multiple bits off

$line->off( from => 3, length => 2 );

ok $line->as_string eq '_X..';
