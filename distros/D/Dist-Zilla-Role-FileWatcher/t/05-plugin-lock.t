use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

# we chdir before attempting to load the file role, so we need to load it now or
# our relative path in @INC will be for naught.
use Dist::Zilla::Role::File::ChangeNotification;

{
    package Dist::Zilla::Plugin::FileCreator;
    use Moose;
    with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::FileWatcher';

    has message => ( is => 'ro', isa => 'Str' );

    sub gather_files
    {
        my $self = shift;
        require Dist::Zilla::File::InMemory;
        my $file = Dist::Zilla::File::InMemory->new(
            name => 'lib/Foo.pm',
            content => "package Foo;\n1;\n",
        );
        ::note('creating file: ' . $file->name);
        $self->add_file($file);

        $self->lock_file($file, $self->message);
    }
}

{
    package Dist::Zilla::Plugin::Graffiti;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';

    sub munge_files
    {
        my $self = shift;
        my ($file) = grep { $_->name eq 'lib/Foo.pm' } @{$self->zilla->files};
        ::note('munging file: ' . $file->name);
        $file->content($file->content . "# Hello etheR WuZ HeRe\n");
    }
}

foreach my $message ( undef, 'KEEP OUT!')
{
    my $tzil = Builder->from_config(
        { dist_root => 'does-not-exist' },
        {
            add_files => {
                path(qw(source dist.ini)) => simple_ini(
                    [ GatherDir => ],
                    [ FileCreator => ( $message ? { message => $message } : () ) ],
                    [ Graffiti => ],
                ),
            },
        },
    );

    $tzil->chrome->logger->set_debug(1);
    like(
        exception { $tzil->build },
        ( $message
            ? qr{KEEP OUT!}
            : qr{someone tried to munge lib/Foo.pm after we read from it. You need to adjust the load order of your plugins!} ),
        ( $message ? 'custom' : 'default' ) . ' message: detected attempt to change the file after it was locked',
    );

    diag 'got log messages: ', explain $tzil->log_messages
        if not Test::Builder->new->is_passing;
}

done_testing;
