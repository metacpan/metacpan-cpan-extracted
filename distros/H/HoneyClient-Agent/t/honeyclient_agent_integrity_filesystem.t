#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
$| = 1;



# =begin testing
{
# Make sure Log::Log4perl loads
BEGIN { use_ok('Log::Log4perl', qw(:nowarn))
        or diag("Can't load Log::Log4perl package. Check to make sure the package library is correctly listed within the path.");

        # Suppress all logging messages, since we need clean output for unit testing.
        Log::Log4perl->init({
            "log4perl.rootLogger"                               => "DEBUG, Buffer",
            "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
            "log4perl.appender.Buffer.min_level"                => "fatal",
            "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
            "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
        });
}
require_ok('Log::Log4perl');
use Log::Log4perl qw(:easy);

# Make sure the module loads properly, with the exportable
# functions shared.
BEGIN { use_ok('HoneyClient::Util::Config', qw(getVar setVar))
        or diag("Can't load HoneyClient::Util::Config package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Util::Config');
can_ok('HoneyClient::Util::Config', 'getVar');
can_ok('HoneyClient::Util::Config', 'setVar');
use HoneyClient::Util::Config qw(getVar setVar);

# Suppress all logging messages, since we need clean output for unit testing.
Log::Log4perl->init({
    "log4perl.rootLogger"                               => "DEBUG, Buffer",
    "log4perl.appender.Buffer"                          => "Log::Log4perl::Appender::TestBuffer",
    "log4perl.appender.Buffer.min_level"                => "fatal",
    "log4perl.appender.Buffer.layout"                   => "Log::Log4perl::Layout::PatternLayout",
    "log4perl.appender.Buffer.layout.ConversionPattern" => "%d{yyyy-MM-dd HH:mm:ss} %5p [%M] (%F:%L) - %m%n",
});

# Make sure Data::Dumper loads
BEGIN { use_ok('Data::Dumper')
        or diag("Can't load Data::Dumper package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Data::Dumper');
use Data::Dumper;

# Make sure Storable loads
BEGIN { use_ok('Storable', qw(nfreeze thaw dclone))
        or diag("Can't load Storable package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'nfreeze');
can_ok('Storable', 'thaw');
can_ok('Storable', 'dclone');
use Storable qw(nfreeze thaw dclone);

# Make sure File::Find loads.
BEGIN { use_ok('File::Find', qw(find)) or diag("Can't load File::Find package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Find');
can_ok('File::Find', 'find');
use File::Find;

# Make sure Filesys::CygwinPaths loads
BEGIN { use_ok('Filesys::CygwinPaths')
        or diag("Can't load Filesys::CygwinPaths package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Filesys::CygwinPaths');
use Filesys::CygwinPaths qw(:all);

# Make sure Algorithm::Diff loads.
BEGIN { use_ok('Algorithm::Diff') or diag("Can't load Algorithm::Diff package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Algorithm::Diff');
use Algorithm::Diff;

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
use File::Basename qw(dirname);

# Make sure HoneyClient::Agent::Integrity::Filesystem loads.
BEGIN { use_ok('HoneyClient::Agent::Integrity::Filesystem') or diag("Can't load HoneyClient::Agent::Integrity::Filesystem package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Filesystem');
use HoneyClient::Agent::Integrity::Filesystem;

# Make sure DateTime loads.
BEGIN { use_ok('DateTime') or diag("Can't load DateTime package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('DateTime');
use DateTime;

# Make sure Digest::MD5 loads.
BEGIN { use_ok('Digest::MD5') or diag("Can't load Digest::MD5 package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Digest::MD5');
use Digest::MD5;

# Make sure Digest::SHA loads.
BEGIN { use_ok('Digest::SHA') or diag("Can't load Digest::SHA package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('Digest::SHA');
use Digest::SHA;

# Make sure File::Type loads.
BEGIN { use_ok('File::Type') or diag("Can't load File::Type package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Type');
use File::Type;

# Make sure IO::File loads.
BEGIN { use_ok('IO::File') or diag("Can't load IO::File package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::File');
use IO::File;
}



# =begin testing
{
diag("These tests will create temporary files in /tmp.  Be sure to cleanup this directory, if any of these tests fail.");

# Create a generic Filesystem object, with test state data.
my $filesystem = HoneyClient::Agent::Integrity::Filesystem->new(test => 1, bypass_baseline => 1);
is($filesystem->{test}, 1, "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");
isa_ok($filesystem, 'HoneyClient::Agent::Integrity::Filesystem', "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");

diag("Performing baseline check of the filesystem; this may take some time...");

# Perform baseline.
$filesystem = HoneyClient::Agent::Integrity::Filesystem->new();
isa_ok($filesystem, 'HoneyClient::Agent::Integrity::Filesystem', "new()") or diag("The new() call failed.");
}



# =begin testing
{
### Get the test directory to monitor.
my $monitor_dir = $ENV{PWD} . "/" . getVar(name      => "monitor_dir",
                                           namespace => "HoneyClient::Agent::Integrity::Filesystem::Test");

### Seed the directory with test data.
my $delete_file = $monitor_dir . "/" . "to_delete.txt";
my $change_file = $monitor_dir . "/" . "to_change.txt";
my $add_file    = $monitor_dir . "/" . "to_add.txt";

my $delete_string  = "Test string for the file to be deleted.";
my $add_string     = "Test string for the added file.";
my $change_string1 = "Original test string for the file to be changed.";
my $change_string2 = "Final test string for the changed file.";

my @file_attr;

open(DELETE_FILE, ">", $delete_file) or BAIL_OUT("Unable to create test file '" . $delete_file . "'.");
print DELETE_FILE $delete_string;
close DELETE_FILE;

@file_attr = stat($delete_file);
my $delete_file_size  = $file_attr[7];
my $delete_file_mtime = $file_attr[9];

open(CHANGE_FILE, ">", $change_file) or BAIL_OUT("Unable to create test file '" . $change_file . "'.");
print CHANGE_FILE $change_string1;
close CHANGE_FILE;

@file_attr = stat($change_file);
my $change_file_size1  = $file_attr[7];
my $change_file_mtime1 = $file_attr[9];

# Make sure the $add_file isn't present.
unlink($add_file);

### Perform baseline.
my $filesystem = HoneyClient::Agent::Integrity::Filesystem->new(monitored_directories => [ $monitor_dir ],
                                                                ignored_entries       => [ $monitor_dir ]);

### Change data in our test directory on the filesystem.
# Delete the target test file.
if (!unlink($delete_file)) {
    fail("Unable to delete test file '" . $delete_file . "'.");
}

# Add the target test file.
open(ADD_FILE, ">", $add_file) or BAIL_OUT("Unable to create test file '" . $add_file . "'.");
print ADD_FILE $add_string;
close ADD_FILE;

my $md5_ctx = Digest::MD5->new();
my $sha1_ctx = Digest::SHA->new("1");
my $type_ctx = File::Type->new();

my $add_fh = IO::File->new($add_file, "r");
$md5_ctx->addfile($add_fh);
my $add_file_md5 = $md5_ctx->hexdigest();
seek($add_fh, 0, 0);
$sha1_ctx->addfile($add_fh);
my $add_file_sha1 = $sha1_ctx->hexdigest();
undef $add_fh;
my $add_file_type = $type_ctx->mime_type($add_file);

@file_attr = stat($add_file);
my $add_file_size  = $file_attr[7];
my $add_file_mtime = $file_attr[9];

# Change the target test file.
open(CHANGE_FILE, ">", $change_file) or BAIL_OUT("Unable to create test file '" . $change_file . "'.");
print CHANGE_FILE $change_string2;
close CHANGE_FILE;

my $change_fh = IO::File->new($change_file, "r");
$md5_ctx->addfile($change_fh);
my $change_file_md5 = $md5_ctx->hexdigest();
seek($change_fh, 0, 0);
$sha1_ctx->addfile($change_fh);
my $change_file_sha1 = $sha1_ctx->hexdigest();
undef $change_fh;
my $change_file_type = $type_ctx->mime_type($change_file);

@file_attr = stat($change_file);
my $change_file_size2  = $file_attr[7];
my $change_file_mtime2 = $file_attr[9];

### Perform check.
my $foundChanges = $filesystem->check(no_prepare => 1);

# Uncomment these lines, if you want to see more
# detailed information about the changes found.
#$Data::Dumper::Terse = 0;
#$Data::Dumper::Indent = 1;
#diag(Dumper($foundChanges));

### Verify changes.
my $expectedChanges = [
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_MODIFIED,
    'new' => {
        'name'  => $change_file,
        'size'  => $change_file_size2,
        'mtime' => $change_file_mtime2,
    },
    'old' => {
        'name'  => $change_file,
        'size'  => $change_file_size1,
        'mtime' => $change_file_mtime1,
    },
  },
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_ADDED,
    'new' => {
        'name'  => $add_file,
        'size'  => $add_file_size,
        'mtime' => $add_file_mtime,
    },
  },
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_DELETED,
    'old' => {
        'name'  => $delete_file,
        'size'  => $delete_file_size,
        'mtime' => $delete_file_mtime,
    },
  },
];

is_deeply($foundChanges, $expectedChanges, "check(no_prepare => 1)") or diag("The check() call failed.");

### Perform check.
$foundChanges = $filesystem->check();

# Uncomment these lines, if you want to see more
# detailed information about the changes found.
#$Data::Dumper::Terse = 0;
#$Data::Dumper::Indent = 1;
#diag(Dumper($foundChanges));

### Verify changes.
$expectedChanges = [
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_MODIFIED,
    'name'  => HoneyClient::Agent::Integrity::Filesystem::_convertFilename($change_file),
    'mtime' => HoneyClient::Agent::Integrity::Filesystem::_convertTime($change_file_mtime2),
    'content' => {
        'size'  => $change_file_size2,
        'type'  => $change_file_type,
        'sha1'  => $change_file_sha1,
        'md5'   => $change_file_md5,
    },
  },
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_ADDED,
    'name'  => HoneyClient::Agent::Integrity::Filesystem::_convertFilename($add_file),
    'mtime' => HoneyClient::Agent::Integrity::Filesystem::_convertTime($add_file_mtime),
    'content' => {
        'size'  => $add_file_size,
        'type'  => $add_file_type,
        'sha1'  => $add_file_sha1,
        'md5'   => $add_file_md5,
    },
  },
  {
    'status' => $HoneyClient::Agent::Integrity::Filesystem::STATUS_DELETED,
    'name'  => HoneyClient::Agent::Integrity::Filesystem::_convertFilename($delete_file),
    'mtime' => HoneyClient::Agent::Integrity::Filesystem::_convertTime($delete_file_mtime),
  },
];

is_deeply($foundChanges, $expectedChanges, "check()") or diag("The check() call failed.");

### Clean up test data.
close DELETE_FILE;
unlink($delete_file);

close CHANGE_FILE;
unlink($change_file);

close ADD_FILE;
unlink($add_file);
}




1;
