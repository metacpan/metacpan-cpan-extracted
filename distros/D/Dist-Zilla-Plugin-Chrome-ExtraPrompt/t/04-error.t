use strict;
use warnings;

use Test::More 0.88;
use Test::Warnings 0.009 ':no_end_test', ':all';
use Test::DZil;
use Test::Fatal;
use Test::Deep;
use Path::Tiny;

use lib 't/lib';

{
    require Dist::Zilla::Chrome::Test;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_around_method_modifier(
        prompt_yn => sub {
            sleep 1;    # time for signal to reach us
            # avoid calling real prompt
        },
    );
}

my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
$tempdir->child('config.ini')->spew(qq{
[Chrome::ExtraPrompt]
command = "$^X" -e"warn qq{warning 1\\n}; warn qq{warning 2\\n}; exit 1"
});

# I need to make sure the chrome sent to the real zilla builder is the same
# chrome that was received from setup_global_config -- because the test
# builder actually unconditionally overwrites it with a ::Chrome::Test.

my $chrome = Dist::Zilla::Chrome::Test->new;

# stolen from Dist::Zilla::App

require Dist::Zilla::MVP::Assembler::GlobalConfig;
require Dist::Zilla::MVP::Section;
my $assembler = Dist::Zilla::MVP::Assembler::GlobalConfig->new({
    chrome => $chrome,
    stash_registry => {},
    section_class  => 'Dist::Zilla::MVP::Section',
});

require Dist::Zilla::MVP::Reader::Finder;
Dist::Zilla::MVP::Reader::Finder->new->read_config($tempdir->child('config'), { assembler => $assembler });

my $tzil = Builder->from_config(
    { dist_root => 'does-not-exist' },
    {
        add_files => {
            path(qw(source dist.ini)) => simple_ini(
                '=TestPrompter',    # will send a prompt during build
                'GatherDir',
            ),
            path(qw(source lib Foo.pm)) => "package Foo;\n1;\n",
        },
    },
);

# grab chrome object we saved from earlier, and assign it back again
$tzil->chrome($chrome);

$tzil->chrome->logger->set_debug(1);

my @warnings;
is(
    exception { @warnings = warnings { $tzil->build } },
    undef,
    'build succeeds even though the command fails',
);

cmp_deeply(
    \@warnings,
    [
        re(qr/^\Q[Chrome::ExtraPrompt] process exited with status 1\E$/),
        re(qr/^\Q[Chrome::ExtraPrompt] warning 1\E$/),
        re(qr/^\Q[Chrome::ExtraPrompt] warning 2\E$/),
    ],
    'warning is issued when the process did not exit successfully; stderr is also captured',
);

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

had_no_warnings if $ENV{AUTHOR_TESTING};
done_testing;
