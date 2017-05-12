use strict;
use Test::More 'no_plan';

use FormValidator::Simple::ProfileManager::YAML;
use Data::Dumper;

my @Test = (
    ['group1'],
    ['group2', 'subgroup1' ],
    ['group2', 'subgroup2' ],
    ['group2.subgroup1' ],
    ['group2.subgroup2' ],
);

my $manager = FormValidator::Simple::ProfileManager::YAML->new('t/test.yml');

for (@Test) {
    my @group = @$_;
    my $manager1 = $manager->extract(@group);
    is( ref $manager1, 'FormValidator::Simple::ProfileManager::YAML');

#    warn Dumper($manager1);
    is_deeply( $manager1->get_profile, $manager->get_profile(@group) );
}

my $manager2 = FormValidator::Simple::ProfileManager::YAML->new('t/test.yml');

my $manager3 = $manager2->extract('not','exist','group');
is ($manager3, undef);
