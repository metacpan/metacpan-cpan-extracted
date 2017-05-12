# To build this script into a PerlSvc, select:
#   Tools | Build Standalone Perl Application...
#
# Note: This functionality is only available if the Perl Dev Kit is
# installed. See: http://www.ActiveState.com/Products/Perl_Dev_Kit/
#

package PerlSvc;
use strict;
use warnings;

BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}

use XML::Simple;
use Time::HiRes qw(sleep usleep);
use MaplatSVCWin;
use Getopt::Long;



my $isCompiled = 0;
if(defined($PerlSvc::VERSION)) {
	$isCompiled = 1;
}

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat SVC";
our $VERSION = "2009-12-09";
MaplatLogo($APPNAME, $VERSION);

my $configfile;
our %Config;

sub Interactive {
	print "INTERACTIVE - running Startup()\n";
	Startup();
}

# the startup routine is called when the service starts
sub Startup {
	
	Getopt::Long::GetOptions(
        'config=s'     => \$configfile,
    );
	
	my $config = XMLin($configfile,
                    ForceArray => ['module', 'run'],);

    if(!$configfile) {
        $configfile='C\src\maplat\configs\rbssvc.xml';
		print "Using default config file '$configfile'\n";
	} else {
		print "Using config file '$configfile'\n";
	}
	
	my $svcserver = new MaplatSVCWin(RunningAsService(),
								  $config->{basedir},
								  $config->{memhserver},
								  $config->{memhnamespace},
								  $APPNAME,
								  $VERSION,
								  $isCompiled,
								  );

	
	my @modlist = @{$config->{module}};
	$svcserver->startconfig();

	# Configure run-once scripts
	if(defined($config->{startup}->{run})) {
		foreach my $script (@{$config->{startup}->{run}}) {
			$svcserver->configure_startup($script);
		}
	}
	if(defined($config->{shutdown}->{run})) {
		foreach my $script (@{$config->{shutdown}->{run}}) {
			$svcserver->configure_shutdown($script);
		}
	}

	foreach my $module (@modlist) {
		$svcserver->configure_module($module);
	}
		
	$svcserver->endconfig();
	
    while (ContinueRun()) {
	    my $workCount = $svcserver->work();
		if(!$workCount) {
			sleep(0.1);
		};
		if(defined($config->{runonce}) && $config->{runonce}) {
		    last;
		}
   }
	
	$svcserver->shutdown;
}

sub Install {
    # add your additional install messages or functions here
	
	Getopt::Long::GetOptions(
        'config=s'     => \$configfile,
    );

    if(!$configfile) {
        $configfile='C\src\maplat\configs\rbssvc.xml';
		print "using default config file '$configfile'\n";
	}
	
	$Config{ServiceName} = "MaplatSVC";
	$Config{DisplayName} = "Maplat Service Control";
	$Config{Description} = "Manages configured MAPLAT workers and webguis";
	$Config{Parameters}	 = "--config \"$configfile\"";
	$Config{StartType}   = "auto";
	$Config{StartNow}    = 0;
	
    print "The MaplatSVC Service has been installed.\n";
    print "Start the service with the command: net start MaplatSVC\n";
}

sub Remove {
    # add your additional remove messages or functions here
	$Config{ServiceName} = "MaplatSVC";
	$Config{DisplayName} = "Maplat Service Control";
	$Config{Description} = "Manages configured MAPLAT workers and webguis";
    print "The MaplatSVC Service has been removed.\n";
}

sub Help {
    # add your additional help messages or functions here
    print "For help, ask Rene Schickbauer.\n";
}

unless (defined &ContinueRun) {
    *ContinueRun      = sub { return 1 };
    *RunningAsService = sub { return 0 };
    Startup();
}
