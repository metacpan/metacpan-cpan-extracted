use strict; use EAI::Wrap;

my $defaultSplitcharacter = "\t"; # default character that splits log entries
my $curDate = get_curdate();
my $curDateDash = get_curdate_gen("Y/M/D");
my $curhyphenDate = get_curdate_gen("Y-M-D");
my $curdotDate = get_curdate_dot();
my $curTime = "00".get_curtime_HHMM()."00";

setupConfigMerge();

my $logger = get_logger();
$logger->info(">>>>>>> starting logcheck, curDate: $curDate, curDateDash: $curDateDash, curhyphenDate: $curhyphenDate, curdotDate: $curdotDate, curTime: $curTime, weekday(curDate):".weekday($curDate).",is_last_day_of_month(curDate):".is_last_day_of_month($curDate));
my $beginOfDay = timelocal_modern(0,0,0,localtime->mday(), localtime->mon(), localtime->year()+1900);
my $fileAge = (stat("$execute{homedir}/alreadyProcessedLogErrors.txt"))[9];
# remove yesterdays doneError information on first run of day
if (-e "$execute{homedir}/alreadyProcessedLogErrors.txt" and $fileAge < $beginOfDay) {
	unlink "$execute{homedir}/alreadyProcessedLogErrors.txt" or $logger->error("couldn't remove $execute{homedir}/alreadyProcessedLogErrors.txt: $@");
}

# read doneError information later for each check
my %doneError;
if (-e "$execute{homedir}/alreadyProcessedLogErrors.txt") {
	open (DONE, "<$execute{homedir}/alreadyProcessedLogErrors.txt") or $logger->error("error opening $execute{homedir}/alreadyProcessedLogErrors.txt: $@");
	while (<DONE>) {
		chomp($_);
		$doneError{$_} = 1;
	}
	close DONE;
}

