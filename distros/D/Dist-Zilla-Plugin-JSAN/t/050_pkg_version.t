use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;
use JSON 2;

use Test::DZil;

{
    $ENV{npm_config_root}     = dir('test_data', 'Bundle', 'npm')->absolute() . '';
    
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Bundle' },
    );

    $tzil->build;
    
    my $digest5_content = $tzil->slurp_file(file(qw(build lib Digest MD5.js))) . "";
    my $digest6_content = $tzil->slurp_file(file(qw(build lib Digest MD6.js))) . "";
    
    ok($digest5_content =~ /VERSION : 0.01,/, 'Correctly embedded version #1');
    ok($digest6_content =~ /VERSION : 0.01(?!,)/, 'Correctly embedded version #2');
    
    
    $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Readme' },
    );

    $tzil->build;
    
    my $sample_dist_content = $tzil->slurp_file(file(qw(build lib Sample Dist.js))) . "";
    
    ok($sample_dist_content =~ /VERSION : '0.01.02',/, 'Correctly embedded version #3');
    
}

done_testing;
