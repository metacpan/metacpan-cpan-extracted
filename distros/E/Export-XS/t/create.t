use strict;
use warnings;
use Test::More;
use Test::Exception;

use Export::XS {CONST1 => 1, CONST2 => 'suka'};
use Export::XS CONST3 => 3, CONST4 => 'suka2';

subtest 'creating constants' => sub {
    is CONST1, 1;
    is CONST2, 'suka';
    is CONST3, 3;
    is CONST4, 'suka2';
};

subtest 'collision error' => sub {
    dies_ok { Export::XS->import({CONST1 => 2}) };
    is CONST1, 1;
};

subtest 'bad const names' => sub {
    dies_ok { Export::XS->import(\1, 1) };
};

subtest 'bad stash' => sub {
    dies_ok { Export::XS::import('Non::Existent', 1, 1) };
};

done_testing();
