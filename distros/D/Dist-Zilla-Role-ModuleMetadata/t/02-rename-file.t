use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Deep;
use Test::Fatal;
use Path::Tiny;

# the cache should be invalidated when the file moves,
# since the filename is stored in the MMD object.

{
    package FileAdder;
    use Moose;
    with 'Dist::Zilla::Role::FileGatherer';
    use Dist::Zilla::File::InMemory;

    sub gather_files {
        my $self = shift;
        $self->add_file(
            Dist::Zilla::File::InMemory->new(
                name => 'Foo.pm',
                content => "package Foo;\nour \$VERSION = '0.001';\n1\n",
            ),
        );
    }
}

{
    package FileMover;
    use Moose;
    with 'Dist::Zilla::Role::FileGatherer',
        'Dist::Zilla::Role::ModuleMetadata';
    use Scalar::Util 'refaddr';

    sub gather_files {
        my $self = shift;

        my ($file) = grep { $_->name eq 'Foo.pm' } @{ $self->zilla->files };

        my $mmd = $self->module_metadata_for_file($file);
        $self->log_debug([ 'got MMD object with refaddr 0x%x for %s', refaddr($mmd), $file->name ]);

        # move file from the root of the repository into lib/
        # this should invalidate the MMD cache
        $file->name('lib/Foo.pm');

        $mmd = $self->module_metadata_for_file($file);
        $self->log_debug([ 'got MMD object with refaddr 0x%x for %s', refaddr($mmd), $file->name ]);
    }
}


my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                '=FileAdder',
                '=FileMover',
            ),
        },
    },
);

$tzil->chrome->logger->set_debug(1);
is(
    exception { $tzil->build },
    undef,
    'build proceeds normally',
);

cmp_deeply(
    $tzil->log_messages,
    superbagof(
        '[=FileMover] parsing Foo.pm for Module::Metadata',
        '[=FileMover] parsing lib/Foo.pm for Module::Metadata',
    ),
    'when a module filename changes, the cache is invalidated',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
