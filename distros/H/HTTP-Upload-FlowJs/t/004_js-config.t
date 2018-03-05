#!perl -w
use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;

use HTTP::Upload::FlowJs;
use File::Temp qw(tempdir);
use ExtUtils::Command();

my $tempdir = tempdir( );
END {
    if( defined $tempdir ) {
        diag "Cleaning up $tempdir";
        @ARGV = $tempdir;
        ExtUtils::Command::rm_rf $tempdir;
    };
};

my $flowjs = HTTP::Upload::FlowJs->new(
    incomingDirectory => $tempdir,
    forceChunkSize => 0,
);

is_deeply
    $flowjs->jsConfig(addition => 'value'),
    {
        'chunkSize' => '524288',
        'forceChunkSize' => 0,
        'simultaneousUploads' => 3,
        'testChunks' => 1,
        'uploadMethod' => 'POST',
        'withCredentials' => 1,
        'addition' => 'value',
    },
    "jsConfig and chunkSize when forceChunkSize(0)";

$flowjs = HTTP::Upload::FlowJs->new(
    incomingDirectory => $tempdir,
);

is_deeply
    $flowjs->jsConfig,
    {
        'chunkSize' => '1048576',
        'forceChunkSize' => 1,
        'simultaneousUploads' => 3,
        'testChunks' => 1,
        'uploadMethod' => 'POST',
        'withCredentials' => 1,
    },
    "jsConfig and chunkSize when forceChunkSize(1)";


ok $flowjs->jsConfigStr, "js str config";

done_testing;
