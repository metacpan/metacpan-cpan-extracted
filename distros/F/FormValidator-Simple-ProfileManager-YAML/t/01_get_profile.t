use strict;
use Test::More 'no_plan';

use FormValidator::Simple::ProfileManager::YAML;
use Data::Dumper;

my @Test = (
    [['group1'], 'name'],
    [['group2', 'subgroup1' ], 'userid'],
    [['group2', 'subgroup2' ], 'tel'],
    [['group2.subgroup1'], 'userid'],
    [['group2.subgroup2'], 'tel'],
);

my $manager = FormValidator::Simple::ProfileManager::YAML->new('t/test.yml');

for (@Test) {
    my ($groups, $array_first) = @$_;
    my $profile = $manager->get_profile(@$groups);
#    warn Dumper($profile);
    ok $profile;
    is (ref $profile, 'ARRAY');
    is ($profile->[0], $array_first);
}

