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

# Make sure Search::Binary loads
BEGIN { use_ok('Search::Binary')
        or diag("Can't load Search::Binary package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Search::Binary');
can_ok('Search::Binary', 'binary_search');
use Search::Binary;

# Make sure Term::ProgressBar loads
BEGIN { use_ok('Term::ProgressBar')
        or diag("Can't load Term::ProgressBar package. Check to make sure the package library is correctly listed within the path."); }
require_ok('Term::ProgressBar');
use Term::ProgressBar;

# Make sure HoneyClient::Agent::Integrity::Registry::Parser loads
BEGIN { use_ok('HoneyClient::Agent::Integrity::Registry::Parser')
        or diag("Can't load HoneyClient::Agent::Integrity::Registry::Parser package. Check to make sure the package library is correctly listed within the path."); }
require_ok('HoneyClient::Agent::Integrity::Registry::Parser');
use HoneyClient::Agent::Integrity::Registry::Parser;
}



# =begin testing
{
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);
isa_ok($parser, 'HoneyClient::Agent::Integrity::Registry::Parser', "init(input_file => $test_registry_file)") or diag("The init() call failed.");
}



# =begin testing
{
my ($nextGroup, $expectedGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

# Verify Test Group #1
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 1") or diag("The nextGroup() call failed.");

# Verify Test Group #2
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 2',
    entries => [ {
        name  => '@',
        value => '\\"Annoying=Value\\"',
    }, {
        name  => '\\"Annoying=Key\\"',
        value => 'Bar',
    }, {
        name  => 'Multiline',
        value => 'This
value spans
multiple lines
',
    }, {
        name  => 'Sane_Key',
        value => '\\"Wierd=\\"Value',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 2") or diag("The nextGroup() call failed.");

# Verify Test Group #3
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 3',
    entries => [ {
        name  => 'Test_Bin_1',
        value => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77'
    }, {
        name  => 'Test_Bin_2',
        value => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00'
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 3") or diag("The nextGroup() call failed.");

# Verify Test Group #4
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 4',
    entries => [],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 4") or diag("The nextGroup() call failed.");

# Verify Test Group #5
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 5',
    entries => [ {
        name  => '@',
        value => '',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 5") or diag("The nextGroup() call failed.");

# Verify Test Group #6
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 6\With\Really\Deep\Nested\Directory\Structure',
    entries => [ {
        name  => 'InstallerLocation',
        value => 'C:\\\\WINDOWS\\\\system32\\\\',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 6") or diag("The nextGroup() call failed.");

# Verify Test Group #7
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 7',
    entries => [ {
        name  => 'C:\\\\Program Files\\\\Common Files\\\\Microsoft Shared\\\\Web Folders\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{350C97B0-3D7C-4EE8-BAA9-00BCB3D54227}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\Program Files\\\\Support Tools\\\\',
        value => '',
    }, {
        name  => 'C:\\\\Documents and Settings\\\\All Users\\\\Start Menu\\\\Programs\\\\Windows Support Tools\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{6855CCDD-BDF9-48E4-B80A-80DFB96FE36C}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{F251B999-08A9-4704-999C-9962F0DFD88E}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{1CB92574-96F2-467B-B793-5CEB35C40C29}\\\\',
        value => '',
    }, {
        name  => 'C:\\\\WINDOWS\\\\Installer\\\\{B37C842A-B624-46B8-A727-654E72F1C91A}\\\\',
        value => '',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 7") or diag("The nextGroup() call failed.");

# Verify Test Group #8
$nextGroup = $parser->nextGroup();
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 8\{00021492-0000-0000-C000-000000000046}',
    entries => [ {
        name  => '000',
        value => 'String Value',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "nextGroup() - 8") or diag("The nextGroup() call failed.");

# Verify Test Group #9
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, { }, "nextGroup() - 9") or diag("The nextGroup() call failed.");
}



# =begin testing
{
my ($nextGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$nextGroup = $parser->nextGroup();
while(scalar(keys(%{$nextGroup}))) {
    $nextGroup = $parser->nextGroup();
}

is($parser->dirsParsed(), 8, "dirsParsed()") or diag("The dirsParsed() call failed.");
}



# =begin testing
{
my ($nextGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$nextGroup = $parser->nextGroup();
while(scalar(keys(%{$nextGroup}))) {
    $nextGroup = $parser->nextGroup();
}

is($parser->entriesParsed(), 19, "entriesParsed()") or diag("The entriesParsed() call failed.");
}



# =begin testing
{
my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$handle = $parser->getFileHandle();

isa_ok($handle, 'IO::File', "getFileHandle()") or diag("The getFileHandle() call failed.");
}



# =begin testing
{
my ($filename);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);

$filename = $parser->getFilename();

is($filename, $test_registry_file, "getFilename()") or diag("The getFilename() call failed.");
}



# =begin testing
{
my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file);
$parser->closeFileHandle();

# Verify Test Group #1
my $nextGroup = $parser->nextGroup();
my $expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is_deeply($nextGroup, $expectedGroup, "closeFileHandle()") or diag("The closeFileHandle() call failed.");
}



# =begin testing
{
my ($handle);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

$parser->seekToNearestGroup(absolute_offset => 84);
my $nextGroup = $parser->nextGroup();

is($parser->getCurrentLineCount(), 9, "getCurrentLineCount()") or diag("The getCurrentLineCount() call failed.");
}



# =begin testing
{
my ($nextGroup, $expectedGroup);
my $test_registry_file = $ENV{PWD} . "/" . getVar(name      => "registry_file",
                                                  namespace => "HoneyClient::Agent::Integrity::Registry::Parser::Test");

# Create a generic Parser object, with test state data.
my $parser = HoneyClient::Agent::Integrity::Registry::Parser->init(input_file => $test_registry_file, index_groups => 1);

# Verify Test Group #2
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 2',
    entries => [ {
        name  => '@',
        value => '\\"Annoying=Value\\"',
    }, {
        name  => '\\"Annoying=Key\\"',
        value => 'Bar',
    }, {
        name  => 'Multiline',
        value => 'This
value spans
multiple lines
',
    }, {
        name  => 'Sane_Key',
        value => '\\"Wierd=\\"Value',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 84), 73, "seekToNearestGroup(absolute_offset => 84)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 84)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 7), 6, "seekToNearestGroup(absolute_linenum => 7)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 7)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #3
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 3',
    entries => [ {
        name  => 'Test_Bin_1',
        value => 'hex:f4,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,bc,02,00,00,00,\
  00,00,00,00,00,00,00,54,00,61,00,68,00,6f,00,6d,00,61,00,00,00,f0,77,3f,00,\
  3f,00,3f,00,3f,00,00,00,00,00,00,00,00,00,00,00,00,00,00,00,78,00,1c,10,fc,\
  7f,22,14,fc,7f,b0,fe,12,00,00,00,00,00,00,00,00,00,98,23,eb,77'
    }, {
        name  => 'Test_Bin_2',
        value => 'hex:f5,ff,ff,ff,00,00,00,00,00,00,00,00,00,00,00,00,90,01,00,00,00,\
  00,00,00,00,00,00,00,4d,00,69,00,63,00,72,00,6f,00,73,00,6f,00,66,00,74,00,\
  20,00,53,00,61,00,6e,00,73,00,20,00,53,00,65,00,72,00,69,00,66,00,00,00,f0,\
  77,00,20,14,00,00,00,00,10,80,05,14,00,f0,1f,14,00,00,00,14,00'
    }, ],
};

is($parser->seekToNearestGroup(absolute_offset => 301), 234, "seekToNearestGroup(absolute_offset => 301)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 301)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 16), 15, "seekToNearestGroup(absolute_linenum => 16)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 16)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 26, adjust_index => -1), 15, "seekToNearestGroup(absolute_linenum => 26, adjust_index => -1)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 26, adjust_index => -1)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #4
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 4',
    entries => [],
};

is($parser->seekToNearestGroup(absolute_offset => 898), 881, "seekToNearestGroup(absolute_offset => 898)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898)") or diag("The seekToNearestGroup() call failed.");

is($parser->seekToNearestGroup(absolute_linenum => 26), 25, "seekToNearestGroup(absolute_linenum => 26)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_linenum => 26)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #8
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\Testing Group 8\{00021492-0000-0000-C000-000000000046}',
    entries => [ {
        name  => '000',
        value => 'String Value',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 898, adjust_index => 99), 1674, "seekToNearestGroup(absolute_offset => 898, adjust_index => 99)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898, adjust_index => 99)") or diag("The seekToNearestGroup() call failed.");

# Verify Test Group #1
$expectedGroup = {
    key     => 'HKEY_CURRENT_USER\]Testing Group 1[',
    entries => [ {
        name  => '@',
        value => 'Default',
    }, {
        name  => 'Foo',
        value => 'Bar',
    }, ],
};
is($parser->seekToNearestGroup(absolute_offset => 898, adjust_index => -99), 0, "seekToNearestGroup(absolute_offset => 898, adjust_index => -99)") or diag("The seekToNearestGroup() call failed.");
$nextGroup = $parser->nextGroup();
is_deeply($nextGroup, $expectedGroup, "seekToNearestGroup(absolute_offset => 898, adjust_index => -99)") or diag("The seekToNearestGroup() call failed.");
}




1;
