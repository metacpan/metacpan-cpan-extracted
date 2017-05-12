use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;
use Test::Deep;
use Test::DZil;
use Path::Tiny;

# we chdir before attempting to load the module, so we need to load it now or
# our relative path in @INC will be for naught.
use Dist::Zilla::Role::File::ChangeNotification;

{
    package Dist::Zilla::Plugin::MyPlugin;
    use Moose;
    use Module::Runtime 'use_module';
    use Moose::Util::TypeConstraints 'enum';
    with 'Dist::Zilla::Role::FileMunger';
    has source_file => (
        is => 'ro', isa => 'Str',
        required => 1,
    );
    has function => (
        is => 'ro', isa => enum([qw(uc lc)]),
        required => 1,
    );

    our @content;

    sub munge_files
    {
        my $self = shift;

        my ($file) = grep { $_->name eq $self->source_file } @{$self->zilla->files};

        # upper-case all the comments
        my $content = $file->content;
        $content =~ s/^# (.+)$/'# ' . uc($1)/me if $self->function eq 'uc';
        $content =~ s/^# (.+)$/'# ' . lc($1)/me if $self->function eq 'lc';
        $file->content($content);

        # lock the file so no one can alter it after we have touched it

        use_module('Dist::Zilla::Role::File::ChangeNotification')->meta->apply($file);
        my $plugin = $self;
        $file->on_changed(sub {
            my ($self, $new_content) = @_;
            push @content, $new_content;
            $plugin->log_fatal('someone tried to munge ' . $self->name
                .' after we read from it. You need to adjust the load order of your plugins.');
        });

        $file->watch_file;
    }
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ MyPlugin => uc => { function => 'uc', source_file => 'lib/Foo.pm' } ],
                [ MyPlugin => lc => { function => 'lc', source_file => 'lib/Foo.pm' } ],
            ),
            path(qw(source lib Foo.pm)) => <<CODE,
package Foo;
# hErE IS a coMMent!
1
CODE
        },
    },
);

$tzil->chrome->logger->set_debug(1);
like(
    exception { $tzil->build },
    qr{someone tried to munge lib/Foo.pm after we read from it. You need to adjust the load order of your plugins},
    'detected attempt to change file after signature was created from it',
);

# ATTENTION! I still haven't decided whether the $file->content at the time of
# the callback should be the old content or the new content . Most things won't
# care, but if you have a stake in this fight, please talk to me and it will
# be formalized!
my ($file) = grep { $_->name eq 'lib/Foo.pm' } @{$tzil->files};
is(
    $file->content,
    <<CODE,
package Foo;
# here is a comment!
1
CODE
    'content of file when the build aborts is <...>'
);

cmp_deeply(
    \@Dist::Zilla::Plugin::MyPlugin::content,
    [
        <<CODE,
package Foo;
# here is a comment!
1
CODE
    ],
    'callback is invoked with the correct arguments: the new content that cannot be set in the file',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
