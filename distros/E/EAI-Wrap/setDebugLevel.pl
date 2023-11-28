use EAI::Common; use strict; use feature 'unicode_strings';

my %levels = ("f" => "FATAL", "e" => "ERROR", "i" => "INFO", "d" => "DEBUG", "t" => "TRACE");
my %appenders = ("s" => "SCREEN", "m" => "MAIL", "f" => "FILE");
# set up using site.config
$EAI_WRAP_CONFIG_PATH = ($ENV{EAI_WRAP_CONFIG_PATH} ? $ENV{EAI_WRAP_CONFIG_PATH} : "");
EAI::Common::readConfigFile($EAI_WRAP_CONFIG_PATH."/site.config") if -e $EAI_WRAP_CONFIG_PATH."/site.config";
EAI::Common::readConfigFile($_) for sort glob($EAI_WRAP_CONFIG_PATH."/additional/*.config");
my ($homedirnode) = (File::Basename::dirname(File::Spec->rel2abs((caller(0))[1])) =~ /^.*[\\\/](.*?)$/);
my $env = $config{folderEnvironmentMapping}{$homedirnode};
if (!$env) {
	# if not configured, use default mapping (usually ''=>"Prod" for production)
	$env = $config{folderEnvironmentMapping}{''};
}
my $logconfig;
if ($config{prodEnvironmentInSeparatePath}) {
	$logconfig = "$ENV{EAI_WRAP_CONFIG_PATH}/$env/log.config";
} else {
	$logconfig = $ENV{EAI_WRAP_CONFIG_PATH}.($config{folderEnvironmentMapping}{$homedirnode} ? '/'.$config{folderEnvironmentMapping}{$homedirnode} : "").'/log.config';
}

