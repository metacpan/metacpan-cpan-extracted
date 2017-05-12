use strict;
use warnings;
use utf8;
use File::Temp 'tempdir';
use HTTP::Tiny::Bandwidth;
use Plack::App::File;
use Plack::Request;
use Plack::Builder;
use Plack::Loader;
use Test::More;
use Test::TCP;
use xt::Util;

my $tempdir = tempdir CLEANUP => 1;
my $file = "$tempdir/file";
write_25MB_content $file;

my $server = Test::TCP->new(code => sub {
    my $port = shift;
    my $app = sub {
        my $req = Plack::Request->new($_[0]);
        my $upload_length = -s $req->body;
        open my $fh, "<", $file or die;
        [200, ['Content-Length' => (-s $fh), 'X-Upload-Length' => $upload_length], $fh];
    };
    Plack::Loader->load('Standalone', port => $port)->run($app);
    exit;
});

my $url = "http://localhost:" . $server->port . "/file";
my $http = HTTP::Tiny::Bandwidth->new;

subtest post => sub {
    my $res;
    my $bps = 32 * (1024**2);
    my $elapsed = elapsed {
        $res = $http->post($url, {
            content_file       => $file,
            upload_limit_bps   => $bps,
            download_limit_bps => $bps,
        });
    };

    ok $res->{success};
    is $res->{status}, 200;
    is $res->{headers}{'content-length'}, 25 * (1024**2);
    is length($res->{content}), 25 * (1024**2);

    my $actual_bps = 8 * (25*2) * (1024**2) / $elapsed;
    note sprintf "-> elapsed: %.2fsec, actual_bps: %.1fMbps, expect_bps: %.1fMbps",
        $elapsed, $actual_bps / (1024**2), $bps / (1024**2);
    ok abs( $actual_bps - $bps ) < 4 * (1024**2);
};

done_testing;
