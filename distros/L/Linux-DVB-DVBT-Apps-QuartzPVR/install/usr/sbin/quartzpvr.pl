#!%PERL_BIN% -w
package Linux::DVB::DVBT::Apps::QuartzPVR ;

use strict ;

use base qw(Net::Server::Fork);

our $VERSION = '1.04' ;

our $scan_log = "%PVR_HOME%/scan.log" ;
our $bg_log = "%PVR_HOME%/background.log" ;

	## Array: [ command, timeout, background ]
	my %COMMANDS = (
	
		## External commands
		'dvb_record_mgr'		=> [ '%PERL_SCRIPTS%/dvbt-record-mgr', 30, 0 ],
		
		'dvb_scan'				=> [ "%PERL_SCRIPTS%/dvbt-qpvr-scan -usecfg -log $scan_log", 3600, 1 ],
		'dvb_scan_info'			=> [ "%PERL_SCRIPTS%/dvbt-qpvr-scan -status -log $scan_log", 30, 0 ],
		'dvb_chans'				=> [ "%PERL_SCRIPTS%/dvbt-chans-sql", 30, 0 ],
		'dvb_epg'				=> [ "%PERL_SCRIPTS%/dvbt-epg-sql", 3600, 1 ],

		'sleep'					=> [ 'sleep', 3600, 0 ],
		
		## Internal commands
		'info'					=> [\&info, 30, 0 ],
	) ;

	# Server settings
	my $server = Linux::DVB::DVBT::Apps::QuartzPVR->new({
		conf_file 	=> '/etc/quartzpvr/quartzpvr-server.conf',
		pid_file	=> '/var/run/quartzpvr/server.pid',
	});

	
	$server->run() ;


##=================================================================================================
## Overriden methods
##=================================================================================================

#--------------------------------------------------------------------------------------------------
# Forked child request
sub process_request 
{
	my $self = shift;

	$self->log(1, "New connection\n") ;
		
	my $cmd = <STDIN> ;
	chomp $cmd ;
	$cmd =~ s/\r\n//g ;

	my $args = "" ;
	if ($cmd =~ /^(\w+)\s+(.*)/)
	{
		($cmd, $args) = ($1, $2) ;
	}

	$self->log(3, "cmd='$cmd' args='$args'\n") ;
		
	if (exists($COMMANDS{$cmd}))
	{
		my ($fullcmd, $timeout, $bg) = @{$COMMANDS{$cmd}} ;
		$self->log(1, "CMD: $fullcmd $args\n") ;
		
        eval {

            local $SIG{'ALRM'} = sub { die "Timed Out!\n" };
            my $previous_alarm = alarm($timeout);
		
			## Check for internal commands
			if (ref($fullcmd) eq 'CODE')
			{
				&$fullcmd($self, $args) ;
			}
			else
			{
				## External commands
				if ($bg)
				{
					## background
					system("$fullcmd $args >$bg_log 2>&1 &") ;
					$self->log(1, "CMD backgrounded\n") ;
				}
				else
				{
					## foreground
					my @lines = `$fullcmd $args 2>&1` ;
					$self->log(1, "CMD Complete\n") ;
			
					for my $line (@lines)
					{
						chomp $line ;
						$self->log(3, "[cmd] $line\n") ;
						print "$line\n" ;
					}
				}
			}
			
            alarm($previous_alarm);
			
        } ; # eval
        
        if ($@ =~ /timed out/i) {
            print STDOUT "Command $fullcmd timed out.\n";
            return;
        }
        
		
	}
		
	$self->log(1, "Connection closed\n") ;
}


##=================================================================================================
## Internal methods
##=================================================================================================

#--------------------------------------------------------------------------------------------------
# Forked child request
sub info 
{
	my $self = shift;

	$self->log(1, "info\n") ;
	print "Version: $VERSION\n" ;

}

