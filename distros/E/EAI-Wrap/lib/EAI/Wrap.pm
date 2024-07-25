package EAI::Wrap 1.915;

use strict; use feature 'unicode_strings'; use warnings;
use Exporter qw(import); use Data::Dumper qw(Dumper); use File::Copy qw(copy move); use Cwd qw(chdir); use Archive::Extract ();
# we make $EAI::Common::common/config/execute/loads/optload/opt an alias for $EAI::Wrap::common/config/execute/loads/optload/opt so that the user can set it without knowing anything about the Common package!
our %common;our %config;our @loads;our %execute;our @optload;our %opt;

BEGIN {
	*EAI::Common::common = \%common;
	*EAI::Common::config = \%config;
	*EAI::Common::execute = \%execute;
	*EAI::Common::loads = \@loads;
	*EAI::Common::optload = \@optload;
	*EAI::Common::opt = \%opt;
};
use EAI::Common; use EAI::DateUtil; use EAI::DB; use EAI::File; use EAI::FTP;

our @EXPORT = qw(%common %config %execute @loads @optload %opt removeFilesinFolderOlderX openDBConn openFTPConn redoFiles getLocalFiles getFilesFromFTP getFiles checkFiles extractArchives getAdditionalDBData readFileData dumpDataIntoDB markProcessed writeFileFromDB writeFileFromMemory putFileInLocalDir markForHistoryDelete uploadFileToFTP uploadFileCMD uploadFile processingEnd processingPause processingContinues standardLoop moveFilesToHistory deleteFiles
monthsToInt intToMonths addLocaleMonths get_curdate get_curdatetime get_curdate_dot formatDate formatDateFromYYYYMMDD get_curdate_dash get_curdate_gen get_curdate_dash_plus_X_years get_curtime get_curtime_HHMM get_lastdateYYYYMMDD get_lastdateDDMMYYYY is_first_day_of_month is_last_day_of_month get_last_day_of_month weekday is_weekend is_holiday is_easter addCalendar first_week first_weekYYYYMMDD last_week last_weekYYYYMMDD convertDate convertDateFromMMM convertDateToMMM convertToDDMMYYYY addDays addDaysHol addMonths subtractDays subtractDaysHol convertcomma convertToThousendDecimal get_dateseries parseFromDDMMYYYY parseFromYYYYMMDD convertEpochToYYYYMMDD make_time formatTime get_curtime_epochs localtime timelocal_modern
newDBH beginWork commit rollback readFromDB readFromDBHash doInDB storeInDB deleteFromDB updateInDB getConn setConn
readText readExcel readXML writeText writeExcel
removeFilesOlderX fetchFiles putFile moveTempFile archiveFiles removeFiles login getHandle setHandle
readConfigFile getSensInfo setupConfigMerge getOptions setupEAIWrap setErrSubject dumpFlat extractConfigs checkHash checkParam setupLogging checkStartingCond sendGeneralMail
get_logger Dumper);

# initialize module, reading all config files and setting basic execution variables
sub INIT {
	# read site config, additional configs and sensitive config in alphabetical order (allowing precedence)
	STDOUT->autoflush(1);
	$EAI_WRAP_CONFIG_PATH = ($ENV{EAI_WRAP_CONFIG_PATH} ? $ENV{EAI_WRAP_CONFIG_PATH} : "");
	$EAI_WRAP_SENS_CONFIG_PATH = ($ENV{EAI_WRAP_SENS_CONFIG_PATH} ? $ENV{EAI_WRAP_SENS_CONFIG_PATH} : "");
	$EAI_WRAP_CONFIG_PATH =~ s/\\/\//g;
	$EAI_WRAP_SENS_CONFIG_PATH =~ s/\\/\//g;
	print STDOUT "EAI_WRAP_CONFIG_PATH: ".($EAI_WRAP_CONFIG_PATH ? $EAI_WRAP_CONFIG_PATH : "not set").", EAI_WRAP_SENS_CONFIG_PATH: ".($EAI_WRAP_SENS_CONFIG_PATH ? $EAI_WRAP_SENS_CONFIG_PATH : "not set")."\n";
	readConfigs();
	
	$execute{homedir} = File::Basename::dirname(File::Spec->rel2abs((caller(0))[1])); # folder, where the main script is being executed.
	$execute{scriptname} = File::Basename::fileparse((caller(0))[1]);
	my ($homedirnode) = ($execute{homedir} =~ /^.*[\\\/](.*?)$/);
	print STDOUT "\$execute{homedir}: $execute{homedir}, \$execute{scriptname}: $execute{scriptname}, \$homedirnode: $homedirnode\n";
	$execute{envraw} = $config{folderEnvironmentMapping}{$homedirnode};
	my $modulepath = File::Basename::dirname(File::Spec->rel2abs(__FILE__)); # get this module's folder as additional folderEnvironmentMapping.
	$execute{envraw} = $config{folderEnvironmentMapping}{$modulepath} if !$execute{envraw}; # if nothing found check if modulepath is configured to get envraw from there...
	if ($execute{envraw}) {
		$execute{env} = $execute{envraw};
		readConfigs($execute{envraw}); # read configs again for different environment
	} else {
		# if not configured, use default mapping (usually ''=>"Prod" for production)
		$execute{env} = $config{folderEnvironmentMapping}{''};
	}

	EAI::Common::getOptions(); # getOptions before logging setup as centralLogHandling depends on interactive options passed. Also need options to be present for executeOnInit
	doExecuteOnInit();
	$execute{failcount}=0;
	EAI::Common::setupLogging();
	EAI::Common::setErrSubject("starting process");
}

# read configs from EAI_WRAP_CONFIG_PATH/site.config, EAI_WRAP_CONFIG_PATH/additional/*.config (if existing) and EAI_WRAP_SENS_CONFIG_PATH/*.config (if existing)
# if argument envraw given, read EAI_WRAP_CONFIG_PATH/envraw/site.config, and additionally to above EAI_WRAP_CONFIG_PATH/envraw/additional/*.config (if existing) and EAI_WRAP_SENS_CONFIG_PATH/envraw/*.config (if existing), because config is set new by reading EAI_WRAP_CONFIG_PATH/envraw/site.config
sub readConfigs (;$) {
	my $envraw = ($_[0] ? $_[0]."/" : "");
	EAI::Common::readConfigFile("$EAI_WRAP_CONFIG_PATH/${envraw}site.config") if -e "$EAI_WRAP_CONFIG_PATH/${envraw}site.config";
	EAI::Common::readConfigFile($_) for sort glob qq{"$EAI_WRAP_CONFIG_PATH/additional/*.config"};
	EAI::Common::readConfigFile($_) for sort glob qq{"$EAI_WRAP_SENS_CONFIG_PATH/*.config"};
	if ($envraw) {
		EAI::Common::readConfigFile($_) for sort glob qq{"$EAI_WRAP_CONFIG_PATH/${envraw}additional/*.config"};
		EAI::Common::readConfigFile($_) for sort glob qq{"$EAI_WRAP_SENS_CONFIG_PATH/${envraw}*.config"};
	}
}

sub doExecuteOnInit () {
	if ($config{executeOnInit}) {
		print STDOUT "doing executeOnInit\n";
		if (ref($config{executeOnInit}) eq "CODE") {
			eval {$config{executeOnInit}->()};
		} else {
			eval $config{executeOnInit};
		}
		die("Error parsing config{executeOnInit} ".(ref($config{executeOnInit}) eq "CODE" ? "defined sub" : "'".$config{executeOnInit}."'").": $@") if $@;
	}
}

# open a DB connection
sub openDBConn ($;$) {
	my $arg = shift;
	my $enforceConn = shift;
	my $logger = get_logger();
	my ($DB,$process) = EAI::Common::extractConfigs("opening DB connection",$arg,"DB","process");
	# only for set prefix, take username and password from $config{sensitive}{$DB->{prefix}}
	if ($DB->{prefix}) {
		$DB->{user} = EAI::Common::getSensInfo($DB->{prefix},"user");
		$DB->{pwd} = EAI::Common::getSensInfo($DB->{prefix},"pwd");
	}
	my ($DSNeval, $newDSN);
	$DSNeval = $DB->{DSN};
	if ($enforceConn) {
		$logger->info("enforced DB reconnect");
		# close connection to reopen when enforced connect
		$EAI::DB::DSN = "";
	} else {
		return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /\QopenDBConn$DSNeval/ and $execute{retryBecauseOfError};
	}
	unless ($DSNeval) {
		$logger->error("no DSN available in \$DB->{DSN}");
		$process->{hadErrors} = 1;
		return 0;
	}
	(!$DB->{user} && $DSNeval =~ /\$DB->\{user\}/) and do {
		$logger->error("specified DSN ('".$DSNeval."') contains \$DB->{user}, which is neither set in \$DB->{user} nor in \$config{sensitive}{".$DB->{prefix}."}{user} !");
		$process->{hadErrors} = 1;
		return 0;
	};
	$newDSN = eval qq{"$DSNeval"};
	if (!$newDSN) {
		$logger->error("error parsing \$DB->{DSN}(".$DSNeval."), couldn't interpolate all values:".$@);
		$process->{hadErrors} = 1;
		return 0;
	}
	EAI::DB::newDBH($DB,$newDSN) or do {
		$logger->error("couldn't open database connection for $newDSN");
		$process->{hadErrors} = 1;
		return 0; # false means error in connection and signal to die...
	};
	$process->{successfullyDone}.="openDBConn".$DSNeval;
	return 1;
}

# open a FTP connection
sub openFTPConn ($;$) {
	my $arg = shift;
	my $enforceConn = shift;
	my $logger = get_logger();
	my ($FTP,$process) = EAI::Common::extractConfigs("opening FTP connection",$arg,"FTP","process");
	my $hostname = $FTP->{remoteHost};
	$hostname = $FTP->{remoteHost}{$execute{env}} if ref($FTP->{remoteHost}) eq "HASH";
	if ($enforceConn) {
		$logger->info("enforced FTP connect");
	} else {
		# don't connect if redo from local file
		return 1 if $common{task}{redoFile};
	}
	# only for set prefix, take username, password, hostkey and privKey from $config{sensitive}{$FTP->{prefix}} (directly or via environment hash)
	if ($FTP->{prefix}) {
		$FTP->{user} = EAI::Common::getSensInfo($FTP->{prefix},"user");
		$FTP->{pwd} = EAI::Common::getSensInfo($FTP->{prefix},"pwd");
		$FTP->{hostkey} = EAI::Common::getSensInfo($FTP->{prefix},"hostkey");
		$FTP->{hostkey2} = EAI::Common::getSensInfo($FTP->{prefix},"hostkey2");
		$FTP->{privKey} = EAI::Common::getSensInfo($FTP->{prefix},"privKey");
	}
	(!$FTP->{user}) and do {
		$logger->error("ftp user neither set in \$FTP->{user} nor in \$config{sensitive}{".$FTP->{prefix}."}{user} !");
		$process->{hadErrors} = 1;
		return 0;
	};
	no warnings 'uninitialized';
	$logger->debug("\$FTP->{user}:$FTP->{user}, \$FTP->{privKey}:$FTP->{privKey}, \$FTP->{hostkey}:$FTP->{hostkey}");
	EAI::FTP::login($FTP,$hostname,$enforceConn) or do {
		$logger->error("couldn't open ftp connection for $hostname");
		$process->{hadErrors} = 1;
		return 0; # false means error in connection and signal to die...
	};
	$process->{successfullyDone}.="openFTPConn".$hostname;
	return 1; 
}

# remove all files in FTP server folders that are older than a given day/month/year
sub removeFilesinFolderOlderX ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($FTP,$process) = EAI::Common::extractConfigs("Cleaning of Archive folders",$arg,"FTP","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /removeFilesOlderX/ and $execute{retryBecauseOfError};
	if (EAI::FTP::removeFilesOlderX($FTP)) {
		$process->{successfullyDone}.="removeFilesOlderX";
		return 1;
	} else {
		return 0;
	}
}

