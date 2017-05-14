#!perl -T

use strict;
use warnings FATAL => 'all';

use Test::More tests => 1;
use Lingua::IdSplitter;

my $splitter = Lingua::IdSplitter->new;
ok( ref($splitter) eq 'Lingua::IdSplitter', 'create splitter object' );
