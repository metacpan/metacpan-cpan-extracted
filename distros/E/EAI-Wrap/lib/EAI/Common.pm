package EAI::Common 1.914;

use strict; use feature 'unicode_strings'; use warnings; no warnings 'uninitialized';
use Exporter qw(import); use EAI::DateUtil; use Data::Dumper qw(Dumper); use Getopt::Long qw(:config no_ignore_case); use Log::Log4perl qw(get_logger); use MIME::Lite (); use Scalar::Util qw(looks_like_number);
# to make use of colored logs with Log::Log4perl::Appender::ScreenColoredLevels on windows we have to use that (special "use" to make this optional on non-win environments)
BEGIN {
	if ($^O =~ /MSWin/) {require Win32::Console::ANSI; Win32::Console::ANSI->import();}
}

our @EXPORT = qw($EAI_WRAP_CONFIG_PATH $EAI_WRAP_SENS_CONFIG_PATH %common %config %execute @loads @optload %opt readConfigFile getSensInfo setupConfigMerge getOptions setupEAIWrap dumpFlat extractConfigs checkHash checkParam getLogFPathForMail getLogFPath MailFilter setErrSubject setupLogging checkStartingCond sendGeneralMail looks_like_number get_logger);

my %hashCheck = (
	common => {
		DB => {},
		File => {},
		FTP => {},
		process => {},
		task => {},
	},
	config => { # parameter category for site global settings, usually defined in site.config and other associated configs loaded at INIT
		checkLogExistDelay => {}, # ref to hash {Test => 2, Dev => 3, "" => 0}, mapping to set delays for checkLogExist per environment in $execute{env}, this can be further overriden per job (and environment) in checkLookup.
		checkLookup => {}, # ref to datastructure {"scriptname.pl + optional addToScriptName" => {errmailaddress => "",errmailsubject => "",timeToCheck =>"", freqToCheck => "", logFileToCheck => "", logcheck => "",logRootPath =>""},...} used for logchecker, each entry of the hash lookup table defines a log to be checked, defining errmailaddress to receive error mails, errmailsubject, timeToCheck as earliest time to check for existence in log, freqToCheck as frequency of checks (daily/monthly/etc), logFileToCheck as the name of the logfile to check, logcheck as the regex to check in the logfile and logRootPath as the folder where the logfile is found. lookup key: $execute{scriptname} + $execute{addToScriptName}
		errmailaddress => "", # default mail address for central logcheck/errmail sending 
		errmailsubject => "", # default mail subject for central logcheck/errmail sending 
		executeOnInit => "", # code to be executed during INIT of EAI::Wrap to allow for assignment of config/execute parameters from commandline params BEFORE Logging!
		folderEnvironmentMapping => {}, # ref to hash {Test => "Test", Dev => "Dev", "" => "Prod"}, mapping for $execute{envraw} to $execute{env}
		fromaddress => "", # from address for central logcheck/errmail sending, also used as default sender address for sendGeneralMail
		historyFolder => {}, # ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where downloaded files are historized, lookup key as in checkLookup, default in "" => "defaultfolder". historyFolder, historyFolderUpload, logRootPath and redoDir are always built with an environment subfolder, the default is built as folderPath/endFolder/environ, otherwise it is built as folderPath/environ/endFolder. Environment subfolders (environ) are also built depending on prodEnvironmentInSeparatePath: either folderPath/endFolder/$execute{env} (prodEnvironmentInSeparatePath = true, Prod has own subfolder) or folderPath/endFolder/$execute{envraw} (prodEnvironmentInSeparatePath = false, Prod is in common folder, other environments have their own folder)
		historyFolderUpload => {}, # ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where uploaded files are historized, lookup key as in checkLookup, default in "" => "defaultfolder"
		logCheckHoliday => "", # calendar for business days in central logcheck/errmail sending. builtin calendars are AT (Austria), TG (Target), UK (United Kingdom) and WE (for only weekends). Calendars can be added with EAI::DateUtil::addCalendar
		logs_to_be_ignored_in_nonprod => qr//, # regular expression to specify logs to be ignored in central logcheck/errmail sending
		logprefixForLastLogfile => sub {}, # prefix for previous (day) logs to be set in error mail (link), if not given, defaults to get_curdate(). In case Log::Dispatch::FileRotate is used as the File Appender in Log4perl config, the previous log is identified with <logname>.1
		logRootPath => {}, # ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, paths to log file root folders (environment is added to that if non production), lookup key as checkLookup, default in "" => "defaultfolder"
		prodEnvironmentInSeparatePath => 1, # set to 1 if the production scripts/logs etc. are in a separate Path defined by folderEnvironmentMapping (prod=root/Prod, test=root/Test, etc.), set to 0 if the production scripts/logs are in the root folder and all other environments are below that folder (prod=root, test=root/Test, etc.)
		redoDir => {}, # ref to hash {"scriptname.pl + optional addToScriptName" => "folder"}, folders where files for redo are contained, lookup key as checkLookup, default in "" => "defaultfolder"
		sensitive => {}, # hash lookup table ({"prefix" => {user=>"",pwd =>"",hostkey=>"",privkey =>""},...}) for sensitive access information in DB and FTP (lookup keys are set with DB{prefix} or FTP{prefix}), may also be placed outside of site.config; all sensitive keys can also be environment lookups, e.g. hostkey=>{Test => "", Prod => ""} to allow for environment specific setting
		smtpServer => "", # smtp server for den (error) mail sending
		smtpTimeout => 60, # timeout for smtp response
		testerrmailaddress => '', # error mail address in non prod environment
		DB => {},
		File => {},
		FTP => {},
		process => {},
		task => {},
	},
	execute => { # hash of parameters for current task execution. This is not to be set by the user, but can be used to as information to set other parameters and control the flow
		alreadyMovedOrDeleted => {}, # hash for checking the already moved or deleted local files, to avoid moving/deleting them again at cleanup
		addToScriptName => "", # this can be set to be added to the scriptname for config{checkLookup} keys, e.g. some passed parameter.
		env => "", # Prod, Test, Dev, whatever is defined as the lookup value in folderEnvironmentMapping. homedir as fetched from the File::basename::dirname of the executing script using /^.*[\\\/](.*?)$/ is used as the key for looking up this value.
		envraw => "", # Production has a special significance here as being an empty string. Otherwise like env.
		errmailaddress => "", # target address for central logcheck/errmail sending in current process
		errmailsubject => "", # mail subject for central logcheck/errmail sending in current process
		failcount => 1, # for counting failures in processing to switch to longer wait period or finish altogether
		filesToDelete => [], # list of files to be deleted locally after download, necessary for cleanup at the end of the process
		filesToMoveinHistory => [], # list of files to be moved in historyFolder locally, necessary for cleanup at the end of the process
		filesToMoveinHistoryUpload => [], # list of files to be moved in historyFolderUpload locally, necessary for cleanup at the end of the process
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
		retryBecauseOfError => 1, # retryBecauseOfError shows if a rerun occurs due to errors (for successMail) 
		retrySeconds => 60, # how many seconds are passed between retries. This is set on error with process=>retrySecondsErr and if planned retry is defined with process=>retrySecondsPlanned
		scriptname => "", # name of the current process script, also used in log/history setup together with addToScriptName for config{checkLookup} keys
		timeToCheck => "", # for logchecker: scheduled time of job (don't look earlier for log entries)
		uploadFilesToDelete => [], # list of files to be deleted locally after upload, necessary for cleanup at the end of the process
	},
	load => {
		DB => {},
		File => {},
		FTP => {},
		process => {},
	},
	DB => { # DB specific configs
		addID => {}, # this hash can be used to additionaly set a constant to given fields: Fieldname => Fieldvalue
		additionalLookup => "", # query used in getAdditionalDBData to retrieve lookup information from DB using EAI::DB::readFromDBHash
		additionalLookupKeys => [], # used for getAdditionalDBData, list of field names to be used as the keys of the returned hash
		cutoffYr2000 => 60, # when storing date data with 2 year digits in dumpDataIntoDB/EAI::DB::storeInDB, this is the cutoff where years are interpreted as 19XX (> cutoffYr2000) or 20XX (<= cutoffYr2000)
		columnnames => [], # returned column names from EAI::DB::readFromDB and EAI::DB::readFromDBHash, this is used in writeFileFromDB to pass column information from database to writeText
		database => "", # database to be used for connecting
		debugKeyIndicator => "", # used in dumpDataIntoDB/EAI::DB::storeInDB as an indicator for keys for debugging information if primkey not given (errors are shown with this key information). Format is the same as for primkey
		deleteBeforeInsertSelector => "", # used in dumpDataIntoDB/EAI::DB::storeInDB to delete specific data defined by keydata before an insert (first occurrence in data is used for key values). Format is the same as for primkey ("key1 = ? ...")
		dontWarnOnNotExistingFields => 0, # suppress warnings in dumpDataIntoDB/EAI::DB::storeInDB for not existing fields
		dontKeepContent => 1, # if table should be completely cleared before inserting data in dumpDataIntoDB/EAI::DB::storeInDB
		doUpdateBeforeInsert => 1, # invert insert/update sequence in dumpDataIntoDB/EAI::DB::storeInDB, insert only done when upsert flag is set
		DSN => '', # DSN String for DB connection
		incrementalStore => 1, # when storing data with dumpDataIntoDB/EAI::DB::storeInDB, avoid setting empty columns to NULL
		ignoreDuplicateErrs => 1, # ignore any duplicate errors in dumpDataIntoDB/EAI::DB::storeInDB
		keyfields => [], # used for EAI::DB::readFromDBHash, list of field names to be used as the keys of the returned hash
		longreadlen => 1024, # used for setting database handles LongReadLen parameter for DB connection, if not set defaults to 1024
		lookups => {}, # similar to $config{sensitive}, a hash lookup table ({"prefix" => {remoteHost=>""},...} or {"prefix" => {remoteHost=>{Prod => "", Test => ""}},...}) for centrally looking up DSN Settings depending on $DB{prefix}. Overrides $DB{DSN} set in config, but is overriden by script-level settings in %common.
		noDBTransaction => 1, # don't use a DB transaction for dumpDataIntoDB
		noDumpIntoDB => 1, # if files from this load should not be dumped to the database
		port => {}, # port to be added to server in environment hash lookup: {Prod => "", Test => ""}
		postDumpExecs => [], # array for DB executions done in dumpDataIntoDB after postDumpProcessing and before commit/rollback: [{execs => ['',''], condition => ''}]. For all execs a doInDB is executed if condition (evaluated string or anonymous sub: condition => sub {...}) is fulfilled
		postDumpProcessing => "", # done in dumpDataIntoDB after EAI::DB::storeInDB, execute perl code in postDumpProcessing (evaluated string or anonymous sub: postDumpProcessing => sub {...})
		postReadProcessing => "", # done in writeFileFromDB after EAI::DB::readFromDB, execute perl code in postReadProcessing (evaluated string or anonymous sub: postReadProcessing => sub {...})
		prefix => "", # key for sensitive information (e.g. pwd and user) in config{sensitive} or system wide DSN in config{DB}{prefix}{DSN}. respects environment in $execute{env} if configured.
		primkey => "", # primary key indicator to be used for update statements, format: "key1 = ? AND key2 = ? ...". Not necessary for dumpDataIntoDB/storeInDB if dontKeepContent is set to 1, here the whole table content is removed before storing
		pwd => "", # for password setting, either directly (insecure -> visible) or via sensitive lookup
		query => "", # query statement used for EAI::DB::readFromDB and EAI::DB::readFromDBHash
		schemaName => "", # schemaName used in dumpDataIntoDB/EAI::DB::storeInDB, if tableName contains dot the extracted schema from tableName overrides this. Needed for datatype information!
		server => {}, # DB Server in environment hash lookup: {Prod => "", Test => ""}
		tablename => "", # the table where data is stored in dumpDataIntoDB/EAI::DB::storeInDB
		upsert => 1, # in dumpDataIntoDB/EAI::DB::storeInDB, should both update and insert be done. doUpdateBeforeInsert=0: after the insert failed (because of duplicate keys) or doUpdateBeforeInsert=1: insert after the update failed (because of key not exists)?
		user => "", # for setting username in db connection, either directly (insecure -> visible) or via sensitive lookup
	},
	File => { # File fetching and parsing specific configs. File{filename} is also used for FTP
		avoidRenameForRedo => 1, # when redoing, usually the cutoff (datetime/redo info) is removed following a pattern. set this flag to avoid this
		append => 0, # for EAI::File::writeText: boolean to append (1) or overwrite (0 or undefined) to file given in filename
		columns => {}, # for EAI::File::writeText: Hash of data fields, that are to be written (in order of keys)
		columnskip => {}, # for EAI::File::writeText: boolean hash of column names that should be skipped when writing the file ({column1ToSkip => 1, column2ToSkip => 1, ...})
		dontKeepHistory => 1, # if up- or downloaded file should not be moved into historyFolder but be deleted
		dontMoveIntoHistory => 1, # if up- or downloaded file should not be moved into historyFolder but be kept in homedir
		emptyOK => 0, # flag to specify whether empty files should not invoke an error message. Also needed to mark an empty file as processed in EAI::Wrap::markProcessed
		extract => 1, # flag to specify whether to extract files from archive package (zip)
		extension => "", # the extension of the file to be read (optional, used for redoFile)
		fieldCode => {}, # additional field based processing code: fieldCode => {field1 => 'perl code', ..}, invoked if key equals either header (as in format_header) or targetheader (as in format_targetheader) or invoked for all fields if key is empty {"" => 'perl code'}. set $EAI::File::skipLineAssignment to true (1) if current line should be skipped from data. perl code can be an evaluated string or an anonymous sub: field1 => sub {...}
		filename => "", # the name of the file to be read, can also be a glob spec to retrieve multiple files. This information is also used for FTP and retrieval and local file copying.
		firstLineProc => "", # processing done when reading the first line of text files in EAI::File::readText (used to retrieve information from a header line, like reference date etc.). The line is available in $_.
		format_allowLinefeedInData => 1, # line feeds in values don't create artificial new lines/records, only works for csv quoted data in EAI::File::readText
		format_autoheader => 1, # assumption: header exists in file and format_header should be derived from there. only for EAI::File::readText
		format_beforeHeader => "", # additional String to be written before the header in EAI::File::writeText
		format_dateColumns => [], # numeric array of columns that contain date values (special parsing) in excel files (EAI::File::readExcel)
		format_decimalsep => "", # decimal separator used in numbers of sourcefile (defaults to . if not given)
		format_defaultsep => "", # default separator when format_sep not given (usually in site.config), if no separator is given (not needed for EAI::File::readExcel/EAI::File::readXML), "\t" is used for parsing format_header and format_targetheader.
		format_encoding => "", # text encoding of the file in question (e.g. :encoding(utf8))
		format_headerColumns => [], # optional numeric array of columns that contain data in excel files (defaults to all columns starting with first column up to format_targetheader length)
		format_header => "", # format_sep separated string containing header fields (optional in excel files, only used to check against existing header row)
		format_headerskip => 1, # skip until row-number for checking header row against format_header in EAI::File::readExcel
		format_eol => "", # for quoted csv specify special eol character (allowing newlines in values)
		format_fieldXpath => {}, # for EAI::File::readXML, hash with field => xpath to content association entries
		format_fix => 1, # for text writing, specify whether fixed length format should be used (requires format_padding)
		format_namespaces => {}, # for EAI::File::readXML, hash with alias => namespace association entries
		format_padding => {}, # for text writing, hash with field number => padding to be applied for fixed length format
		format_poslen => [], # array of array defining positions and lengths [[pos1,len1],[pos2,len2]...[posN,lenN]] of data in fixed length format text files (if format_sep == "fix")
		format_quotedcsv => 1, # special parsing/writing of quoted csv data using Text::CSV
		format_sep => "", # separator string for EAI::File::readText and EAI::File::writeText csv formats, a regex for splitting other separated formats. If format_sep is not explicitly given as a regex here (=> qr//), then it is assumed to be a regex by split, however this causes surprising effects with regex metacharacters (should be quoted, such as qr/\|/)! Also used for splitting format_header and format_targetheader (Excel and XML-formats use tab as default separator here).
		format_sepHead => "", # special separator for header row in EAI::File::writeText, overrides format_sep
		format_skip => "", # either numeric or string, skip until row-number if numeric or appearance of string otherwise in reading textfile. If numeric, format_skip can also be used in EAI::File::readExcel
		format_stopOnEmptyValueColumn => 1, # for EAI::File::readExcel, stop row parsing when a cell with this column number is empty (denotes end of data, to avoid very long parsing).
		format_suppressHeader => 1, # for text and excel file writing, suppress output of header
		format_targetheader => "", # format_sep separated string containing target header fields (= the field names in target/database table). optional for XML and tabular textfiles, defaults to format_header if not given there.
		format_thousandsep => "", # thousand separator used in numbers of sourcefile (defaults to , if not given)
		format_worksheetID => 1, # worksheet number for EAI::File::readExcel, this should always work
		format_worksheet => "", # alternatively the worksheet name can be passed for EAI::File::readExcel, this only works for new excel format (xlsx)
		format_xlformat => "xlsx|xls", # excel format for parsing, also specifies that excel parsing should be done
		format_xpathRecordLevel => "", # xpath for level where data nodes are located in xml
		format_XML => 1, # specify xml parsing
		lineCode => "", # additional line based processing code, invoked after whole line has been read (evaluated string or anonymous sub: lineCode => sub {...})
		localFilesystemPath => "", # if files are taken from or put to the local file system with getLocalFiles/putFileInLocalDir then the path is given here. Setting this to "." avoids copying files.
		optional => 1, # to avoid error message for missing optional files, set this to 1
	},
	FTP => { # FTP specific configs
		additionalParamsGet => {}, # additional parameters for Net::SFTP::Foreign get.
		additionalMoreArgs => [], # additional more args for Net::SFTP::Foreign new (args passed to ssh command).
		additionalParamsNew => {}, # additional parameters for Net::SFTP::Foreign new.
		additionalParamsPut => {}, # additional parameters for Net::SFTP::Foreign put.
		archiveDir => "", # folder for archived files on the FTP server
		dontMoveTempImmediately => 1, # if 0 oder missing: rename/move files immediately after writing to FTP to the final name, otherwise/1: a call to EAI::FTP::moveTempFiles is required for that
		dontDoSetStat => 1, # for Net::SFTP::Foreign, no setting of time stamp of remote file to that of local file (avoid error messages of FTP Server if it doesn't support this)
		dontDoUtime => 1, # don't set time stamp of local file to that of remote file
		dontUseQuoteSystemForPwd => 0, # for windows, a special quoting is used for passing passwords to Net::SFTP::Foreign that contain [()"<>& . This flag can be used to disable this quoting.
		dontUseTempFile => 1, # directly upload files, without temp files
		fileToArchive => 1, # should files be archived on FTP server? if archiveDir is not set, then file is archived (rolled) in the same folder
		fileToRemove => 1, # should files be removed on FTP server?
		FTPdebugLevel => 0, # debug ftp: 0 or ~(1|2|4|8|16|1024|2048), loglevel automatically set to debug for module EAI::FTP
		hostkey => "", # hostkey to present to the server for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup
		hostkey2 => "", # additional hostkey to be presented (e.g. in case of round robin DNS)
		localDir => "", # optional: local folder for files to be placed, if not given files are downloaded into current folder
		lookups => {}, # similar to $config{sensitive}, a hash lookup table ({"prefix" => {remoteHost=>""},...} or {"prefix" => {remoteHost=>{Prod => "", Test => ""}},...}) for centrally looking up remoteHost and port settings depending on $FTP{prefix}.
		maxConnectionTries => 5, # maximum number of tries for connecting in login procedure
		noDirectRemoteDirChange => 1, # if no direct change into absolute paths (/some/path/to/change/into) ist possible then set this to 1, this does a separated change into setcwd(undef) and setcwd(remoteDir)
		onlyArchive => 0, # only archive/remove given files on the FTP server, requires archiveDir to be set
		path => "", # additional relative FTP path (under remoteDir which is set at login), where the file(s) is/are located
		port => 22, # ftp/sftp port (leave empty for default port 22 when using Net::SFTP::Foreign, or port 21 when using Net::FTP)
		prefix => "ftp", # key for sensitive information (e.g. pwd and user) in config{sensitive} or system wide remoteHost/port in config{FTP}{prefix}{remoteHost} or config{FTP}{prefix}{port}. respects environment in $execute{env} if configured.
		privKey => "", # sftp key file location for Net::SFTP::Foreign, either directly (insecure -> visible) or via sensitive lookup
		pwd => "", # for password setting, either directly (insecure -> visible) or via sensitive lookup
		queue_size => 1, # queue_size for Net::SFTP::Foreign, if > 1 this causes often connection issues
		remove => {}, # ref to hash {removeFolders=>[], day=>, mon=>, year=>1} for for removing (archived) files with removeFilesOlderX, all files in removeFolders are deleted being older than day days, mon months and year years
		remoteDir => "", # remote root folder for up-/download, archive and remove: "out/Marktdaten/", path is added then for each filename (load)
		remoteHost => {}, # ref to hash of IP-addresses/DNS of host(s).
		SFTP => 0, # to explicitly use SFTP, if not given SFTP will be derived from existence of privKey or hostkey
		simulate => 0, # for removal of files using removeFilesinFolderOlderX/removeFilesOlderX only simulate (1) or do actually (0)?
		sshInstallationPath => "", # path were ssh/plink exe to be used by Net::SFTP::Foreign is located
		type => "", # (A)scii or (B)inary, only applies to Net::FTP
		user => "", # set user directly, either directly (insecure -> visible) or via sensitive lookup
	},
	process => { # used to pass information within each process (data, additionalLookupData, filenames, hadErrors or commandline parameters starting with interactive) and for additional configurations not suitable for DB, File or FTP (e.g. uploadCMD* and onlyExecFor)
		additionalLookupData => {}, # additional data retrieved from database with EAI::Wrap::getAdditionalDBData
		archivefilenames => [], # in case a zip archive package is retrieved, the filenames of these packages are kept here, necessary for cleanup at the end of the process
		countPercent => 0, # percentage for counting File text reading and DB storing, if given (greater 0) then on each reaching of the percentage in countPercent a progress is shown (e.g. every 10% if countPercent = 10). Any value >=100 will count ALL lines...
		data => [], # loaded data: array (rows) of hash refs (columns)
		filenames => [], # names of files that were retrieved and checked to be locally available for that load, can be more than the defined file in File->filename (due to glob spec or zip archive package)
		filesProcessed => {}, # hash for checking the processed files, necessary for cleanup at the end of the whole task
		hadErrors => 1, # set to 1 if there were any errors in the process
		interactive_ => "", # interactive options (are not checked), can be used to pass arbitrary data via command line into the script (eg a selected date for the run with interactive_date).
		onlyExecFor => qr//, # define loads to only be executed when $common{task}{execOnly} !~ $load->{process}{onlyExecFor}. Empty onlyExecFor loads are always executed regardless of $common{task}{execOnly}
		successfullyDone => "", # accumulates API sub names to prevent most API calls that ran successfully from being run again.
		uploadCMD => "", # upload command for use with uploadFileCMD
		uploadCMDPath => "", # path of upload command
		uploadCMDLogfile => "", # logfile where command given in uploadCMD writes output (for error handling)
	},
	task => { # contains parameters used on the task script level, only available for %common parameter hash.
		customHistoryTimestamp => "", # optional custom timestamp to be added to filenames moved to History/HistoryUpload/FTP archive, if not given, get_curdatetime is used (YYYYMMDD_hhmmss)
		execOnly => "", # do not execute loads where $common{task}{execOnly} !~ $load->{process}{onlyExecFor}. Empty onlyExecFor loads are always executed regardless of $common{task}{execOnly}
		ignoreNoTest => 0, # ignore the notest file in the process-script folder, usually preventing all runs that are not in production
		plannedUntil => 2359, # latest time that planned repetition should start, this can be given either as HHMM (HourMinute) or HHMMSS (HourMinuteSecond), in case of HHMM the "Second" part is attached as 59
		redoFile => 1, # flag for specifying a redo
		redoTimestampPatternPart => "", # part of the regex for checking against filename in redo with additional timestamp/redoDir pattern (e.g. "redo", numbers and _), anything after files barename (and before ".$ext" if extension is defined) is regarded as a timestamp. Example: '[\d_]', the regex is built like ($ext ? qr/$barename($redoTimestampPatternPart|$redoDir)*\.$ext/ : qr/$barename($redoTimestampPatternPart|$redoDir)*.*/)
		retrySecondsErr => 60, # retry period in case of error
		retrySecondsErrAfterXfails => 600, # after fail count is reached this alternate retry period in case of error is applied. If 0/undefined then job finishes after fail count
		retrySecondsXfails => 3, # fail count after which the retrySecondsErr are changed to retrySecondsErrAfterXfails
		retrySecondsPlanned => 300, # retry period in case of planned retry
		skipHolidays => "", # skip script execution on holidays
		skipHolidaysDefault => "", # holiday calendar to take into account for skipHolidays
		skipWeekends => 0, # skip script execution on weekends
		skipForFirstBusinessDate => "", # used for "wait with execution for first business date", either this is a calendar or 1 (then calendar is skipHolidaysDefault), this cannot be used together with skipHolidays
	},
);
# alternate type checking for these as they might have different types
my %alternateType = (
	configexecuteOnInit => sub {}, # can be eval string or anonymous sub
	DBpostDumpProcessing => sub {}, # can be eval string or anonymous sub
	DBpostReadProcessing => sub {}, # can be eval string or anonymous sub
	Filecolumns => [], # can be ref to hash or ref to array
	Fileformat_skip => 1, # can be "skip until pattern" string or line number (int)
	Fileformat_sep => qr//, # can be separator string or regex split
	FilelineCode => sub {}, # can be eval string or anonymous sub
	FTPremoteHost => "", # can also be string
	taskskipHolidays => 1, # can be calendar string or true (1)
	taskskipForFirstBusinessDate => 1, # can be calendar string or true (1)
);

