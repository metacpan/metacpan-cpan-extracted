use strict;
use warnings;
use utf8;
use Test::More;
use Distribution::Metadata::Factory;

subtest not_found => sub {
    my $f = Distribution::Metadata::Factory->new;
    my $info1 = $f->create_from_module("HogeHogeFooBar");
    isa_ok $info1, "Distribution::Metadata";
    is $info1->packlist, undef;

    my $f2 = Distribution::Metadata::Factory->new(inc => []);
    my $info2 = $f2->create_from_module("FindBin");
    is $info2->packlist, undef;
};

subtest core_module => sub {
    my $f = Distribution::Metadata::Factory->new;
    my $info = $f->create_from_module("FindBin");
    is $info->main_module, "perl";
    is $info->main_module_version, $^V;
    is $info->main_module_file, $^X;
    is ref($info->files), "ARRAY";
    is $info->meta_directory, undef;
    is $info->mymeta_json, undef;
    is $info->install_json, undef;
    is $info->mymeta_json_hash, undef;
    is $info->install_json_hash, undef;
    is $info->distvname, do { my $v = $^V; $v =~ s/^v//; "perl-$v" };
    is $info->name, "perl";
    is $info->version, $^V;

    my ($pm_file) = grep /FindBin\.pm$/, @{ $info->files };
    my $new_info = $f->create_from_file($pm_file);
    is $new_info->packlist, $info->packlist;
    is_deeply $new_info->files, $info->files;
};


done_testing;
