#!perl
use strict;
use warnings;
use utf8;
use Test2::V0;

use FindBin '$Bin';
use File::Spec;
use File::Glob 'bsd_glob';
use Path::Tiny 'path';

use JSON::Feed;

for my $f ( bsd_glob( File::Spec->catfile($Bin, 'data', '*.json') ) ) {
    subtest $f, sub {
        ok lives {
            my $feed = JSON::Feed->parse( $f );
            is $feed->get('version'), "https://jsonfeed.org/version/1";
        }, "file name";

        ok lives {
            open my $fh, '<:utf8', $f;
            my $feed = JSON::Feed->parse( $fh );
            is $feed->get('version'), "https://jsonfeed.org/version/1";
            close($fh);
        }, "file handle";

        ok lives {
            my $content = path($f)->slurp;
            my $feed = JSON::Feed->parse( \$content );
            is $feed->get('version'), "https://jsonfeed.org/version/1";
        }, "content ref";
    };
}

done_testing;
