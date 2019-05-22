use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::DZil;

my $package = 'error1';
my $module  = "$package.pm";

dies_ok { Builder->from_config( { dist_root => "corpus/$package" } ) }
'cannot use both underscore_eval_version and semantic_version attributes';

$package = 'error2';
$module  = "$package.pm";

dies_ok { Builder->from_config( { dist_root => "corpus/$package" } ) }
'rejects invalid version number';

done_testing;
