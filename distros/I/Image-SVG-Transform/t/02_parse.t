use strict;
use warnings;
use Test::More;
use Test::Exception;

use blib;

use_ok 'Image::SVG::Transform';

##skewX
my $trans = Image::SVG::Transform->new();
lives_ok { $trans->extract_transforms('skewX(1)') } 'parses a single skewX command';
is_deeply $trans->transforms(), [ { type => 'skewX', params => [1], }], '... validate parameters';

dies_ok { $trans->extract_transforms('skewX()'); } 'skewX dies on too few arguments';
like $@, qr'No parameters for transform skewX', '...correct error message';

dies_ok { $trans->extract_transforms('skewX(1,2,3)'); } 'skewX dies on too many arguments';
like $@, qr'Too many parameters 3 for transform skewX', '...correct error message';

##skewY
lives_ok { $trans->extract_transforms('skewY(4)'); } 'parses a single skewY command, two args';
is_deeply $trans->transforms(), [ { type => 'skewY', params => [4], }], '... validate parameters';

##rotate
lives_ok { $trans->extract_transforms('rotate(1)') } 'parses a single rotate command, 1 arg';
is_deeply $trans->transforms(), [ { type => 'rotate', params => [1], }], '... validate parameters';

lives_ok { $trans->extract_transforms('rotate(1 2 3)') } 'parses a single rotate command, 3 args';
is_deeply
    $trans->transforms,
    [
        { type => 'translate', params => [2,3], },
        { type => 'rotate', params => [1], },
        { type => 'translate', params => [-2,-3], },
    ],
    '3-arg rotate adds a pre- and post translate';

dies_ok { $trans->extract_transforms('rotate(1,2,3,4)'); } 'rotate dies on too many arguments';
like $@, qr'Too many parameters 4 for transform rotate', '...correct error message';

dies_ok { $trans->extract_transforms('rotate(1,2)'); } 'rotate dies with only two arguments';
like $@, qr'rotate transform may not have two parameters', '...correct error message';

##matrix
lives_ok { $trans->extract_transforms('matrix(1 2 3 4 5 6)') } 'parses a single matrix command, 3 args';
is_deeply $trans->transforms(), [ { type => 'matrix', params => [1,2,3,4,5,6], }], '... validate parameters';

dies_ok { $trans->extract_transforms('matrix(1,2,3,4,5)'); } 'matrix dies with only five arguments';
like $@, qr'matrix transform must have exactly six parameters', 'correct error message';

done_testing();
