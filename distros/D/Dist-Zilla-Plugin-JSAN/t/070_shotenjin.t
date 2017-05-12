use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/Shotenjin' },
    );

    $tzil->build;
    
    my $digest_md5_content              = $tzil->slurp_file(file(qw(build lib Digest MD5.js)));
    my $test_content                    = $tzil->slurp_file(file(qw(build lib Test.js)));
    
    
    ok($digest_md5_content =~ m!\Q<a>this is a template</a>\E!s, '`Digest/MD5.js` content was processed');
    ok($test_content =~ m/sources : '/s, '`Test.js` content was processed');

}

done_testing;
