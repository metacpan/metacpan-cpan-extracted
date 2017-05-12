### 08-custom_user_logger.t ##############################
# This file tests calls with a custom "logger" object created by the user (not the default created by HPCI.pm)

### Includes ####################################################

# Safe Perl
use warnings;
use strict;
use Carp;
use Test::More tests=>8;
use Test::Exception;

use Log::Log4perl qw(:easy get_logger);
use Log::Log4perl::Appender::Screen;
use Log::Log4perl::Level;

use File::Temp;

use HPCI;

# Create a directory for the custom logger 
#-d 'temp' or mkdir 'temp';
my $tmp_dir = File::Temp->newdir( TEMPLATE => 'TEST.XXXX',DIR =>'scratch', CLEANUP=> 0 );
print( "Creating custom logging directory named: " . $tmp_dir->dirname ."\n");


my $cluster = $ENV{HPCI_CLUSTER} || 'uni';

# Specify arguments for custom logger



my $log = Log::Log4perl::get_logger();

$log->level("DEBUG");
my $filename = $tmp_dir->dirname . "/123TEST1234.log";

# Appenders - they specify where logging events should be printed/sent
my $file_appender = Log::Log4perl::Appender->new(
	"Log::Log4perl::Appender::File",
	filename => $filename,
	mode     => 'append',
	);
my %layout = (
	simple  => "%d %6p> %m%n",
	verbose => "%d (%10r) %6p> %m%n",
	);
$_ = Log::Log4perl::Layout::PatternLayout->new($_) for values %layout;

$file_appender->layout($layout{simple});
$log->add_appender($file_appender);

$log->debug("TEST before group TEST");

# Create the group 
my $group = HPCI->group(cluster => $cluster, base_dir => 'scratch', name => 'CUSTOM_LOGGER', log =>$log);
ok($group, "Group created");

my $stage1 = $group->stage (
    name => "echoTest",
    command => "echo 3"
);
ok ($stage1, "Stage 1 created");
$log->debug("TEST before execute TEST");
$group->execute();
$log->debug("TEST after execute TEST");

ok (-e $filename, "Log file created");

undef $log; # stop logging

open my $fh, '<', $filename;

for my $text (
		'TEST before group',
		'Created stage',
		'TEST before execute',
		'Starting execution',
		'TEST after execute',
	) {
	my $line = <$fh>;
	unless ($line) {
		ok( 0, "EOF in log while searching for ($text)" );
		last;
	}
	if (index($line,$text) >= 0 ) {
		ok( 1, "found ($text)" );
		next;
		}
	redo;
	}

done_testing();
