use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

# we chdir before attempting to load the module, so we need to load it now or
# our relative path in @INC will be for naught.
use Dist::Zilla::Role::File::ChangeNotification;

{
    package Dist::Zilla::Plugin::Appender;
    use Moose;
    use Module::Runtime 'use_module';
    with 'Dist::Zilla::Role::FileMunger';

    # appends an __END__ statement to all Foo files
    sub munge_files
    {
        my $self = shift;

        my ($file) = grep { $_->name =~ /Foo/ } @{$self->zilla->files};
        use_module('Dist::Zilla::Role::File::ChangeNotification')->meta->apply($file);

        $self->log('watching content of ' . $file->name);

        my $plugin = $self;
        $file->on_changed(sub {
            my $self = shift;
            $plugin->log('callback invoked for ' . $self->name);

            # ensure we do not loop forever
            return if $self->content =~ /__END__/;

            $plugin->log('updating content of ' . $self->name);
            $self->content( $file->content . "\n__END__\n" );
        });

        $file->watch_file;
    }
}

{
    package Dist::Zilla::Plugin::Setter;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';

    # sets the file content
    sub munge_files {
        my $self = shift;

        my ($file) = grep { $_->name =~ /Foo/ } @{$self->zilla->files};

        $self->log('munging content of ' . $file->name);
        $file->content( 'package Foo; 2;' );
    }
}

{
    package Dist::Zilla::Plugin::Resetter;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';

    # resets the file content to the original version
    sub munge_files {
        my $self = shift;

        my ($file) = grep { $_->name =~ /Foo/ } @{$self->zilla->files};

        $self->log('munging content of ' . $file->name);
        $file->content( 'package Foo; 1;' );
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ 'GatherDir' ],
                [ 'Appender' ],
                [ 'Setter' ],
                [ 'Resetter' ],
            ),
            path(qw(source lib Foo.pm)) => 'package Foo; 1;',
        },
    },
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

like(
    $tzil->slurp_file( 'build/lib/Foo.pm' ),
    qr'__END__',
    'MyPlugin1 has ensured that a footer is present in the finalized file',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
