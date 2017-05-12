use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::DZil;
use Path::Tiny;

# we chdir before attempting to load the module, so we need to load it now or
# our relative path in @INC will be for naught.
use Dist::Zilla::Role::File::ChangeNotification;

{
    package Dist::Zilla::Plugin::MyPlugin;
    use Moose;
    use Module::Runtime 'use_module';
    with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::FileMunger';
    has source_file => (
        is => 'ro', isa => 'Str',
        required => 1,
    );
    sub gather_files
    {
        my $self = shift;

        require Dist::Zilla::File::InMemory;
        my $file = Dist::Zilla::File::InMemory->new(
            name => $self->source_file,
            content => 'this data should never change!',
        );
        # we add the file first because older Dist::Zilla manipulates the file
        # object using the MOP in a way that will not work if there has been a role
        # applied to the object's class
        $self->add_file($file);
        use_module('Dist::Zilla::Role::File::ChangeNotification')->meta->apply($file);
        $file->watch_file;
    }

    sub munge_files
    {
        my $self = shift;

        my ($file) = grep { $_->name eq $self->source_file } @{$self->zilla->files};

        # try to alter the content after it is being watched
        $file->content($file->content . ' ... but I will try to change it anyway');
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MyPlugin => { source_file => 'immutable.dat' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr{content of immutable\.dat has changed!},
    'detected attempt to change file after signature was created from it',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
