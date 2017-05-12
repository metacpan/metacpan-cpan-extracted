use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;
use JSON 2;
use String::BOM qw(string_has_bom);

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/StripBOM' },
    );

    $tzil->build;
    
    
    my $content1 = $tzil->slurp_file(file(qw(build lib Sample Dist.js))) . "";
    
    ok(!string_has_bom($content1), 'BOM was stripped out');
}

done_testing;
