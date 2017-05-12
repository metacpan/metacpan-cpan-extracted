# check core module: cache

#TODO: more comprehensive tests of add_condition_date

use strict;
use warnings;

use Test::More tests => 24;

#=== Dependencies
use Konstrukt::Settings;
$Konstrukt::Settings->default("cache/dir", '/t/data/Cache/cache');
$Konstrukt::Handler->{filename} = "test";
use Konstrukt::Debug;
$Konstrukt::Debug->init();

#=== Current working directory
use Cwd;
use Konstrukt::File;
$Konstrukt::File->set_root(getcwd());

#Cache
use Konstrukt::Cache;
is($Konstrukt::Cache->init(), 1, "init");

#filename - must be the absolute path!
my $filename = "/t/data/Cache/testfile";
my $abs_filename = $Konstrukt::File->absolute_path($filename);
my $content;

#create input files during test, as we will modify them later.
#on some platforms we won't have write access to files that have been copied from the source archive
$Konstrukt::File->create_dirs($Konstrukt::File->extract_path($abs_filename));
$Konstrukt::File->write($filename, "testdata");
$Konstrukt::File->write("${filename}2", "foobar");

#write_cache, get_cache, delete_cache
$content = $Konstrukt::File->read_and_track($filename); #read
$Konstrukt::File->pop(); #we're done with this file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "write_cache");
is($Konstrukt::Cache->get_cache($abs_filename)->{content}, "testdata", "get_cache");
$Konstrukt::File->pop(); #done
is($Konstrukt::Cache->delete_cache($abs_filename), 1, "delete_cache");
is($Konstrukt::Cache->get_cache($abs_filename), undef, "delete_cache");

#add_condition_date
#init and start
$Konstrukt::Cache->init();
$content = $Konstrukt::File->read_and_track($filename); #read
#add condition
is($Konstrukt::Cache->add_condition_date("+2s"), 1, "add_condition_date");
$Konstrukt::File->pop(); #we're done with this (cached) file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "add_condition_date: write");
#test (in)validation
is($Konstrukt::Cache->get_cache($abs_filename)->{content}, "testdata", "add_condition_date: read valid");
$Konstrukt::File->pop(); #we're done with this file now
sleep 3;
is($Konstrukt::Cache->get_cache($abs_filename), undef, "add_condition_date: read invalid");
#no pop() as get_cache should "fail"

#add_condition_file - self modification
$Konstrukt::Cache->init();
$content = $Konstrukt::File->read_and_track($filename); #read
$Konstrukt::File->pop(); #we're done with this file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "add_condition_file: self modification - write");
is($Konstrukt::Cache->get_cache($abs_filename)->{content}, "testdata", "add_condition_file: self modification - read valid");
$Konstrukt::File->pop(); #we're done with this (cached) file now
$Konstrukt::File->write($filename, "testdata"); #modify
is($Konstrukt::Cache->get_cache($abs_filename), undef, "add_condition_file: self modification - read invalid");
#no pop() as get_cache should "fail"

#add_condition_file - modification of another file
$Konstrukt::Cache->init();
$content = $Konstrukt::File->read_and_track($filename); #read
$Konstrukt::File->read_and_track("${filename}2"); #read another file
$Konstrukt::File->pop(); #we're done with both files
$Konstrukt::File->pop();
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "add_condition_file: other modification - write");
is($Konstrukt::Cache->get_cache($abs_filename)->{content}, "testdata", "add_condition_file: other modification - read valid");
$Konstrukt::File->pop(); #we're done with this (cached) file now
$Konstrukt::File->write("${filename}2", "foobar"); #modify
is($Konstrukt::Cache->get_cache($abs_filename), undef, "add_condition_file: other modification - read invalid");
#no pop() as get_cache should "fail"

#add_condition_perl - valid condition
$Konstrukt::Cache->init();
$content = $Konstrukt::File->read_and_track($filename); #read
is($Konstrukt::Cache->add_condition_perl("return 1"), 1, "add_condition_perl: valid - add condition");
$Konstrukt::File->pop(); #we're done with this file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "add_condition_perl: valid - write");
is($Konstrukt::Cache->get_cache($abs_filename)->{content}, "testdata", "add_condition_file: valid - read");
$Konstrukt::File->pop(); #we're done with this (cached) file now

#add_condition_perl - invalid condition
$Konstrukt::Cache->init();
$content = $Konstrukt::File->read_and_track($filename); #read
is($Konstrukt::Cache->add_condition_perl("return undef"), 1, "add_condition_perl: invalid - add condition");
$Konstrukt::File->pop(); #we're done with this file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), 1, "add_condition_perl: invalid - write");
is($Konstrukt::Cache->get_cache($abs_filename), undef, "add_condition_file: invalid - read");
#no pop() as get_cache should "fail"

#prevent_caching
$Konstrukt::Cache->init();
$Konstrukt::Cache->delete_cache($abs_filename);
$content = $Konstrukt::File->read_and_track($filename); #read
is($Konstrukt::Cache->prevent_caching($abs_filename, 0), 1, "prevent_caching");
$Konstrukt::File->pop(); #we're done with this file now
is($Konstrukt::Cache->write_cache($abs_filename, { content => "testdata" }), undef, "prevent_caching - write");
is($Konstrukt::Cache->get_cache($abs_filename), undef, "prevent_caching - get");
#no pop() as get_cache should "fail"

#TODO: test add_condition_sql and add_condition_sql_advanced (both to be implemented)
