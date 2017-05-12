use strict;
use warnings;
use utf8;
use File::Temp 'tempdir';
use HTTP::Tiny::Bandwidth;
use Plack::App::File;
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
    my $app = builder {
        enable 'ConditionalGET';
        Plack::App::File->new(root => $tempdir)->to_app;
    };
    Plack::Loader->load('Standalone', port => $port)->run($app);
    exit;
});

my $url = "http://localhost:" . $server->port . "/file";
my $http = HTTP::Tiny::Bandwidth->new;

subtest get => sub {
    my $res;
    my $bps = 32 * (1024**2);
    my $elapsed = elapsed {
        $res = $http->get($url, { download_limit_bps => $bps });
    };

    ok $res->{success};
    is $res->{status}, 200;
    is $res->{headers}{'content-length'}, 25 * (1024**2);
    is length($res->{content}), 25 * (1024**2);

    my $actual_bps = 8 * 25 * (1024**2) / $elapsed;
    note sprintf "-> elapsed: %.2fsec, actual_bps: %.1fMbps, expect_bps: %.1fMbps",
        $elapsed, $actual_bps / (1024**2), $bps / (1024**2);
    ok abs( $actual_bps - $bps ) < 4 * (1024**2);
};

subtest mirror => sub {
    my $res;
    my $mirror_file = "$tempdir/mirror_file";
    my $bps = 32 * (1024**2);
    my $elapsed = elapsed {
        $res = $http->mirror($url, $mirror_file, {
            download_limit_bps => $bps,
        });
    };

    ok $res->{success};
    is $res->{status}, 200;
    is $res->{headers}{'content-length'}, 25 * (1024**2);
    ok -f $mirror_file;
    is -s $mirror_file, 25 * (1024**2);
    my $mtime = (stat $mirror_file)[9];

    my $actual_bps = 8 * 25 * (1024**2) / $elapsed;
    note sprintf "-> elapsed: %.2fsec, actual_bps: %.1fMbps, expect_bps: %.1fMbps",
        $elapsed, $actual_bps / (1024**2), $bps / (1024**2);
    ok abs( $actual_bps - $bps ) < 4 * (1024**2);

    sleep 2;
    $res = $http->mirror($url, $mirror_file, { download_limit_bps => $bps });
    ok $res->{success};
    is $res->{status}, 304;
    is( (stat $mirror_file)[9] , $mtime );
};

done_testing;
