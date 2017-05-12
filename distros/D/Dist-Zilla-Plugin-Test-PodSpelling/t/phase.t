use strict;
use warnings;

use Test::More 0.88;
use Test::DZil;
use Test::Fatal;

{
    package Dist::Zilla::Plugin::CheckPhases;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';
    use Moose::Util 'find_meta';

    # runs before [Test::PodSpelling]'s munge_files
    sub munge_files
    {
        my $self = shift;
        my $distmeta_attr = find_meta($self->zilla)->find_attribute_by_name('distmeta');
        die 'distmeta has already been calculated before file munging phase!'
            if $distmeta_attr->has_value($self->zilla);
    }
}

my $tzil
    = Builder->from_config(
        {
            dist_root    => 'corpus/a',
        },
        {
            add_files => {
                'source/lib/Foo.pm' => "package Foo;\n1;\n",
                'source/dist.ini' => simple_ini(
                    [ GatherDir => ],
                    [ CheckPhases => ],
                    ['Test::PodSpelling']
                )
            }
        },
    );

is(
    exception { $tzil->build },
    undef,
    'no exceptions during dzil build',
);

done_testing;
