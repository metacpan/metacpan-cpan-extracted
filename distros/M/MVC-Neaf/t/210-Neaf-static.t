#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use FindBin qw($Bin);
use Cwd qw(cwd);
use File::Basename qw(basename);

use MVC::Neaf;

my $restore_dir = cwd();
END { chdir $restore_dir };

neaf->static( t => $Bin, buffer => 1024*1024, cache_ttl => 100500 );
neaf->static( t2 => $Bin, buffer => 32, cache_ttl => 100500 );
neaf static => local => '.';

chdir '/';

my $sample = basename( __FILE__ ).".png";

my $real_content = do {
    open my $fd, "<", "$Bin/$sample"
        or die "Failed to open sample file $sample: $!";
    binmode $fd;
    local $/;
    <$fd>;
};
die "Failed to fetch sample content from $sample: $!"
    unless $real_content;

subtest 'Content found' => sub {
    my ($status, $head, $content) = neaf->run_test( "/t/$sample" );

    note explain $head;

    is ($status, 200, "Found self");
    is ($head->header( 'Content-Type' ), 'image/png', "Served as image");
    is ($head->header( 'Content-Length' ), length $content, "Length");
    like( $head->header( 'Expires' ), qr#\w\w\w, \d.*GMT#, "expire date present");
    ok ($content eq $real_content, "Content matches sample");
};

subtest "Testing cache now" => sub {
    my ($status, $head, $content) = neaf->run_test( "/t/$sample" );

    is ($status, 200, "Found self");
    is ($head->header( 'Content-Type' ), 'image/png', "Served as image");
    is ($head->header( 'Content-Length' ), length $content, "Length");
    like( $head->header( 'Expires' ), qr#\w\w\w, \d.*GMT#, "expire date present");

    ok ($content eq $real_content, "Content not changed");
};

subtest "Testing multipart file" => sub {
    my ($status, $head, $content) = neaf->run_test( "/t2/$sample" );

    is ($status, 200, "Found self");
    is ($head->header( 'Content-Type' ), 'image/png', "Served as image");
    is ($head->header( 'Content-Length' ), length $content, "Length");
    like( $head->header( 'Expires' ), qr#\w\w\w, \d.*GMT#, "expire date present");

    ok ($content eq $real_content, "Content not changed");
};

subtest "Relative path" => sub {
    my ($status, $head, $content) = neaf->run_test( "/local/$sample" );
    is ($status, 200, "Found self");
    ok ($content eq $real_content, "Content not changed");
};

done_testing;
