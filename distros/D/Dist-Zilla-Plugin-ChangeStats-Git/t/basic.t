use strict;
use warnings;

use Test::More;

plan skip_all => 'need to create sub-git repo for tests';

use Test::DZil;

subtest standard => sub {
    {
        my $tzil = make_tzil({ group => 'STATISTICS' });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \[\s*STATISTICS\s*\]\s*\n
                \s*-\s*code\schurn:\s+\d+\sfiles?\schanged,
                \s\d+\sinsertions?\(\+\),\s\d+\sdeletions?\(-\)
            /x,
            "with group";
    }
    {
        my $tzil = make_tzil({ text => '' });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \w\n                                                # \w for timezone
                \s*-\s*\d+\sfiles?\schanged,
                \s\d+\sinsertions?\(\+\),\s\d+\sdeletions?\(-\)
            /x,
            "without group, without leading text";
    }
};

subtest skip_file => sub {
    {
        my $tzil = make_tzil({ group => 'STATISTICS', skip_file => 'Changes' });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \[ \s* STATISTICS \s* \] \s* \n
                \s*-\s*code\schurn:\s+0\sfiles?\schanged,
                \s0\sinsertions?\(\+\),\s0\sdeletions?\(-\)
            /x,
            "using skip_file with hit";
    }
    {
        my $tzil = make_tzil({ group => 'STATISTICS', skip_file => ['non_existant.file', 'andanother.file'] });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \[ \s* STATISTICS \s* \] \s* \n
                \s*-\s*code\schurn:\s+\d+\sfiles?\schanged,
                \s\d+\sinsertions?\(\+\),\s\d+\sdeletions?\(-\)
            /x,
            "using skip_file without hit";
    }
};

subtest skip_match => sub {
    {
        my $tzil = make_tzil({ group => 'STATISTICS', skip_match => 'cha' });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \[ \s* STATISTICS \s* \] \s* \n
                \s*-\s*code\schurn:\s+0\sfiles?\schanged,
                \s0\sinsertions?\(\+\),\s0\sdeletions?\(-\)
            /x,
            "using skip_match with hit";
    }
    {
        my $tzil = make_tzil({ group => 'STATISTICS', skip_match => 'nohit' });

        like $tzil->slurp_file('build/Changes'),
            qr/
                \[ \s* STATISTICS \s* \] \s* \n
                \s*-\s*code\schurn:\s+\d+\sfiles?\schanged,
                \s\d+\sinsertions?\(\+\),\s\d+\sdeletions?\(-\)
            /x,
            "using skip_match without hit";
    }
};
done_testing;

sub make_tzil {
    my $ini = simple_ini(
        { },
        [ 'ChangeStats::Git', $_[0] ],
        qw/
            GatherDir
            NextRelease
            FakeRelease
        /
    );

    (my $changes = <<"        CHANGES") =~ s/^\s{8}//gm;
        {{\$NEXT}}

        CHANGES

    my $tzil = Builder->from_config(
        {   dist_root => '/t' },
        {
            add_files => {
                'source/dist.ini' => $ini,
                'source/Changes' => $changes,
            },
        },
    );
    $tzil->build;
    return $tzil;
}