our %common;our %config;our @loads;our %execute;our @optload;our %opt;
our $EAI_WRAP_CONFIG_PATH; our $EAI_WRAP_SENS_CONFIG_PATH;
my @coreConfig = ("DB","File","FTP","process");
my @commonCoreConfig = (@coreConfig,"task");
my @allConfig = (@commonCoreConfig,"config");
our $logConfig;

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
		die("Error parsing config file $configfilename for script $execute{homedir}/$execute{scriptname}: $@") if $@;
		die("Error executing config file $configfilename for script $execute{homedir}/$execute{scriptname}: $!") unless defined $return;
	}
	print STDOUT "included $configfilename\n";
}

# get key info from $config{sensitive}{$prefix}{$key}. Also checks if $config{sensitive}{$prefix}{$key} is a hash, then get info from $config{sensitive}{$prefix}{$key}{$execute{env}}
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
	# check for unintended merging/inheritance into sections of loads defined with underscore (inheritance prevention)
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
				delete $loads[$check]{$hashName."_"}; # need to remove, otherwise checkHash further below throws an error for these...
			}
		}
	}
	# fall back to config level defined settings for prefix (in config subhash "lookups") if given/defined
	for my $hashName (@commonCoreConfig) {
		for my $defkey (keys %{$hashCheck{$hashName}}) {
			if (defined($config{$hashName}{lookups})) {
				# do this for common config
				if (defined($config{$hashName}{lookups}{$common{$hashName}{prefix}}) and defined($config{$hashName}{lookups}{$common{$hashName}{prefix}}{$defkey})) {
					$common{$hashName}{$defkey} = $config{$hashName}{lookups}{$common{$hashName}{prefix}}{$defkey};
				}
				# and also for loads
				for my $i (0..$#loads) {
					if (defined($config{$hashName}{lookups}{$loads[$i]{$hashName}{prefix}}) and defined($config{$hashName}{lookups}{$loads[$i]{$hashName}{prefix}}{$defkey})) {
						$loads[$i]{$hashName}{$defkey} = $config{$hashName}{lookups}{$loads[$i]{$hashName}{prefix}}{$defkey};
					}
				}
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
	my $i=0;
	while ($i <= $#loads) {
		if ($common{task}{execOnly} and $loads[$i]{process}{onlyExecFor} and $common{task}{execOnly} !~ $loads[$i]{process}{onlyExecFor}) {
			$logger->debug("removing load $i because \$common{task}{execOnly} given and $common{task}{execOnly} !~ $loads[$i]{process}{onlyExecFor} (\$load{process}{onlyExecFor}), \$#loads: $#loads");
			splice @loads, $i, 1;
		} else {
			$i++;
		}
	};
}

# get options for overriding configured settings
sub getOptions {
	# construct option definitions for Getopt::Long::GetOptions, everything parsed as a string first
	my %optiondefs = ("DB=s%" => \$opt{DB}, "FTP=s%" => \$opt{FTP}, "File=s%" => \$opt{File},"process=s%" => \$opt{process}, "task=s%" => \$opt{task}, "config=s%" => \$opt{config}); # first option overrides for common
	for my $i (0..$#loads) {
		# then option overrides for each load
		 %optiondefs = (%optiondefs, "load${i}DB=s%" => \$optload[$i]{DB}, "load${i}FTP=s%" => \$optload[$i]{FTP}, "load${i}File=s%" => \$optload[$i]{File},"load${i}process=s%" => \$optload[$i]{process});
	}
	my @orig_ARGV = @ARGV;
	Getopt::Long::GetOptions(%optiondefs);
	@ARGV = @orig_ARGV; # restore @ARGV in case the calling script does its own option processing
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
	$logger->debug(($contextSub ? "setting err subject <$contextSub> for " : "").(caller(1))[3]) if caller(1);
	setErrSubject($contextSub) if $contextSub;
	my @ret;
	if (ref($arg) eq "HASH") {
		for my $req (@required) {
			push(@ret, \%{$arg->{$req}}); # return the required subhash into the list of hashes
			checkHash($ret[$#ret],$req) or $logger->error($@); # check last added hash after adding it...
		}
	} else {
		my $errStr = "no ref to hash passed when calling ".(caller(0))[3].", line ".(caller(0))[2]." in ".(caller(0))[1];
		$errStr = "no ref to hash passed when calling ".(caller(1))[3].", line ".(caller(1))[2]." in ".(caller(1))[1] if caller(1);
		$logger->error($errStr);
	}
	return @ret;
}

# check config hash passed in $hash for validity against hashCheck (valid key entries are there + their valid value types (examples)). returns 0 on error and exception $@ contains details
sub checkHash ($$) {
	my ($hash, $hashName) = @_;
	# try to backtrack as far as possible, maximum 3 calls (script -> function -> extractConfigs):
	my $locStr = " when calling ".(caller(0))[3].", line ".(caller(0))[2]." in ".(caller(0))[1];
	$locStr = " when calling ".(caller(1))[3].", line ".(caller(1))[2]." in ".(caller(1))[1] if caller(1);
	$locStr = " when calling ".(caller(2))[3].", line ".(caller(2))[2]." in ".(caller(2))[1] if caller(2);
	eval {
		for my $defkey (keys %{$hash}) {
			unless ($hashName eq "process" and $defkey =~ /interactive.*/) {
				if (!exists($hashCheck{$hashName}{$defkey})) {
					die "key name not allowed: \$".$hashName."{".$defkey."},".$locStr;
				} else {
					# check type for existing keys, if explicitly not defined then ignore...
					if (defined($hash->{$defkey})) {
						if (ref($hashCheck{$hashName}{$defkey}) ne ref($hash->{$defkey})) {
							if (!defined($alternateType{$hashName.$defkey}) or (ref($alternateType{$hashName.$defkey}) ne ref($hash->{$defkey}))) {
								die "wrong reference type for value: \$".$hashName."{".$defkey."}:".ref($hash->{$defkey}).", it should be either:".ref($hashCheck{$hashName}{$defkey})." or:".ref($alternateType{$hashName.$defkey}).",".$locStr;
							}
						}
						# numeric check: either hashcheck is same looks_like_number as given key or alternateType is same looks_like_number
						if (looks_like_number($hash->{$defkey}) and !looks_like_number($hashCheck{$hashName}{$defkey})) {
							if (!defined($alternateType{$hashName.$defkey}) or (looks_like_number($hash->{$defkey}) and !looks_like_number($alternateType{$hashName.$defkey}))) {
								die "wrong numeric type for value: \$".$hashName."{".$defkey."},".$locStr;
							}
						}
						# non-numeric check: if non-numeric type given, then check if either hashcheck looks like a number or hashcheck was a ref type and alternateType looks like a number
						if (!looks_like_number($hash->{$defkey}) and !ref($hash->{$defkey}) and looks_like_number($hashCheck{$hashName}{$defkey})) {
							if (!defined($alternateType{$hashName.$defkey}) or (!looks_like_number($hash->{$defkey}) and looks_like_number($alternateType{$hashName.$defkey}))) {
								die "wrong non-numeric type for value: \$".$hashName."{".$defkey."},".$locStr;
							}
						}
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
		$logger->error("key $keytoCheck not defined in subhash ".dumpFlat($subhash,1));
		return 0;
	} elsif (!$subhash->{$keytoCheck} and !looks_like_number($hashCheck{$subhashname}{$keytoCheck})) {
		$logger->error("value of key $keytoCheck empty in subhash ".dumpFlat($subhash,1));
		return 0;
	}
	return 1;
}

# path of logfile and path of yesterdays logfile (after rolling) - getLogFPathForMail and getLogFPath can be used in site-wide log.config
our ($LogFPath, $LogFPathDayBefore);
sub getLogFPathForMail {
	return 'file://'.$LogFPath.($LogFPathDayBefore ? ', or '.'file://'.$LogFPathDayBefore : '');
};
# called by log4perl.appender.FILE.filename = ... so always provide the logfile path here
sub getLogFPath {
	return $LogFPath;
};

# MailFilter is used for filtering error logs (called in log.config) if a log error was already sent by mail (otherwise floods)...this is reset on retry because of error
our $alreadySent = 0;
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
	my $extendedScriptname = $execute{scriptname}.$execute{addToScriptName};
	my $prodEnvironmentInSeparatePath = ($config{checkLookup}{$extendedScriptname}{prodEnvironmentInSeparatePath} ne "" ? $config{checkLookup}{$extendedScriptname}{prodEnvironmentInSeparatePath} : $config{prodEnvironmentInSeparatePath});

	# get logRootPath, historyFolder, historyFolderUpload and redoDir from lookups in config.
	# if they are not in the script home directory (having an absolute path) then build environment-path separately for end folder (script home directory is already in its environment)
	for my $foldKey ("redoDir","logRootPath","historyFolder","historyFolderUpload") {
		warn ("\$config{$foldKey} is not a hash, cannot get $foldKey from it !") if (ref($config{$foldKey}) ne "HASH");
		my $folder = $config{$foldKey}{$extendedScriptname} if (ref($config{$foldKey}) eq "HASH");
		my $defaultFolder;
		if (!$folder) {
			$folder = $config{$foldKey}{""}; # take default, if no lookup defined for script
			$defaultFolder = 1;
		}
		$folder = $opt{config}{$foldKey} if $opt{config}{$foldKey}; # also possible to override these settings via options
		# convert backslash to slash to avoid problems in string handling (unicode ...)
		$folder =~ s/\\/\//g;
		if ($folder =~ /^(\S:)*\/(.*?)$/ and !$opt{config}{$foldKey}) {
			my ($folderPath,$endFolder) = ($folder =~ /(.*)\/(.*?)$/); # slash acts as path separator for last part
			# default Folder is built with environment: folderPath/endFolder/environ instead of folderPath/environ/endFolder
			# environments are built depending on prodEnvironmentInSeparatePath: either folderPath/endFolder/$execute{env} (Prod has own subfolder) or folderPath/endFolder/$execute{envraw} (Prod is in common folder, other environments have their own folder)
			$execute{$foldKey} = ($defaultFolder 
									? $folderPath."/".$endFolder.($prodEnvironmentInSeparatePath 
										? '/'.$execute{env}
										: ($execute{envraw} ? '/'.$execute{envraw} : ""))
									: $folderPath."/".($prodEnvironmentInSeparatePath 
										? '/'.$execute{env}
										: ($execute{envraw} ? '/'.$execute{envraw} : "")).$endFolder);
		} else {
			# folders without slashes are assumed to be relative to home, so now amendment with environment needed.
			$execute{$foldKey} = $folder;
		}
	}
	my $logFolder = $execute{logRootPath};
	# if logFolder doesn't exist, warn and log to $execute{homedir}.
	if (! -e $logFolder) {
		print "can't log to logfolder $logFolder (set specially for script with \$config{logRootPath}{$extendedScriptname} or default with \$config{logRootPath}{\"\"}), folder doesn't exist. Setting to $execute{homedir}";
		$logFolder = $execute{homedir};
	}
	$LogFPath = $logFolder."/".$extendedScriptname.".log";
	$logConfig = $EAI_WRAP_CONFIG_PATH."/".$execute{env}."/log.config"; # environment dependent log config, Prod is either in EAI_WRAP_CONFIG_PATH/.$execute{env} or EAI_WRAP_CONFIG_PATH
	$logConfig = $EAI_WRAP_CONFIG_PATH."/log.config" if (! -e $logConfig); # fall back to main config log.config
	die "log.config neither in $logConfig nor in ".$EAI_WRAP_CONFIG_PATH."/log.config" if (! -e $logConfig);
	Log::Log4perl::init($logConfig);
	# workaround for utf8 problems with Win32::Console::ANSI
	if ($^O =~ /MSWin/) {
		my $test = \*STDOUT; bless $test, 'IO::Handle';
		my $testcopy = IO::Handle->new_from_fd($test, ">");
		$test->fdopen($testcopy, ">");
	}
	my $logger = get_logger();
	my $logAppender = Log::Log4perl->appenders()->{"FILE"}->{"appender"} if Log::Log4perl->appenders() and Log::Log4perl->appenders()->{"FILE"};
	if ($logAppender) {
		my $logprefix = get_curdate();
		unless ($logAppender->isa("Log::Dispatch::FileRotate")) {
			$@ = ""; # reset bogus error messages from Log::Log4perl::init
			eval {$logprefix = $config{logprefixForLastLogfile}->()} if $config{logprefixForLastLogfile};
			$logger->warn("error getting logprefix from \$config{logprefixForLastLogfile}: $@") if $@;
			# if mail is watched next day, the rolled file is in $LogFPathDayBefore. Depending on appender, either append ".1" to filename or prepend $logprefix to it (default assume a date rotator, with current date in format yyyymmdd)
			$LogFPathDayBefore = "$logFolder/$logprefix.$extendedScriptname.log";
		} else {
			$LogFPathDayBefore = "$logFolder/$extendedScriptname.log.1";
		}
	}
	if ($config{smtpServer}) {
		# remove explicitly enumerated lookups (1:scriptname.pl, 2:scriptname.pl) in case they are used for the current script, the first such entry will be taken here
		for my $lookupKey (reverse sort keys(%{$config{checkLookup}})) {
			if ($lookupKey =~ /^\d:.*/ and $lookupKey =~ /$execute{scriptname}/) {
				my $lookupKeyAdd = $lookupKey;
				$lookupKeyAdd =~ s/^\d://;
				$config{checkLookup}{$lookupKeyAdd} = $config{checkLookup}{$lookupKey};
				delete($config{checkLookup}{$lookupKey});
			}
		}
		# configure err mail sending
		MIME::Lite->send('smtp', $config{smtpServer}, AuthUser=>$config{sensitive}{smtpAuth}{user}, AuthPass=>$config{sensitive}{smtpAuth}{pwd}, Timeout=>$config{smtpTimeout});
		# get email from central log error handling $config{checkLookup}{<>};
		$execute{errmailaddress} = $config{checkLookup}{$extendedScriptname}{errmailaddress}; # errmailaddress for the task script
		$execute{errmailsubject} = $config{checkLookup}{$extendedScriptname}{errmailsubject}; # errmailsubject for the task script
		$execute{errmailaddress} = $config{errmailaddress} if !$execute{errmailaddress};
		$execute{errmailsubject} = $config{errmailsubject} if !$execute{errmailsubject};
		$execute{errmailaddress} = $config{testerrmailaddress} if $execute{envraw};
		if ($execute{errmailaddress}) {
			Log::Log4perl->appenders()->{"MAIL"}->{"appender"}->{"to"} = [$execute{errmailaddress}];
		} else {
			# Production: no errmailaddress found, error message to Testerrmailaddress (if set)
			Log::Log4perl->appenders()->{"MAIL"}->{"appender"}->{"to"} = [$config{testerrmailaddress}] if $config{testerrmailaddress};
			if ($execute{envraw}) {
				$logger->error("no errmailaddress found, no entry found in \$config{testerrmailaddress}");
			} else {
				$logger->error("no errmailaddress found for ".$extendedScriptname.", no entry found in \$config{checkLookup}{$extendedScriptname}");
			}
		}
		setErrSubject("Setting up EAI::Wrap"); # general context after logging initialization: setup of EAI::Wrap by script
	} else {
		# remove any defined mail appenders
		undef(Log::Log4perl->appenders()->{"MAIL"}) if Log::Log4perl->appenders()->{"MAIL"};
	}
}

# set up EAI configuration
sub setupEAIWrap {
	my $logger = get_logger();
	setupConfigMerge(); # %config (from site.config, amended with command line options) and %common (from process script, amended with command line options) are merged into %common and all @loads (amended with command line options)
	# starting log entry: process script name + %common parameters, used for process monitoring (%config is not written due to sensitive information)
	$logger->info("==============================================================================================");
	$logger->info("started $execute{scriptname} in $execute{homedir} (environment $execute{env}) ... execute parameters: ".dumpFlat(\%execute,1,1)." ... common parameters: ".dumpFlat(\%common,1,1));
	if ($logger->is_debug) {
		$logger->debug("load $_ parameters: ".dumpFlat($loads[$_],1,1)) for (0..$#loads);
		$logger->trace("config parameters: ".dumpFlat(\%config,1,1)) if !defined($config{sensitive}) and $logger->is_trace();
	}
	# check starting conditions and exit if met (returned true)
	checkStartingCond(\%common) and exit 0;
	setErrSubject("General EAI::Wrap script execution"); # general context after setup of EAI::Wrap
}

# returned Data::Dumpered datastructure given in $arg flattened, sorted (if $sortDump given) and compressed (if $compressDump given)
sub dumpFlat ($;$$) {
	my $arg = shift;
	my $sortDump = shift;
	my $compressDump = shift;
	$Data::Dumper::Indent = 0; # temporarily flatten dumper output for single line
	$Data::Dumper::Sortkeys = 1 if $sortDump; # sort keys to get outputs easier to read
	$Data::Dumper::Deepcopy = 1;
	my $dump = Dumper($arg);
	if ($compressDump) {
		$dump =~ s/\s+//g;$dump =~ s/,'/,/g;$dump =~ s/{'/{/g;$dump =~ s/'=>/=>/g; # compress information
	}
	$dump =~ s/\$VAR1//;
	$Data::Dumper::Indent = 2;
	$Data::Dumper::Deepcopy = 0;
	return $dump;
}

# check starting conditions and return 1 if met
sub checkStartingCond ($) {
	my $arg = shift;
	my $logger = get_logger();
	my ($task) = extractConfigs("checking starting conditions",$arg,"task");
	my $curdate = get_curdate();
	$logger->debug("checkStartingCond for \$curdate: $curdate, task config:".dumpFlat($task,1));
	# skipHolidays is either a calendar or 1 (then defaults to $task->{skipHolidaysDefault})
	my $holidayCal = $task->{skipHolidays} if $task->{skipHolidays};
	# skipForFirstBusinessDate is for "wait with execution for first business date", either this is a calendar or 1 (then calendar is skipHolidaysDefault), this cannot be used together with skipHolidays
	$holidayCal = $task->{skipForFirstBusinessDate} if $task->{skipForFirstBusinessDate};
	# default setting (1 becomes $task->{skipHolidaysDefault})
	$holidayCal = $task->{skipHolidaysDefault} if ($task->{skipForFirstBusinessDate} eq "1" or $task->{skipHolidays} eq "1");
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
		$logger->debug("\$nonBusinessDays: $nonBusinessDays,\$daysfrom1st: $daysfrom1st");
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
	$logger->error("cannot send mail as \$config{smtpServer} not set") if !$config{smtpServer};
	$logger->info("sending general mail From:".($From ? $From : $config{fromaddress}).", To:".($execute{envraw} ? $config{testerrmailaddress} : $To).", CC:".($execute{envraw} ? "" : $Cc).", Bcc:".($execute{envraw} ? "" : $Bcc).", Subject:".($execute{envraw} ? $execute{envraw}.": " : "").$Subject.", Type:".($Type ? $Type : "TEXT").", Encoding:".($Type eq 'multipart/related' ? undef : $Encoding));
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
	$logger->error("couldn't create msg for mail sending..") unless $msg;
	if ($Type eq 'multipart/related') {
		if (ref($AttachFile) ne 'ARRAY') {
			$logger->error("argument $AttachFile needs to be ref to array for type multipart/related");
			return 0;
		}
		if (!$AttachType) {
			$logger->error("no AttachType given for type multipart/related");
			return 0;
		}
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
	if ($AttachFile and !$AttachType) {
		$logger->error("no AttachType given for attachment $AttachFile");
		return 0;
	}
	$msg->send();
	if ($msg->last_send_successful()) {
		$logger->info("Mail sent");
		$logger->trace("sent message: ".$msg->as_string) if $logger->is_trace();
	}
}

package Log::Dispatch::Email::LogSender;

use feature 'unicode_strings';
use Log::Dispatch::Email;
use base qw( Log::Dispatch::Email );

sub send_email {
	my $self = shift;
	my %p    = @_;
	# catch wide non utf8 characters to avoid die in MIME::Lite
	#eval {decode('UTF-8',$p{message},$Encode::FB_CROAK )} or $p{message} =~ s/[^\x00-\x7f]/?/g;
	my $msg = MIME::Lite->new(
			From    => $self->{from},
			To      => ( join ',', @{ $self->{to} } ),
			Subject => $self->{subject},
			Type    => "TEXT",
			Data    => $p{message},
		);
	eval {$msg->send();} or warn("couldn't send error mail: $@");
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

 readConfigFile ($configfilename)
 getKeyInfo ($prefix, $key, $area)
 setupConfigMerge ()
 getOptions ()
 extractConfigs ($contextSub, $arg, @required)
 checkHash ($hash, $hashName)
 checkParam ($subhash, $hashName)
 setupEAIWrap ()
 dumpFlat ($arg, $sortDump, $compressDump)
 getLogFPathForMail ()
 getLogFPath ()
 MailFilter ()
 setErrSubject ($context)
 setupLogging ()
 checkStartingCond ($task)
 sendGeneralMail ($From, $To, $Cc, $Bcc, $Subject, $Type, $Data, $Encoding, $AttachType, $AttachFile)

=head1 DESCRIPTION

EAI::Common contains common used functions for L<EAI::Wrap>. This is for reading config files, setting up the config hierarchy, including commandline options, setting up logging, including callbacks for the log.config, setting the error subject for error mails, checking starting conditions and a generic Mail sending.

=head2 API

=over

=item readConfigFile ($)

read given config file (eval perl code in site.config and related files)

=item getSensInfo ($$)

arguments are $prefix and $key

get sensitive info from $config{getSensInfo}{$prefix}{$key}, if queried key is a ref to hash, get the key value using the environment lookup hash ($config{sensitive}{$prefix}{$key}{$execute{env}}).

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

arguments are $contextSub, $arg and @required.

sets error subject to $contextSub (first argument) and extracts config hashes (DB,FTP,File,process,task) from ref to hash $arg (second argument) and return them as a list of hashes. The config hashes to be extracted are given as strings in the parameter list @required (at least one is required).

=item checkHash ($$)

arguments are $hash and $hashName

check keys of config subhash (named $hashName) being passed in $hash for validity against internal hash %hashCheck (valid key entries + their valid value types (examples) are defined there). returns 0 on error and exception $@ contains details, to allow for checkHash(..) or {handle exception}.

=item checkParam ($$)

arguments are $subhash and $hashName

check existence of parameter $hashName within first argument $subhash, returns 0 if not defined or empty (only non-numerics)

=item setupEAIWrap

Usually this is the first call after the configuration (assignments to %common and @loads) was defined.
This sets up the configuration datastructure and merges the hierarchy of configurations. 
Correctness of the configuration and all conditions preventing the task script's actual starting are also checked; finally all used parameters are written into the initial log line, which is used by the logchecker (see L<checkLogExist.pl>).

following three functions can be used in the central log.config as coderefs for callback.

=item dumpFlat ($;$$)

arguments are $arg: datastructure to be flat dumped, $sortDump: sort all keys in $arg and $compressDump: compress information in $arg

returns Data::Dumper dumped datastructure given in $arg flattened, sorted (if $sortDump given) and compressed (if $compressDump given)

=item getLogFPathForMail

for custom conversion specifiers: returns path of configured logfile resp logfile of previous day (as a file:// hyperlink)

=item getLogFPath

for file appender config, returns the path of current logfile.

=item MailFilter

for Mail appender config: used for filtering if further mails should be sent, contains throttling flag "alreadySent" for avoiding mail flooding when errors occur.

=item setErrSubject ($)

argument $context .. text for context of subject

set context specific subject for ErrorMail

=item setupLogging

set up logging from site.config information (potentially split up using additional configs) and the central log.config. Important configs for logging in the config hash are logRootPath (direct or environment lookup setting for the log root folder), errmailaddress (default address for sending mails in case of error), errmailsubject (subject for error mails, can be changed with L<setErrSubject|/setErrSubject>), testerrmailaddress (default address for sending mails in case of error in non production environments), smtpServer (for error and other mail sending), smtpTimeout and checkLookup.

checkLookup is both used by checkLogExist.pl and setupLogging. The key is used to lookup the scriptname (inlcuding .pl) + any additionally defined suffix(C<$execute{addToScriptName}>) that can be set with C<$config{executeOnInit}>. So, a call of C<mytask.pl --process interactive_addinfo=add12 interactive_type=type3 interactive_zone=zone4> and a definition C<$config{executeOnInit} = '$execute{addToScriptName} = $opt{process}{interactive_addinfo}.$opt{process}{interactive_type}.$opt{process}{interactive_zone};'> would yield a lookup of C<mytask.pladd12type3zone4>, which should have an existing key in checkLookup, like C<$config{checkLookup} = {"mytask.pladd12type3zone4" =E<gt> {...}, ...}>.

Each entry of the sub-hash defines defines the errmailaddress to receive error mails and the errmailsubject, the rest is used by checkLogExist.pl.

Explicitly enumerated lookups (1:scriptname.pl, 2:scriptname.pl, etc.) that are required for differentiated treatment in checkLogExist.pl are removed and replaced by one with key scriptname.pl.

=item checkStartingCond ($)

argument $task .. config information

check starting conditions from process config information and return 1 if met

=item sendGeneralMail ($$$$$$;$$$$)

arguments are

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

=back

=head1 COPYRIGHT

Copyright (c) 2024 Roland Kapl

All rights reserved.  This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut