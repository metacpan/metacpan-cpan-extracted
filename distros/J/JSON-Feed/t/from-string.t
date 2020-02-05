#!perl
use strict;
use warnings;
use Test2::V0;

use FindBin '$Bin';
use File::Spec;
use File::Glob 'bsd_glob';
use Path::Tiny 'path';

use JSON::Feed;

for my $f ( bsd_glob( File::Spec->catfile($Bin, 'data', '*.json') ) ) {
    ok(lives {
        my $jf = JSON::Feed->from_string( path($f)->slurp );
        is $jf->get('version'), "https://jsonfeed.org/version/1";
    }, "from_string: $f") or note($@);
}

done_testing;
