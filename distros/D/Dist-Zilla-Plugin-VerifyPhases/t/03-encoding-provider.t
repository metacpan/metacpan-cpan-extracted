use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::DZil;
use Path::Tiny;

my @added_line;
{
    package Dist::Zilla::Plugin::Naughty;
    use Moose;
    with
        'Dist::Zilla::Role::FileGatherer',
        'Dist::Zilla::Role::FileMunger';
    use List::Util 'first';
    use Dist::Zilla::File::InMemory;

    sub gather_files
    {
        my $self = shift;
        push @added_line, __LINE__; $self->add_file( Dist::Zilla::File::InMemory->new(
            name => 'file_0',
            content => 'oh hai!',
        ));
    }
    sub munge_files
    {
        my $self = shift;

        # not okay to change encodings at munge time
        my $file0 = first { $_->name eq 'file_0' } @{$self->zilla->files};
        $file0->encoding('Latin1');
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
    like(
        exception { $tzil->build },
        qr/cannot change value of .*encoding/,
        'cannot set encoding attribute after EncodingProvider phase',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
