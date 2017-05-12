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
BEGIN { use_ok('Storable', qw(dclone))
        or diag("Can't load Storable package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Storable');
can_ok('Storable', 'dclone');
use Storable qw(dclone);

# Make sure IO::Handle loads
BEGIN { use_ok('IO::Handle')
        or diag("Can't load IO::Handle package. Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::Handle');
use IO::Handle;

# Make sure IO::File loads
BEGIN { use_ok('IO::File')
        or diag("Can't load IO::File package. Check to make sure the package library is correctly listed within the path."); }
require_ok('IO::File');
use IO::File;

# Make sure Fcntl loads
BEGIN { use_ok('Fcntl')
        or diag("Can't load Fcntl package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Fcntl');
use Fcntl qw(:seek);

# Make sure File::Temp loads
BEGIN { use_ok('File::Temp')
        or diag("Can't load File::Temp package. Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Temp');
can_ok('File::Temp', 'tmpnam');
can_ok('File::Temp', 'unlink0');
use File::Temp qw(tmpnam unlink0);

# Make sure Filesys::CygwinPaths loads
BEGIN { use_ok('Filesys::CygwinPaths')
        or diag("Can't load Filesys::CygwinPaths package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Filesys::CygwinPaths');
use Filesys::CygwinPaths qw(:all);

# Make sure Search::Binary loads
BEGIN { use_ok('Search::Binary')
        or diag("Can't load Search::Binary package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Search::Binary');
can_ok('Search::Binary', 'binary_search');
use Search::Binary;

# Make sure HoneyClient::Agent::Integrity::Registry::Parser loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry::Parser')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry::Parser package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry::Parser');
use HoneyClient::Agent::Integrity::Registry::Parser;

# Make sure HoneyClient::Agent::Integrity::Registry loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry');
use HoneyClient::Agent::Integrity::Registry;

# Make sure File::Basename loads.
BEGIN { use_ok('File::Basename', qw(dirname basename fileparse)) or diag("Can't load File::Basename package.  Check to make sure the package library is correctly listed within the path."); }
require_ok('File::Basename');
can_ok('File::Basename', 'dirname');
can_ok('File::Basename', 'basename');
can_ok('File::Basename', 'fileparse');
use File::Basename qw(dirname basename fileparse);
}



# =begin testing
{
diag("These tests will create temporary files in /tmp.  Be sure to cleanup this directory, if any of these tests fail.");

# Create a generic Registry object, with test state data.
my $registry = HoneyClient::Agent::Integrity::Registry->new(test => 1, bypass_baseline => 1);
is($registry->{test}, 1, "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");
isa_ok($registry, 'HoneyClient::Agent::Integrity::Registry', "new(test => 1, bypass_baseline => 1)") or diag("The new() call failed.");

diag("Performing baseline check of 'HKEY_CURRENT_USER' hive; this may take some time...");

# Perform Registry baseline on HKEY_CURRENT_USER.
$registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_USER' ]);
isa_ok($registry, 'HoneyClient::Agent::Integrity::Registry', "new(hives_to_check => [ 'HKEY_CURRENT_USER' ])") or diag("The new() call failed.");
}



# =begin testing
{
my ($foundChanges, $expectedChanges);
my $before_registry_file = $ENV{PWD} . "/" . getVar(name      => "before_registry_file",
                                                    namespace => "HoneyClient::Agent::Integrity::Registry::Test");
my $after_registry_file = $ENV{PWD} . "/" . getVar(name      => "after_registry_file",
                                                   namespace => "HoneyClient::Agent::Integrity::Registry::Test");


# Create a generic Registry object, with test state data.
my $registry = HoneyClient::Agent::Integrity::Registry->new(bypass_baseline => 1);

# Verify Changes
$foundChanges = $registry->check(before_file => $before_registry_file,
                                 after_file  => $after_registry_file);
$expectedChanges = [
  {
    'entries' => [
      {
        'new_value' => undef,
        'name' => 'Test_Bin_1',
        'old_value' => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77',
      },
      {
        'new_value' => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77',
        'name' => 'Test_Bon_1',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 3',
  },
  {
    'entries' => [],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_DELETED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 4',
  },
  {
    'entries' => [
      {
        'new_value' => 'new value',
        'name' => '@',
        'old_value' => '',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 5',
  },
  {
    'entries' => [
      {
        'new_value' => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00',
        'name' => 'Test_Bin_3',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 6',
  },
  {
    'entries' => [
      {
        'new_value' => 'C:\\\\WINDOWSsystem32\\\\',
        'name' => 'InstallerLocation',
        'old_value' => 'C:\\\\WINDOWS\\\\system32\\\\',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 6\\With\\Really\\Deep\\Nested\\Directory\\Structure',
  },
  {
    'entries' => [
      {
        'new_value' => '',
        'name' => 'C:\\\\WINDOWS\\\\Installer\\\\{6855XXXX-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        'old_value' => undef,
      },
      {
        'new_value' => undef,
        'name' => 'C:\\\\WINDOWS\\\\Installer\\\\{6855CCDD-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        'old_value' => '',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_MODIFIED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 7',
  },
  {
    'entries' => [
      {
        'new_value' => undef,
        'name' => '000',
        'old_value' => 'String Value',
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_DELETED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 8\\{00021492-0000-0000-C000-000000000046}',
  },
  {
    'entries' => [
      {
        'new_value' => 'String Value',
        'name' => '000',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Testing Group 8\\{01021492-0000-0000-C000-000000000046}',
  },
  {
    'entries' => [
      {
        'new_value' => 'newvalue',
        'name' => 'newkey',
        'old_value' => undef,
      }
    ],
    'status' => $HoneyClient::Agent::Integrity::Registry::STATUS_ADDED,
    'key_name' => 'HKEY_CURRENT_USER\\Tsting Group 9',
  }
];

is_deeply($foundChanges, $expectedChanges, "check(before_file => '" . $before_registry_file . "', after_file => '" . $after_registry_file . "')") or diag("The check() call failed.");
}



# =begin testing
{
# Perform Registry baseline on HKEY_CURRENT_CONFIG.
diag("Performing baseline check of 'HKEY_CURRENT_CONFIG' hive; this may take some time...");
my $registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_CONFIG' ]);
my @files_created = $registry->getFilesCreated();
use Data::Dumper;
my $tmpfile = tmpnam();
unlink($tmpfile); 
my $tmpdir = dirname($tmpfile);
foreach my $file (@files_created) {
    like($file, qr/$tmpdir/, "getFilesCreated()") or diag("The getFilesCreated() call failed.");
}
}



# =begin testing
{
# Perform Registry baseline on HKEY_CURRENT_CONFIG.
diag("Performing baseline check of 'HKEY_CURRENT_CONFIG' hive; this may take some time...");
my $registry = HoneyClient::Agent::Integrity::Registry->new(hives_to_check => [ 'HKEY_CURRENT_CONFIG' ]);
$registry->closeFiles();
my @files_created = $registry->getFilesCreated();
use Data::Dumper;
my $tmpfile = tmpnam();
unlink($tmpfile); 
my $tmpdir = dirname($tmpfile);
foreach my $file (@files_created) {
    like($file, qr/$tmpdir/, "closeFiles()") or diag("The closeFiles() call failed.");
}
}




1;
