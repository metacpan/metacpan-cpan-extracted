# check core module: taghandler

use strict;
use warnings;

use Test::More tests => 5;

#=== Dependencies
use Konstrukt::Settings;
$Konstrukt::Settings->set("debug/warn_error_messages", 0);
$Konstrukt::Settings->set("debug/short_messages", 1);
use Konstrukt::Debug;
$Konstrukt::Debug->init();
$Konstrukt::Handler->{filename} = "test";

#TagHandler
use Konstrukt::TagHandler;

my $taghandler_interface = Konstrukt::TagHandler->new();
is($taghandler_interface->init(), 1, "init");
is($taghandler_interface->prepare_again(), 0, "parse_again");
is_deeply($taghandler_interface->prepare(), [], "prepare");
is_deeply($taghandler_interface->execute(), [], "execute");
is($Konstrukt::Debug->format_error_messages(),
<<EOT
Errors/Warnings:
Konstrukt::TagHandler->prepare: Not overloaded!
Konstrukt::TagHandler->execute: Not overloaded!
EOT
, "error_messages");

exit;
