use strict;
use warnings;

use Test::More;
use Test::Warnings;
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;
use Moose::Util 'find_meta';
use File::pushd 'pushd';
use Dist::Zilla::App::Command::stale;

BEGIN {
    # dzil changes directories..
    unshift @INC, path(qw(t lib))->absolute->stringify;
}
use EnsureStdinTty;

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

my $tzil = Builder->from_config(
    { dist_root => 't/does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                [ GatherDir => ],
                [ 'PromptIfStale' => { modules => [ 'Dist::Zilla::Plugin::PromptIfStale' ], phase => 'build' } ],
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

{
    my $wd = pushd $tzil->root;
    cmp_deeply(
        [ Dist::Zilla::App::Command::stale->stale_modules($tzil) ],
        [],
        'no stale modules found',
    );
    Dist::Zilla::Plugin::PromptIfStale::__clear_already_checked();
}

$tzil->chrome->logger->set_debug(1);

# if a response has not been configured for a particular prompt, we will die
is(
    exception { $tzil->build },
    undef,
    'build succeeded when checking for a module that is not stale',
);

is(scalar @prompts, 0, 'there were no prompts') or diag 'got: ', explain \@prompts;

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
