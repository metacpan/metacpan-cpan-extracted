use strict;
use warnings;
use utf8;
use Test::More;
use Distribution::Metadata;
use File::Temp 'tempdir';
use Config;
use File::Find 'find';
use File::Basename 'basename';
use File::pushd 'tempd';
use File::Spec;
sub cpanm { !system "cpanm", "-nq", "--reinstall", @_ or die "cpanm fail"; }

subtest basic => sub {
    my $tempdir = tempdir CLEANUP => 1;
    cpanm "-l$tempdir/local", 'TOKUHIROM/Test-TCP-2.07.tar.gz';
    my $info1 = Distribution::Metadata->new_from_module(
        "Test::TCP",
        inc => ["$tempdir/local/lib/perl5"],
    );
    my $info2 = Distribution::Metadata->new_from_module(
        "Net::EmptyPort",
        inc => ["$tempdir/local/lib/perl5"],
    );

    for my $method (qw(packlist meta_directory install_json mymeta_json
        main_module main_module_version)) {
        ok $info1->$method, "$method ok";
        is $info1->$method, $info2->$method;
    }
    for my $method (qw(install_json_hash mymeta_json_hash files)) {
        ok $info1->$method;
        is_deeply $info1->$method, $info2->$method;
    }

    is $info1->name, "Test-TCP";
    is $info1->version, "2.07";
    is $info1->distvname, "Test-TCP-2.07";
    is $info1->pathname, 'T/TO/TOKUHIROM/Test-TCP-2.07.tar.gz';
    is $info1->author, 'TOKUHIROM';
};

subtest prefer => sub {
    my $tempdir = tempdir CLEANUP => 1;
    cpanm "-l$tempdir/local2.07", 'TOKUHIROM/Test-TCP-2.07.tar.gz';
    cpanm "-l$tempdir/local2.06", 'TOKUHIROM/Test-TCP-2.06.tar.gz';
    my $info = Distribution::Metadata->new_from_module(
        "Test::TCP",
        inc => [
            "$tempdir/local2.06/lib/perl5",
            "$tempdir/local2.07/lib/perl5",
        ],
    );
    like $info->$_, qr/2\.06/ for qw(install_json mymeta_json meta_directory);
    is $info->install_json_hash->{version}, '2.06';
};

subtest abs_path => sub {
    my $tempdir = tempd;
    cpanm "-llocal", 'TOKUHIROM/Test-TCP-2.07.tar.gz';
    my $info = Distribution::Metadata->new_from_module(
        "Test::TCP",
        inc => [
            "local/lib/perl5",
        ],
    );

    for my $method (qw(packlist mymeta_json install_json)) {
        my $is_abs = File::Spec->file_name_is_absolute($info->$method);
        ok $is_abs;
    }
};

subtest archlib => sub {
    my $tempdir = tempdir CLEANUP => 1;
    cpanm "-l$tempdir/local", 'MLEHMANN/common-sense-3.74.tar.gz';
    my $info1 = Distribution::Metadata->new_from_module(
        "common::sense",
        inc => ["$tempdir/local/lib/perl5"],
        fill_archlib => 0,
    );
    is $info1->packlist, undef;

    my $info2 = Distribution::Metadata->new_from_module(
        "common::sense",
        inc => ["$tempdir/local/lib/perl5"],
    );
    is $info2->packlist, undef;

    my $info3 = Distribution::Metadata->new_from_module(
        "common::sense",
        inc => ["$tempdir/local/lib/perl5"],
        fill_archlib => 1,
    );
    ok $info3->packlist;
    ok $info3->meta_directory;

    my $info4 = Distribution::Metadata->new_from_module(
        "common::sense",
        inc => ["$tempdir/local/lib/perl5/$Config{archname}"],
        fill_archlib => 0,
    );
    ok $info3->packlist;
    ok $info3->meta_directory;
};

done_testing;
