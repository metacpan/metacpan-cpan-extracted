# check core module: taghandler::plugin

use strict;
use warnings;

use Test::More tests => 6;

#=== Dependencies
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
my $root = "${cwd}t/data/TagHandler/Plugin/";

use Konstrukt::TagHandler;
use Konstrukt::Parser::Node;
$Konstrukt::Handler->{filename} = "test";

#use fake Konstrukt::Plugin::test_dummy
unshift @INC, "${root}lib";

#TagHandler
use Konstrukt::TagHandler::Plugin;

#dummy tag
my $tag = Konstrukt::Parser::Node->new({ type => "tag", handler_type => "plugin", tag => { type => "test_dummy" } });

is($Konstrukt::TagHandler::Plugin->init(), 1, "init");
is(ref($Konstrukt::TagHandler::Plugin->load_plugin("test_dummy")), "Konstrukt::Plugin::test_dummy", "plugin: test_dummy");
my $plugin = $Konstrukt::TagHandler::Plugin->load_plugin("test_dummy");
is($plugin->prepare(), undef, "prepare");
is(${$plugin->execute()}, "executed", "execute");
is($plugin->prepare_again(), 23, "prepare_again");
is($plugin->execute_again(), 42, "execute_again");

my $result;
#$result = $Konstrukt::TagHandler::Plugin->prepare($tag_node);
#$result = $Konstrukt::TagHandler::Plugin->execute($tag_node);

exit;
