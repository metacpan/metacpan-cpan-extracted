#!perl
use Test::Most;

use strict;
use warnings;

use autodie;
use Test::DZil;

use Dist::Zilla::Plugin::ReadmeAnyFromPod;

# Pull out types from the plugin to get default filenames

sub type_filename {
    return $Dist::Zilla::Plugin::ReadmeAnyFromPod::_types->{$_[0]}->{filename};
}

sub config_implicit {
    my ($type, $location) = map { lc } @_;
    return "InvalidReadmeType::$type" unless type_filename($type);
    return "InvalidReadmeLocation::$location" unless $location eq 'root' || $location eq 'build';
    my $tc_type = ucfirst $type;
    my $tc_loc = ucfirst $location;
    return [ 'ReadmeAnyFromPod', "Readme${tc_type}In${tc_loc}"];
}

my @possible_types = keys %$Dist::Zilla::Plugin::ReadmeAnyFromPod::_types;
my @possible_locations = qw(root build);

my $expected_number_of_tests = scalar(@possible_types) * scalar(@possible_locations) + 1;

my @config = ('GatherDir');
for my $type (@possible_types) {
    for my $loc (@possible_locations) {
        push @config, config_implicit($type, $loc);
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'corpus/dist/DZT' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(@config),
        },
    }
);

lives_ok { $tzil->build; } "Built dist successfully"
    or skip "Building dist failed", scalar(@possible_types) * scalar(@possible_locations);

my @expected_readme_files;
for my $type (@possible_types) {
    for my $loc (qw(source build)) {
        my $fname = "$loc/" . type_filename($type);
        my $content = $tzil->slurp_file($fname);
        like($content, qr/\S/, "Dist contains non-empty $type README in $loc");
    }
}

done_testing($expected_number_of_tests);
