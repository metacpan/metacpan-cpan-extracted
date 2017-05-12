# check core module: Settings

use strict;
use warnings;

use Test::More tests => 10;

#=== Dependencies
use Konstrukt::Settings;
use Konstrukt::Cache;

#=== Current working directory
use Cwd;
my $cwd = getcwd();
$cwd .= "/" unless substr($cwd, -1, 1) eq "/";
use Konstrukt::File;
$Konstrukt::File->set_root($cwd);

#=== Settings
use Konstrukt::Settings;
is($Konstrukt::Settings->load_settings("/t/data/Settings/test.settings"), 1, "load");
is($Konstrukt::Settings->get("cache/create"),           1,                       "get: number");
is($Konstrukt::Settings->get("cache/file_ext"),         ".cached",               "get: string");
is($Konstrukt::Settings->get("cache/use"),              1,                       "get: comment in string");
is($Konstrukt::Settings->get("sendmail/default_name"),  "streawkceurs homepage", "get: multiword string");
is($Konstrukt::Settings->get("sendmail/default_namee"), undef,                   "get: not defined");
is($Konstrukt::Settings->default("foo", "bar"), 1, "default");
is($Konstrukt::Settings->get("foo"), "bar", "get: default");
is($Konstrukt::Settings->set("foo", "baz"), 1, "set");
is($Konstrukt::Settings->get("foo"), "baz", "get: set");
