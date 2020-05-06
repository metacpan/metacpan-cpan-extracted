use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';
use File::pushd 'pushd';
use Dist::Zilla::App::Command::stale;

use lib 't/lib';
use NoNetworkHits;
use DiagFilehandles;

my @prompts;
{
    use Dist::Zilla::Chrome::Test;
    my $meta = find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_before_method_modifier(prompt_str => sub {
        my ($self, $prompt, $arg) = @_;
        push @prompts, $prompt;
    });
}

{
    package inc::Foo;
    use Moose;
    extends 'Dist::Zilla::Plugin::MakeMaker';
}

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => {
                        check_all_plugins => 1,
                        skip => [ qw(Dist::Zilla::Plugin::GatherDir Dist::Zilla::Plugin::FinderCode Dist::Zilla::Plugin::PromptIfStale) ],
                    } ],
                [ '=inc::Foo' ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
            path(qw(source inc Foo.pm)) => "package inc::Foo;\nuse Moose;\nextends 'Dist::Zilla::Plugin::MakeMaker';\n1",
        },
        # copy the module to the source directory, because that's where $tzil->build chdirs
        also_copy => { 't/corpus' => 'source/t/lib' },
    },
);

# find the library in the source dir, so that it is a directory beneath the current dir
unshift @INC, path($tzil->tempdir, qw(source t lib))->stringify;
{
    my $wd = pushd $tzil->root;
    my @stale = Dist::Zilla::App::Command::stale->stale_modules($tzil);
    cmp_deeply(\@stale, [ ], 'app finds no stale modules')
        or diag 'found stale modules: ', explain \@stale;
}

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
