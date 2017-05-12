use strict;
use Test::More 'no_plan';

use FormValidator::Simple::ProfileManager::YAML;
use Data::Dumper;

my @Test = (
    ['test', [['NOT_BLANK']], 'group2', 'subgroup2' ],
    ['test', [['EMAIL']], 'group2', 'subgroup2' ],
    ['test', [['NOT_BLANK']], 'group2.subgroup2' ],
    ['test', [['EMAIL']], 'group2.subgroup2' ],
);

my $manager = FormValidator::Simple::ProfileManager::YAML->new('t/test.yml');

for (@Test) {
    my ($keys, $constraints, @group) = @$_;

    $manager->add_profile($keys, $constraints, @group);

    my $profile = $manager->get_profile(@group);

    my $key = $manager->_get_key($keys);

    my ($constraints_added);
    for ( my $i=0; $i<@$profile; $i+=2) {
        my $cur_key = $manager->_get_key($profile->[$i]);
        if ( $key eq $cur_key) {
            $constraints_added = $profile->[$i+1];
            last;
        }
    }
    is_deeply($constraints, $constraints_added);

}