# redo file from redo directory if specified (used in getLocalFile and getFileFromFTP)
sub redoFiles ($) {
	my $arg = shift;
	my $logger = get_logger();
	return unless $common{task}{redoFile};
	my ($File) = EAI::Common::extractConfigs("setting/renaming redo files",$arg,"File");
	my $redoDir = $execute{redoDir};
	# file extension for local redo 
	my ($barename,$ext) = $File->{filename} =~ /(.*)\.(.*?)$/; # get file bare name and extension from filename
	if (!$ext) {
		$ext = $File->{extension}; # if no dots in filename (e.g. because of glob) -> no file extension retrievable -> take from here
	}
	if (!$ext) {
		$logger->error("redoFile set, no file extension for renaming redo files! should be either retrievable in filename as .<ext> or be set separately in File=>extension");
		return 0;
	}
	$logger->info("redoFile set, redoing files in ".$redoDir.", looking for files with extension ".$ext);
	if ($File->{filename} =~ /\*/) {
		$barename = $File->{filename}; 
		$barename =~ s/\*.*$//g; # remove glob pattern and quote dots to allow matching with redo file
	}
	if (chdir($redoDir)) {
		my $globPattern = $barename."*".($ext ? ".$ext" : ""); # extend glob with .$ext only if defined
		$logger->debug("checking against glob pattern ".$globPattern);
		for my $redofile (glob qq{"$globPattern"}) { #qq{}, um Ergebnis des interpolierten $globPattern in hochkomma einzuschliessen, weil glob leerzeichen als trennzeichen interpretiert und dann pfade/files mit leerzeichen geglobbed werden.
			$logger->debug("found candidate file $redofile in $redoDir");
			my $redoTimestampPatternPart = $common{task}{redoTimestampPatternPart};
			if (!$redoTimestampPatternPart) {
				$redoTimestampPatternPart = '[\d_]'; # sensible default, but warn...
				$logger->warn('missing $common{task}{redoTimestampPatternPart}, set to [\d_]');
			}
			# check against barename with additional timestamp pattern (e.g. numbers and _) and \.$ext only if defined
			# anything after barename (and before ".$ext" if extension defined) is regarded as a timestamp
			my $regexCheck = ($ext ? qr/$barename($redoTimestampPatternPart|$redoDir)*\.$ext/ : qr/$barename($redoTimestampPatternPart|$redoDir)*.*/);
			$logger->debug("checking candidate against regex ".$regexCheck);
			if ($redofile =~ $regexCheck) {
				$logger->info("file $redofile available for redo, matched regex $barename.*");
				# only rename if not prohibited and not a glob, else just push into retrievedFiles
				if (!$File->{avoidRenameForRedo} and $File->{filename} !~ /\*/) {
					rename $redofile, "$barename.$ext" or $logger->error("error renaming file $redofile to $barename.$ext : $!");
					push @{$execute{retrievedFiles}}, "$barename.$ext";
				} else {
					push @{$execute{retrievedFiles}}, $redofile;
				}
			}
		}
	} else {
		$logger->error("couldn't change into redo folder ".$redoDir." !");
		return 0;
	}
	chdir($execute{homedir});
	return checkFiles($arg);
}

# get local file(s) from source into homedir
sub getLocalFiles ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("Getting local files",$arg,"File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /getLocalFiles/ and $execute{retryBecauseOfError};
	@{$execute{retrievedFiles}} = (); # reset last retrieved
	if ($File->{localFilesystemPath}) {
		my $localFilesystemPath = $File->{localFilesystemPath};
		$localFilesystemPath.="/" if $localFilesystemPath !~ /^.*\/$/;
		if ($common{task}{redoFile}) {
			return redoFiles($arg);
		} else {
			my @multipleFiles;
			if ($File->{filename} =~ /\*/) { # if there is a glob character then copy multiple files !
				if (chdir($localFilesystemPath)) {
					@multipleFiles = glob qq{"$File->{filename}"};
					chdir($execute{homedir});
				} else {
					$logger->error("couldn't change into folder ".$localFilesystemPath." !");
					$process->{hadErrors} = 1;
					return 0;
				}
			} else {
				# no glob char -> single file
				push @multipleFiles, $File->{filename};
			}
			push @{$execute{retrievedFiles}}, @multipleFiles;
			for my $localfile (@multipleFiles) {
				unless ($File->{localFilesystemPath} eq ".") {
					$logger->info("copying local file: ".$localFilesystemPath.$localfile." to ".$execute{homedir});
					copy ($localFilesystemPath.$localfile, ".") or do {
						$logger->error("couldn't copy ".$localFilesystemPath.$localfile.": $!");
						@{$execute{retrievedFiles}} = ();
						$process->{hadErrors} = 1;
						return 0;
					};
				} else {
					$logger->info("taking local file: ".$localfile." from current folder (".$execute{homedir}.")");
				}
			}
		}
	} else {
		$logger->error("no \$File->{localFilesystemPath} parameter given");
		$process->{hadErrors} = 1;
		return 0;
	}
	$process->{successfullyDone}.="getLocalFiles";
	return checkFiles($arg);
}

# get file/s (can also be a glob for multiple files) from FTP into homedir
sub getFilesFromFTP ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($FTP,$File,$process) = EAI::Common::extractConfigs("Getting files from ftp",$arg,"FTP","File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /getFilesFromFTP/ and $execute{retryBecauseOfError};
	@{$execute{retrievedFiles}} = (); # reset last retrieved, but this is also necessary to create the retrievedFiles hash entry for passing back the list from getFiles
	if (defined($FTP->{remoteDir})) {
		if ($common{task}{redoFile}) {
			return redoFiles($arg);
		} else {
			if ($File->{filename}) {
				unless (EAI::FTP::fetchFiles($FTP,{firstRunSuccess=>$execute{firstRunSuccess},homedir=>$execute{homedir},fileToRetrieve=>$File->{filename},fileToRetrieveOptional=>$File->{optional},retrievedFiles=>$execute{retrievedFiles}})) {
					$logger->warn("EAI::FTP::fetchFiles not successful");
				}
			} else {
				$logger->error("no \$File->{filename} given, can't get it from FTP");
				$process->{hadErrors} = 1;
				return 0;
			}
		}
	} else {
		$logger->error("no \$FTP->{remoteDir} parameter defined");
		$process->{hadErrors} = 1;
		return 0;
	}
	if (checkFiles($arg)) {
		$process->{successfullyDone}.="getFilesFromFTP";
		return 1;
	} else {
		return 0;
	}
}

# general procedure to get files from FTP or locally
sub getFiles ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($FTP,$File,$process) = EAI::Common::extractConfigs("",$arg,"FTP","File","process");
	if ($File->{localFilesystemPath}) {
		return getLocalFiles($arg);
	} else {
		return getFilesFromFTP($arg);
	}
}

# check files for continuation of processing and extract archives if needed
sub checkFiles ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("checking for existence of files",$arg,"File","process");
	my $redoDir = ($common{task}{redoFile} ? $execute{redoDir}."/" : "");
	my $fileDoesntExist = 0;
	if ($execute{retrievedFiles} and @{$execute{retrievedFiles}} >= 1) {
		for my $singleFilename (@{$execute{retrievedFiles}}) {
			$logger->debug("checking file: ".$redoDir.$singleFilename);
			open (CHECKFILE, "<".$redoDir.$singleFilename) or $fileDoesntExist=1;
			close CHECKFILE;
		}
	} else {
		$fileDoesntExist=1;
	}
	if ($fileDoesntExist) {
		# exceptions from error message and return false for not continuing with readFile/whatever
		if ($File->{optional} || ($execute{firstRunSuccess} && $common{task}{plannedUntil}) || $common{task}{redoFile}) {
			if ($execute{firstRunSuccess} && $common{task}{plannedUntil}) {
				$logger->warn("file ".$File->{filename}." missing with planned execution until ".$common{task}{plannedUntil}." and first run successful, skipping");
			} elsif ($File->{optional}) {
				$logger->warn("file ".$File->{filename}." missing being marked as optional, skipping");
			} elsif ($common{task}{redoFile}) {
				$logger->warn("file ".$File->{filename}." missing being retried, skipping");
			}
		} else {
			if (!$execute{retrievedFiles} or @{$execute{retrievedFiles}} == 0) {
				$logger->error("file ".$File->{filename}." was not retrieved (maybe no successful call done to getFilesFromFTP or getLocalFiles ?)");
			} else {
				$logger->error("file ".$File->{filename}." doesn't exist and is not marked as optional!");
			}
			$process->{hadErrors} = 1;
		}
		$logger->info("checking file failed");
		return 0;
	}
	# extract from files if needed
	if ($File->{extract}) {
		if (@{$execute{retrievedFiles}} == 1) {
			$logger->info("file to be extracted exists, now extracting archive");
			return extractArchives($arg);
		} else {
			$logger->error("multiple files returned (probably glob passed as filename), extracting not supported in this case");
			$process->{hadErrors} = 1;
			return 0;
		}
	}
	# add the files retrieved
	if ($execute{retrievedFiles} && @{$execute{retrievedFiles}} > 0) {
		push @{$process->{filenames}}, @{$execute{retrievedFiles}};
		$logger->info("files checked: @{$process->{filenames}}");
		return 1;
	} else {
		$logger->error("no files retrieved for checking");
		return 0;
	}
}

# extract files from archive
sub extractArchives ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($process) = EAI::Common::extractConfigs("extracting archives",$arg,"process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone}  =~ /extractArchives/ and $execute{retryBecauseOfError};
	my $redoDir = ($common{task}{redoFile} ? $execute{redoDir}."/" : "");
	if ($execute{retrievedFiles}) { 
		my $filename = $execute{retrievedFiles}[0]; # only one file expected.
		if (! -e $redoDir.$filename) {
			$logger->error($redoDir.$filename." doesn't exist for extraction");
			$process->{hadErrors} = 1;
			return 0;
		}
		$logger->info("extracting file(s) from archive package: $redoDir$filename");
		local $SIG{__WARN__} = sub { $logger->error("opening archive: ".$_[0]); }; # capturing warnings...
		my $ae;
		eval {
			$ae = Archive::Extract->new(archive => $redoDir.$filename);
		};
		unless ($ae) {
			$process->{hadErrors} = 1;
			return 0;
		}
		if (!$ae->extract(to => ($redoDir ? $redoDir : "."))) {
			$logger->error("extracting files: ".$ae->error());
			$process->{hadErrors} = 1;
			return 0;
		}
		$logger->info("extracted files: @{$ae->files}");
		push @{$process->{filenames}}, @{$ae->files};
		push @{$process->{archivefilenames}}, $filename; # archive itself needs to be removed/historized
		# reset retrievedFiles to get rid of fetched archives (not to be processed further)
		@{$execute{retrievedFiles}} = ();
	} else {
		$logger->error("no files available to extract..");
		$process->{hadErrors} = 1;
		return 0;
	}
	$process->{successfullyDone}.="extractArchives";
	return 1;
}

# get additional data from DB, optionally give ref to hash in argument $refToDataHash for returning data there (otherwise data is returned in $process->{additionalLookupData})
sub getAdditionalDBData ($;$) {
	my ($arg,$refToDataHash) = @_;
	my $logger = get_logger();
	my ($DB,$process) = EAI::Common::extractConfigs("Getting additional data from DB",$arg,"DB","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /getAdditionalDBData/ and $execute{retryBecauseOfError};
	# reset additionalLookupData to avoid strange errors in retrying run. Also needed to pass data back as reference
	%{$process->{additionalLookupData}} = ();
	if ($refToDataHash and ref($refToDataHash) ne "HASH") {
		$logger->error("passed second argument \$refToDataHash is not a ref to a hash");
		return 0;
	}
	return 0 if !checkParam($DB,"additionalLookup");
	return 0 if !checkParam($DB,"additionalLookupKeys");
	# additional lookup needed (e.g. used in addtlProcessing), if optional $refToDataHash given pass data into that?
	my $readSuccess = EAI::DB::readFromDBHash({query => $DB->{additionalLookup}, keyfields=> $DB->{additionalLookupKeys}}, ($refToDataHash ? \%{$refToDataHash} : \%{$process->{additionalLookupData}}));
	$process->{successfullyDone}.="getAdditionalDBData" if $readSuccess;
	return $readSuccess;
}

# read data from file
sub readFileData ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("reading file data",$arg,"File","process");
	my $redoDir = $execute{redoDir}."/" if $common{task}{redoFile};
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /readFileData/ and $execute{retryBecauseOfError};
	my $readSuccess;
	@{$process->{data}} = (); # reset data in case of error retries having erroneous data
	if ($File->{format_xlformat}) {
		$readSuccess = EAI::File::readExcel($File, \@{$process->{data}}, $process->{filenames}, $redoDir, $process->{countPercent});
	} elsif ($File->{format_XML}) {
		$readSuccess = EAI::File::readXML($File, \@{$process->{data}}, $process->{filenames}, $redoDir);
	} else {
		$readSuccess = EAI::File::readText($File, \@{$process->{data}}, $process->{filenames}, $redoDir, $process->{countPercent});
	}
	$process->{successfullyDone}.="readFileData" if $readSuccess;
	return $readSuccess; # return error when reading files with readFile/readExcel/readXML
}

