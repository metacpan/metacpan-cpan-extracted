# check core module: Debug

use strict;
use warnings;

use Test::More tests => 3;

#=== Dependencies
use Konstrukt::Settings;
use Konstrukt::Cache;
$Konstrukt::Handler->{filename} = "test";

#=== Current working directory
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
use Konstrukt::File;
$Konstrukt::File->set_root($cwd);

#Debug
use Konstrukt::Debug;
is($Konstrukt::Debug->init(), 1, "init");
$Konstrukt::Settings->set('debug/warn_error_messages', 0);

#create long messages
$Konstrukt::Settings->set('debug/short_messages', 0);
$Konstrukt::Debug->debug_message("foo debug");
$Konstrukt::Debug->error_message("bar error");

#create short messages
$Konstrukt::Settings->set('debug/short_messages', 1);
$Konstrukt::Debug->debug_message("foo short debug");
$Konstrukt::Debug->error_message("bar short error");

ok(
(
#unix
$Konstrukt::Debug->format_debug_messages() eq
<<EOT
Debug messages:
main->(unknown): foo debug (Requested file: test - Package: main - Sub/Method: (unknown) - Source file: t/002_core_003_debug.t @ line 27)
main->(unknown): foo short debug
EOT

or

#windows
$Konstrukt::Debug->format_debug_messages() eq
<<EOT
Debug messages:
main->(unknown): foo debug (Requested file: test - Package: main - Sub/Method: (unknown) - Source file: t\\002_core_003_debug.t @ line 27)
main->(unknown): foo short debug
EOT
)
, "debug_messages");

ok(
(
#unix
$Konstrukt::Debug->format_error_messages() eq
<<EOT
Errors/Warnings:
main->(unknown): bar error (Requested file: test - Package: main - Sub/Method: (unknown) - Source file: t/002_core_003_debug.t @ line 28)
main->(unknown): bar short error
EOT

or

#windows
$Konstrukt::Debug->format_error_messages() eq
<<EOT
Errors/Warnings:
main->(unknown): bar error (Requested file: test - Package: main - Sub/Method: (unknown) - Source file: t\\002_core_003_debug.t @ line 28)
main->(unknown): bar short error
EOT
)
, "error_messages");
