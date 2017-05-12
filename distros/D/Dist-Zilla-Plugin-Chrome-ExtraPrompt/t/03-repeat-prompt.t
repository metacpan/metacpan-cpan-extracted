use strict;
use warnings;

use Test::More;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::DZil;
use Path::Tiny;

use lib 't/lib';

# most of this file is copied from t/01-basic.t

{
    require Dist::Zilla::Chrome::Test;
    my $meta = Moose::Util::find_meta('Dist::Zilla::Chrome::Test');
    $meta->make_mutable;
    $meta->add_around_method_modifier(
        prompt_yn => sub {
            sleep 1;    # allow time for the file to be written
            # avoid calling real prompt
        },
    );
}

my $tempdir = Path::Tiny->tempdir(CLEANUP => 1);
my $promptfile = $tempdir->child('gotprompt');

my $config_ini = <<'CONFIG';
[Chrome::ExtraPrompt]
command = "%s" -MPath::Tiny -e"path(q[%s])->spew(@ARGV)"
repeat_prompt = 1
CONFIG

$tempdir->child('config.ini')->spew(sprintf($config_ini, $^X, $promptfile));

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
    { dist_root => 't/does_not_exist' },
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
$tzil->build;

SKIP: {
    ok(-e $promptfile, 'we got prompted')
        or skip 'no file was created to test', 1;

    is(
        $promptfile->slurp,
        'hello, are you there?',
        'prompt string was correctly sent to the command, as a single argument',
    );
}

diag 'got log messages: ', explain $tzil->log_messages
    if not Test::Builder->new->is_passing;

done_testing;