# main loop: read log.config and write back changes made by user choices
while (1) {
	system $^O eq 'MSWin32' ? 'cls' : 'clear'; # clear screen first
	my $data = read_file ($logconfig);
	my (@datalines, $i,%toChange, %levelToChange);
	if ($data) {
		@datalines = split('\n',$data);
		$i=1;
		# print loggers with levels to screen, collecting them for later change
		print "Use setDebugLevel to change the following entries from $logconfig (enter 0 to switch to common log.config and back):\n\n";
		do {
			print "$i: $datalines[$i-1]\n";
			($toChange{$i},$levelToChange{$i}) = ($datalines[$i-1] =~ /(.+?) = (.+?)$/) if $datalines[$i-1] =~ /(.+?) = (.+?)$/;
			($toChange{$i},$levelToChange{$i}) = ($datalines[$i-1] =~ /(.+?) = (.+?),.*$/) if $datalines[$i-1] =~ /(.+?) = (.+?),.*$/;
			$i+=1;
		} until($datalines[$i-1] eq "" or $datalines[$i-1] eq "\r");
		# ask user for choices of logger to change
		print "\nenter first logger (1..".($i-1).") or (#) to invert comments globally,\nthen level to change to ((F)ATAL, (E)RROR, (I)NFO, (D)EBUG, (T)RACE) or (#) to comment the logger in/out,\nand finally optional appenders ((S)CREEN, (M)AIL, (F)ILE) not for rootLogger!), only possible with changing the level.\n(no entry ends the program):";
	} else {
		print "no log.config found in $logconfig (enter 0 to switch to common log.config and back):\n\n";
	}
	my $choice= <STDIN>; chomp $choice;
	last if $choice eq ""; # break out of loop
	my ($loggerToChange,$level,$appenders) = ($choice =~ /^(.)(.)(.*?)$/);
	my @appenders = split(//,lc($appenders)); $appenders = "";
	for (@appenders) {
		if ($appenders{$_}) {
			$appenders.=", ".$appenders{$_};
		} else {
			print "invalid choice made for appender ($_), will be ignored.\npress enter";
			<STDIN>;
		}
	}
	# switch to common log.config and back
	if ($choice eq "0") {
		if ($logconfig ne "$ENV{EAI_WRAP_CONFIG_PATH}/log.config") {
			$logconfig = "$ENV{EAI_WRAP_CONFIG_PATH}/log.config";
		} else {
			$logconfig = "$ENV{EAI_WRAP_CONFIG_PATH}/$env/log.config";
		}
		next;
	}
	if ($data) {
		# globally invert comments if the only input is #
		if ($choice eq "#") {
			$i=0;
			do {
				if ($datalines[$i] =~ /^#.+$/) {
					$datalines[$i] =~ s/#//;
					$data =~ s/^#$datalines[$i]$/$datalines[$i]/gm;
				} else {
					$data =~ s/^$datalines[$i]$/#$datalines[$i]/gm;
				}
				$i+=1;
			} until($datalines[$i] eq "" or $datalines[$i] eq "\r");
		} else {
			print "you have to enter at least two choices or only # for inverting comments\n" if !$level and !$loggerToChange;
			print "invalid choice made for level ($level), available:".join(" ",%levels)."\n" if !$levels{$level} and $toChange{$loggerToChange};
			print "invalid choice made for logger to change ($loggerToChange)\n" if !$toChange{$loggerToChange} and $levels{$level};
			# now change it in the log.config
			if ($level eq "#") {
				# toggle comment for this logger
				if ($toChange{$loggerToChange} =~ /^#.+$/) {
					$toChange{$loggerToChange} =~ s/#//;
					$data =~ s/^#$toChange{$loggerToChange} = (.*?)$/$toChange{$loggerToChange} = $1/gm;
				} else {
					$data =~ s/^$toChange{$loggerToChange} = (.*?)$/#$toChange{$loggerToChange} = $1/gm;
				}
			} elsif ($toChange{$loggerToChange} and $levels{$level}) {
				# change level and appenders (except for root logger)
				if ($toChange{$loggerToChange} =~ /rootLogger/) {
					$data =~ s/^$toChange{$loggerToChange} = $levelToChange{$loggerToChange}(.*?)$/$toChange{$loggerToChange} = $levels{$level}$1/gm;
				} else {
					$data =~ s/^$toChange{$loggerToChange} = $levelToChange{$loggerToChange}(.*?)$/$toChange{$loggerToChange} = $levels{$level}$appenders/gm;
				}
			} else {
				print "press enter";
				<STDIN>;
				next;
			}
		}
		# and write back
		write_file($logconfig, $data);
	}
}

sub read_file {
	my ($filename) = @_;

	open my $in, '<:encoding(UTF-8)', $filename or do {
		print "Could not open '$filename' for reading $!\n";
		return;
	};
	binmode($in);
	local $/ = undef;
	my $all = <$in>;
	close $in;

	return $all;
}

sub write_file {
	my ($filename, $content) = @_;

	open my $out, '>:encoding(UTF-8)', $filename or do {
		print "Could not open '$filename' for writing $!\n";
		return;
	};
	binmode($out);
	print $out $content;
	close $out;

	return;
}
__END__
=head1 NAME

setDebugLevel.pl - small UI for setting debug levels and appenders for the various loggers (main script, and each EAI::Wrap package)

=head1 SYNOPSIS

 setDebugLevel.pl

=head1 DESCRIPTION

Following screen (example) is offered when calling setDebugLevel (and there is a log.config in $ENV{EAI_WRAP_CONFIG_PATH}/$execute{env}, see also L<EAI::Wrap::%execute|EAI::Wrap/%execute> and L<EAI::Wrap::DESCRIPTION|EAI::Wrap/DESCRIPTION>):

 Use setDebugLevel to change the following entries from $ENV{EAI_WRAP_CONFIG_PATH}/$execute{env}/log.config (enter 0 to switch to common log.config and back):

 1: log4perl.rootLogger = INFO, FILE, SCREEN, MAIL
 2: #log4perl.logger.main = DEBUG
 3: #log4perl.logger.EAI.Wrap = DEBUG
 4: #log4perl.logger.EAI.DB = DEBUG
 5: #log4perl.logger.EAI.FTP = DEBUG
 6: #log4perl.logger.EAI.File = DEBUG
 7: #log4perl.logger.EAI.Common = DEBUG
 
 enter first logger (1..7) or (#) to invert comments globally,
 then level to change to ((F)ATAL, (E)RROR, (I)NFO, (D)EBUG, (T)RACE) or (#) to comment the logger in/out,
 and finally optional appenders ((S)CREEN, (M)AIL, (F)ILE) not for rootLogger!), only possible with changing the level.
 (no entry ends the program):

use entries to manipulate log.config in the described way, e.g. 1t to enable general tracing, 2# to uncomment the main logger (which then overrides the rootLoggers INFO level), 3e to set log leverl to error for EAI::Wrap (to enable this logger you have to uncomment it with 3# !).

=head1 COPYRIGHT

Copyright (c) 2023 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut