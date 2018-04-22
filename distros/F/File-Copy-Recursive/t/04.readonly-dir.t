use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 'warnings';
use Test::Deep;
use File::Temp;
use Path::Tiny;
use File::Copy::Recursive 'dircopy';

if ( $^O eq 'MSWin32' ) {
    plan skip_all => "test uses chmod which may or may not do what we want here, patches welcome!";
}

my $dir = File::Temp->newdir;
for my $pth (qw(src/ src/top src/top/sub1 src/top/sub2)) {
    mkdir "$dir/$pth";
}

path("$dir/src/top/sub1/file1.2")->spew("hello-1.2");
path("$dir/src/top/sub2/file2.2")->spew("hello-2.2");
path("$dir/src/top/sub2/file2.1")->spew("");
`chmod -w $dir/src/top/sub2`;

SKIP: {
    skip "test read only", 3, if -w "$dir/src/top/sub2";
    my @warnings = warnings { dircopy( "$dir/src", "$dir/dest" ) };
    cmp_deeply( \@warnings, [ re(qr/Copying readonly directory/) ], "read only dir issues warning");
    is( scalar( path("$dir/src/top/sub2")->children ), 2, "readonly direct0ry contents are copied" );
    is( scalar( path("$dir/src/top/sub1")->children ), 1, "writable directory contents are copied" );
}

`chmod +w $dir/src/top/sub2`;

done_testing;
