use strict;
use warnings;

use IO::All;
use Kwiki::Test;
use Test::More tests => 6;

my $REGISTRY_FILE = 'registry.dd';
my $CONFIG_FILE = 'config.yaml';
my $CONFIG_DIR = 'config';
my $TEMPLATE_DIR = 'template';
my $CSS_DIR = 'css';
my $HOME_PAGE = 'database/HomePage';

my $kwiki = Kwiki::Test->new->init;

ok($kwiki->exists_as_file($REGISTRY_FILE), "$REGISTRY_FILE exists");
ok($kwiki->exists_as_file($CONFIG_FILE), "$CONFIG_FILE exists");
ok($kwiki->exists_as_dir($TEMPLATE_DIR), "$TEMPLATE_DIR exists");
ok($kwiki->exists_as_dir($CONFIG_DIR), "$CONFIG_DIR exists");
ok($kwiki->exists_as_dir($CSS_DIR), "$CSS_DIR exists");
ok($kwiki->exists_as_file($HOME_PAGE), "$HOME_PAGE exists");

$kwiki->cleanup;
