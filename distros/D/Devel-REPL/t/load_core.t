use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Module::Runtime 'use_module';
use Test::Fatal;

_use_ok('Devel::REPL');
_use_ok('Devel::REPL::Script');
_use_ok('Devel::REPL::Plugin::Colors');
_use_ok('Devel::REPL::Plugin::Commands');

SKIP: {
    eval 'use PPI; 1' or skip 'PPI not installed: skipping completion plugins', 6;

    _use_ok('Devel::REPL::Plugin::Completion');
    _use_ok('Devel::REPL::Plugin::CompletionDriver::Globals');
    _use_ok('Devel::REPL::Plugin::CompletionDriver::Methods');
    _use_ok('Devel::REPL::Plugin::CompletionDriver::Turtles');

    test_plugin('File::Next', 'CompletionDriver::INC');
    test_plugin('B::Keywords', 'CompletionDriver::Keywords');
    test_plugin('Lexical::Persistence', 'CompletionDriver::LexEnv');
};

test_plugin('Lexical::Persistence', 'LexEnv');

test_plugin('Data::Dumper::Concise', 'DDC');

test_plugin('Data::Dump::Streamer', 'DDS');

_use_ok('Devel::REPL::Plugin::DumpHistory');
_use_ok('Devel::REPL::Plugin::FancyPrompt');
_use_ok('Devel::REPL::Plugin::FindVariable');
_use_ok('Devel::REPL::Plugin::History');

test_plugin('Sys::SigAction', 'Interrupt');

# _use_ok('Devel::REPL::Plugin::Interrupt') unless $^O eq 'MSWin32';

test_plugin('PPI', 'MultiLine::PPI');

test_plugin('App::Nopaste', 'Nopaste');

_use_ok('Devel::REPL::Plugin::OutputCache');
_use_ok('Devel::REPL::Plugin::Packages');
_use_ok('Devel::REPL::Plugin::Peek');

test_plugin('PPI' ,'PPI');

_use_ok('Devel::REPL::Plugin::ReadLineHistory');

test_plugin('Module::Refresh', 'Refresh');

_use_ok('Devel::REPL::Plugin::ShowClass');
_use_ok('Devel::REPL::Plugin::Timing');
_use_ok('Devel::REPL::Plugin::Turtles');

sub _use_ok {
    my $module = shift;
    is(exception { use_module $module }, undef, $module . ' ok');
}

sub test_plugin
{
    my ($prereq, $plugin) = @_;

    SKIP: {
        eval "use $prereq; 1"
            or skip "$prereq not installed: skipping $plugin", 1;

        _use_ok("Devel::REPL::Plugin::$plugin");
    }
}

done_testing;
