use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZ1' },
    {
        add_files => {
            'source/dist.ini' => simple_ini(
                ('GatherDir', 'ConsistentVersionTest')
            ),
        },
    },
);
$tzil->build;

my $prereqs = $tzil->prereqs->as_string_hash;
ok exists $prereqs->{develop}->{requires}->{'Test::ConsistentVersion'},
    'Test::ConsistentVersion is a develop prereq',
    ;

done_testing;
