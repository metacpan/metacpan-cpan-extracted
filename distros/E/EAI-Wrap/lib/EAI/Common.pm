package EAI::Common 0.3;

use strict;
use Exporter; use Log::Log4perl qw(get_logger); use EAI::DateUtil; use Data::Dumper; use Getopt::Long qw(:config no_ignore_case); use Scalar::Util qw(looks_like_number);
# to make use of colored logs with Log::Log4perl::Appender::ScreenColoredLevels on windows we have to use that (special "use" to make this optional on non-win environments)
BEGIN {
	if ($^O =~ /MSWin/) {require Win32::Console::ANSI; Win32::Console::ANSI->import();}
}

our @ISA = qw(Exporter);
our @EXPORT = qw($EAI_WRAP_CONFIG_PATH $EAI_WRAP_SENS_CONFIG_PATH %common %config %execute @loads @optload %opt readConfigFile getSensInfo setupConfigMerge getOptions setupEAIWrap extractConfigs checkHash checkParam getLogFPathForMail getLogFPath MailFilter setErrSubject setupLogging checkStartingCond sendGeneralMail looks_like_number get_logger);

my %hashCheck = (
	common => {
		DB => {},
		File => {},
		FTP => {},
		process => {},
		task => {},
	},
	config => { # parameter category for site global settings, defined in site.config and other associated configs loaded at INIT
		checkLookup => {"test.pl" => {errmailaddress => "",errmailsubject => "",timeToCheck =>, freqToCheck => "", logFileToCheck => "", logcheck => "",logRootPath =>""},}, # used for logchecker, each entry of the hash defines a log to be checked, defining errmailaddress to receive error mails, errmailsubject, timeToCheck as earliest time to check for existence in log, freqToCheck as frequency of checks (daily/monthly/etc), logFileToCheck as the name of the logfile to check, logcheck as the regex to check in the logfile and logRootPath as the folder where the logfile is found. lookup key: $execute{scriptname} + $execute{addToScriptName}
		errmailaddress => "", # default mail address for central logcheck/errmail sending 
		errmailsubject => "", # default mail subject for central logcheck/errmail sending 
		executeOnInit => "", # code to be executed during INIT of EAI::Wrap to allow for assignment of config/execute parameters from commandline params BEFORE Logging!
		folderEnvironmentMapping => {Test => "Test", Dev => "Dev", "" => "Prod"}, # Mapping for $execute{envraw} to $execute{env}
		fromaddress => "", # from address for central logcheck/errmail sending, also used as default sender address for sendGeneralMail
		historyFolder => {"" => "default",}, # folders where downloaded files are historized, lookup key as checkLookup, default in "" =>
		historyFolderUpload => {"" => "default",}, # folders where uploaded files are historized, lookup key as checkLookup, default in "" =>
		logCheckHoliday => "", # calendar for business days in central logcheck/errmail sending
		logs_to_be_ignored_in_nonprod => '', # logs to be ignored in central logcheck/errmail sending
		logRootPath => {"" => "default",}, # paths to log file root folders (environment is added to that if non production), lookup key as checkLookup, default in "" =>
		redoDir => {"" => "default",}, # folders where files for redo are contained, lookup key as checkLookup, default in "" =>
		sensitive => {"prefix" => {user=>"",pwd =>"",hostkey=>"",privkey =>""},}, # hash lookup for sensitive access information in DB and FTP (lookup keys are set with DB{prefix} or FTP{prefix}), may also be placed outside of site.config; all sensitive keys can also be environment lookups, e.g. hostkey=>{Test => "", Prod => ""} to allow for environment specific setting
		smtpServer => "", # smtp server for den (error) mail sending
		smtpTimeout => 60, # timeout for smtp response
		testerrmailaddress => '', # error mail address in non prod environment
		DB => {},
		File => {},
		FTP => {},
		process => {},
		task => {},
	},
	execute => { # hash of parameters for current task execution which is not set by the user but can be used to set other parameters and control the flow
		alreadyMovedOrDeleted => {}, # hash for checking the already moved or deleted files, to avoid moving/deleting them again at cleanup
		addToScriptName => "", # this can be set to be added to the scriptname for config{checkLookup} keys, e.g. some passed parameter.
		env => "", # Prod, Test, Dev, whatever
		envraw => "", # Production has a special significance here as being the empty string (used for paths). Otherwise like env.
		errmailaddress => "", # for central logcheck/errmail sending in current process
		errmailsubject => "", # for central logcheck/errmail sending in current process
		failcount => 1, # for counting failures in processing to switch to longer wait period or finish altogether
		filesToArchive => [], # list of files to be moved in archiveDir on FTP server, necessary for cleanup at the end of the process
		filesToDelete => [], # list of files to be deleted on FTP server, necessary for cleanup at the end of the process
		filesToMoveinHistory => [], # list of files to be moved in historyFolder locally, necessary for cleanup at the end of the process
		filesToMoveinHistoryUpload => [], # list of files to be moved in historyFolderUpload locally, necessary for cleanup at the end of the process
		filesToRemove => [], # list of files to be deleted locally, necessary for cleanup at the end of the process
		firstRunSuccess => 1, # for planned retries (process=>plannedUntil filled) -> this is set after the first run to avoid error messages resulting of files having been moved/removed.
		freqToCheck => "", # for logchecker:  frequency to check entries (B,D,M,M1) ...
		homedir => "", # the home folder of the script, mostly used to return from redo and other folders for globbing files.
		historyFolder => "", # actually set historyFolder
		historyFolderUpload => "", # actually set historyFolderUpload
		logcheck => "", # for logchecker: the Logcheck (regex)
		logFileToCheck => "", # for logchecker: Logfile to be searched
		logRootPath => "", # actually set logRootPath
		processEnd => 1, # specifies that the process is ended, checked in EAI::Wrap::processingEnd
		redoDir => "", # actually set redoDir
		retrievedFiles => [], # files retrieved from FTP or redo directory
		retryBecauseOfError => 1, # retryBecauseOfError shows if a rerun occurs due to errors (for successMail) and also prevents several API calls from being run again.
		retrySeconds => 60, # how many seconds are passed between retries. This is set on error with process=>retrySecondsErr and if planned retry is defined with process=>retrySecondsPlanned
		scriptname => "", # name of the current process script, also used in log/history setup together with addToScriptName for config{checkLookup} keys
		timeToCheck => "", # for logchecker: scheduled time of job (don't look earlier for log entries)
	},
	load => {
		DB => {},
		File => {},
		FTP => {},
		process => {},
	},
	DB => { # DB specific configs
		addID => {}, # this hash can be used to additionaly set a constant to given fields: Fieldname => Fieldvalue
		additionalLookup => "", # query used in getAdditionalDBData to retrieve lookup information from DB using readFromDBHash
		additionalLookupKeys => [], # used for getAdditionalDBData, list of field names to be used as the keys of the returned hash
		cutoffYr2000 => 60, # when storing date data with 2 year digits in dumpDataIntoDB/storeInDB, this is the cutoff where years are interpreted as 19XX (> cutoffYr2000) or 20XX (<= cutoffYr2000)
		columnnames => [], # returned column names from readFromDB and readFromDBHash, this is used in writeFileFromDB to pass column information from database to writeText
		database => "", # database to be used for connecting
		debugKeyIndicator => "", # used in dumpDataIntoDB/storeInDB as an indicator for keys for debugging information if primkey not given (errors are shown with this key information). Format is the same as for primkey
		deleteBeforeInsertSelector => "", # used in dumpDataIntoDB/storeInDB to delete specific data defined by keydata before an insert (first occurrence in data is used for key values). Format is the same as for primkey ("key1 = ? ...")
		dontWarnOnNotExistingFields => 0, # suppress warnings in dumpDataIntoDB/storeInDB for not existing fields
		dontKeepContent => 1, # if table should be completely cleared before inserting data in dumpDataIntoDB/storeInDB
		doUpdateBeforeInsert => 1, # invert insert/update sequence in dumpDataIntoDB/storeInDB, insert only done when upsert flag is set
		DSN => '', # DSN String for DB connection
		incrementalStore => 1, # when storing data with dumpDataIntoDB/storeInDB, avoid setting empty columns to NULL
		ignoreDuplicateErrs => 1, # ignore any duplicate errors in dumpDataIntoDB/storeInDB
		keyfields => [], # used for readFromDBHash, list of field names to be used as the keys of the returned hash
		longreadlen => 1024, # used for setting database handles LongReadLen parameter for DB connection, if not set defaults to 1024
		noDBTransaction => 1, # don't use a DB transaction for dumpDataIntoDB
		noDumpIntoDB => 1, # if files from this load should not be dumped to the database
		postDumpExecs => [{execs => ['',''], condition => ''},], # done in dumpDataIntoDB after postDumpProcessing and before commit/rollback. doInDB everything in execs if condition is fulfilled 
		postDumpProcessing => "", # done in dumpDataIntoDB after storeInDB, execute perl code in postDumpProcessing
		postReadProcessing => "", # done in writeFileFromDB after readFromDB, execute perl code in postReadProcessing
		prefix => "db", # key for sensitive information (e.g. pwd and user) in config{sensitive}
		primkey => "", # primary key indicator to be used for update statements, format: "key1 = ? AND key2 = ? ..."
		pwd => "", # for password setting, either directly (insecure -> visible) or via sensitive lookup
		query => "", # query statement used for readFromDB and readFromDBHash
		schemaName => "", # schemaName used in dumpDataIntoDB/storeInDB, if tableName contains dot the extracted schema from tableName overrides this. Needed for datatype information!
		server => {Prod => "", Test => ""}, # DB Server in environment hash
		tablename => "", # the table where data is stored in dumpDataIntoDB/storeInDB
		upsert => 1, # in dumpDataIntoDB/storeInDB, should an update be done after the insert failed (because of duplicate keys) or insert after the update failed (because of key not exists)?
		user => "", # for user setting, either directly (insecure -> visible) or via sensitive lookup
	},
	File => { # File parsing specific configs
		avoidRenameForRedo => 1, # when redoing, usually the cutoff (datetime/redo info) is removed following a pattern. set this flag to avoid this
		columns => {}, # for writeText: Hash of data fields, that are to be written (in order of keys)
		columnskip => {}, # for writeText: boolean hash of column names that should be skipped when writing the file ({column1ToSkip => 1, column2ToSkip => 1, ...})
		dontKeepHistory => 1, # if up- or downloaded file should not be moved into historyFolder but be deleted
		dontMoveIntoHistory => 1, # if up- or downloaded file should not be moved into historyFolder but be kept in homedir
		emptyOK => 0, # flag to specify whether empty files should not invoke an error message. Also needed to mark an empty file as processed in EAI::Wrap::markProcessed
		encoding => "", # text encoding of the file in question (e.g. :encoding(utf8))
		extract => 1, # flag to specify whether to extract files from archive package (zip)
		extension => "", # the extension of the file to be read (optional, used for redoFile)
		fieldCode => {}, # additional field based processing code: fieldCode => {field1 => 'perl code', ..}, invoked if key equals either header (as in format_header) or targetheader (as in format_targetheader) or invoked for all fields if key is empty {"" => 'perl code'}. set $skipLineAssignment to true (1) if current line should be skipped from data.
		filename => "", # the name of the file to be read
		firstLineProc => '', # processing done in reading the first line of text files
		format_allowLinefeedInData => 1, # line feeds in values don't create artificial new lines/records, only works for csv quoted data
		format_beforeHeader => "", # additional String to be written before the header in write text
		format_dateColumns => [], # numeric array of columns that contain date values (special parsing) in excel files
		format_decimalsep => "", # decimal separator used in numbers of sourcefile (defaults to . if not given)
		format_headerColumns => [], # optional numeric array of columns that contain data in excel files (defaults to all columns starting with first column up to format_targetheader length)
		format_header => "", # format_sep separated string containing header fields (optional in excel files, only used to check against existing header row)
		format_headerskip => 1, # skip until row-number for checking header row against format_header in excel files
		format_eol => "", # for quoted csv specify special eol character (allowing newlines in values)
		format_fieldXpath => {}, # for XML reading, hash with field => xpath to content association entries
		format_fix => 1, # for text writing, specify whether fixed length format should be used (requires format_padding)
		format_namespaces => {}, # for XML reading, hash with alias => namespace association entries
		format_padding => {}, # for text writing, hash with field number => padding to be applied for fixed length format
		format_poslen => [], # array of positions/length definitions: e.g. "poslen => [(0,3),(3,3)]" for fixed length format text file parsing
		format_quotedcsv => 1, # special parsing/writing of quoted csv data using Text::CSV
		format_sep => "", # separator string for csv format, regex for split for other separated formats. Also needed for splitting up format_header and format_targetheader (Excel and XML-formats use tab as default separator here).
		format_sepHead => "", # special separator for header row in write text, overrides format_sep
		format_skip => "", # either numeric or string, skip until row-number if numeric or appearance of string otherwise in reading textfile
		format_stopOnEmptyValueColumn => 1, # for excel reading, stop row parsing when a cell with this column number is empty (denotes end of data, to avoid very long parsing).
		format_suppressHeader => 1, # for textfile writing, suppress output of header
		format_targetheader => "", # format_sep separated string containing target header fields (= the field names in target/database table). optional for XML and tabular textfiles, defaults to format_header if not given there.
		format_thousandsep => "", # thousand separator used in numbers of sourcefile (defaults to , if not given)
		format_worksheetID => 1, # worksheet number for excel reading, this should always work
		format_worksheet => "", # alternatively the worksheet name can be passed, this only works for new excel format (xlsx)
		format_xlformat => "xlsx|xls", # excel format for parsing, also specifies excel parsing
		format_xpathRecordLevel => "", # xpath for level where data nodes are located in xml
		format_XML => 1, # specify xml parsing
		lineCode => "", # additional line based processing code, invoked after whole line has been read
		localFilesystemPath => "", # if files are taken from or put to the local file system with getLocalFiles/putFileInLocalDir then the path is given here. Setting this to "." avoids copying files.
		optional => 1, # to avoid error message for missing optional files, set this to 1
	},
	FTP => { # FTP specific configs
		archiveDir => "", # folder for archived files on the FTP server
		dontMoveTempImmediately => 1, # if 0 oder missing: rename/move files immediately after writing to FTP to the final name, otherwise/1: a call to EAI::FTP::moveTempFiles is required for that
		dontDoSetStat => 1, # for Net::SFTP::Foreign, no setting of time stamp of remote file to that of local file (avoid error messages of FTP Server if it doesn't support this)
		dontDoUtime => 1, # don't set time stamp of local file to that of remote file
		dontUseQuoteSystemForPwd => 0, # for windows, a special quoting is used for passing passwords to Net::SFTP::Foreign that contain [()"<>& . This flag can be used to disable this quoting.
		dontUseTempFile => 1, # directly upload files, without temp files
		fileToArchive => 1, # should file be archived on FTP server? requires archiveDir to be set
		fileToRemove => 1, # should file be removed on FTP server?
		FTPdebugLevel => 0, # debug ftp: 0 or ~(1|2|4|8|16|1024|2048), loglevel automatically set to debug for module EAI::FTP
		hostkey => "", # hostkey to present to the server for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup
		localDir => "", # optional: local folder for files to be placed, if not given files are downloaded into current folder
		maxConnectionTries => 5, # maximum number of tries for connecting in login procedure
		onlyArchive => 0, # only archive/remove on the FTP server, requires archiveDir to be set
		path => "", # additional relative FTP path (under remoteDir which is set at login), where the file(s) is/are located
		port => 22, # ftp/sftp port (leave empty for default port 22)
		prefix => "ftp", # key for sensitive information (e.g. pwd and user) in config{sensitive}
		privKey => "", # sftp key file location for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup
		pwd => "", # for password setting, either directly (insecure -> visible) or via sensitive lookup
		queue_size => 1, # queue_size for Net::SFTP::Foreign, if > 1 this causes often connection issues
		remove => {removeFolders=>[], day=>, mon=>, year=>1}, # for for removing (archived) files with removeFilesOlderX, all files in removeFolders are deleted being older than day=> days, mon=> months and year=> years
		remoteDir => "", # remote root folder for up-/download, archive and remove: "out/Marktdaten/", path is added then for each filename (load)
		remoteHost => {Prod => "", Test => ""}, # ref to hash of IP-addresses/DNS of host(s).
		SFTP => 0, # to explicitly use SFTP, if not given SFTP will be derived from existence of privKey or hostkey
		simulate => 0, # for removal of files using removeFilesinFolderOlderX/removeFilesOlderX only simulate (1) or do actually (0)?
		sshInstallationPath => "", # path were ssh/plink exe to be used by Net::SFTP::Foreign is located
		type => "", # (A)scii or (B)inary
		user => "", # set user directly, either directly (insecure -> visible) or via sensitive lookup
	},
	process => { # used to pass information within each process (data, additionalLookupData, filenames, hadErrors or commandline parameters starting with interactive) and for additional configurations not suitable for DB, File or FTP (e.g. uploadCMD* and onlyExecFor)
		additionalLookupData => {}, # additional data retrieved from database with EAI::Wrap::getAdditionalDBData
		archivefilenames => [], # in case a zip archive package is retrieved, the filenames of these packages are kept here, necessary for cleanup at the end of the process
		data => [], # loaded data: array (rows) of hash refs (columns)
		filenames => [], # names of files that were retrieved and checked to be locally available for that load, can be more than the defined file in File->filename (due to glob spec or zip archive package)
		filesProcessed => {}, # hash for checking the processed files, necessary for cleanup at the end of the whole task
		hadErrors => 1, # set to 1 if there were any errors in the process
		interactive_ => "", # interactive options (are not checked), can be used to pass arbitrary data via command line into the script (eg a selected date for the run with interactive_date).
		onlyExecFor => qr//, # mark loads to only be executed when $common{task}{execOnly} !~ $load->{process}{onlyExecFor}
		uploadCMD => "", # upload command for use with uploadFileCMD
		uploadCMDPath => "", # path of upload command
		uploadCMDLogfile => "", # logfile where command given in uploadCMD writes output (for error handling)
	},
	task => { # contains parameters used on the task script level
		customHistoryTimestamp => "", # optional custom timestamp to be added to filenames moved to History/HistoryUpload/FTP archive, if not given, get_curdatetime is used (YYYYMMDD_hhmmss)
		execOnly => "", # used to remove loads where $common{task}{execOnly} !~ $load->{process}{onlyExecFor}
		ignoreNoTest => 0, # ignore the notest file in the process-script folder, usually preventing all runs that are not in production
		plannedUntil => "2359", # latest time that planned repitition should last
		redoFile => 1, # flag for specifying a redo
		redoTimestampPatternPart => "", # part of the regex for checking against filename in redo with additional timestamp/redoDir pattern (e.g. "redo", numbers and _), anything after files barename (and before ".$ext" if extension is defined) is regarded as a timestamp. Example: '[\d_]', the regex is built like ($ext ? qr/$barename($redoTimestampPatternPart|$redoDir)*\.$ext/ : qr/$barename($redoTimestampPatternPart|$redoDir)*.*/)
		retrySecondsErr => 60, # retry period in case of error
		retrySecondsErrAfterXfails => 600, # after fail count is reached this alternate retry period in case of error is applied. If 0/undefined then job finishes after fail count
		retrySecondsXfails => 3, # fail count after which the retrySecondsErr are changed to retrySecondsErrAfterXfails
		retrySecondsPlanned => 300, # retry period in case of planned retry
		skipHolidays => 0, # skip script execution on holidays
		skipHolidaysDefault => "AT", # holiday calendar to take into account for skipHolidays
		skipWeekends => 0, # skip script execution on weekends
		skipForFirstBusinessDate => 0, # used for "wait with execution for first business date", either this is a calendar or 1 (then calendar is skipHolidaysDefault), this cannot be used together with skipHolidays
	},
);
# ignore type checking for these as they might have different types
my %ignoreType = (
	Filecolumns => 1, # can be ref to hash or ref to array
	Fileformat_skip => 1, # can be line number (int) or "skip until pattern" string
	Fileformat_sep => 1, # can be regex split or separator string
	taskskipHolidays => 1, # can be true (1) or calendar string
);

