use strict;
use Test::More;
use Test::DZil;

my $ini = simple_ini('GatherDir', 'NameFromDirectory');
$ini =~ s/name = \S*//;

{
    my $tzil = Builder->from_config(
        { dist_root => 't/dist' },
        { add_files => {
            'source/dist.ini' => $ini,
        } },
    );
    $tzil->build;

    is $tzil->name, 'source'; # Dist::Zilla::Tester hardcodes the dist directory name
}

done_testing;
