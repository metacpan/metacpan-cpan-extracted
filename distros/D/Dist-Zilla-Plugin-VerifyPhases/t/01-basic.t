use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::DZil;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';
use Moose::Util 'find_meta';

my (@content_line, @filename_line);
{
    package Dist::Zilla::Plugin::Naughty;
    use Moose;
    with
        'Dist::Zilla::Role::NameProvider',
        'Dist::Zilla::Role::VersionProvider',
        'Dist::Zilla::Role::LicenseProvider',
        'Dist::Zilla::Role::FileGatherer',
        'Dist::Zilla::Role::FileMunger',
        'Dist::Zilla::Role::MetaProvider',
        'Dist::Zilla::Role::PrereqSource',
        'Dist::Zilla::Role::FileInjector';
    use Dist::Zilla::File::InMemory;
    use List::Util 'first';
    use Software::License::Artistic_2_0;
    use Moose::Util 'find_meta';

    sub provide_name { 'My-Sample-Dist' }
    sub provide_version { '999' }
    sub provide_license { Software::License::Artistic_2_0->new({ holder => 'me', year => 2014 }) }

    sub gather_files
    {
        my $self = shift;

        # add the main module
        $self->add_file(Dist::Zilla::File::InMemory->new({
            name => 'lib/Foo.pm',
            content => "package Foo;\n# ABSTRACT: Ether wuz here\n1;\n",
        }));

        # make these attributes fire
        my @stuff = map { $self->zilla->$_ }
            qw(name version abstract main_module license authors distmeta),
            find_meta($self->zilla)->find_attribute_by_name('release_status') ? 'release_status' : ();

        push @content_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'normal_file_0',
            content => 'oh hai!',
        ));
        push @content_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'normal_file_1',
            content => 'oh hai!',
        ));
        push @content_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'normal_file_2',
            content => 'oh hai!',
        ));
    }
    sub munge_files
    {
        my $self = shift;

        # okay to rename files at munge time
        my $file0 = first { $_->name eq 'normal_file_0' } @{$self->zilla->files};
        push @filename_line, __LINE__; $file0->name('normal_file_0_moved');

        # not okay to remove files at munge time
        $self->zilla->prune_file(first { $_->name eq 'normal_file_2' } @{$self->zilla->files});

        # not okay to add files at munge time
        push @content_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'rogue_file_3',
            content => 'naughty naughty!',
        ));

        # make this attribute fire
        my $prereqs = $self->zilla->prereqs;
    }
    sub metadata
    {
        my $self = shift;
        +{ prereqs => { runtime => { requires => { 'Improper::Prereq' => '0' } } } }
    }
    sub register_prereqs
    {
        my $self = shift;

        # not okay to remove files at prereq time
        $self->zilla->prune_file(first { $_->name eq 'normal_file_0_moved' } @{$self->zilla->files});

        # not okay to rename files at prereq time
        my $file1 = first { $_->name eq 'normal_file_1' } @{$self->zilla->files};
        push @filename_line, __LINE__; $file1->name('normal_file_1_moved');

        # not okay to add files at prereq time
        push @content_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'rogue_file_4',
            content => 'naughty naughty!',
        ));

        # not okay to alter non-prerequisite metadata at prereq time
        $self->zilla->distmeta->{x_ohhai} = 'I am a bad plugin!';
        #$self->zilla->distmeta->{dynamic_config} = 1;
    }
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                # no root section, because we want the attribute builders to
                # be called for every core attribute.
                path(qw(source dist.ini)) => dist_ini(
                    [ Naughty => ],
                    [ VerifyPhases => ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    my $verb = Dist::Zilla->VERSION < 5.023 ? 'set' : 'added';

    cmp_deeply(
        [ grep { /\[VerifyPhases\]/ } map { colorstrip($_) } @{ $tzil->log_messages } ],
        bag(
            (map { "[VerifyPhases] $_ has already been calculated by end of file gathering phase" }
                qw(name version abstract main_module license authors distmeta),
                find_meta($tzil)->find_attribute_by_name('release_status') ? 'release_status' : ()),
            "[VerifyPhases] file has been removed after file pruning phase: 'normal_file_0_moved' (content $verb by Naughty (Dist::Zilla::Plugin::Naughty line $content_line[0])" . (Dist::Zilla->VERSION < 5.023 ? '' : "; filename set by Naughty (Dist::Zilla::Plugin::Naughty line $filename_line[0])") . ")",
            "[VerifyPhases] file has been renamed after munging phase: 'normal_file_1_moved' (originally 'normal_file_1', content $verb by Naughty (Dist::Zilla::Plugin::Naughty line $content_line[1])" . (Dist::Zilla->VERSION < 5.023 ? '' : "; filename set by Naughty (Dist::Zilla::Plugin::Naughty line $filename_line[1])") . ")",
            "[VerifyPhases] file has been removed after file pruning phase: 'normal_file_2' (content $verb by Naughty (Dist::Zilla::Plugin::Naughty line $content_line[2]))",
            "[VerifyPhases] file has been added after file gathering phase: 'rogue_file_3' (content $verb by Naughty (Dist::Zilla::Plugin::Naughty line $content_line[3]))",
            "[VerifyPhases] file has been added after file gathering phase: 'rogue_file_4' (content $verb by Naughty (Dist::Zilla::Plugin::Naughty line $content_line[4]))",
            Dist::Zilla->VERSION >= 5.024 ? "[VerifyPhases] prereqs have already been read from after munging phase!" : (),
            re(qr/\[VerifyPhases\] prereqs have been improperly included with distribution metadata: \{
\[VerifyPhases\]\s+'runtime' => \{
\[VerifyPhases\]\s+'requires' => \{
\[VerifyPhases\]\s+'Improper::Prereq' => '0'
\[VerifyPhases\]\s+\}
\[VerifyPhases\]\s+\}
\[VerifyPhases\]\s+\}
/),
            re(qr/\[VerifyPhases\] distribution metadata has been altered after munging phase!.*Extra: \'x_ohhai\'/s),
        ),
        'warnings are logged about our naughty plugin',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