# store data into Database
sub dumpDataIntoDB ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($DB,$File,$process) = EAI::Common::extractConfigs("storing data to DB",$arg,"DB","File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /dumpDataIntoDB/ and $execute{retryBecauseOfError};
	our $hadDBErrors = 0;
	if ($process->{data} and @{$process->{data}}) { # data supplied?
		if ($DB->{noDumpIntoDB}) {
			$logger->info("skip dumping of ".$File->{filename}." into DB");
		} else {
			my $table = $DB->{tablename};
			# Transaction begin
			unless ($DB->{noDBTransaction}) {
				EAI::DB::beginWork() or do {
					$logger->error ("couldn't start DB transaction");
					$hadDBErrors=1;
				};
			}
			# store data, tables are deleted if explicitly marked
			if ($DB->{dontKeepContent}) {
				$logger->info("removing all data from Table $table ...");
				EAI::DB::doInDB({doString => "delete from $table"});
			}
			$logger->info("dumping data to table $table");
			if (! EAI::DB::storeInDB($DB, $process->{data},$process->{countPercent})) {
				$logger->error("error storing DB data.. ");
				$hadDBErrors=1;
			}
			# post processing (Perl code) for config, where postDumpProcessing is defined
			if ($DB->{postDumpProcessing}) {
				evalCustomCode($DB->{postDumpProcessing},"postDumpProcessing",\$hadDBErrors);
			}
			# post processing (execute in DB!) for all configs, where postDumpExecs conditions and referred execs (DB scripts, that should be executed) are defined
			if (!$hadDBErrors && $DB->{postDumpExecs}) {
				$logger->info("starting postDumpExecs ... ");
				for my $postDumpExec (@{$DB->{postDumpExecs}}) {
					$logger->info("checking postDumpExec condition: ".$postDumpExec->{condition});
					my $dopostdumpexec;
					if (ref($config{executeOnInit}) eq "CODE") {
						eval {$dopostdumpexec = eval $postDumpExec->{condition}->();};
					} else {
						$dopostdumpexec = eval $postDumpExec->{condition};
					}
					if ($@) {
						$logger->error("error parsing postDumpExec condition: ".(ref($postDumpExec->{condition}) eq "CODE" ? "defined sub" : "'".$postDumpExec->{condition}."'").": $@");
						$hadDBErrors = 1;
						last;
					}
					if ($dopostdumpexec) {
						for my $exec (@{$postDumpExec->{execs}}) {
							if ($exec) { # only if defined (there could be an interpolation of perl variables, if these are contained in $exec. This is for setting $selectedDate in postDumpProcessing.
								$logger->debug("pre eval execute: $exec");
								# eval qq{"$exec"} doesn't evaluate $exec but the quoted string (to enforce interpolation where needed)
								$exec = eval qq{"$exec"} if $exec =~ /$/; # only interpolate if perl scalars are contained
								$logger->info("post execute: $exec");
								if (!EAI::DB::doInDB({doString => $exec})) {
									$logger->error("error executing postDumpExec: '".$exec."' .. ");
									$hadDBErrors=1;
									last;
								}
							}
						}
					}
				}
				$logger->info("postDumpExecs finished");
			}
			if (!$hadDBErrors) {
				# Transaction: commit of DB changes
				unless ($DB->{noDBTransaction}) {
					$logger->debug("committing data");
					if (EAI::DB::commit()) {
						$logger->info("data stored into table $table successfully");
					} else {
						$logger->error("error when committing");
						$hadDBErrors = 1;
					};
				}
			} else { # error dumping to DB or during pre/postDumpExecs
				unless ($DB->{noDBTransaction}) {
					$logger->info("Rollback because of error when storing into database");
					EAI::DB::rollback() or $logger->error("error with rollback ...");
				}
				$logger->error("error storing data into database");
				$hadDBErrors = 1;
			}
		}
	} else {
		if ($File->{emptyOK}) {
			$logger->warn("received empty data, will be ignored as \$File{emptyOK}=1");
		} else {
			my @filesdone = @{$process->{filenames}} if $process->{filenames};
			$logger->error("error as none of the following files contained any data: @filesdone !");
			$hadDBErrors = 1;
		}
	}
	$process->{successfullyDone}.="dumpDataIntoDB" if !$hadDBErrors;
	$process->{hadErrors} = $hadDBErrors if $hadDBErrors;
	return $hadDBErrors;
}

# evaluate custom code contained either in string or ref to sub
sub evalCustomCode ($$;$) {
	my ($customCode,$processingName,$hadDBErrorsRef) = @_;
	my $logger = get_logger();
	$logger->info("starting $processingName");
	if (ref($customCode) eq "CODE") {
		eval {$customCode->()};
	} else {
		my $hadDBErrors;
		eval $customCode;
		$$hadDBErrorsRef = $hadDBErrors;
	}
	$logger->error("eval of $processingName ".(ref($customCode) eq "CODE" ? "defined sub" : "'".$customCode."'")." returned error:$@") if $@;
}


# mark files as being processed depending on whether there were errors, also decide on removal/archiving of downloaded files
sub markProcessed ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("marking processed",$arg,"File","process");
	# this is important for the archival/deletion on the FTP Server!
	if ($File->{emptyOK} || !$process->{hadErrors}) {
		for (@{$process->{filenames}}) {
			$process->{filesProcessed}{$_} = 1;
			$logger->info("filesProcessed: $_");
		}
	} else {
		$process->{hadErrors} = 1;
	}
	# mark to be removed or be moved to history
	if ($File->{dontKeepHistory}) {
		push @{$execute{filesToDelete}}, @{$process->{filenames}} if $process->{filenames};
		push @{$execute{filesToDelete}}, @{$process->{archivefilenames}} if $process->{archivefilenames};
	} else {
		push @{$execute{filesToMoveinHistory}}, @{$process->{filenames}} if $process->{filenames};
		push @{$execute{filesToMoveinHistory}}, @{$process->{archivefilenames}} if $process->{archivefilenames};
	}
}

# create Data-files from Database
sub writeFileFromDB ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($DB,$File,$process) = EAI::Common::extractConfigs("creating/writing file from DB",$arg,"DB","File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /writeFileFromDB/ and $execute{retryBecauseOfError};

	# get data from database, including column names (passed by ref)
	@{$DB->{columnnames}} = (); # reset columnnames to pass data back as reference
	@{$process->{data}} = (); # reset data to pass data back as reference
	EAI::DB::readFromDB($DB,\@{$process->{data}}) or do {
		$logger->error("couldn' read from DB");
		$process->{hadErrors} = 1;
		return 0;
	};
	# pass column information from database, if not explicitly set
	$File->{columns} = $DB->{columnnames} if !$File->{columns};
	$logger->warn("no data retrieved from database for file ".$File->{filename}.", query: ".$DB->{query}) if ($process->{data} and @{$process->{data}} == 0);
	# prepare for all configs, where postReadProcessing is defined
	if ($DB->{postReadProcessing}) {
		evalCustomCode($DB->{postReadProcessing},"postReadProcessing");
	}
	my $writeSuccess;
	if ($File->{format_xlformat}) {
		$writeSuccess = EAI::File::writeExcel($File,\@{$process->{data}},$process->{countPercent});
	} else {
		$writeSuccess = EAI::File::writeText($File,\@{$process->{data}},$process->{countPercent});
	}
	$process->{successfullyDone}.="writeFileFromDB" if $writeSuccess;
	$process->{hadErrors} = 1 unless $writeSuccess;
	return $writeSuccess;
}

# create Data-files from Memory
sub writeFileFromMemory ($$) {
	my $arg = shift;
	my $data = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("creating/writing file from Memory",$arg,"File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /writeFileFromMem/ and $execute{retryBecauseOfError};
	$logger->warn("no columns given for file ".$File->{filename}) if !$File->{columns};
	$logger->warn("no data available for writing") if !$data or ($data and @{$data} == 0);
	my $writeSuccess;
	if ($File->{format_xlformat}) {
		$writeSuccess = EAI::File::writeExcel($File,$data,$process->{countPercent});
	} else {
		$writeSuccess = EAI::File::writeText($File,$data,$process->{countPercent});
	}
	$process->{successfullyDone}.="writeFileFromMem" if $writeSuccess;
	$process->{hadErrors} = 1 unless $writeSuccess;
	return $writeSuccess;
}

# put files into local folder if required
sub putFileInLocalDir ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("putting file into local folder",$arg,"File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /putFileInLocalDir/ and $execute{retryBecauseOfError};
	if ($File->{localFilesystemPath} and $File->{localFilesystemPath} ne '.') {
		$logger->info("moving file '".$File->{filename}."' into local dir ".$File->{localFilesystemPath});
		move($File->{filename}, $File->{localFilesystemPath}."/".$File->{filename}) or do {
			$logger->error("couldn't move ".$File->{filename}." into ".$File->{localFilesystemPath}.": ".$!);
			$process->{hadErrors} = 1;
			return 0;
		};
	} else {
		if ($File->{localFilesystemPath} eq '.') {
			$logger->info("\$File->{localFilesystemPath} is '.', didn't move files");
		} else {
			$logger->error("no \$File->{localFilesystemPath} defined, therefore no files processed with putFileInLocalDir");
			return 0;
		}
	}
	$process->{successfullyDone}.="putFileInLocalDir";
	return 1;
}

# mark to be removed or be moved to history after upload
sub markForHistoryDelete ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File) = EAI::Common::extractConfigs("",$arg,"File");
	if ($File->{dontKeepHistory}) {
		push @{$execute{uploadFilesToDelete}}, $File->{filename};
	} elsif (!$File->{dontMoveIntoHistory}) {
		push @{$execute{filesToMoveinHistoryUpload}}, $File->{filename};
	}
}

# upload files to FTP
sub uploadFileToFTP ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($FTP,$File,$process) = EAI::Common::extractConfigs("uploading files to FTP",$arg,"FTP","File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /uploadFileToFTP/ and $execute{retryBecauseOfError};
	markForHistoryDelete($arg) unless ($FTP->{localDir});
	if (defined($FTP->{remoteDir})) {
		$logger->debug ("upload of file '".$File->{filename}."' using FTP");
		EAI::Common::setErrSubject("Upload of file to FTP remoteDir ".$FTP->{remoteDir});
		if (!EAI::FTP::putFile ($FTP,{fileToWrite => $File->{filename}})) {
			$process->{hadErrors} = 1;
			return 0;
		}
	} else {
		$logger->warn("no \$FTP->{remoteDir} defined, therefore no files processed with uploadFileToFTP");
	}
	$process->{successfullyDone}.="uploadFileToFTP";
	return 1;
}

