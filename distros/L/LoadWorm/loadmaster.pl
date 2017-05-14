#!/usr/local/bin/perl

# AUTHOR Glenn Wood, Glenn.Wood@savesmart.com
# Copyright 1997-1998 SaveSmart, Inc.
# Released under the Perl Artistic License.
# $Header: C:/CVS/LoadWorm/loadmaster.pl,v 1.1.1.1 2001/05/19 02:54:40 Glenn Wood Exp $
	
#use strict;
use Tk;
use LoadWorm;
use English;
use File::Path;
use File::Copy;
	
# Sockets
use Socket;
use Carp;
use FileHandle;
use Sys::Hostname;
sub SetUpSockets;


	($MASTERDIR) = @ARGV;		
	$MASTERDIR = "." unless $MASTERDIR;
	my $I_AM = 'uninitialized';

	LoadWorm::GetConfiguration("$MASTERDIR/loadworm.cfg");
	$Harvest = "$MASTERDIR/Harvest"; # This is where the results will be stored upon HARVEST.
	
	%Clients = ();
	%ClientsName = ();
	$MyIPAddr = gethostbyname(hostname());
	SetUpSockets();

	$TickCounter = 0;
	$RunningCounter = 0;
	$Trace = 1;
	$TotalDone = 0;
	$TotalTime = 0;
	$StartingTime = LoadWorm->GetTickCount();
	$RunningTime = 0;
	$RunningDone = 0;
	$RestartGoKey = 0;
	$HarvestCount = 0;

	my $LoadMasterWindow = new MainWindow(-title => "Load Master");
	FillMainWindow($LoadMasterWindow, 'Load Master');
	$LoadMasterWindow->repeat(100, \&Ticker);

	MainLoop;

###############################################################################
sub NewMaster { my($label, $name) = @_;

	unless ( $SlaveMasters{$label} )
	{
		my $slavewindow = $LoadMasterWindow->Toplevel(-title => $name, -background => green);
		FillSlaveMasterWindow($slavewindow, $label);
		$SlaveMasters{$label} = $slavewindow;
	}
}


