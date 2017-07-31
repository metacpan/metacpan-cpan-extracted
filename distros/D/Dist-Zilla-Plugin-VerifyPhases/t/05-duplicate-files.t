use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;
use Term::ANSIColor 2.01 'colorstrip';

{
    package Dist::Zilla::Plugin::Naughty;
    use Moose;
    with
        'Dist::Zilla::Role::FileGatherer',
        'Dist::Zilla::Role::FilePruner';
    use Dist::Zilla::File::InMemory;
    use List::Util 'first';

    sub gather_files
    {
        my $self = shift;

        $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'file_0',
            content => 'first file',
        ));
        $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'file_0',
            content => 'second file',
        ));
    }

    sub prune_files
    {
        my $self = shift;
        $self->zilla->prune_file(first { $_->content eq 'second file' } @{ $self->zilla->files } );
    }
}

{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ Naughty => ],
                    [ VerifyPhases => ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    $tzil->build;

    is(
        scalar(
            grep { ! /^\[VerifyPhases\] ---- this is the last .* plugin ----$/ }
            grep { /\[VerifyPhases\]/ }
            map { colorstrip($_) } @{ $tzil->log_messages }
        ),
        0,
        'no warnings were logged - the duplicate file was removed before the end of the build',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