LOGCHECK:
foreach my $job (keys %{$config{checkLookup}}) {
	next LOGCHECK if $job eq "checkLogExist.pl"; # don't check our own logfile, configuration only for own error emailing (e.g from setupConfigMerge)
	my $splitcharacter = ($config{checkLookup}{$job}{splitcharacter} ? $config{checkLookup}{$job}{splitcharacter} : $defaultSplitcharacter);
	# delayed checking for environments/specific jobs, either general $config{checkLogExistDelay}{$execute{env}} or job specific $config{checkLookup}{$job}{checkLogExistDelay}{$execute{env}}:
	my $checkLogExistDelay = (defined($config{checkLookup}{$job}{checkLogExistDelay}{$execute{env}}) ? $config{checkLookup}{$job}{checkLogExistDelay}{$execute{env}} : (defined($config{checkLogExistDelay}{$execute{env}}) ? $config{checkLogExistDelay}{$execute{env}} : 0));
	my $freqToCheck = $config{checkLookup}{$job}{freqToCheck}; # frequency to check log file (business-daily, daily, monthly, etc.), default (if not given): every business day
	$freqToCheck = "B" if !$freqToCheck;
	my $timeToCheck = $config{checkLookup}{$job}{timeToCheck}; # earliest time to check log start entry
	my $logFileToCheck = $config{checkLookup}{$job}{logFileToCheck}; # Logfile to be searched
	my $logRootPath = ($config{checkLookup}{$job}{logRootPath} ne "" ? $config{checkLookup}{$job}{logRootPath} : $config{logRootPath}{""}); # default log root path
	my $prodEnvironmentInSeparatePath = ($config{checkLookup}{$job}{prodEnvironmentInSeparatePath} ne "" ? $config{checkLookup}{$job}{prodEnvironmentInSeparatePath} : $config{prodEnvironmentInSeparatePath});
	my $mailsendTo = ($execute{envraw} ? $config{testerrmailaddress} : $config{checkLookup}{$job}{errmailaddress});
	# amend logfile path with environment, depending on prodEnvironmentInSeparatePath:
	if ($prodEnvironmentInSeparatePath) {
		$logFileToCheck = $logRootPath.'/'.$execute{env}.'/'.$logFileToCheck;
	} else {
		$logFileToCheck = $logRootPath.($execute{envraw} ? '/'.$execute{envraw} : "").'/'.$logFileToCheck;
	}
	my $logcheck = $config{checkLookup}{$job}{logcheck}; # Logcheck (regex)
	
	$logger->info("preparing logcheck for $job, freqToCheck:$freqToCheck, timeToCheck:$timeToCheck, logFileToCheck:$logFileToCheck, logcheck regex:/$logcheck/");
	if ($freqToCheck eq "B" and (is_weekend($curDate) || is_holiday($config{logCheckHoliday},$curDate))) {
		$logger->info("IGNORING logcheck as freqToCheck eq B and is_weekend($curDate)=".is_weekend($curDate)." || is_holiday(".$config{logCheckHoliday}.",$curDate)=".is_holiday($config{logCheckHoliday},$curDate));
		next LOGCHECK;
	}
	if ($freqToCheck eq "M1" and $curDate !~ /\d{4}\d{2}01/) {
		$logger->info("IGNORING logcheck as freqToCheck eq M1 and curDate ($curDate) !~ /\d{4}\d{2}01/");
		next LOGCHECK;
	}
	if ($freqToCheck eq "Q" and $curDate !~ /\d{4}0102/ and $curDate !~ /\d{4}0401/ and $curDate !~ /\d{4}0701/ and $curDate !~ /\d{4}1001/) {
		$logger->info("IGNORING logcheck as freqToCheck eq Q and curDate ($curDate) !~ /\d{4}0102/ and curDate !~ /\d{4}0401/ and curDate !~ /\d{4}0701/ and curDate !~ /\d{4}1001/");
		next LOGCHECK;
	}
	if ($freqToCheck eq "ML" and !is_last_day_of_month($curDate)) {
		$logger->info("IGNORING logcheck as freqToCheck eq ML and !is_last_day_of_month($curDate)=".is_last_day_of_month($curDate));
		next LOGCHECK;
	}
	if (substr($freqToCheck,0,1) eq "W" and !(weekday($curDate) eq substr($freqToCheck,1,1))) {
		$logger->info("IGNORING logcheck as substr($freqToCheck,0,1) eq W and !(weekday($curDate) (".weekday($curDate).") eq substr($freqToCheck,1,1))");
		next LOGCHECK;
	}
	if (substr($freqToCheck,0,2) eq "MW" and !(first_weekYYYYMMDD($curDate,substr($freqToCheck,2,1)))) {
		$logger->info("IGNORING logcheck as substr($freqToCheck,0,2) eq MW and !(first_weekYYYYMMDD($curDate,substr($freqToCheck,2,1)))");
		next LOGCHECK;
	}
	my $checkTime = formatTime(make_time($timeToCheck."00",60*$checkLogExistDelay),"%02d%02d%02d%02d");
	if ($checkTime gt $curTime) {
		$logger->info("IGNORING logcheck as timeToCheck ($timeToCheck) + checkLogExistDelay ($checkLogExistDelay) minutes (totals to $checkTime) is greater than curTime ($curTime)");
		next LOGCHECK;
	}
	# for non prod environments
	if ($execute{envraw}) {
		# ignore some jobs in non prod environments
		if ($config{logs_to_be_ignored_in_nonprod} ne "" and $job =~ $config{logs_to_be_ignored_in_nonprod}) {
			$logger->info("IGNORING logcheck as environment not Production and non production logs are to be ignored for $job due to match with ".$config{logs_to_be_ignored_in_nonprod});
			next LOGCHECK;
		}
	}
	my $infos = " is missing for job $job:\n";
	my $lastLogFile = $logFileToCheck;
	my $logAppender = Log::Log4perl->appenders()->{"FILE"}->{"appender"} if Log::Log4perl->appenders() and Log::Log4perl->appenders()->{"FILE"};
	if ($logAppender) {
		my $logprefix = get_curdate();
		unless ($logAppender->isa("Log::Dispatch::FileRotate")) {
			$@ = ""; # reset bogus error messages from Log::Log4perl::init
			eval {$logprefix = $config{logprefixForLastLogfile}->()} if $config{logprefixForLastLogfile};
			$logger->warn("error getting logprefix from \$config{logprefixForLastLogfile}: $@") if $@;
			# if mail is watched next day, the rolled file is in $LogFPathDayBefore. Depending on appender, either append ".1" to filename or prepend $logprefix to it (default assume a date rotator, with current date in format yyyymmdd)
			$lastLogFile =~ s/^(.+?[\\\/])([^\\\/]+?)$/$1$curDate\.$2/;
		} else {
			$lastLogFile .= ".1";
		}
	}
	if (open (LOGFILE, "<$logFileToCheck")) {
		# check log file for log check pattern, assumption tab separated!
		while (<LOGFILE>){
			my $wholeLine = $_;
			my @logline = split $splitcharacter;
			# found, if log check pattern matches and date today, either YYYY/MM/DD or "german" logs using dd.mm.yyyy or log4j using YYYY-MM-DD
			if (($logline[0] =~ /$curDateDash/ or $logline[0] =~ /$curdotDate/ or $logline[0] =~ /$curhyphenDate/) and $wholeLine =~ /$logcheck/) {
				$logger->info("logcheck '".$logcheck."' successful, row:".$wholeLine);
				if ($doneError{$job}) {
					$infos = "The log starting entry in logfile $logFileToCheck was found now.\njob: <$job>, frequency: ".$freqToCheck.", time to check: ".$timeToCheck;
					$doneError{$job} = 0;
					$logger->info("logcheck successful for originally failed '".$job."', sending mail to: '".$mailsendTo);
					#            sendGeneralMail($From, $To, $Cc, $Bcc, $Subject, $Data, $Type, $Encoding, $AttachType, $AttachFile)
					EAI::Common::sendGeneralMail("", $mailsendTo,"","","Resolved the starting problem for $job",$infos,'text/plain');
				}
				close LOGFILE; next LOGCHECK;
			}
		}
		$logger->info("$logcheck wasn't found in $logFileToCheck on a line starting with $curDateDash or $curdotDate or $curhyphenDate");
		$infos = "The log starting entry in logfile $logFileToCheck".$infos;
	} else {
		$infos = "The logfile $logFileToCheck".$infos;
	}
	close LOGFILE;
	# send mail for not found log entries
	# insert $curDate before file name with a dot
	unless ($doneError{$job}) {
		$infos = $infos."\njob: <$job>, frequency: ".$freqToCheck.", time to check: ".$timeToCheck.", log in file file:///".$logFileToCheck." resp. file:///".$lastLogFile;
		$logger->warn("failed logcheck for '".$job."', sending mail to: '".$mailsendTo);
		#            sendGeneralMail($From, $To, $Cc, $Bcc, $Subject, $Data, $Type, $Encoding, $AttachType, $AttachFile)
		EAI::Common::sendGeneralMail("", $mailsendTo,"","","Starting problem detected for $job",$infos,'text/plain');
		$doneError{$job} = 1;
	}
}
my $jobErrors = "";
for (sort keys(%doneError)) {
	$jobErrors .= "$_\n" if $doneError{$_};
}
open (DONE, ">$execute{homedir}/alreadyProcessedLogErrors.txt") or $logger->error("couldn't write to $execute{homedir}/alreadyProcessedLogErrors.txt: $@");
print DONE $jobErrors;
close DONE;
__END__
=head1 NAME