our %common;our %config;our @loads;our %execute;our @optload;our %opt;
our $EAI_WRAP_CONFIG_PATH; our $EAI_WRAP_SENS_CONFIG_PATH;
my @coreConfig = ("DB","File","FTP","process");
my @commonCoreConfig = (@coreConfig,"task");
my @allConfig = (@commonCoreConfig,"config");
my $logConfig;

# read given config file (eval perl code)
sub readConfigFile ($) {
	my $configfilename = shift;
	my $siteCONFIGFILE;
	open (CONFIGFILE, "<$configfilename") or die("couldn't open $configfilename: $@ $!, caller ".(caller(1))[3].", line ".(caller(1))[2]." in ".(caller(1))[1]);
	{
		local $/=undef;
		$siteCONFIGFILE = <CONFIGFILE>;
		close CONFIGFILE;
	}
	unless (my $return = eval $siteCONFIGFILE) {
		die("Error parsing config file $configfilename: $@") if $@;
		die("Error executing config file $configfilename: $!") unless defined $return;
		die("Error executing config file $configfilename") unless $return;
	}
	print STDOUT "read $configfilename\n";
}

# get sensitive info from $config{sensitive}{$prefix}{$key}
sub getSensInfo ($$) {
	my ($prefix,$key) = @_;
	# depending on queried key being a ref to hash, get the environment lookup hash key value or the value directly
	return (ref($config{sensitive}{$prefix}{$key}) eq "HASH" ? $config{sensitive}{$prefix}{$key}{$execute{env}} : $config{sensitive}{$prefix}{$key});
}

