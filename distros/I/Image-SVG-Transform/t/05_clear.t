use strict;
use warnings;
use Test::More;
use Test::Exception;

use blib;

use_ok 'Image::SVG::Transform';

##simple transform
my $trans = Image::SVG::Transform->new();
ok ! $trans->has_transforms, 'no transforms yet';
$trans->extract_transforms('translate(1,1) scale(2)');
ok $trans->has_transforms, 'have transforms';

$trans->clear_transforms;
ok ! $trans->has_transforms, 'cleared transforms';

$trans->extract_transforms('scale(3)');
ok $trans->has_transforms, 'put them back in';

$trans->extract_transforms('');
ok !$trans->has_transforms, 'cleared by sending empty string';


done_testing();
