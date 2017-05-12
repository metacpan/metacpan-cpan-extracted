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

my @invocations;

{
    package Dist::Zilla::Plugin::FileCreator;
    use Moose;
    with 'Dist::Zilla::Role::FileGatherer', 'Dist::Zilla::Role::FileWatcher';

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

        $self->watch_file(
            $file,
            sub {
                my ($me, $my_file) = @_;
                push @invocations, { args => \@_, content => $my_file->content };
                ::note('file watcher invoked for: ' . $my_file->name);
            },
        );
    }
}

{
    package Dist::Zilla::Plugin::Graffiti;
    use Moose;
    with 'Dist::Zilla::Role::FileMunger';

    has suffix => ( is => 'ro', isa => 'Str' );

    sub munge_files
    {
        my $self = shift;
        my ($file) = grep { $_->name eq 'lib/Foo.pm' } @{$self->zilla->files};
        ::note('munging file: ' . $file->name);
        $file->content($file->content . '# Hello etheR WuZ HeRe: ' . $self->suffix . "\n");
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ FileCreator => ],
                [ Graffiti => 1 => { suffix => 'plugin 1' } ],
                [ Graffiti => 2 => { suffix => 'plugin 2' } ],
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

my ($file) = grep { $_->name eq 'lib/Foo.pm' } @{$tzil->files};
is(
    $file->content,
    <<CODE,
package Foo;
1;
# Hello etheR WuZ HeRe: plugin 1
# Hello etheR WuZ HeRe: plugin 2
CODE
    'file was munged by second plugin'
);

cmp_deeply(
    \@invocations,
     [
         {
             args => [
                $tzil->plugin_named('FileCreator'),
                all(
                    isa('Dist::Zilla::File::InMemory'),
                    methods(name => 'lib/Foo.pm'),
                ),
            ],
            content => <<CODE,
package Foo;
1;
# Hello etheR WuZ HeRe: plugin 1
CODE
        },
        {
            args => [
                $tzil->plugin_named('FileCreator'),
                all(
                    isa('Dist::Zilla::File::InMemory'),
                    methods(name => 'lib/Foo.pm'),
                ),
            ],
            content => <<CODE,
package Foo;
1;
# Hello etheR WuZ HeRe: plugin 1
# Hello etheR WuZ HeRe: plugin 2
CODE
        },
    ],
    'callback is invoked twice, each with the correct arguments',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
