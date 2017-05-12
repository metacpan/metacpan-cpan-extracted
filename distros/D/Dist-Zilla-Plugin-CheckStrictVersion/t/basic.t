use strict;
use warnings;
use Test::More 0.96;
use utf8;

use Test::DZil;
use Test::Fatal;
use Version::Next qw/next_version/;

sub _new_tzil {
    my ( $version, @plugins ) = @_;
    return Builder->from_config(
        { dist_root => 'corpus/DZT' },
        {
            add_files => {
                'source/dist.ini' =>
                  simple_ini( { version => $version }, qw(GatherDir FakeRelease), @plugins ),
            },
        },
    );
}

my @lax_versions = qw(
  1.23_4
  v1.23
  v1.2.3_4
  1.2.3
);

for my $lax (@lax_versions) {
    subtest "lax $lax" => sub {
        my $tzil = _new_tzil( $lax, qw/CheckStrictVersion/ );

        $tzil->build;
        pass("dzil build");

        like(
            exception { $tzil->release },
            qr/\Q$lax\E fails version::is_strict/,
            "caught error on lax version"
        );

        ok( !grep( {/fake release happen/i} @{ $tzil->log_messages } ), "release stopped", );

    };
}

subtest "decimal only" => sub {
    my $ver = "v1.2.3";
    my $tzil = _new_tzil( $ver, [ CheckStrictVersion => { decimal_only => 1 } ] );

    $tzil->build;
    pass("dzil build");

    like(
        exception { $tzil->release },
        qr/\Q$ver\E is not a decimal/,
        "caught error on tuple version"
    );

    ok( !grep( {/fake release happen/i} @{ $tzil->log_messages } ), "release stopped", );

};

subtest "tuple only" => sub {
    my $ver = "1.23";
    my $tzil = _new_tzil( $ver, [ CheckStrictVersion => { tuple_only => 1 } ] );

    $tzil->build;
    pass("dzil build");

    like(
        exception { $tzil->release },
        qr/\Q$ver\E is not a tuple/,
        "caught error on decimal version"
    );

    ok( !grep( {/fake release happen/i} @{ $tzil->log_messages } ), "release stopped", );

};

done_testing;
