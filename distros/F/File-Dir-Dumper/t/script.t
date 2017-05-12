#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use POSIX qw(mktime strftime);
use File::Path;
use English;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "t", "lib");

use File::Find::Object::TreeCreate;
use File::Dir::Dumper::Stream::JSON::Reader;

{
    my $tree =
    {
        'name' => "traverse-1/",
        'subs' =>
        [
            {
                'name' => "a.doc",
                'contents' => "This file was spotted in the wild.",
            },
            {
                'name' => "b/",
            },
            {
                'name' => "foo/",
                'subs' =>
                [
                    {
                        'name' => "yet/",
                    },
                ],
            },
        ],
    };

    my $t = File::Find::Object::TreeCreate->new();
    $t->create_tree("./t/sample-data/", $tree);

    my $test_dir = "t/sample-data/traverse-1";
    my $out_file = File::Spec->catfile("t", "sample-data", "out.txt");

    my $ret =
    system(
        $^X,
        "-Mblib",
        "-e",
        <<'EOF',
use strict;
use warnings;
use File::Dir::Dumper::App;

my $app = File::Dir::Dumper::App->new({argv => \@ARGV});
exit($app->run());
EOF
        "--",
        "--output", $out_file,
        $t->get_path("$test_dir")
    );

    # TEST
    ok (!$ret, "system returned OK.");


    open my $from_out, "<", $out_file;

    my $reader = File::Dir::Dumper::Stream::JSON::Reader->new(
        {
            input => $from_out,
        }
    );

    my $token = $reader->fetch();

    # TEST
    is ($token->{'type'}, "header",
        "Token type is header - file was written OK."
    );

    # Cleanup.
    close($from_out);
    undef($reader);
    rmtree($t->get_path($test_dir));
    unlink($out_file);
}