# upload files using an upload command program
sub uploadFileCMD ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($FTP,$File,$process) = EAI::Common::extractConfigs("uploading files with CMD",$arg,"FTP","File","process");
	return 1 if $process->{successfullyDone} and $process->{successfullyDone} =~ /uploadFileCMD/ and $execute{retryBecauseOfError};
	markForHistoryDelete($arg) unless ($FTP->{localDir});
	if ($process->{uploadCMD}) {
		$logger->debug ("upload of file '".$File->{filename}."' using uploadCMD ".$process->{uploadCMD});
		EAI::Common::setErrSubject("Uploading of file with ".$process->{uploadCMD});
		system $process->{uploadCMD};
		my $errHappened;
		if ($? == -1) {
			$logger->error($process->{uploadCMD}." failed: $!");
			$errHappened = 1;
		} elsif ($? & 127) {
			$logger->error($process->{uploadCMD}." unexpected finished returning ".($? & 127).", ".(($? & 128) ? 'with' : 'without')." coredump");
			$errHappened = 1;
		} elsif ($? != 0) {
			$logger->error($process->{uploadCMD}." finished returning ".($? >> 8).", err: $!");
			$errHappened = 1;
		} else {
			$logger->info("finished upload using ".$process->{uploadCMD});
		}
		# remove produced files
		unlink ($process->{uploadCMDPath}."/".$File->{filename}) or $logger->error("couldn't remove $File->{filename} in ".$process->{uploadCMDPath}.": ".$!);
		# take error log from uploadCMD
		if (-e $process->{uploadCMDLogfile} && $errHappened) {
			my $err = do {
				local $/ = undef;
				open (FHERR, "<".$process->{uploadCMDLogfile}) or $logger->error("couldn't read uploadCMD log file ".$process->{uploadCMDLogfile}.":".$!);
				<FHERR>;
			};
			$logger->error($process->{uploadCMD}." returned following: $err");
			$process->{hadErrors} = 1;
			return 0;
		}
	} else {
		$logger->error("no \$process->{uploadCMD} defined, therefore no files processed with uploadFileCMD");
		return 0;
	}
	$process->{successfullyDone}.="uploadFileCMD";
	return 1;
}

# general procedure to upload files via FTP or CMD or to put into local dir
sub uploadFile ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($File,$process) = EAI::Common::extractConfigs("",$arg,"File","process");
	if ($File->{localFilesystemPath}) {
		return putFileInLocalDir($arg);
	} elsif ($process->{uploadCMD}) {
		return uploadFileCMD($arg);
	} else {
		return uploadFileToFTP($arg);
	}
}

my $retrySeconds; # seconds to wait for next retry, can change depending on settings (plannedUntil, errors, etc.)
# final processing steps for processEnd (cleanup, FTP removal/archiving) or retry after pausing. No context argument as it always depends on all loads/common
sub processingEnd {
	my $logger = get_logger();
	my $processFailed;
	# incremental checking for errors in processes
	$processFailed = ($common{process}{hadErrors} ? 1 : 0) unless @loads;
	$processFailed += ($_->{process}{hadErrors} ? 1 : 0) for @loads;
	$logger->debug("processingEnd: \$processFailed: $processFailed");
	unless ($processFailed) {
		# archiving/removing on the FTP server only if not a local redo
		if (!$common{task}{redoFile}) {
			EAI::Common::setErrSubject("FTP archiving/removal");
			my (@filesToRemove,@filesToArchive);
			if ($common{process}{filenames} and !@loads) { # only take common part if no loads were defined.
				my (%filesToRemove, %filesToArchive); # hash to collect this only once
				for (@{$common{process}{filenames}}) {
					# "onlyArchive" files are not processed and there is no need to check whether they were processed,
					# else only pass the actual processed files for archiving/removal
					$filesToRemove{$_} = 1 if $common{FTP}{fileToRemove} and ($common{process}{filesProcessed}{$_} or $common{FTP}{onlyArchive});
					$filesToArchive{$_} = 1 if $common{FTP}{fileToArchive} and ($common{process}{filesProcessed}{$_} or $common{FTP}{onlyArchive});
				}
				@filesToArchive = keys(%filesToArchive); @filesToRemove = keys(%filesToRemove);
				if (@filesToArchive or @filesToRemove) {
					openFTPConn(\%common);
					$logger->info("file cleanup: ".(@filesToArchive ? "\narchiving @filesToArchive" : "").(@filesToRemove ? "\nremoving @filesToRemove" : "")." on FTP Server...");
					EAI::FTP::archiveFiles ({filesToArchive => \@filesToArchive, archiveDir => $common{FTP}{archiveDir}, remoteDir => $common{FTP}{remoteDir}, timestamp => $common{task}{customHistoryTimestamp}}) if @filesToArchive;
					EAI::FTP::removeFiles ({filesToRemove => \@filesToRemove, remoteDir => $common{FTP}{remoteDir}}) if @filesToRemove;
				}
			}
			for my $load (@loads) {
				my (%filesToRemove, %filesToArchive); # hash to collect this only once
				if ($load->{process}{filenames}) {
					for (@{$load->{process}{filenames}}) {
						$filesToRemove{$_} = 1 if $load->{FTP}{fileToRemove} and ($load->{process}{filesProcessed}{$_} or $load->{FTP}{onlyArchive});
						$filesToArchive{$_} = 1 if $load->{FTP}{fileToArchive} and ($load->{process}{filesProcessed}{$_} or $load->{FTP}{onlyArchive});
					}
					@filesToArchive = keys(%filesToArchive); @filesToRemove = keys(%filesToRemove);
					if (@filesToArchive or @filesToRemove) {
						openFTPConn($load);
						$logger->info("file cleanup: ".(@filesToArchive ? "\narchiving @filesToArchive, " : "").(@filesToRemove ? "\nremoving @filesToRemove" : "")." on FTP Server...");
						EAI::FTP::archiveFiles ({filesToArchive => \@filesToArchive, archiveDir => $load->{FTP}{archiveDir}, remoteDir => $load->{FTP}{remoteDir}, timestamp => $common{task}{customHistoryTimestamp}}) if @filesToArchive;
						EAI::FTP::removeFiles ({filesToRemove => \@filesToRemove, remoteDir => $load->{FTP}{remoteDir}}) if @filesToRemove;
					}
				}
			}
		}

		# clean up locally
		EAI::Common::setErrSubject("local archiving/removal");
		moveFilesToHistory($common{task}{customHistoryTimestamp});
		deleteFiles($execute{filesToDelete}) if $execute{filesToDelete};
		deleteFiles($execute{uploadFilesToDelete},1) if $execute{uploadFilesToDelete};
		if ($common{task}{plannedUntil}) {
			$execute{processEnd} = 0; # reset, if repetition is planned
			$retrySeconds = $common{task}{retrySecondsPlanned};
		} else {
			$execute{processEnd} = 1;
		}
		if ($execute{retryBecauseOfError}) {
			my @filesProcessed = sort keys %{$common{process}{filesProcessed}};
			for my $load (@loads) {
				push @filesProcessed, sort keys %{$load->{process}{filesProcessed}};
			}
			# send success mail, if successful after first failure
			my $retryScript = $execute{scriptname}.(defined($execute{addToScriptName}) ? " ".$execute{addToScriptName} : "");
			EAI::Common::sendGeneralMail("", $execute{errmailaddress},"","","Successful retry of $retryScript","@filesProcessed succesfully done on retry");
		}
		$execute{firstRunSuccess} = 1 if $common{task}{plannedUntil}; # for planned retries (plannedUntil) -> no more error messages (files might be gone)
		$execute{retryBecauseOfError} = 0;
	} else {
		if ($common{task}{plannedUntil} && $execute{firstRunSuccess}) {
			$retrySeconds = $common{task}{retrySecondsPlanned};
		} else {
			$retrySeconds = $common{task}{retrySecondsErr};
			$execute{retryBecauseOfError} = 1;
			$execute{failcount}++;
		}
		$logger->debug("processingEnd: process failed, \$retrySeconds $retrySeconds, \$execute{failcount}: $execute{failcount}");
	}
	unless ($execute{processEnd}) {
		# refresh config for getting changes, also refresh changes in logging configuration
		$logger->info("process has not ended, refreshing configs, planning next execution");
		readConfigs($execute{envraw});
		doExecuteOnInit();
		EAI::Common::setupLogging();
		# pausing processing/retry
		$retrySeconds = 60 if !$retrySeconds; # sanity fallback if retrySecondsErr not set
		my $failcountFinish;
		my $retrySecondsXfails = (defined($common{task}{retrySecondsXfails}) ? $common{task}{retrySecondsXfails} : 0);
		if ($execute{failcount} > $retrySecondsXfails) {
			$logger->info("fail count reached $retrySecondsXfails, so now retrySeconds are switched to $common{task}{retrySecondsErrAfterXfails}") if $common{task}{retrySecondsErrAfterXfails};
			$failcountFinish = 1 if !$common{task}{retrySecondsErrAfterXfails};
			$retrySeconds = $common{task}{retrySecondsErrAfterXfails};
		}
		my $nextStartTime = calcNextStartTime($retrySeconds);
		my $currentTime = EAI::DateUtil::get_curtime("%02d%02d%02d");
		my $endTime = $common{task}{plannedUntil};
		$endTime .= ($endTime eq "2359" ? "59" : (length($endTime) == 4 ? "00" : "")) if $endTime; # amend HHMM time with seconds, special case 235959
		$endTime = "235959" if !$endTime and $processFailed; # set to retry until end of day for failed processes (can be shortened with $common{task}{retrySecondsXfails})
		$endTime = "000000->not set" if !$endTime; # if neither planned nor process failed then endtime is undefined and needs to be lower than any currentTime for next decision
		if ($failcountFinish or $nextStartTime >= $endTime or ($common{task}{retryEndsAfterMidnight} and ($nextStartTime =~ /1....../ or (substr($execute{startingTime},0,2) > substr($currentTime,0,2))))) {
			$logger->info("finished processing due ".($failcountFinish ? "to reaching set error count \$common{task}{retrySecondsXfails} $common{task}{retrySecondsXfails} and \$common{task}{retrySecondsErrAfterXfails} is false" : ($common{task}{retryEndsAfterMidnight} ? "to ending retry after midnight: nextStartTime=$nextStartTime, startingTime=$execute{startingTime}, currentTime=$currentTime" : "to time out: next start time(".$nextStartTime.") >= endTime(".$endTime.")")));
			moveFilesToHistory($common{task}{customHistoryTimestamp});
			deleteFiles($execute{filesToDelete}) if $execute{filesToDelete};
			deleteFiles($execute{uploadFilesToDelete},1) if $execute{uploadFilesToDelete};
			$execute{processEnd}=1;
		} else {
			# reset hadErrors flag, successfullyDone (only for planned retries) and filenames/filesProcessed
			unless (@loads) {
				$common{process}{hadErrors} = 0;
				$common{process}{successfullyDone} = "" if $common{task}{plannedUntil}; # only reset for planned retries
				delete($common{process}{filesProcessed});
				delete($common{process}{filenames});
			}
			for (@loads) {
				$_->{process}{hadErrors} = 0;
				$_->{process}{successfullyDone} = "" if $common{task}{plannedUntil}; # only reset for planned retries
				delete($_->{process}{filesProcessed});
				delete($_->{process}{filenames});
			}
			$logger->info("Retrying in ".$retrySeconds." seconds because of ".($execute{retryBecauseOfError} ? "occurred error" : "planned retry")." until ".$endTime.", next run: ".$nextStartTime);
			sleep $retrySeconds;
		}
	} else {
		$logger->info("------> finished $execute{scriptname}");
	}
	# reset error mail filter for planned tasks ..
	$EAI::Common::alreadySent = 0 unless $execute{retryBecauseOfError};
	return $execute{processEnd};
}

my $processingInitialized = 0; # specifies that the process was initialized
# wrapper for processingEnd to be used at the beginning of the process loop
sub processingContinues {
	if ($processingInitialized) {
		# second start: process loop finished, normal call to processingEnd() and return its inverted result
		return !processingEnd();
	} else {
		# at the first start always return true to enter the process loop
		$processingInitialized = 1;
		return 1;
	}
}

sub standardLoop (;$) {
	my $getAddtlDBData = shift;
	my $logger = get_logger();
	while (processingContinues()) {
		if ($common{DB}{DSN}) {
			openDBConn(\%common,1) or $logger->error("failed opening DB connection");
		}
		if ($common{FTP}{remoteHost}) {
			openFTPConn(\%common,1) or $logger->error("failed opening FTP connection");
		}
		if (@loads) {
			for my $load (@loads) {
				if (getFiles($load)) {
					getAdditionalDBData($load) if $getAddtlDBData;
					readFileData($load);
					dumpDataIntoDB($load);
					markProcessed($load);
				}
			}
		} else {
			if (getFiles(\%common)) {
				getAdditionalDBData(\%common) if $getAddtlDBData;
				readFileData(\%common);
				dumpDataIntoDB(\%common);
				markProcessed(\%common);
			}
		}
	}
}

