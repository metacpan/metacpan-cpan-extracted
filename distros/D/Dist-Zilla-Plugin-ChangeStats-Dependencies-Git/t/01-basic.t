use strict;
use warnings;
use Test::More;
use syntax 'qi';
use JSON::MaybeXS qw/encode_json/;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use Dist::Zilla::Plugin::ChangeStats::Dependencies::Git;

use Test::DZil;

$SIG{'__WARN__'} = sub {
    # Travis has an uninitialized warning in CPAN::Changes on 5.10
    if($] < 5.012000 && caller eq 'CPAN::Changes') {
        diag 'Caught warning: ' . shift;
    }
    else {
        warn shift;
    }
};

subtest first_release => sub {
    plan skip_all => 'Not ready';
    my $tzil = make_tzil({ auto_previous_tag => 1 });

    like $tzil->slurp_file('build/Changes'),
        qr{
            0\.0002
            \s+
            2[-\d\s:+]+    # date+time
            [\w/]+         # timezone
            [\n\r\s]*$     # empty
        }x, 'First release, no dependency changes';

};

subtest normal => sub {
    plan skip_all => 'Not ready';

    my $tzil = make_tzil({ auto_previous_tag => 1, group => 'Dependency Changes' }, qi{
        0.0001    Not Released
         - Not much of a change
    });

    like $tzil->slurp_file('build/Changes'), qr/\[Dependency Changes\]/, 'Group created';
    like $tzil->slurp_file('build/Changes'), qr/\(run req\) \+ Moosey/, 'New dependecy added';

    if($ENV{'AUTHOR_TESTING'}) {
        like $tzil->slurp_file('build/Changes'), qr/\(dev req\) ~ Test::More/, 'Dependecy version changed';
        like $tzil->slurp_file('build/Changes'), qr/\(dev req\) - Dist::Iller/, 'Dependecy removed';
    }
};

subtest existing_group => sub {
    plan skip_all => 'Not ready';
    # the ; is for indentation
    my $tzil = make_tzil({ auto_previous_tag => 1, group => 'Dependency Changes' }, qi{
        ;
         [Dependency Changes]
         - With a change

        0.0001    Not Released
         - Not much of a change
    });

    like $tzil->slurp_file('build/Changes'), qr/\[Dependency Changes\]/, 'Group created';
    #like $tzil->slurp_file('build/Changes'), qr/\(run req\) \+ Moosey/, 'New dependecy added';
    like $tzil->slurp_file('build/Changes'), qr/\[Dependency Changes\][\s\n\r]*- With a change/, 'Changes added to existing group';

    #if($ENV{'AUTHOR_TESTING'}) {
    #    like $tzil->slurp_file('build/Changes'), qr/\(dev req\) ~ Test::More/, 'Dependecy version changed';
    #    like $tzil->slurp_file('build/Changes'), qr/\(dev req\) - Dist::Iller/, 'Dependecy removed';
    #}
};

done_testing;

sub make_tzil {
    my $changestats_args = shift;
    my $changes = shift || '';

    my $ini = simple_ini(
        { version => '0.0002' },
        [ 'ChangeStats::Dependencies::Git', $changestats_args ],
        qw/
            GatherDir
            NextRelease
            FakeRelease
            Git::Tag
            Prereqs::FromCPANfile
        /,
    );

    my $changelog = qqi{
        Revision history for {{\$dist->name}}

        {{\$NEXT}}
        $changes
    };

    my $tzil = Builder->from_config(
        {   dist_root => '/t' },
        {
            add_files => {
                'source/dist.ini' => $ini,
                'source/Changes' => $changelog,
                'source/cpanfile' => cpanfile(),
            },
        },
    );
    $tzil->build;
    return $tzil;
}

sub cpanfile {
    return qi{
        configure_requires 'ExtUtils::MakeMaker' => '0';
        on develop => sub {
            requires 'Dist::Zilla::Plugin::BumpVersionAfterRelease::Transitional' => '0';
            requires 'Dist::Zilla::Plugin::CheckChangesHasContent' => '0';
            requires 'Dist::Zilla::Plugin::ExecDir' => '0';
            requires 'Dist::Zilla::Plugin::Git::Check' => '0';
            requires 'Dist::Zilla::Plugin::Git::Contributors' => '0';
            requires 'Dist::Zilla::Plugin::Git::GatherDir' => '0';
            requires 'Dist::Zilla::Plugin::Git::Push' => '0';
            requires 'Test::More' => '0.000001';
            requires 'Test::NoTabs' => '0';
            requires 'Test::Pod' => '1.40';
            requires 'Test::Warnings' => '0';
        };
        on runtime => sub {
            requires 'perl' => '5.010002';
            requires 'Moosey' => '2.1400';
        };
        on test => sub {
            recommends 'CPAN::Meta' => '2.120800';
            requires 'ExtUtils::MakeMaker' => '0';
            requires 'File::Spec' => '0';
            requires 'IO::Handle' => '0';
            requires 'IPC::Open3' => '0';
            requires 'Test::More' => '0.96';
        };
    }
}