# Check for any new SlaveMasters (via socket SERVER).
# Check for any input from current SlaveMasters (via their
#   respective sockets in @Clients.)
sub Ticker { my $self = @_;
	
	while ( select($rin=$SocketsVector, undef, $ein=$SocketsVector, 0) ) {
		if ( vec($rin, fileno(SERVER), 1) ) {
			$NewClient = new FileHandle;
			$paddr = accept($NewClient, SERVER);
			select ($NewClient); $| = 1; select(STDOUT);
			my ($port, $iaddr) = sockaddr_in($paddr);
			# Win95 can't gethostbyaddr(); besides, everyone gets "localhost".
#			my $name = gethostbyaddr($iaddr, AF_INET);
#			unless ( $name ) {
				$name = inet_ntoa($iaddr);
#				$name =~ /^.*\.(\d+)$/;	# so we'll use the
#				$name = $1;					# fourth octet.
#			}
			$MainWindowText->insert(end, "\n$name:$port is born");
			$MainWindowText->yview(end);
			vec($SocketsVector, fileno($NewClient), 1) |= 1;
			$Clients{"$name\_$port"} = $NewClient;
			NewMaster("$name\_$port", "ME");
			$ClientsName{$NewClient} = "$name\_$port";
			print $NewClient "YOU_ARE=$name\_$port\n";
			print $NewClient "PROXY=$Proxy[0]\n" if $Proxy[0];
			for ( @NoProxy ) {
				print $NewClient "NOPROXY=$_\n";
			}
			for ( @Credentials ) {
				print $NewClient "CREDENTIALS=$_\n";
			}
			print $NewClient "TIMEOUT=$ENV{TIMEOUT}\n";
			print $NewClient "HARVEST=$ENV{HARVEST}\n";
			my $num = 0;
			open TMP, "<$MASTERDIR/visits.txt";
			while ( <TMP> ) {
				print $NewClient "VISITS $num $_";
				$num += 1;
			}
			close TMP;
			if ( $RestartGoKey )
			{
				&GoKey($RestartGoKey);
            $RestartGoKey = 0;
			}
		}
	
		for $Client ( values %Clients )
		{
			if ( vec($ein, fileno($Client), 1) )
			{
				print "SlaveMaster $ClientsName{$Client} failed.\n";
				vec($SocketsVector, fileno($Client), 1) = 0;
				close $Client;
				$Client = undef;
				$RunningSlaves{$ClientsName{$Client}} = undef;
				next;
			};
	
			if ( vec($rin, fileno($Client), 1) )
			{
				unless ( $_ = <$Client> )
				{
					print "SlaveMaster $ClientsName{$Client} died.\n";
					vec($SocketsVector, fileno($Client), 1) = 0;
					close $Client;
					$RunningSlaves{$ClientsName{$Client}} = undef;
					&CountAndDisplayTotalSlaves();
					$Client = undef;
					next;
				};

				/^I_AM (\S*) (\S*)$/ && do { $SlaveMasters{$1}->title($2); next; };

				/^HARVEST (\S*) (.*)$/ && do
					{
						$SlaveName = $1;
						$val = $2;
						$p = $SlaveFile{$SlaveName};
						unless ( $p ) {
							$p = new FileHandle;
							open $p, ">$Harvest/$SlaveName\.timings";
							$SlaveFile{$SlaveName} = $p;
						}
						if ( $val =~ /CLOSE/ ) {
							close $p;
							$MainWindowText->insert(end, "\n$SlaveName harvested");
							$MainWindowText->yview(end);
							$SlaveFile{$SlaveName} = undef;
							$HarvestCount -= 1;
							unless ( $HarvestCount ) {
								$MainWindowText->insert(end, "\n**** HARVEST IS COMPLETE ****");
								$MainWindowText->yview(end);
							}
						}
						else {
							print $p $val."\n";
						}
						next;
					};
	
				/^REPORT (\S*) (\S*) (\S*) (\S*) (\S*)$/ && do
				{
					&UpdateReports($1, $2, $3, $4, $5);
					next;
				};

				/^TEXT (\S*) (.*)$/ && do
				{
               if ( defined $SlaveMasters{$1} ) {
						$TheSlave = $1;
						$SlaveText{$TheSlave}->delete('1.0', end);
						$SlaveText{$TheSlave}->insert('1.0', $2);
					}
					next;
				};

				chomp;
				print "Received $_ from $ClientsName{$Client}\n";
			}
		}
	}
	$TickCounter += 1;
	if ( $TickCounter > 9 ) {
		$TickCounter = 0;
		$RunningCounter += 1;
		if ( $RunningCounter > 4 ) {
			&UpdateRunningReport();
			$RunningCounter = 0;
			$RunningTime = 0;
			$RunningDone = 0;
		}
		&AllSlavers('REPORT');
	}
}



sub Harvest {

	return unless $ENV{HARVEST};
	mkpath($Harvest);
	unlink "$Harvest/*.*";
	copy("loadworm.cfg", "$Harvest/loadworm.cfg");
	copy("visits.txt", "$Harvest/visits.txt");
	&AllSlavers('HARVEST=GIMME');
	for ( values %RunningSlaves ) {
		$HarvestCount += $_;
	}
}



###############################################################################
###############################################################################
sub FillMainWindow {
	
	my ($window, $label) = @_;
	$TextWidth = 30;

#	$window->Label(-text => $label)->pack;
{	
	my $frame = $window->Frame(-relief=>sunken);
	$frame->Button(-text => 'GO',
						 -command => sub { &GoKey($window); }
						 )->grid(-row=>0, -column=>0);
	$frame->Button(-text => 'PAUSE',
						 -command => sub { &AllSlavers('PAUSE'); }
						 )->grid(-row=>0, -column=>1);
	
	if ( $ENV{HARVEST} )
	{	$frame->Button(-text => 'HARVEST',
					 -command => sub { &Harvest(); }
					 )->grid(-row=>1, -column=>0);
		$frame->Button(-text => 'RESULTS',
							 -command => sub { &Results(); }
							 )->grid(-row=>1, -column=>1);
	$frame->Button(-text => 'View Results',
						 -command => sub { &ViewResults("$Harvest/results.txt"); }
						 )->grid(-row=>2, -column=>1);
	$frame->Button(-text => 'View Fails',
						 -command => sub { &ViewResults("$Harvest/failed.txt"); }
						 )->grid(-row=>2, -column=>0);
	}

#	$frame->Button(-text => 'EXIT',
#						 -command => sub { &AllSlavers('SUICIDE'); destroy $window; exit; }
#						 )->grid(-row=>1, -column=>1);
	$frame->pack;
}

	$MainWindowText = $window->ROText(-width => $TextWidth, -height => 5)->pack;
	$window->Button(-text => 'CLEAR RUNNING AVERAGE',
						 -command => sub { &ClearStats(); })->pack;
	$MainWindowProgress1 = $window->ROText(-width => $TextWidth, -height => 1, -wrap=>word)->pack;
	$MainWindowProgress2 = $window->ROText(-width => $TextWidth, -height => 1, -wrap=>word)->pack;
{	
	my $frame = $window->Frame(-relief=>raised);
	$frame->Label(-text => 'Target Hits/sec')->grid(-row=>0, -column=>0);
	$MainWindowSlaves = $frame->Entry(-text => 'Slaves', -width => 4)->grid(-row=>0, -column=>1);
	$frame->Label(-text => 'Actual Hits/sec')->grid(-row=>1, -column=>0);
	$MainWindowTotalSlaves = $frame->ROText(-width => 4, -height => 1)->grid(-row=>1, -column=>1);
	$frame->pack;
}

	$I_AM = inet_ntoa($MyIPAddr).":$MyPort";
	print "SlaveMaster at $I_AM is started.\n";
	$window->Label(-text => $I_AM)->pack;
}


