use strict;
use warnings;
use utf8;
use Test::More;
use Distribution::Metadata;

subtest not_found => sub {
    my $info1 = Distribution::Metadata->new_from_module("HogeHogeFooBar");
    isa_ok $info1, "Distribution::Metadata";
    is $info1->packlist, undef;

    my $info2 = Distribution::Metadata->new_from_module("FindBin", inc => []);
    is $info2->packlist, undef;
};

subtest core_module => sub {
    my $info = Distribution::Metadata->new_from_module("FindBin");
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
    my $new_info = Distribution::Metadata->new_from_file($pm_file);
    is $new_info->packlist, $info->packlist;
    is_deeply $new_info->files, $info->files;
};

done_testing;
