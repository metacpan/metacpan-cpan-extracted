#!/usr/bin/env perl

use strict;
use warnings;

use DBI;

use Tree::DAG_Node;
use Tree::DAG_Node::Persist;

# --------------------------

my($tree) = Tree::DAG_Node -> new;

$tree -> name('Menu');

my($backup) = Tree::DAG_Node -> new;
my($crypt)  = Tree::DAG_Node -> new;
my($module) = Tree::DAG_Node -> new;

$backup -> name('Backup');
$crypt -> name('Crypt');
$module -> name('Module');

$module -> attributes({url => '/Module'});
$tree -> add_daughters($backup, $crypt, $module);

my(@backup) =
(
 Tree::DAG_Node -> new, # Database.
 Tree::DAG_Node -> new, # Directory.
);

$backup[0] -> name('Database');
$backup[0] -> attributes({url => '/Database'});
$backup[1] -> name('Directory');
$backup[1] -> attributes({url => '/Directory'});

$backup -> add_daughters(@backup);

my(@crypt) =
(
 Tree::DAG_Node -> new, # Decrypt.
 Tree::DAG_Node -> new, # Encrypt.
);

$crypt[0] -> name('Decrypt');
$crypt[0] -> attributes({url => '/Decrypt'});
$crypt[1] -> name('Encrypt');
$crypt[1] -> attributes({url => '/Encrypt'});

$crypt  -> add_daughters(@crypt);

my(@module) =
(
 Tree::DAG_Node -> new, # Build.
 Tree::DAG_Node -> new, # Export db.
 Tree::DAG_Node -> new, # Git status (of all).
 Tree::DAG_Node -> new, # Install.
 Tree::DAG_Node -> new, # Tag.
 Tree::DAG_Node -> new, # Update version #.
);

$module[0] -> name('Build');
$module[0] -> attributes({url => '/Build'});
$module[1] -> name('Export db');
$module[1] -> attributes({url => '/ExportDB'});
$module[2] -> name('Git status');
$module[2] -> attributes({url => '/GitStatus'});
$module[3] -> name('Install');
$module[3] -> attributes({url => '/Install'});
$module[4] -> name('Tag');
$module[4] -> attributes({url => '/Tag'});
$module[5] -> name('Update version #');
$module[5] -> attributes({url => '/UpdateVersionNumber'});

$module -> add_daughters(@module);

my($dbh)    = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS});
my($driver) = Tree::DAG_Node::Persist -> new
(
 context    => 'HTML::YUI3::Menu',
 dbh        => $dbh,
 table_name => 'items',
);

$driver -> write($tree, ['url']);
