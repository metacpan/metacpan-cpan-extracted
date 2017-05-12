package Example;
use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Methods -as => 'routine';

sub new { bless {}, __PACKAGE__ };

routine foo ($a, $b) {
    $a + $b;
}

1;