checkLogExist.pl - checks Log-entries at given times

=head1 SYNOPSIS

 checkLogExist.pl

=head1 DESCRIPTION

checkLogExist is supposed to be called frequently in a separate timed job and checks if defined log entries exist in the defined log files, (hinting that the task was run/started), respectively whether the logfile exists at all. Missing logfiles or missing entries are being notified by e-mail, for multiple runs of checkLogExist already notified log check failures are stored to avoid too much error e-mails.

Configuration is done in sub-hash C<$config{checkLookup}>, being the same place for the errmailaddress/errmailsubject of error mails being sent in the tasks themselves:

 $config{checkLookup} = {
  <nameOfJobscript.pl> => {
     errmailaddress => "test\@test.com",
     errmailsubject => "testjob failed",
     timeToCheck => "0800",
     freqToCheck => "B",
     logFileToCheck => "test.log",
     logcheck => "started.*",
     logRootPath => "optional alternate logfile path"
   },
  <...> => {
     
   },
 }

The key consists of the scriptname + any additional defined interactive options, which are being passed to the script in an alphabetically sorted manner. For checkLogExist.pl the key is irrelevant as all entries of C<$config{checkLookup}> are worked through.

=over 4

=item errmailaddress 

where should the mail be sent to in case of non-existence of logfile/logline or an error in the script.

=item errmailsubject

subject-line for error mail, only used for error mail sending in the task scripts themselves.

=item timeToCheck

all checks earlier than this are ignored, given in format HHMM.

=item freqToCheck

ignore log check except on: ML..Monthend, D..every day, B..Business days, M1..Month-beginning, W{n}..Weekday (n:1=Sunday-7=Saturday)

=item logFileToCheck

Where (which logfile) should the job have written into ? this logfile is expected either in the logRootPath configured in site.config or in logRootPath configured for this locgcheck entry (see below).

=item logcheck

"regex keyword/expression" to compare the rows, if this is missing in the logfile after the current date/timeToCheck then an alarm is sent to the configured errmailaddress

=item logRootPath

instead of using the logRootPath configured in site.config, a special logRootPath can be optionally configured here for each log check.

=item checkLogExistDelay

hash of environment => delay entries, delay (in minutes) will be added to timeToCheck when checkLogExist is executed in this environment to cater for later executions in this environment

=item prodEnvironmentInSeparatePath

set to 1 if the production and other environments logs for this scriptname are in separate Paths defined by folderEnvironmentMapping (prod=root/Prod, test=root/Test, etc.), set to 0 if the production log is in the root folder and all other environments are below that folder (prod=root, test=root/Test, etc.)

=item splitcharacter

character being used to separate the log entries of this logfile into columns (date, user, process, message, etc.)

=back

=head1 COPYRIGHT

Copyright (c) 2023 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut