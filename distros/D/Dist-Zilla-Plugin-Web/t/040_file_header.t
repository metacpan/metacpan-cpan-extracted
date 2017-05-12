use strict;
use warnings;
use Test::More 0.88;

use lib 't/lib';

use Path::Class;
use JSON 2;

use Test::DZil;

{
    my $tzil = Dist::Zilla::Tester->from_config(
        { dist_root => 'test_data/FileHeader' },
    );

    $tzil->build;
    
    
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    
    # perl is such an oldboy :)
    $year += 1900;
    
    my $version         = $tzil->version;
    
    my $digest5_content = $tzil->slurp_file(file(qw(build lib Digest MD5.js))) . "";
    
    ok($digest5_content =~ /\/\*HEADER/, 'Correctly embedded header #1');
    ok($digest5_content =~ /HEADER\*\//, 'Correctly embedded header #2');
    
    ok($digest5_content =~ /$year/, 'Correctly embedded year');
    ok($digest5_content =~ /$version/, 'Correctly embedded version');
}

done_testing;
