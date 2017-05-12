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
    
    my $static_file = $tzil->slurp_file(file(qw(build lib Digest MD5 assets dep dep.js))) . "";
    
    ok($static_file =~ /Some external js dependency/, 'Static dir processed correctly');
}

done_testing;