###############################################################################
###############################################################################
sub FillSlaveMasterWindow { my ($window, $label) = @_;

	$SlaveTextWidth = 20;
	$SlaveText{$label} = $window->Text(-width => $SlaveTextWidth, -height => 1)->pack;
	$SlaveProgress1{$label} = $window->Text(-width => $SlaveTextWidth, -height => 1)->pack;
	$SlaveProgress2{$label} = $window->Text(-width => $SlaveTextWidth, -height => 1)->pack;
	$SlaveProgress3{$label} = $window->Text(-width => $SlaveTextWidth, -height => 1)->pack;
	$window->Button(-text => 'close',
						 -command => sub{ &SlaverDo($label, 'SUICIDE');
												$SlaveMasters{$label} = undef;
												# I think we have to keep listening to the client sockets, else things get locked up.
												#close $Clients{$label};
												#$Clients{$label} = undef;
												#unlink "$MASTERDIR/$label.slave";
												destroy $window;
												})->pack(-side => left);
	$window->Label(-text => $label)->pack;
}




sub SlaverDo { my($master, $cmd) = @_;

	$Client = $Clients{$master};
	print $Client "$cmd\n" if $Client;
}


sub AllSlavers { my($cmd) = @_;

	for ( sort keys %SlaveMasters ) {
		SlaverDo($_, $cmd);
	}
}


# Called by GetConfiguration() when it reads the [Slave] section.
sub SlaveOption {
}


sub GoKey { my ($window) = @_;

	my $num = $MainWindowSlaves->get();
	unless ( $num )
	{
		$MainWindowSlaves->delete('1.0', end);
		$MainWindowSlaves->insert('1.0', 1);
		$num = 1;
	}
	my $cnt = 0;
	for ( values %SlaveMasters ) {
		$cnt += 1 if $_;
	};
	unless ( $cnt )
	{
		$MainWindowText->insert(end, "\nAutoStarting a SlaveMaster");
		$MainWindowText->yview(end);
		$RestartGoKey = $window;
		if ( $OSNAME eq 'MSWin32' ) {
			$AutoStartPipe = new FileHandle "|$ENV{PERL}/bin/perl loadslave.pl $I_AM";
		}
		else {
			$AutoStartPipe = new FileHandle "|./loadslave.pl $I_AM";
		}
		return;
	};

	my $ave = int($num / $cnt);
	$ave += 1 unless ($ave * $cnt == $num);

	for ( keys %SlaveMasters ) {
		next unless $SlaveMasters{$_};
		if ( $num < $ave ) {
			$ave = $num;
		};
		$num -= $ave;
		SlaverDo($_, "SLAVES=$ave");
	}
	
	&AllSlavers('GO');
}


