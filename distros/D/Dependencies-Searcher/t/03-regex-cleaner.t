use strict;
use warnings;
use Test::More 'no_plan';
use Dependencies::Searcher;
use Data::Printer;

my @modules_cases = (
    "use Data::Printer;",
    "use Module::CoreList 2.99;",
    "use Module::Version 'get_version';",
    "use Moose;",
    "use IPC::Cmd qw[can_run run];",
    "use Log::Minimal env_debug => 'LM_DEBUG';",
    "use File::Stamped;",
    "use IO::File;",
    "use File::HomeDir;",
    "use File::Spec::Functions qw(catdir catfile);",
    "use Version::Compare;",
    "use Data::Printer;",
    "use Module::CoreList qw();",
    "use Moose;",
    "use IPC::Cmd qw[can_run run];",
    "use IPC::Run;",
    "use Log::Minimal env_debug => 'LM_DEBUG';",
    "use File::Stamped;",
    "use File::HomeDir;",
    "use File::Spec::Functions qw(catdir catfile);",
    "use strict;",
    "use ExtUtils::MakeMaker;",
    "use Regexp::Common qw/ URI /;",
    "use Coro qw( async );",
);

my @special_cases = ();
my @imaginary_modules = ();
my @failing_stuff = (
    # Issue #53 https://git.framasoft.org/smonff/dependencies-searcher/issues/53
    "use IPC::Cmd qw(can_run run);",
    "use Number::Bytes::Human qw(format_bytes);",
);

my @dirty_modules = (@modules_cases, @failing_stuff);

my $searcher = Dependencies::Searcher->new();

for my $dirty_module (@dirty_modules) {
    like $dirty_module, qr/use \s /x, "Line should contain 'use '";
    like $dirty_module, qr/ ; /x, "Line should contain ;";
}

like $dirty_modules[22], qr/ \s qw \/ (\s*[A-Za-z]+(\s*[A-Za-z]*))* \s*\/ /x, "Line should contain a qw/ x /";
like $dirty_modules[23], qr/ \s qw \( (\s*[A-Za-z]+(\s*[A-Za-z]*))* \s*\) /x, "Line should contain a qw( x )";
like $dirty_modules[23], qr/ \s qw \( (\s*[A-Za-z]+(\s*[A-Za-z]*))* \s*\) /x, "Line should contain a qw( x )";

my @clean_modules = $searcher->clean_everything(@dirty_modules);

for my $module (@clean_modules) {
    unlike $module, qr/use \s /x, "Line should not contain any 'use '";
    unlike $module, qr/requires \s ' (.*?) '/x, "Line should not contain any 'require \'Mod::Name\''";
    unlike $module, qr/ ; /x, "Line should not contain any ;";
    unlike $module, qr/ \s qw \/ (\s*[A-Za-z]+(\s*[A-Za-z]*))* \s*\/ /x, "Line should not contain any qw/ x /";
    unlike $module, qr/ \s qw \( (\s*[A-Za-z]+(\s*[A-Za-z]*))* \s*\) /x, "Line should not contain any qw( x )";
    # Issue #53
    unlike $module, qr/ qw \( ([A-Za-z]+(_[A-Za-z]+)*(\s*[A-Za-z]*))* \) /xi, "Line should not contain any qw(x) nor qw(undescore_in_method_name)";
}