# helps to calculate next start time
sub calcNextStartTime ($) {
	my $seconds = shift;
	return EAI::DateUtil::get_curtime("%02d%02d%02d",$seconds);
}

# generally available procedure for pausing processing
sub processingPause ($) {
	my $pauseSeconds = shift;
	my $logger = get_logger();
	$logger->info("pausing ".$pauseSeconds." seconds, resume processing: ".calcNextStartTime($pauseSeconds));
	sleep $pauseSeconds;
}

# moving files into history folder
sub moveFilesToHistory (;$) {
	my ($archiveTimestamp) = @_;
	my $logger = get_logger();
	$archiveTimestamp = EAI::DateUtil::get_curdatetime() if !$archiveTimestamp;
	my $redoDir = ($common{task}{redoFile} ? $execute{redoDir}."/" : "");
	EAI::Common::setErrSubject("local archiving");
	for my $histFolder ("historyFolder", "historyFolderUpload") {
		my @filenames = @{$execute{filesToMoveinHistory}} if $execute{filesToMoveinHistory};
		if ($histFolder eq "historyFolderUpload" and $execute{filesToMoveinHistoryUpload}) {
			@filenames = @{$execute{filesToMoveinHistoryUpload}};
			$redoDir = ""; # no redoDir for uploads !
		}
		for (@filenames) {
			my ($strippedName, $ext) = /(.+)\.(.+?)$/;
			# if done from a redoDir, then add this folder to file (e.g. if done from redo/user specific folder then Filename_20190219_124409.txt becomes Filename_20190219_124409_redo_userspecificfolder_.txt)
			my $cutOffSpec = $archiveTimestamp;
			if ($redoDir) {
				my $redoSpec = $redoDir;
				$redoSpec =~ s/[\/\\\*\|\?:<>"]/_/g;
				$cutOffSpec = $archiveTimestamp.'_'.$redoSpec;
			}
			if (!$execute{alreadyMovedOrDeleted}{$_}) {
				my $histTarget = $execute{$histFolder}."/".$strippedName."_".$cutOffSpec.".".$ext;
				$logger->info("moving file $redoDir$_ into $histTarget");
				rename $redoDir.$_, $histTarget or $logger->error("error when moving file $redoDir$_ into $histTarget: $!");
				$execute{alreadyMovedOrDeleted}{$_} = 1;
			}
		}
	}
}

# removing files
sub deleteFiles ($;$) {
	my ($filenames,$uploadFileFlag) = @_;
	my $logger = get_logger();
	my $redoDir = ($common{task}{redoFile} ? $execute{redoDir}."/" : "");
	$redoDir = "" if $uploadFileFlag;
	EAI::Common::setErrSubject("local cleanup"); #
	for (@$filenames) {
		if (!$execute{alreadyMovedOrDeleted}{$_}) {
			$logger->info("removing ".($common{task}{redoFile} ? "re-done " : "")."file $redoDir$_ ");
			unlink $redoDir.$_ or $logger->error("error when removing file $redoDir".$_." : $!");
			$execute{alreadyMovedOrDeleted}{$_} = 1;
		}
	}
}
1;
__END__

=head1 NAME

EAI::Wrap - framework for easy creation of Enterprise Application Integration tasks

=head1 SYNOPSIS


    # site.config
    %config = (
    	sensitive => {
    			dbSys => {user => "DBuser", pwd => "DBPwd"},
    			ftpSystem1 => {user => "FTPuser", pwd => "FTPPwd", privKey => 'path_to_private_key', hostkey =>'hostkey'},
    		},
    	checkLookup => {"task_script.pl" => {errmailaddress => "test\@test.com", errmailsubject => "testjob failed", timeToCheck => "0800", freqToCheck => "B", logFileToCheck => "test.log", logcheck => "started.*"}},
    	executeOnInit => sub {$execute{addToScriptName} = "doWhateverHereToModifySettings";},
    	folderEnvironmentMapping => {Test => "Test", Dev => "Dev", "" => "Prod"},
    	errmailaddress => 'your@mail.address',
    	errmailsubject => "No errMailSubject defined",
    	fromaddress => 'service@mail.address',
    	smtpServer => "a.mail.server",
    	smtpTimeout => 60,
    	testerrmailaddress => 'your@mail.address',
    	logRootPath => {"" => "C:/dev/EAI/Logs",},
    	historyFolder => {"" => "History",},
    	historyFolderUpload => "HistoryUpload",
    	redoDir => {"" => "redo",},
    	task => {
    		redoTimestampPatternPart => '[\d_]',
    		retrySecondsErr => 60*5,
    		retrySecondsErrAfterXfails => 60*10,
    		retrySecondsXfails => 2,
    		retrySecondsPlanned => 60*15,
    	},
    	DB => {
    		server => {Prod => "ProdServer", Test => "TestServer"},
    		cutoffYr2000 => 60,
    		DSN => 'driver={SQL Server};Server=$DB->{server}{$execute{env}};database=$DB->{database};TrustedConnection=Yes;',
    		schemaName => "dbo",
    	},
    	FTP => {
    		lookups => {
    			ftpSystem1 => {remoteHost => {Test => "TestHost", Prod => "ProdHost"}, port => 5022},
    		},
    		maxConnectionTries => 5,
    		sshInstallationPath => "C:/dev/EAI/putty/PLINK.EXE",
    	},
    	File => {
    		format_defaultsep => "\t",
    		format_thousandsep => ",",
    		format_decimalsep => ".",
    	}
    );

    # task_script.pl
    use EAI::Wrap;
    %common = (
    	FTP => {
    		remoteHost => {"Prod" => "ftp.com", "Test" => "ftp-test.com"},
    		remoteDir => "/reports",
    		port => 22,
    		user => "myuser",
    		privKey => 'C:/keystore/my_private_key.ppk',
    		FTPdebugLevel => 0, # ~(1|2|4|8|16|1024|2048)
    	},
    	DB => {
    		tablename => "ValueTable",
    		deleteBeforeInsertSelector => "rptDate = ?",
    		dontWarnOnNotExistingFields => 1,
    		database => "DWH",
    	},
    	task => {
    		plannedUntil => "2359",
    	},
    );
    @loads = (
    	{
    		File => {
    			filename => "Datafile1.XML",
    			format_XML => 1,
    			format_sep => ',',
    			format_xpathRecordLevel => '//reportGrp/CM1/*',
    			format_fieldXpath => {rptDate => '//rptHdr/rptDat', NotionalVal => 'NotionalVal', tradeRef => 'tradeRefId', UTI => 'UTI'}, 
    			format_header => "rptDate,NotionalVal,tradeRef,UTI",
    		},
    	},
    	{
    		File => {
    			filename => "Datafile2.txt",
    			format_sep => "\t",
    			format_skip => 1,
    			format_header => "rptDate	NotionalVal	tradeRef	UTI",
    		},
    	}
    );
    setupEAIWrap();
    standardLoop();

=head1 DESCRIPTION

EAI::Wrap provides a framework for defining EAI jobs directly in Perl, sparing the creator of low-level tasks as FTP-Fetching, file-parsing and storing into a database.
It also can be used to handle other workflows, like creating files from the database and uploading to FTP-Servers or using other externally provided tools.

The definition is done by first setting up datastructures for configurations and then providing a high-level scripting of the job itself using the provided subs (although any perl code is welcome here!).

EAI::Wrap has a lot of infrastructure already included, like logging using Log4perl, database handling with L<DBI> and L<DBD::ODBC>, FTP services using L<Net::SFTP::Foreign>, file parsing using L<Text::CSV> (text files), L<Data::XLSX::Parser> and L<Spreadsheet::ParseExcel> (excel files), L<XML::LibXML> (xml files), file writing with L<Spreadsheet::WriteExcel> and L<Excel::Writer::XLSX> (excel files), L<Text::CSV> (text files).

Furthermore it provides very flexible commandline options, allowing almost all configurations to be set on the commandline.
Commandline options (e.g. additional information passed on with the interactive option) of the task script are fetched at INIT allowing use of options within the configuration, e.g. $opt{process}{interactive_startdate} for a passed start date.

Also the logging configured in C<$ENV{EAI_WRAP_CONFIG_PATH}/log.config> (logfile root path set in C<$ENV{EAI_WRAP_CONFIG_PATH}/site.config>) starts immediately at INIT of the task script, to use a logger, simply make a call to get_logger(). For the logging configuration, see L<EAI::Common>, setupLogging.

There are two accompanying scripts:

L<setDebugLevel.pl> to easily modify the configured log-levels of the task-script itself and all EAI-Wrap modules.

L<checkLogExist.pl> to run checks on the produced logs (at given times using a cron-job or other scheduler) for their existence and certain (starting/finishing) entries, giving error notifications if the check failed.

=head2 API: datastructures for configurations

=over 4

=item %config 

global config (set in C<$ENV{EAI_WRAP_CONFIG_PATH}/site.config>, amended with C<$ENV{EAI_WRAP_CONFIG_PATH}/additional/*.config>), contains special parameters (default error mail sending, logging paths, etc.) and site-wide pre-settings for the five categories in task scripts, described below under L<configuration categories|/configuration categories>)

=item %common 

common configs for the task script, may contain one configuration hash for each configuration category.

=item @loads

list of hashes defining specific load processes within the task script. Each hash may contain one configuration hash for each configuration category.

=item configuration categories

In the above mentioned hashes can be five categories (sub-hashes): L<DB|/DB>, L<File|/File>, L<FTP|/FTP>, L<process|/process> and L<task|/task>. These allow further parameters to be set for the respective parts of EAI::Wrap (L<EAI::DB>, L<EAI::File> and L<EAI::FTP>), process parameters and task parameters. The parameters are described in detail in section L<CONFIGURATION REFERENCE|/CONFIGURATION REFERENCE>.

The L<process|/process> category is on the one hand used to pass information within each process (data, additionalLookupData, filenames, hadErrors or custom commandline parameters starting with interactive), on the other hand for additional configurations not suitable for L<DB|/DB>, L<File|/File> or L<FTP|/FTP> (e.g. L<uploadCMD|/uploadCMD>). The L<task|/task> category contains parameters used on the task script level and is therefore only allowed in C<%config> and C<%common>. It contains parameters for skipping, retrying and redoing the whole task script.

The settings in DB, File, FTP and task are "merge" inherited in a cascading manner (i.e. missing parameters are merged, parameters already set below are not overwritten):

 - %config (defined in site.config and other associated configs. This is being loaded at INIT)
 merged into ->
 - %common (common task parameters defined in script. This is being loaded when calling setupEAIWrap())
 merged into each instance of ->
 - $loads[] (only if loads are defined, you can also stay with %common if there is only one load in the script)

special config parameters and DB, FTP, File, task parameters from command line options are merged at the respective level (config at the top, the rest at the bottom) and always override any set parameters.
Only scalar parameters can be given on the command line, no lists and hashes are possible. Commandline options are given in the format:

  --<category> <parameter>=<value>

for the common level and 

  --load<i><category> <parameter>=<value>

for the loads level.

Command line options are also available to the script via the hash C<%opt> or the list of hashes C<@optloads>, so in order to access the cmdline option C<--process interactive_date=202300101> you could either use C<$common{process}{interactive_date}> or C<$opt{process}{interactive_date}>. 

In order to use C<--load1process interactive_date=202300101>, you would use C<$loads[1]{process}{interactive_date}> or C<$optloads[1]{process}{interactive_date}>.

The merge inheritance for L<DB|/DB>, L<FTP|/FTP>, L<File|/File> and L<task|/task> can be prevented by using an underscore after the hashkey, ie. C<DB_>, C<FTP_>, C<File_> and C<task_>. In this case the parameters are not merged from C<common>. However, they are always inherited from C<config>.

A special merge is done for configurations defined in hash C<lookups>, which may appear in all five categories (sub-hashes) of the top-level configuration C<%config>. This uses the prefix defined in the task script's C<%common> configuration to get generally defined settings for this specific prefix. As an example, common remoteHosts or ports for FTP can be defined here. These settings also allow an environment dependent hash, like C<{Test =E<gt> "TestHost", Prod =E<gt> "ProdHost"}>.

=item %execute

hash of parameters for current task execution, which is not set by the user but can be read to set other parameters and control the flow. Most important here are C<$execute{env}>, giving the current used environment (Prod, Test, Dev, whatever), C<$execute{envraw}> (same as C<$execute{env}>, with Production being empty here), the several file lists (files being procesed, files for deletion/moving, etc.), flags for ending/interrupting processing and directory locations as the home dir and history folders for processed files.

Detailed information about these parameters can be found in section L<execute|/execute> of the configuration parameter reference, there are parameters for files (L<filesProcessed|/filesProcessed>, L<filesToDelete|/filesToDelete>, L<filesToMoveinHistory|/filesToMoveinHistory>, L<filesToMoveinHistoryUpload|/filesToMoveinHistoryUpload>, L<retrievedFiles|/retrievedFiles>) and L<uploadFilesToDelete|/uploadFilesToDelete>, directories (L<homedir|/homedir>, L<historyFolder|/historyFolder>, L<historyFolderUpload|/historyFolderUpload> and L<redoDir|/redoDir>), process controlling parameters (L<failcount|/failcount>, L<firstRunSuccess|/firstRunSuccess>, L<retryBecauseOfError|/retryBecauseOfError>, L<retrySeconds|/retrySeconds> and L<processEnd|/processEnd>).

Retrying after C<$execute{processEnd}> is false (this parameter is set during C<processingEnd()>, combining this call and check can be done in loop header at start with C<processingContinues()>) can happen because of two reasons: First, due to C<task =E<gt> {plannedUntil =E<gt> "HHMM"}> being set to a time until the task has to be retried, however this is done at most until midnight. Second, because an error occurred, in such a case C<$process-E<gt>{hadErrors}> is set for each load that failed. C<$process{successfullyDone}> is also important in this context as it prevents the repeated run of following API procedures if the loads didn't have an error during their execution:

L<openDBConn|/openDBConn>, L<openFTPConn|/openFTPConn>, L<getLocalFiles|/getLocalFiles>, L<getFilesFromFTP|/getFilesFromFTP>, L<getFiles|/getFiles>, L<extractArchives|/extractArchives>, L<getAdditionalDBData|/getAdditionalDBData>, L<readFileData|/readFileData>, L<dumpDataIntoDB|/dumpDataIntoDB>, L<writeFileFromDB|/writeFileFromDB>, L<putFileInLocalDir|/putFileInLocalDir>, L<uploadFileToFTP|/uploadFileToFTP>, L<uploadFileCMD|/uploadFileCMD>, and L<uploadFile|/uploadFile>.

L<checkFiles|/checkFiles> is always run, regardless of C<$process{successfullyDone}>.

After the first successful run of the task, C<$execute{firstRunSuccess}> is set to prevent any error messages resulting of files having been moved/removed while rerunning the task until the defined planned time (C<task =E<gt> {plannedUntil =E<gt> "HHMM"}>) has been reached.

=item initialization

The INIT procedure is executed at the task script initialization (when EAI::Wrap is "use"d in the task script) and loads the site configuration, starts logging and reads commandline options. This means that everything passed to the script via command line may be used in the definitions, especially the C<task{interactive.*}> parameters, here the name and the type of the parameter are not checked by the consistency checks (other parameters that are not allowed or have the wrong type throw an error). The task script's configuration itself is then read with setupEAIWrap(), which is usually called immediately after the datastructures for configurations have been finished.

=back

=head2 API: High-level subs

Following are the high level subs that can be called for a standard workflow. Most of them accumulate their sub names in process{successfullyDone} to prevent any further call in a faulting loop, when they alrady ran successfully. Also process{hadErrors} is set in case of errors to provide for error repeating. Downloaded files are collected in process{filenames} and completely processed files in process{filesProcessed}.

=over 4

=item setupEAIWrap

setupEAIWrap is actually imported from L<EAI::Common>, but as it is usually called as the first sub, it is mentioned here as well. This sub sets up the configuration datastructure and merges the hierarchy of configurations, more information in L<EAI::Common::setupEAIWrap|EAI::Common/setupEAIWrap>.

=item removeFilesinFolderOlderX

Usually done for clearing FTP archives, this removes files on FTP server being older than a time back (given in day/mon/year in C<remove =E<gt> {removeFolders =E<gt> ["",""], day=E<gt>, mon=E<gt>, year=E<gt>1}>), see L<EAI::FTP::removeFilesOlderX|EAI::FTP/removeFilesOlderX> (always runs in a faulting loop)

=item openDBConn ($)

argument $arg (ref to current load or common)

open a DB connection with the information provided in C<$DB-E<gt>{user}>, C<$DB-E<gt>{pwd}> (these can be provided by the sensitive information looked up using C<$DB-E<gt>{prefix}>) and C<$DB-E<gt>{DSN}> which can be dynamically configured using information from C<$DB> itself, using C<$execute{env}> inside C<$DB-E<gt>{server}{*}>: C<'driver={SQL Server};Server=$DB-E<gt>{server}{$execute{env}};database=$DB-E<gt>{database};TrustedConnection=Yes;'>, also see L<EAI::DB::newDBH|EAI::DB/newDBH>

If the DSN information is not found in C<$DB> then a system wide DSN for the set $DB{prefix} is tried to be fetched from C<$config{DB}{$DB{prefix}}{DSN}>. This also respects environment information in C<$execute{env}> if configured.

=item openFTPConn ($)

argument $arg (ref to current load or common)

open a FTP connection with the information provided in C<$FTP-E<gt>{remoteHost}>, C<$FTP-E<gt>{user}>, C<$FTP-E<gt>{pwd}>, C<$FTP-E<gt>{hostkey}>, C<$FTP-E<gt>{privKey}> (these four can be provided by the sensitive information looked up using C<$FTP-E<gt>{prefix}>) and C<$execute{env}>, also see L<EAI::FTP::login|EAI::FTP/login>

If the remoteHost information is not found in C<$FTP> then a system wide remoteHost for the set $FTP{prefix} is tried to be fetched from C<$config{FTP}{$FTP{prefix}}{remoteHost}>. This also respects environment information in C<$execute{env}> if configured.

=item redoFiles ($)

argument $arg (ref to current load or common)

redo file from redo directory if specified (C<$common{task}{redoFile}> is being set), this is also being called by getLocalFiles and getFilesFromFTP. Arguments are fetched from common or loads[i], using File parameter. (always runs in a faulting loop when called directly)

=item getLocalFiles ($)

argument $arg (ref to current load or common)

get local file(s) from source into homedir, checks files for continuation of processing and extract archives if needed. Arguments are fetched from common or loads[i], using File parameter. The processed files are put into process->{filenames} (always runs in a faulting loop). Uses C<$File-E<gt>{filename}>, C<$File-E<gt>{extension}> and C<$File-E<gt>{avoidRenameForRedo}>.

=item getFilesFromFTP ($)

argument $arg (ref to current load or common)

get file/s (can also be a glob for multiple files) from FTP into homedir, checks files for continuation of processing and extract archives if needed. Arguments are fetched from common or loads[i], using File and FTP parameters. The processed files are put into process->{filenames} (always runs in a faulting loop).

=item getFiles ($)

argument $arg (ref to current load or common)

combines above two procedures in a general procedure to get files from FTP or locally. Arguments are fetched from common or loads[i], using File and FTP parameters. 

=item checkFiles ($)

argument $arg (ref to current load or common)

check files for continuation of processing and extract archives if needed. Arguments are fetched from common or loads[i], using File parameter. The processed files are put into process->{filenames} (always runs in a faulting loop). Important: files (their filenames) not retrieved by getFilesFromFTP or getLocalFiles have to be put into $execute{retrievedFiles} (e.g. push @{$execute{retrievedFiles}}, $filenameTobeChecked)!

=item extractArchives ($)

argument $arg (ref to current load or common)

extract files from archive (only one archive is allowed). Arguments are fetched from common or loads[i], using only the process->{filenames} parameter that was filled by checkFiles. If not being called by getFilesFromFTP/getLocalFiles and checkFiles @{$process{filenames}} has to contain the archive filename.

=item getAdditionalDBData ($;$)

arguments $arg (ref to current load or common) and optional $refToDataHash

get additional data from DB. Arguments are fetched from common or loads[i], using DB and process parameters. You can also pass an optional ref to a data hash parameter to store the retrieved data there instead of C<$process->{additionalLookupData}>

=item readFileData ($)

argument $arg (ref to current load or common)

read data from a file. Arguments are fetched from common or loads[i], using File parameter. This parses the file content into the datastructure process{data}. Custom "hooks" can be defined with L<fieldCode|/fieldCode> and L<lineCode|/lineCode> to modify and enhance the standard mapping defined in format_header. To access the final line data the hash %EAI::File::line can be used (specific fields with $EAI::File::line{<target header column>}). if a field is being replaced using a different name from targetheader, the data with the original header name is placed in %EAI::File::templine. You can also access data from the previous line with %EAI::File::previousline and the previous temp line with %EAI::File::previoustempline.

=item dumpDataIntoDB ($)

argument $arg (ref to current load or common)

store data into Database. Arguments are fetched from common or loads[i], using DB and File (for emptyOK) parameters.

=item markProcessed ($)

argument $arg (ref to current load or common)

mark files as being processed depending on whether there were errors, also decide on removal/archiving of downloaded files. Arguments are fetched from common or loads[i], using File parameter. (always runs in a faulting loop)

=item writeFileFromDB ($)

argument $arg (ref to current load or common)

create data-files (excel or text) from Database. Arguments are fetched from common or loads[i], using DB and File parameters.

=item writeFileFromMemory ($$)

arguments $arg (ref to current load or common) and $data (ref to array of hash values coming from readFromDB or readText/readExcel/readXML)

create data-files (excel or text) from memory stored array of hash values. The created (in case of text files also appended) file information is taken from $arg, the data from $data.

=item putFileInLocalDir ($)

argument $arg (ref to current load or common)

put files into local folder if required. Arguments are fetched from common or loads[i], using File parameter.

=item markForHistoryDelete ($)

argument $arg (ref to current load or common)

mark to be removed or be moved to history after upload. Arguments are fetched from common or loads[i], using File parameter. (always runs in a faulting loop)

=item uploadFileToFTP ($)

argument $arg (ref to current load or common)

upload files to FTP. Arguments are fetched from common or loads[i], using FTP and File parameters.

=item uploadFileCMD ($)

argument $arg (ref to current load or common)

upload files using an upload command program. Arguments are fetched from common or loads[i], using File and process parameters.

=item uploadFile ($)

argument $arg (ref to current load or common)

combines above two procedures in a general procedure to upload files via FTP or CMD or to put into local dir. Arguments are fetched from common or loads[i], using File and process parameters

=item standardLoop (;$)

executes the given configuration in a standard extract/transform/load loop (as shown below), depending on whether loads are given an additional loop is done for all loads within the @loads list. 
If the definition only contains the common hash then there is no loop. The additional optional parameter $getAddtlDBData activates getAdditionalDBData before reading in file data.
No other processing is possible (creating files from data, uploading, etc.)

  while (processingContinues()) {
  	if ($common{DB}{DSN}) {
  		openDBConn(\%common,1) or $logger->error("failed opening DB connection");
  	}
  	if ($common{FTP}{remoteHost}) {
  		openFTPConn(\%common,1) or $logger->error("failed opening FTP connection");
  	}
  	if (@loads) {
  		for my $load (@loads) {
  			if (getFiles($load)) {
  				getAdditionalDBData($load) if $getAddtlDBData;
  				readFileData($load);
  				dumpDataIntoDB($load);
  				markProcessed($load);
  			}
  		}
  	} else {
  		if (getFiles(\%common)) {
  			getAdditionalDBData(\%common) if $getAddtlDBData;
  			readFileData(\%common);
  			dumpDataIntoDB(\%common);
  			markProcessed(\%common);
  		}
  	}
  }

=item processingEnd

final processing steps for process ending (cleanup, FTP removal/archiving) or retry after pausing. No context argument as this always depends on all loads and/or the common definition (always runs in a faulting loop). Returns true if process ended and false if not. Using this as a check also works for do .. while or do .. until loops.

=item processingPause ($)

generally available procedure for pausing processing, argument $pauseSeconds gives the delay

=item processingContinues

Alternative and compact way to combine call to C<processingEnd()> and check of C<$execute{processEnd}> in one go in a while or until loop header. Returns true if process continues and false if not. Caveat: This doesn't works for do .. while or do .. until loops!
Instead of checking C<processingEnd()> and C<processingContinues()>, a check of C<!$execute{processEnd}> can be done in the while or until header with a call to C<processingEnd()> at the end of the loop.

=item moveFilesToHistory (;$)

optional argument $archiveTimestamp

move transferred files marked for moving (filesToMoveinHistory/filesToMoveinHistoryUpload) into history and/or historyUpload folder. Optionally a custom timestamp can be passed.
 
=item deleteFiles ($)

argument $filenames, ref to array

delete transferred files given in $filenames

=back



=head2 CONFIGURATION REFERENCE

=over 4

=item config

parameter category for site global settings, usually defined in site.config and other associated configs loaded at INIT

=over 4

=item checkLogExistDelay

ref to hash {Test => 2, Dev => 3, "" => 0}, mapping to set delays for checkLogExist per environment in $execute{env}, this can be further overriden per job (and environment) in checkLookup.

=item checkLookup

ref to datastructure {"scriptname.pl + optional addToScriptName" => {errmailaddress => "",errmailsubject => "",timeToCheck =>"", freqToCheck => "", logFileToCheck => "", logcheck => "",logRootPath =>""},...} used for logchecker, each entry of the hash lookup table defines a log to be checked, defining errmailaddress to receive error mails, errmailsubject, timeToCheck as earliest time to check for existence in log, freqToCheck as frequency of checks (daily/monthly/etc), logFileToCheck as the name of the logfile to check, logcheck as the regex to check in the logfile and logRootPath as the folder where the logfile is found. lookup key: $execute{scriptname} + $execute{addToScriptName}

=item errmailaddress

default mail address for central logcheck/errmail sending 

=item errmailsubject

default mail subject for central logcheck/errmail sending 

=item executeOnInit

code to be executed during INIT of EAI::Wrap to allow for assignment of config/execute parameters from commandline params BEFORE Logging!

=item folderEnvironmentMapping

ref to hash {Test => "Test", Dev => "Dev", "" => "Prod"}, mapping for $execute{envraw} to $execute{env}

=item fromaddress

from address for central logcheck/errmail sending, also used as default sender address for sendGeneralMail

=item historyFolder

ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where downloaded files are historized, lookup key as in checkLookup, default in "" => "defaultfolder". historyFolder, historyFolderUpload, logRootPath and redoDir are always built with an environment subfolder, the default is built as folderPath/endFolder/environ, otherwise it is built as folderPath/environ/endFolder. Environment subfolders (environ) are also built depending on prodEnvironmentInSeparatePath: either folderPath/endFolder/$execute{env} (prodEnvironmentInSeparatePath = true, Prod has own subfolder) or folderPath/endFolder/$execute{envraw} (prodEnvironmentInSeparatePath = false, Prod is in common folder, other environments have their own folder)

=item historyFolderUpload

ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where uploaded files are historized, lookup key as in checkLookup, default in "" => "defaultfolder"

=item logCheckHoliday

calendar for business days in central logcheck/errmail sending. builtin calendars are AT (Austria), TG (Target), UK (United Kingdom) and WE (for only weekends). Calendars can be added with EAI::DateUtil::addCalendar

=item logs_to_be_ignored_in_nonprod

regular expression to specify logs to be ignored in central logcheck/errmail sending

=item logprefixForLastLogfile

prefix for previous (day) logs to be set in error mail (link), if not given, defaults to get_curdate(). In case Log::Dispatch::FileRotate is used as the File Appender in Log4perl config, the previous log is identified with <logname>.1

=item logRootPath

ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, paths to log file root folders (environment is added to that if non production), lookup key as checkLookup, default in "" => "defaultfolder"

=item prodEnvironmentInSeparatePath

set to 1 if the production scripts/logs etc. are in a separate Path defined by folderEnvironmentMapping (prod=root/Prod, test=root/Test, etc.), set to 0 if the production scripts/logs are in the root folder and all other environments are below that folder (prod=root, test=root/Test, etc.)

=item redoDir

ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where files for redo are contained, lookup key as checkLookup, default in "" => "defaultfolder"

=item sensitive

hash lookup table ({"prefix" => {user=>"",pwd =>"",hostkey=>"",privkey =>""},...}) for sensitive access information in DB and FTP (lookup keys are set with DB{prefix} or FTP{prefix}), may also be placed outside of site.config; all sensitive keys can also be environment lookups, e.g. hostkey=>{Test => "", Prod => ""} to allow for environment specific setting

=item smtpServer

smtp server for den (error) mail sending

=item smtpTimeout

timeout for smtp response

=item testerrmailaddress

error mail address in non prod environment

=back

=item execute

hash of parameters for current task execution. This is not to be set by the user, but can be used to as information to set other parameters and control the flow

=over 4

=item alreadyMovedOrDeleted

hash for checking the already moved or deleted local files, to avoid moving/deleting them again at cleanup

=item addToScriptName

this can be set to be added to the scriptname for config{checkLookup} keys, e.g. some passed parameter.

=item env

Prod, Test, Dev, whatever is defined as the lookup value in folderEnvironmentMapping. homedir as fetched from the File::basename::dirname of the executing script using /^.*[\\\/](.*?)$/ is used as the key for looking up this value.

=item envraw

Production has a special significance here as being an empty string. Otherwise like env.

=item errmailaddress

target address for central logcheck/errmail sending in current process

=item errmailsubject

mail subject for central logcheck/errmail sending in current process

=item failcount

for counting failures in processing to switch to longer wait period or finish altogether

=item filesToDelete

list of files to be deleted locally after download, necessary for cleanup at the end of the process

=item filesToMoveinHistory

list of files to be moved in historyFolder locally, necessary for cleanup at the end of the process

=item filesToMoveinHistoryUpload

list of files to be moved in historyFolderUpload locally, necessary for cleanup at the end of the process

=item firstRunSuccess

for planned retries (process=>plannedUntil filled) -> this is set after the first run to avoid error messages resulting of files having been moved/removed.

=item freqToCheck

for logchecker:  frequency to check entries (B,D,M,M1) ...

=item homedir

the home folder of the script, mostly used to return from redo and other folders for globbing files.

=item historyFolder

actually set historyFolder

=item historyFolderUpload

actually set historyFolderUpload

=item logcheck

for logchecker: the Logcheck (regex)

=item logFileToCheck

for logchecker: Logfile to be searched

=item logRootPath

actually set logRootPath

=item processEnd

specifies that the process is ended, checked in EAI::Wrap::processingEnd

=item redoDir

actually set redoDir

=item retrievedFiles

files retrieved from FTP or redo directory

=item retryBecauseOfError

retryBecauseOfError shows if a rerun occurs due to errors (for successMail) 

=item retrySeconds

how many seconds are passed between retries. This is set on error with process=>retrySecondsErr and if planned retry is defined with process=>retrySecondsPlanned

=item scriptname

name of the current process script, also used in log/history setup together with addToScriptName for config{checkLookup} keys

=item startingTime

tasks starting time for checking task{retryEndsAfterMidnight} against current time

=item timeToCheck

for logchecker: scheduled time of job (don't look earlier for log entries)

=item uploadFilesToDelete

list of files to be deleted locally after upload, necessary for cleanup at the end of the process

=back

=item DB

DB specific configs

=over 4

=item addID

this hash can be used to additionaly set a constant to given fields: Fieldname => Fieldvalue

=item additionalLookup

query used in getAdditionalDBData to retrieve lookup information from DB using EAI::DB::readFromDBHash

=item additionalLookupKeys

used for getAdditionalDBData, list of field names to be used as the keys of the returned hash

=item cutoffYr2000

when storing date data with 2 year digits in dumpDataIntoDB/EAI::DB::storeInDB, this is the cutoff where years are interpreted as 19XX (> cutoffYr2000) or 20XX (<= cutoffYr2000)

=item columnnames

returned column names from EAI::DB::readFromDB and EAI::DB::readFromDBHash, this is used in writeFileFromDB to pass column information from database to writeText

=item database

database to be used for connecting

=item debugKeyIndicator

used in dumpDataIntoDB/EAI::DB::storeInDB as an indicator for keys for debugging information if primkey not given (errors are shown with this key information). Format is the same as for primkey

=item deleteBeforeInsertSelector

used in dumpDataIntoDB/EAI::DB::storeInDB to delete specific data defined by keydata before an insert (first occurrence in data is used for key values). Format is the same as for primkey ("key1 = ? ...")

=item dontWarnOnNotExistingFields

suppress warnings in dumpDataIntoDB/EAI::DB::storeInDB for not existing fields

=item dontKeepContent

if table should be completely cleared before inserting data in dumpDataIntoDB/EAI::DB::storeInDB

=item doUpdateBeforeInsert

invert insert/update sequence in dumpDataIntoDB/EAI::DB::storeInDB, insert only done when upsert flag is set

=item DSN

DSN String for DB connection

=item incrementalStore

when storing data with dumpDataIntoDB/EAI::DB::storeInDB, avoid setting empty columns to NULL

=item ignoreDuplicateErrs

ignore any duplicate errors in dumpDataIntoDB/EAI::DB::storeInDB

=item keyfields

used for EAI::DB::readFromDBHash, list of field names to be used as the keys of the returned hash

=item longreadlen

used for setting database handles LongReadLen parameter for DB connection, if not set defaults to 1024

=item lookups

similar to $config{sensitive}, a hash lookup table ({"prefix" => {remoteHost=>""},...} or {"prefix" => {remoteHost=>{Prod => "", Test => ""}},...}) for centrally looking up DSN Settings depending on $DB{prefix}. Overrides $DB{DSN} set in config, but is overriden by script-level settings in %common.

=item noDBTransaction

don't use a DB transaction for dumpDataIntoDB

=item noDumpIntoDB

if files from this load should not be dumped to the database

=item port

port to be added to server in environment hash lookup: {Prod => "", Test => ""}

=item postDumpExecs

array for DB executions done in dumpDataIntoDB after postDumpProcessing and before commit/rollback: [{execs => ['',''], condition => ''}]. For all execs a doInDB is executed if condition (evaluated string or anonymous sub: condition => sub {...}) is fulfilled

=item postDumpProcessing

done in dumpDataIntoDB after EAI::DB::storeInDB, execute perl code in postDumpProcessing (evaluated string or anonymous sub: postDumpProcessing => sub {...})

=item postReadProcessing

done in writeFileFromDB after EAI::DB::readFromDB, execute perl code in postReadProcessing (evaluated string or anonymous sub: postReadProcessing => sub {...})

=item prefix

key for sensitive information (e.g. pwd and user) in config{sensitive} or system wide DSN in config{DB}{prefix}{DSN}. respects environment in $execute{env} if configured.

=item primkey

primary key indicator to be used for update statements, format: "key1 = ? AND key2 = ? ...". Not necessary for dumpDataIntoDB/storeInDB if dontKeepContent is set to 1, here the whole table content is removed before storing

=item pwd

for password setting, either directly (insecure -> visible) or via sensitive lookup

=item query

query statement used for EAI::DB::readFromDB and EAI::DB::readFromDBHash

=item schemaName

schemaName used in dumpDataIntoDB/EAI::DB::storeInDB, if tableName contains dot the extracted schema from tableName overrides this. Needed for datatype information!

=item server

DB Server in environment hash lookup: {Prod => "", Test => ""}

=item tablename

the table where data is stored in dumpDataIntoDB/EAI::DB::storeInDB

=item upsert

in dumpDataIntoDB/EAI::DB::storeInDB, should both update and insert be done. doUpdateBeforeInsert=0: after the insert failed (because of duplicate keys) or doUpdateBeforeInsert=1: insert after the update failed (because of key not exists)?

=item user

for setting username in db connection, either directly (insecure -> visible) or via sensitive lookup

=back

=item File

File fetching and parsing specific configs. File{filename} is also used for FTP

=over 4

=item avoidRenameForRedo

when redoing, usually the cutoff (datetime/redo info) is removed following a pattern. set this flag to avoid this

=item append

for EAI::File::writeText: boolean to append (1) or overwrite (0 or undefined) to file given in filename

=item columns

for EAI::File::writeText: Hash of data fields, that are to be written (in order of keys)

=item columnskip

for EAI::File::writeText: boolean hash of column names that should be skipped when writing the file ({column1ToSkip => 1, column2ToSkip => 1, ...})

=item dontKeepHistory

if up- or downloaded file should not be moved into historyFolder but be deleted

=item dontMoveIntoHistory

if up- or downloaded file should not be moved into historyFolder but be kept in homedir

=item emptyOK

flag to specify whether empty files should not invoke an error message. Also needed to mark an empty file as processed in EAI::Wrap::markProcessed

=item extract

flag to specify whether to extract files from archive package (zip)

=item extension

the extension of the file to be read (optional, used for redoFile)

=item fieldCode

additional field based processing code: fieldCode => {field1 => 'perl code', ..}, invoked if key equals either header (as in format_header) or targetheader (as in format_targetheader) or invoked for all fields if key is empty {"" => 'perl code'}. set $EAI::File::skipLineAssignment to true (1) if current line should be skipped from data. perl code can be an evaluated string or an anonymous sub: field1 => sub {...}

=item filename

the name of the file to be read, can also be a glob spec to retrieve multiple files. This information is also used for FTP and retrieval and local file copying.

=item firstLineProc

processing done when reading the first line of text files in EAI::File::readText (used to retrieve information from a header line, like reference date etc.). The line is available in $_.

=item format_allowLinefeedInData

line feeds in values don't create artificial new lines/records, only works for csv quoted data in EAI::File::readText

=item format_autoheader

assumption: header exists in file and format_header should be derived from there. only for EAI::File::readText

=item format_beforeHeader

additional String to be written before the header in EAI::File::writeText

=item format_dateColumns

numeric array of columns that contain date values (special parsing) in excel files (EAI::File::readExcel)

=item format_decimalsep

decimal separator used in numbers of sourcefile (defaults to . if not given)

=item format_defaultsep

default separator when format_sep not given (usually in site.config), if no separator is given (not needed for EAI::File::readExcel/EAI::File::readXML), "\t" is used for parsing format_header and format_targetheader.

=item format_encoding

text encoding of the file in question (e.g. :encoding(utf8))

=item format_headerColumns

optional numeric array of columns that contain data in excel files (defaults to all columns starting with first column up to format_targetheader length)

=item format_header

format_sep separated string containing header fields (optional in excel files, only used to check against existing header row)

=item format_headerskip

skip until row-number for checking header row against format_header in EAI::File::readExcel

=item format_eol

for quoted csv specify special eol character (allowing newlines in values)

=item format_fieldXpath

for EAI::File::readXML, hash with field => xpath to content association entries

=item format_fix

for text writing, specify whether fixed length format should be used (requires format_padding)

=item format_namespaces

for EAI::File::readXML, hash with alias => namespace association entries

=item format_padding

for text writing, hash with field number => padding to be applied for fixed length format

=item format_poslen

array of array defining positions and lengths [[pos1,len1],[pos2,len2]...[posN,lenN]] of data in fixed length format text files (if format_sep == "fix")

=item format_quotedcsv

special parsing/writing of quoted csv data using Text::CSV

=item format_sep

separator string for EAI::File::readText and EAI::File::writeText csv formats, a regex for splitting other separated formats. If format_sep is not explicitly given as a regex here (=> qr//), then it is assumed to be a regex by split, however this causes surprising effects with regex metacharacters (should be quoted, such as qr/\|/)! Also used for splitting format_header and format_targetheader (Excel and XML-formats use tab as default separator here).

=item format_sepHead

special separator for header row in EAI::File::writeText, overrides format_sep

=item format_skip

either numeric or string, skip until row-number if numeric or appearance of string otherwise in reading textfile. If numeric, format_skip can also be used in EAI::File::readExcel

=item format_stopOnEmptyValueColumn

for EAI::File::readExcel, stop row parsing when a cell with this column number is empty (denotes end of data, to avoid very long parsing).

=item format_suppressHeader

for text and excel file writing, suppress output of header

=item format_targetheader

format_sep separated string containing target header fields (= the field names in target/database table). optional for XML and tabular textfiles, defaults to format_header if not given there.

=item format_thousandsep

thousand separator used in numbers of sourcefile (defaults to , if not given)

=item format_worksheetID

worksheet number for EAI::File::readExcel, this should always work

=item format_worksheet

alternatively the worksheet name can be passed for EAI::File::readExcel, this only works for new excel format (xlsx)

=item format_xlformat

excel format for parsing, also specifies that excel parsing should be done

=item format_xpathRecordLevel

xpath for level where data nodes are located in xml

=item format_XML

specify xml parsing

=item lineCode

additional line based processing code, invoked after whole line has been read (evaluated string or anonymous sub: lineCode => sub {...})

=item localFilesystemPath

if files are taken from or put to the local file system with getLocalFiles/putFileInLocalDir then the path is given here. Setting this to "." avoids copying files.

=item optional

to avoid error message for missing optional files, set this to 1

=back

=item FTP

FTP specific configs

=over 4

=item additionalParamsGet

additional parameters for Net::SFTP::Foreign get.

=item additionalMoreArgs

additional more args for Net::SFTP::Foreign new (args passed to ssh command).

=item additionalParamsNew

additional parameters for Net::SFTP::Foreign new.

=item additionalParamsPut

additional parameters for Net::SFTP::Foreign put.

=item archiveDir

folder for archived files on the FTP server

=item dontMoveTempImmediately

if 0 oder missing: rename/move files immediately after writing to FTP to the final name, otherwise/1: a call to EAI::FTP::moveTempFiles is required for that

=item dontDoSetStat

for Net::SFTP::Foreign, no setting of time stamp of remote file to that of local file (avoid error messages of FTP Server if it doesn't support this)

=item dontDoUtime

don't set time stamp of local file to that of remote file

=item dontUseQuoteSystemForPwd

for windows, a special quoting is used for passing passwords to Net::SFTP::Foreign that contain [()"<>& . This flag can be used to disable this quoting.

=item dontUseTempFile

directly upload files, without temp files

=item fileToArchive

should files be archived on FTP server? if archiveDir is not set, then file is archived (rolled) in the same folder

=item fileToRemove

should files be removed on FTP server?

=item FTPdebugLevel

debug ftp: 0 or ~(1|2|4|8|16|1024|2048), loglevel automatically set to debug for module EAI::FTP

=item hostkey

hostkey to present to the server for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup

=item hostkey2

additional hostkey to be presented (e.g. in case of round robin DNS)

=item localDir

optional: local folder for files to be placed, if not given files are downloaded into current folder

=item lookups

similar to $config{sensitive}, a hash lookup table ({"prefix" => {remoteHost=>""},...} or {"prefix" => {remoteHost=>{Prod => "", Test => ""}},...}) for centrally looking up remoteHost and port settings depending on $FTP{prefix}.

=item maxConnectionTries

maximum number of tries for connecting in login procedure

=item noDirectRemoteDirChange

if no direct change into absolute paths (/some/path/to/change/into) ist possible then set this to 1, this does a separated change into setcwd(undef) and setcwd(remoteDir)

=item onlyArchive

only archive/remove given files on the FTP server, requires archiveDir to be set

=item path

additional relative FTP path (under remoteDir which is set at login), where the file(s) is/are located

=item port

ftp/sftp port (leave empty for default port 22 when using Net::SFTP::Foreign, or port 21 when using Net::FTP)

=item prefix

key for sensitive information (e.g. pwd and user) in config{sensitive} or system wide remoteHost/port in config{FTP}{prefix}{remoteHost} or config{FTP}{prefix}{port}. respects environment in $execute{env} if configured.

=item privKey

sftp key file location for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup

=item pwd

for password setting, either directly (insecure -> visible) or via sensitive lookup

=item queue_size

queue_size for Net::SFTP::Foreign, if > 1 this causes often connection issues

=item remove

ref to hash {removeFolders=>[], day=>, mon=>, year=>1} for for removing (archived) files with removeFilesOlderX, all files in removeFolders are deleted being older than day days, mon months and year years

=item remoteDir

remote root folder for up-/download, archive and remove: "out/Marktdaten/", path is added then for each filename (load)

=item remoteHost

ref to hash of IP-addresses/DNS of host(s).

=item SFTP

to explicitly use SFTP, if not given SFTP will be derived from existence of privKey or hostkey

=item simulate

for removal of files using removeFilesinFolderOlderX/removeFilesOlderX only simulate (1) or do actually (0)?

=item sshInstallationPath

path were ssh/plink exe to be used by Net::SFTP::Foreign is located

=item type

(A)scii or (B)inary, only applies to Net::FTP

=item user

set user directly, either directly (insecure -> visible) or via sensitive lookup

=back

=item process

used to pass information within each process (data, additionalLookupData, filenames, hadErrors or commandline parameters starting with interactive) and for additional configurations not suitable for DB, File or FTP (e.g. uploadCMD* and onlyExecFor)

=over 4

=item additionalLookupData

additional data retrieved from database with EAI::Wrap::getAdditionalDBData

=item archivefilenames

in case a zip archive package is retrieved, the filenames of these packages are kept here, necessary for cleanup at the end of the process

=item countPercent

percentage for counting File text reading and DB storing, if given (greater 0) then on each reaching of the percentage in countPercent a progress is shown (e.g. every 10% if countPercent = 10). Any value >=100 will count ALL lines...

=item data

loaded data: array (rows) of hash refs (columns)

=item filenames

names of files that were retrieved and checked to be locally available for that load, can be more than the defined file in File->filename (due to glob spec or zip archive package)

=item filesProcessed

hash for checking the processed files, necessary for cleanup at the end of the whole task

=item hadErrors

set to 1 if there were any errors in the process

=item interactive_

interactive options (are not checked), can be used to pass arbitrary data via command line into the script (eg a selected date for the run with interactive_date).

=item onlyExecFor

define loads to only be executed when $common{task}{execOnly} !~ $load->{process}{onlyExecFor}. Empty onlyExecFor loads are always executed regardless of $common{task}{execOnly}

=item successfullyDone

accumulates API sub names to prevent most API calls that ran successfully from being run again.

=item uploadCMD

upload command for use with uploadFileCMD

=item uploadCMDPath

path of upload command

=item uploadCMDLogfile

logfile where command given in uploadCMD writes output (for error handling)

=back

=item task

contains parameters used on the task script level, only available for %common parameter hash.

=over 4

=item customHistoryTimestamp

optional custom timestamp to be added to filenames moved to History/HistoryUpload/FTP archive, if not given, get_curdatetime is used (YYYYMMDD_hhmmss)

=item execOnly

do not execute loads where $common{task}{execOnly} !~ $load->{process}{onlyExecFor}. Empty onlyExecFor loads are always executed regardless of $common{task}{execOnly}

=item ignoreNoTest

ignore the notest file in the process-script folder, usually preventing all runs that are not in production

=item plannedUntil

latest time that planned repetition should start, this can be given either as HHMM (HourMinute) or HHMMSS (HourMinuteSecond), in case of HHMM the "Second" part is attached as 59

=item redoFile

flag for specifying a redo

=item redoTimestampPatternPart

part of the regex for checking against filename in redo with additional timestamp/redoDir pattern (e.g. "redo", numbers and _), anything after files barename (and before ".$ext" if extension is defined) is regarded as a timestamp. Example: '[\d_]', the regex is built like ($ext ? qr/$barename($redoTimestampPatternPart|$redoDir)*\.$ext/ : qr/$barename($redoTimestampPatternPart|$redoDir)*.*/)

=item retryEndsAfterMidnight

if set, all retries should end after midnight

=item retrySecondsErr

retry period in case of error

=item retrySecondsErrAfterXfails

after fail count is reached this alternate retry period in case of error is applied. If 0/undefined then job finishes after fail count

=item retrySecondsXfails

fail count after which the retrySecondsErr are changed to retrySecondsErrAfterXfails

=item retrySecondsPlanned

retry period in case of planned retry

=item skipHolidays

skip script execution on holidays

=item skipHolidaysDefault

holiday calendar to take into account for skipHolidays

=item skipWeekends

skip script execution on weekends

=item skipForFirstBusinessDate

used for "wait with execution for first business date", either this is a calendar or 1 (then calendar is skipHolidaysDefault), this cannot be used together with skipHolidays

=back

=back

=head1 COPYRIGHT

Copyright (c) 2024 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut