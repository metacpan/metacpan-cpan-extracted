use strict;
use Test::More;
use Test::DZil;

unless (eval { require Dist::Zilla::Plugin::VersionFromModule; 1 }) {
    plan skip_all => "requires VersionFromModule";
}

sub test_build {
    my($path, $cb) = @_;

    my $ini = simple_ini('GatherDir', 'VersionFromModule', 'ReversionOnRelease', 'FakeRelease');
    $ini =~ s/version = (\S*)\n//;

    my $tzil = Builder->from_config(
        { dist_root => $path },
        { add_files => {
            'source/dist.ini' => $ini,
        } },
    );

    $tzil->release;

    my $content = $tzil->slurp_file("build/lib/DZT/Sample.pm");

    $cb->($content, $tzil->version);
};

test_build 't/dist_package/0.01', sub {
    my($content, $version) = @_;

    like $content, qr/package DZT::Sample 0.02 \{/;
    is $version, '0.02';
};

{
    local $ENV{V} = '0.10';
    test_build 't/dist_package/0.01', sub {
        my($content, $version) = @_;
        like $content, qr/package DZT::Sample 0.10 \{/;
        is $version, '0.10';
    };
}

test_build 't/dist_package/v1.0.0', sub {
    my($content, $version) = @_;

    like $content, qr/package DZT::Sample v1.0.1 \{/;
    is $version, 'v1.0.1';
};

test_build 't/dist_package/1.0019', sub {
    my($content, $version) = @_;

    like $content, qr/package DZT::Sample 1.0020 \{/;
    is $version, '1.0020';
};

{
    local $ENV{V} = 'v1.2.0';
    test_build 't/dist_package/v1.0.0', sub {
        my($content, $version) = @_;

        like $content, qr/package DZT::Sample v1.2.0 \{/;
        is $version, 'v1.2.0';
    };
}

done_testing;