sub Results {
	$MainWindowText->insert(end, "\n\n\n\n\nRunning loadresults.pl");
	$MainWindowText->yview(end);

	$rslt = `$ENV{PERL}/bin/perl loadresults.pl $Harvest`;
	if ( $rslt =~ /(Average\s+[\d\.]+ seconds)/ )
	{
		$MainWindowText->insert(end, "\n$1");
	}
	if ( $rslt =~ /(\d+ requests on \d+ URLs failed)/ )
	{
		$MainWindowText->insert(end, "\n$1");
	}
	if ( $rslt =~ /(Apparent duration: \d+ minutes)/ )
	{
		$MainWindowText->insert(end, "\n$1");
	}
	$MainWindowText->insert(end, "\n");
	$MainWindowText->yview(end);
}


sub ViewResults {	($which) = @_;

	open TMP, "| $ENV{EDITOR} $which";
}

sub ClearStats {
	my $TheSlave;

	$TotalDone = 0; $TotalTime = 0;
	$StartingTime = LoadWorm->GetTickCount();
	$MainWindowProgress2->delete('1.0', end);
	for $TheSlave ( keys %TotalDone ) {
		$TotalDone{$TheSlave} = 0;
		$TotalTime{$TheSlave} = 0;
	}
}


sub CountAndDisplayTotalSlaves {
	my $TotalSlaves = 0;
	for ( values %RunningSlaves ) {
		$TotalSlaves += $_;
	}
	$MainWindowTotalSlaves->delete('0.0', end);
	$MainWindowTotalSlaves->insert('1.0', "$TotalSlaves");
}



# Set up a socket listener, listening for the SlaveMasters.
sub SetUpSockets {
	
	$| = 1;
	my $proto = getprotobyname('tcp');
	my $rslt = socket(SERVER, PF_INET, SOCK_STREAM, $proto)		or die "socket: $!";
	setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, pack("l", 1))	or die "setsockopt: $!";
#	setsockopt(SERVER, IPPROTO_TCP, TCP_NODELAY, pack("l", 1))	or die "setsockopt: $!";
	bind(SERVER, sockaddr_in($MyPort, INADDR_ANY))					or die "bind: $!";
	listen(SERVER, SOMAXCONN)												or die "listen: $!";
	vec($SocketsVector, fileno(SERVER), 1) = 1;
}





sub UpdateReports { my ($TheSlave, $myTotalDone, $myTotalTime, $RunningNow, $ActualAve) = @_;

	my $ave;
	
	$RunningDone += $myTotalDone;
	$RunningTime += $myTotalTime;
	$TotalDone += $myTotalDone;
	$TotalTime += $myTotalTime;
	$RunningSlaves{$TheSlave} = $RunningNow;
	
	if ( $myTotalDone && defined $SlaveMasters{$TheSlave} )
	{
		$TotalDone{$TheSlave} += $myTotalDone;
		$TotalTime{$TheSlave} += $myTotalTime;
		$ave = sprintf "%5.2f", $myTotalTime / ($myTotalDone*1000);
		$SlaveProgress1{$TheSlave}->delete('1.0', end);
		$SlaveProgress1{$TheSlave}->insert('1.0', "$ave secs $myTotalDone GETs");
		$ave = sprintf "%5.2f", $TotalTime{$TheSlave} / ($TotalDone{$TheSlave}*1000);
		$SlaveProgress2{$TheSlave}->delete('1.0', end);
		$SlaveProgress2{$TheSlave}->insert('1.0', "$ave secs $TotalDone{$TheSlave} GETs");
		$ave = sprintf "%4.1f", $ActualAve;
		$SlaveProgress3{$TheSlave}->delete('1.0', end);
		$SlaveProgress3{$TheSlave}->insert('1.0', "Actual $ave GETs/sec");
	}
	
	&CountAndDisplayTotalSlaves();
}



sub UpdateRunningReport {
my $ave, $aave;

	if ( $RunningDone ) {
		$ave = sprintf "%5.2f", $RunningTime / ($RunningDone*1000);
		$MainWindowProgress1->delete('1.0', end);
		$MainWindowProgress1->insert('1.0', "$ave secs over $RunningDone GETs");
	}
	if ( $TotalDone )
	{	
		$ave = sprintf "%5.2f", $TotalTime / ($TotalDone*1000);
		$MainWindowProgress2->delete('1.0', end);
		$aave = sprintf "%4.1f", ($TotalDone*1000) / (LoadWorm->GetTickCount()-$StartingTime);
		$MainWindowProgress2->insert('1.0', " $ave  $TotalDone GETs at $aave/sec");
	}
}