# setupConfigMerge creates cascading inheritance of config/DB/File/FTP/process/task settings
sub setupConfigMerge {
	my $logger = get_logger();
	for (@commonCoreConfig) {
		# fill missing keys in order to avoid Can't use an undefined value as a HASH reference errors in hash config merging later
		$common{$_} = {} if !defined($common{$_});
		$config{$_} = {} if !defined($config{$_});
		$opt{$_} = {} if !defined($opt{$_});
	}
	# check for unintended mergin/inheritance into sections of loads defined with underscore (inheritance prevention)
	for my $check (0..$#loads) {
		for my $hashName (@allConfig) {
			if (defined($loads[$check]{$hashName."_"})) {
				# first write the $hashName."_" values into the normal config hash...
				for my $defkey (keys %{$loads[$check]{$hashName."_"}}) {
					$loads[$check]{$hashName}{$defkey} = $loads[$check]{$hashName."_"}{$defkey};
				}
				for my $defkey (keys %{$common{$hashName}}) {
					if (!defined($loads[$check]{$hashName."_"}{$defkey})) {
						$loads[$check]{$hashName}{$defkey} = undef;
						$logger->debug("creating empty $hashName\{$defkey\} in load $check instead of inheriting as ${hashName}_ is given here");
					}
				}
				delete $loads[$check]{$hashName."_"}; # need to remove otherwise checkHash below throws an error for these...
			}
		}
	}
	# do check before the merging below removes all nonconforming entries.
	checkHash(\%config,"config") or $logger->error($@);
	checkHash(\%common,"common") or $logger->error($@);
	for my $i (0..$#loads) {checkHash($loads[$i],"load") or $logger->error($@);}

	# merge cmdline option overrides into toplevel global config (DB, FTP, File and process overrides are merged directly into common below)...
	%config=(%config,%{$opt{config}}) if $opt{config};
	# merge DB/FTP/File/process/task sections from global config and cmdline options into common...
	%common=(DB=>{%{$config{DB}},%{$common{DB}},%{$opt{DB}}},FTP=>{%{$config{FTP}},%{$common{FTP}},%{$opt{FTP}}},File=>{%{$config{File}},%{$common{File}},%{$opt{File}}},process=>{%{$config{process}},%{$common{process}},%{$opt{process}}},task=>{%{$config{task}},%{$common{task}},%{$opt{task}}},);
	# now merge above into the the loads including cmdline options, except the task section...
	for my $i (0..$#loads) {
		# fill missing keys in order to avoid Can't use an undefined value as a HASH reference errors in hash config merging later
		for (@coreConfig) {
			$loads[$i]{$_} = {} if !defined($loads[$i]{$_});
			$optload[$i]{$_} = {} if !defined($optload[$i]{$_});
		}
		# merge common and cmdline option overrides into loads
		$loads[$i]={DB=>{%{$common{DB}},%{$loads[$i]{DB}},%{$optload[$i]{DB}}},FTP=>{%{$common{FTP}},%{$loads[$i]{FTP}},%{$optload[$i]{FTP}}},File=>{%{$common{File}},%{$loads[$i]{File}},%{$optload[$i]{File}}},process=>{%{$common{process}},%{$loads[$i]{process}},%{$optload[$i]{process}}}};
	}
	# remove load elements where $common{task}{execOnly} !~ $load->{process}{onlyExecFor}
	my $i;
	do {
		if ($common{task}{execOnly} and $common{task}{execOnly} !~ $loads[$i]{process}{onlyExecFor}) {
			$logger->debug("removing load $i because \$common{task}{execOnly} given and $common{task}{execOnly} !~ $loads[$i]{process}{onlyExecFor} (\$load{process}{onlyExecFor})");
			splice @loads, $i, 1;
		}
		$i++;
	} while $i <= $#loads;
}

# get options for overriding configured settings
sub getOptions {
	# construct option definitions for Getopt::Long::GetOptions, everything parsed as a string first
	my %optiondefs = ("DB=s%" => \$opt{DB}, "FTP=s%" => \$opt{FTP}, "File=s%" => \$opt{File},"process=s%" => \$opt{process}, "task=s%" => \$opt{task}, "config=s%" => \$opt{config}); # first option overrides for common
	for my $i (0..$#loads) {
		# then option overrides for each load
		 %optiondefs = (%optiondefs, "load${i}DB=s%" => \$optload[$i]{DB}, "load${i}FTP=s%" => \$optload[$i]{FTP}, "load${i}File=s%" => \$optload[$i]{File},"load${i}process=s%" => \$optload[$i]{process});
	}
	Getopt::Long::GetOptions(%optiondefs);
	# now correct strings to numeric where needed, also checking validity
	my $errStr;
	for my $hashName (@allConfig) {
		for my $defkey (keys %{$opt{$hashName}}) {
			# allow only options predefined in $hashCheck or generic option --process interactive.*=..., here everything can be passed into the process script
			unless (exists($hashCheck{$hashName}{$defkey}) or ($hashName eq "process" and $defkey =~ /interactive.*/)) {
				$errStr.="option not allowed: --$hashName $defkey=<value>\n";
			} else {
				$opt{$hashName}{$defkey} = 0+$opt{$hashName}{$defkey} if looks_like_number($hashCheck{$hashName}{$defkey});
			}
		}
		for my $i (0..$#loads) {
			next if $hashName eq "config" or $hashName eq "task" ; # no config or task section in loads...
			for my $defkey (keys %{$optload[$i]{$hashName}}) {
				# allow only options predefined in $hashCheck or generic option --process interactive.*=..., here everything can be passed into the process script
				unless (exists($hashCheck{$hashName}{$defkey}) or ($hashName eq "process" and $defkey =~ /interactive.*/)) {
					$errStr.="option not allowed: --load$i$hashName $defkey=<value>\n";
				} else {
					$optload[$i]{$hashName}{$defkey} = 0+$optload[$i]{$hashName}{$defkey} if looks_like_number($hashCheck{$hashName}{$defkey});
				}
			}
		}
	}
	if ($errStr) {
		my $availabeOpts;
		for my $hashName (sort @allConfig) {
			for my $defkey (sort keys %{$hashCheck{$hashName}}) {
				$availabeOpts.="--$hashName $defkey=<value>\n" if ref($hashCheck{$hashName}{$defkey}) ne "HASH" and ref($hashCheck{$hashName}{$defkey}) ne "ARRAY";
			}
		}
		die $errStr."===> available options (use --load<N><group> instead of --<group> for load specific settings):\n".$availabeOpts;
	}
}

# extract config hashes (DB,FTP,File,process; task is always part of common, which is always there) from $arg hash and return as list of hashes. The config hashes to be extracted are given in string list @required and returned in @ret
# side effect: sets error subject to first argument $contextSub if ne ""
sub extractConfigs ($$$;@) {
	my ($contextSub,$arg,@required) = @_;
	my $logger = get_logger();
	$logger->debug(($contextSub ? $contextSub." for " : "").(caller(1))[3]);
	setErrSubject($contextSub) if $contextSub;
	my @ret;
	if (ref($arg) eq "HASH") {
		for my $req (@required) {
			push(@ret, \%{$arg->{$req}}); # return the required subhash into the list of hashes
			checkHash($ret[$#ret],$req) or $logger->error($@); # check last added hash after adding it...
		}
		checkHash(\%execute,"execute") or $logger->error($@); # also check always the execute hash ...
	} else {
		my $errStr = "no ref to hash passed when calling ".(caller(1))[3].", line ".(caller(1))[2]." in ".(caller(1))[1];
		$logger->error($errStr);
	}
	return @ret;
}

# check config hash passed in $hash for validity against hashCheck (valid key entries are there + their valid value types (examples)). returns 0 on error and exception $@ contains details
sub checkHash ($$) {
	my ($hash, $hashName) = @_;
	my $locStr = " when calling ".(caller(2))[3].", line ".(caller(2))[2]." in ".(caller(2))[1];
	eval {
		for my $defkey (keys %{$hash}) {
			unless ($hashName eq "process" and $defkey =~ /interactive.*/) {
				if (!exists($hashCheck{$hashName}{$defkey})) {
					die "key name not allowed: \$".$hashName."{".$defkey."},".$locStr;
				} else {
					# check type for existing keys, if explicitly not defined then ignore...
					if (defined($hash->{$defkey})) {
						die "wrong reference type for value: \$".$hashName."{".$defkey."}: ".ref($hashCheck{$hashName}{$defkey})." not like passed:".ref($hash->{$defkey}).",".$locStr if (ref($hashCheck{$hashName}{$defkey}) ne ref($hash->{$defkey}) && !$ignoreType{$hashName.$defkey});
						die "wrong type for value: \$".$hashName."{".$defkey."},".$locStr if (looks_like_number($hashCheck{$hashName}{$defkey}) ne looks_like_number($hash->{$defkey}) && !$ignoreType{$hashName.$defkey});
					}
				}
			}
		}
	};
	return 0 if $@;
	return 1;
}

# check parameter passed in $subhash
sub checkParam ($$) {
	my ($subhash,$keytoCheck) = @_;
	my $logger = get_logger();
	if (ref($subhash) ne "HASH") {
		$logger->error("passed argument subhash to checkParam is not a hash");
		return 0;
	}
	my ($subhashname) = split /=/, Dumper($subhash);
	$subhashname =~ s/\$//;
	if (!defined($subhash->{$keytoCheck})) {
		$logger->error("key $keytoCheck not defined in subhash ".Dumper($subhash));
		return 0;
	} elsif (!$subhash->{$keytoCheck} and !looks_like_number($hashCheck{$subhashname}{$keytoCheck})) {
		$logger->error("value of key $keytoCheck empty in subhash ".Dumper($subhash));
		return 0;
	}
	return 1;
}

# path of logfile and path of yesterdays logfile (after rolling) - getLogFPathForMail and getLogFPath can be used in site-wide log.config
our ($LogFPath, $LogFPathDayBefore);
sub getLogFPathForMail {
	return 'file://'.$LogFPath.', or '.'file://'.$LogFPathDayBefore;
};
sub getLogFPath {
	return $LogFPath;
};

# MailFilter is used for filtering error logs (called in log.config) if error was already sent by mail (otherwise floods)...
my $alreadySent = 0;
sub MailFilter {
	my %p = @_;
	return (!$alreadySent and ($p{log4p_level} eq "ERROR" or $p{log4p_level} eq "FATAL") ? $alreadySent = 1 : 0);
};

# sets the error subject for the subsequent error mails from logger->error()
sub setErrSubject ($) {
	my $context = shift;
	Log::Log4perl->appenders()->{"MAIL"}->{"appender"}->{"subject"} = [($execute{envraw} ? $execute{envraw}.": " : "").$execute{errmailsubject}.": $context"];
}

# setup logging for Log4perl
sub setupLogging {
	# get logRootPath, historyFolder, historyFolderUpload and redoDir from lookups in config.
	# if they are not in the script home directory (having an absolute path) then build environment-path separately for end folder (script home directory is already in its environment)
	for my $foldKey ("redoDir","logRootPath","historyFolder","historyFolderUpload") {
		my $folder = $config{$foldKey}{$execute{scriptname}.$execute{addToScriptName}};
		my $defaultFolder;
		if (!$folder) {
			$folder = $config{$foldKey}{""}; # take default, if no lookup defined for script
			$defaultFolder = 1;
		}
		if ($folder =~ /^(\S:)*[\\|\/](.*?)$/) {
			my ($folderPath,$endFolder) = ($folder =~ /(.*)[\\|\/](.*?)$/); # both slash as well as backslash act as path separator for last part
			# default Folder is built differently: folderPath/endFolder/environ instead of folderPath/environ/endFolder
			$execute{$foldKey} = ($defaultFolder ? $folderPath."/".$endFolder.($execute{envraw} ? "/".$execute{envraw} : "") : $folderPath.($execute{envraw} ? "/".$execute{envraw} : "")."/".$endFolder);
		} else {
			$execute{$foldKey} = $folder;
		}
	}
	my $logFolder = $execute{logRootPath};
	# if logFolder doesn't exist, warn and log to $execute{homedir}.
	my $noLogFolderErr;
	if (! -e $logFolder) {
		$noLogFolderErr = "can't log to logfolder $logFolder (set specially for script with \$config{logRootPath}{".$execute{scriptname}.$execute{addToScriptName}."} or default with \$config{logRootPath}{\"\"}), folder doesn't exist. Setting to $execute{homedir}";
		$logFolder = $execute{homedir};
	}
	$LogFPath = $logFolder."/".$execute{scriptname}.".log";
	$LogFPathDayBefore = $logFolder."/".get_curdate().".". $execute{scriptname}.".log"; # if mail is watched next day, show the rolled file here
	$logConfig = $EAI_WRAP_CONFIG_PATH."/".$execute{envraw}."/log.config"; # environment dependent log config, Prod is in EAI_WRAP_CONFIG_PATH
	$logConfig = $EAI_WRAP_CONFIG_PATH."/log.config" if (! -e $logConfig); # fall back to main config log.config
	die "log.config neither in $logConfig nor in ".$EAI_WRAP_CONFIG_PATH."/log.config" if (! -e $logConfig);
	Log::Log4perl::init($logConfig);
	my $logger = get_logger();
	$logger->warn($noLogFolderErr) if $noLogFolderErr;
	if ($config{smtpServer}) {
		# configure err mail sending
		MIME::Lite->send('smtp', $config{smtpServer}, AuthUser=>$config{sensitive}{smtpAuth}{user}, AuthPass=>$config{sensitive}{smtpAuth}{pwd}, Timeout=>$config{smtpTimeout});
		# get email from central log error handling $config{checkLookup}{<>};
		$execute{errmailaddress} = $config{checkLookup}{$execute{scriptname}.$execute{addToScriptName}}{errmailaddress}; # errmailaddress for the task script
		$execute{errmailsubject} = $config{checkLookup}{$execute{scriptname}.$execute{addToScriptName}}{errmailsubject}; # errmailsubject for the task script
		$execute{errmailaddress} = $config{errmailaddress} if !$execute{errmailaddress};
		$execute{errmailsubject} = $config{errmailsubject} if !$execute{errmailsubject};
		$execute{errmailaddress} = $config{testerrmailaddress} if $execute{envraw};
		if ($execute{errmailaddress}) {
			Log::Log4perl->appenders()->{"MAIL"}->{"appender"}->{"to"} = [$execute{errmailaddress}];
		} else {
			# Production: no errmailaddress found, error message to Testerrmailaddress (if set)
			Log::Log4perl->appenders()->{"MAIL"}->{"appender"}->{"to"} = [$config{testerrmailaddress}] if $config{testerrmailaddress};
			$logger->error("no errmailaddress found for ".$execute{scriptname}.$execute{addToScriptName}.", no entry found in \$config{checkLookup}{$execute{scriptname}.$execute{addToScriptName}}");
		}
		setErrSubject("Setting up EAI.Wrap"); # general context after logging initialization: setup of EAI.Wrap by script
	}
}

# set up EAI configuration
sub setupEAIWrap {
	my $logger = get_logger();
	setupConfigMerge(); # %config (from site.config, amended with command line options) and %common (from process script, amended with command line options) are merged into %common and all @loads (amended with command line options)
	# starting log entry: process script name + %common parameters, used for process monitoring (%config is not written due to sensitive information)
	$Data::Dumper::Indent = 0; # temporarily flatten dumper output for single line
	$Data::Dumper::Sortkeys = 1; # sort keys to get outputs easier to read
	my $configdump = Dumper(\%common);
	$configdump =~ s/\s+//g;$configdump =~ s/\$VAR1=//;$configdump =~ s/,'/,/g;$configdump =~ s/{'/{/g;$configdump =~ s/'=>/=>/g; # compress information
	my $exedump = Dumper(\%execute);
	$exedump =~ s/\s+//g;$exedump =~ s/\$VAR1=//;$exedump =~ s/,'/,/g;$exedump =~ s/{'/{/g;$exedump =~ s/'=>/=>/g; # compress information
	$logger->info("==============================================================================================");
	$logger->info("started $execute{scriptname} in $execute{homedir} (environment $execute{env}), execute parameters: $exedump common parameters: $configdump");
	if ($logger->is_debug) {
		for my $i (0..$#loads) {
			my $loaddump = Dumper($loads[$i]);
			$loaddump =~ s/\s+//g;$loaddump =~ s/\$VAR1=//;$loaddump =~ s/,'/,/g;$loaddump =~ s/{'/{/g;$loaddump =~ s/'=>/=>/g; # compress information
			$logger->debug("load $i parameters: $loaddump");
		}
	}
	$Data::Dumper::Indent = 2;
	# check starting conditions and exit if met (returned true)
	checkStartingCond(\%common) and exit 0;
	setErrSubject("General EAI.Wrap script execution"); # general context after setup of EAI.Wrap
}

# refresh modules and logging config for changes
sub refresh() {
	# refresh modules to enable correction of processing without restart
	Module::Refresh->refresh;
	# also check for changes in logging configuration
	Log::Log4perl::init($logConfig);
}

# check starting conditions and return 1 if met
sub checkStartingCond ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($task) = extractConfigs("checking starting conditions",$arg,"task");

	my $curdate = get_curdate();
	# skipHolidays is either a calendar or 1 (then defaults to $task->{skipHolidaysDefault})
	my $holidayCal = $task->{skipHolidays} if $task->{skipHolidays};
	# skipForFirstBusinessDate is for "wait with execution for first business date", either this is a calendar or 1 (then calendar is skipHolidaysDefault), this cannot be used together with skipHolidays
	$holidayCal = $task->{skipForFirstBusinessDate} if $task->{skipForFirstBusinessDate};
	# default setting (1 becomes $task->{skipHolidaysDefault})
	$holidayCal = $task->{skipHolidaysDefault} if ($task->{skipForFirstBusinessDate} == 1 or $task->{skipHolidays} == 1);
	if ($holidayCal) {
		if (is_holiday($holidayCal,$curdate) and !$task->{redoFile}) {
			$logger->info("skip processing (skipHolidays = ".$task->{skipHolidays}.", skipForFirstBusinessDate = ".$task->{skipForFirstBusinessDate}.") as $curdate holiday in $holidayCal !");
			return 1;
		}
	}
	if (($task->{skipWeekends} or $task->{skipForFirstBusinessDate}) and is_weekend($curdate) and !$task->{redoFile}) {
		$logger->info("skip processing (skipWeekends = ".$task->{skipWeekends}.", skipForFirstBusinessDate = ".$task->{skipForFirstBusinessDate}.") as $curdate is day of weekend !");
		return 1;
	}
	# if there are were any business days (meaning that nonBusinessDays are less than calendar days) since the 1st of the month, then skip if $task->{skipForFirstBusinessDate}
	if ($task->{skipForFirstBusinessDate} and !$task->{redoFile}) {
		my $nonBusinessDays; 
		my $daysfrom1st = substr($curdate,-2)-1; # get the first decimal from day part of today, this is the number of days from the 1st
		# count non business days since the 1st of the month
		for (1..$daysfrom1st) {
			$nonBusinessDays += (is_weekend(subtractDays($curdate,$_)) or is_holiday($holidayCal,subtractDays($curdate,$_)));
		}
		if ($nonBusinessDays < $daysfrom1st) {
			$logger->info("skip processing (skipForFirstBusinessDate = ".$task->{skipForFirstBusinessDate}.") as processing already took place on a business day before $curdate!");
			return 1;
		}
	}
	# if notest file exists, then exit here if not set to ignore that...
	if (!$task->{ignoreNoTest} && -e "notest") {
		$logger->info("skip processing, because notest set (file exists).");
		return 1;
	}
	return 0;
}

# general mail sending for notifying of conditions/sending reports (for use in user specific code)
sub sendGeneralMail ($$$$$$;$$$$) {
	my ($From, $To, $Cc, $Bcc, $Subject, $Data, $Type, $Encoding, $AttachType, $AttachFile) = @_;
	my $logger = get_logger();
	$logger->info("sending general mail From:".($From ? $From : $config{fromaddress}).", To:".($execute{envraw} ? $config{testerrmailaddress} : $To).", CC:".($execute{envraw} ? "" : $Cc).", Bcc:".($execute{envraw} ? "" : $Bcc).", Subject:".($execute{envraw} ? $execute{envraw}.": " : "").$Subject.", Type:".($Type ? $Type : "TEXT").", Encoding:".($Type eq 'multipart/related' ? undef : $Encoding).", AttachType:$AttachType, AttachFile:$AttachFile ...");
	$logger->debug("Mailbody: $Data");
	my $msg = MIME::Lite->new(
			From    => ($From ? $From : $config{fromaddress}),
			To      => ($execute{envraw} ? $config{testerrmailaddress} : $To),
			Cc      => ($execute{envraw} ? "" : $Cc),
			Bcc     => ($execute{envraw} ? "" : $Bcc),
			Subject => ($execute{envraw} ? $execute{envraw}.": " : "").$Subject,
			Type    => ($Type ? $Type : "TEXT"),
			Data    => ($Type eq 'multipart/related' ? undef : $Data),
			Encoding => ($Type eq 'multipart/related' ? undef : $Encoding)
		);
	$logger->error("couldn't create msg  for mail sending..") unless $msg;
	if ($Type eq 'multipart/related') {
		$msg->attach(
			Type => 'text/html',
			Data    => $Data,
			Encoding => $Encoding
		);
		for (@$AttachFile) {
			$msg->attach(
				Encoding => 'base64',
				Type     => $AttachType,
				Path     => $_,
				Id       => $_,
			);
		}
	} elsif ($AttachFile and $AttachType) {
		$msg->attach(
			Type => $AttachType,
			Id   => $AttachFile,
			Path => $AttachFile
		);
	}
	$msg->send('smtp', $config{smtpServer}, AuthUser=>$config{smtpAuth}{user}, AuthPass=>$config{smtpAuth}{pwd});
	if ($msg->last_send_successful()) {
		$logger->info("Mail sent");
		$logger->trace("sent message: ".$msg->as_string) if $logger->is_trace();
	}
}
1;
__END__

=head1 NAME

EAI::Common - Common parts for the EAI::Wrap package

=head1 SYNOPSIS

 %config .. hash for global config (set in $EAI_WRAP_CONFIG_PATH/site.config, amended with $EAI_WRAP_CONFIG_PATH/additional/*.config)
 %common .. common load configs for the task script
 @loads .. list of hashes defining specific load processes
 %execute .. hash of parameters for current running task script

 readConfigFile
 getSensInfo
 setupConfigMerge
 getOptions
 extractConfigs
 checkHash
 setupEAIWrap
 getLogFPathForMail
 getLogFPath
 MailFilter
 setupLogging
 setErrSubject $context
 checkStartingCond $process
 sendGeneralMail $From, $To, $Cc, $Bcc, $Subject, $Type, $Data, $Encoding, $AttachType, $AttachFile

=head1 DESCRIPTION

EAI::Common contains common used functions for L<EAI::Wrap>. This is for reading config files, setting up the config hierarchy, including commandline options, setting up logging, including callbacks for the log.config, setting the error subject for error mails, checking starting conditions and a generic Mail sending.

=head2 API

=over

=item readConfigFile ($)

read given config file (eval perl code in site.config and related files)

=item getSensInfo ($$)

get sensitive info from $config{sensitive}{$prefix}{$key}, arguments are $prefix and $key, depending on queried key being a ref to hash, get the environment lookup hash key value or the value directly

=item setupConfigMerge

setupConfigMerge creates cascading inheritance of config/DB/File/FTP/process/task settings (lower means more precedence (overriding previously set parameters)):

 %config <-- config options from command line
 - is merged into -->
 %common (common task parameters defined in script) <-- DB, FTP, File, task and process options from command line
 - is merged into -->
 $loads[] <-- DB, FTP, File and process options from command line

=item getOptions

get options for overriding configured settings, results are stored in globally available hash %opt and list @optloads

=item extractConfigs ($$$;@)

sets error subject to $contextSub (first argument) and extracts config hashes (DB,FTP,File,process,task) from ref to hash $arg (second argument) and return them as a list of hashes. The config hashes to be extracted are given as strings in the following parameter list @required (at least one is required).

=item checkHash ($$)

check config hash passed in $hash for validity against hashCheck (valid key entries are there + their valid value types (examples)). returns 0 on error and exception $@ contains details, to allow for checkHash(..) or {handle exception}

=item checkParam ($$)

check parameter key from second argument within first argument $subhash, returns 0 if not defined or not existing (only non-numerics)

=item setupEAIWrap

Usually this is the first call after the configuration (assignments to %common and @loads) was defined.
This sets up the configuration internally and merges the hierarchy of configurations. 
Correctness of the configuration and starting conditions are also checked, preventing the task script's starting; finally all used parameters are written into the initial log line.

following three functions can be used in the central log.config as coderefs for callback.

=item getLogFPathForMail

for custom conversion specifiers: returns path of configured logfile resp logfile of previous day (as a file:// hyperlink)

=item getLogFPath

for file appender config, returns the path of current logfile.

=item MailFilter

for Mail appender config: used for filtering if further mails should be sent, contains throttling flag "alreadySent" for avoiding mail flooding when errors occur.

=item setErrSubject ($)

set context specific subject for ErrorMail

 $context .. text for context of subject

=item setupLogging

set up logging from site.config information (potentially split up using additional configs) and the central log.config. Important configs for logging in the config hash are logRootPath (direct or environment lookup setting for the log root folder), errmailaddress (default address for sending mails in case of error), errmailsubject (subject for error mails, can be changed with L<setErrSubject|/setErrSubject>), testerrmailaddress (default address for sending mails in case of error in non production environments), smtpServer (for error and other mail sending), smtpTimeout and checkLookup.

checkLookup is both used by checkLogExist.pl and setupLogging. The key is used to lookup the scriptname + any additional defined interactive options, which are being passed to the script in an alphabetically sorted manner. So, a call of C<mytask.pl --process interactive_addinfo=add12 interactive_type=type3 interactive_zone=zone4> would yield a lookup of C<mytask.pladd12type3zone4>, which should have an existing key in checkLookup, like C<$config{checkLookup} = {"mytask.pladd12type3zone4" =E<gt> {...}, ...}>.

Each entry of the sub-hash defines defines the errmailaddress to receive error mails and the errmailsubject, the rest is used by checkLogExist.pl.

=item checkStartingCond ($)

check starting conditions from process config information and return 1 if met

 $task .. config information

=item sendGeneralMail ($$$$$$;$$$$)

send general mail, either simple text or html mails, mails with an attachment or multipart mails for "in-body" attachments (eg pictures). 
In this case the mail body needs to be HTML, attachments are referred to inside the HTML code and are passed as a ref to array of paths in $AttachFile.
 
Example:

 # prepare body with refererring to attachments in a HTML table
 my $body='<style>table, th, td {border: 1px solid black;border-collapse: collapse;} th, td {padding: 5px;text-align: right;}}</style>';
 $body.='<table style="width:1600px; border:0; text-align:center;" cellpadding="0" cellspacing="0">
 <tr><td width="800px" height="800px"><img style="display:block;"  width="100%" height="100%" src="cid:relativePathToPic.png" alt="alternateDescriptionOfPic"/></td></tr>';
 # pass needed files to sendGeneralMail:
 my @filelist = glob("*.png");
 sendGeneralMail(undef,'address@somewhere.com',undef,undef,"subject for mail",$body,'multipart/related','quoted-printable','image/png',\@filelist);

parameters for sendGeneralMail

 $From .. sender
 $To .. recipient
 $Cc .. cc recipient (optional, but need arg)
 $Bcc .. mcc recipient  (optional, but need arg)
 $Subject .. mail subject
 $Data .. the mail body, either plain text or html.
 $Type .. mail mime type (eg text/plain, text/html oder 'multipart/related'), if 'multipart/related', then a ref to array to the filenames (path), that should be attached is expected to be set in $AttachFile. 
 In the above example a mail body ($Data) is being set as the first attachment and its type is text/html. The rest of the attachments from $AttachFile are encoded using base64 and all have mime type AttachType (see below).
 $Encoding .. encoding for mail body, optional (eg quoted-printable)
 $AttachType .. mime type for attachment(s) (eg text/csv or image/png), optional
 $AttachFile .. file name/path(s) for attachment(s), optional (hat to be ref to array, if $Type = 'multipart/related')

=back

=head1 COPYRIGHT

Copyright (c) 2023 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut