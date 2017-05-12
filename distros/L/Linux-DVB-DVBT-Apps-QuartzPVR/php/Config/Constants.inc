<?php

#-----------------------------------------------------------------
define("CONFIG_VERSION", "4.001") ;
#-----------------------------------------------------------------

# Modify this parameter to specify a space/comma separated list of the adapters
# you want to use. Leaving blank defaults to using whatever adapters are detected.
# Use this in combination with UDEV rules to ensure specific adapters are used regardless
# of when they are plugged in.
#
define("ADAPTERS",		'%ADAPTERS%') ;


#============================================================================================
# PVR
#============================================================================================

# Mail url that the scripts use to mail errors to
define("MAIL_TO", 		'%MAIL_TO%') ;


#============================================================================================
# Perl libs etc
#============================================================================================

// File path specification for audio & video files. The variables ($xxx) are replaced with each
// file's specific values. Supported variables are:
//
//Date-related:
//	$Y			4 digit recording year
//	$m			2 digit recording month 
//	$d			2 digit recording day
//	$H			2 digit recording hour
//	$M			2 digit recording minute
//	$S			2 digit recording second
//
//	$Ymd		recording year,month,day (e.g. 20110920 for 20/sep/2011)
//	$HMS		recording hour, minute, second (e.g. 173000 for 17:30:00)
//	$YmdHMS		recording timestamp (e.g. 20110920173000 for 20/sep/2011 at 17:30:00)
//
//Series information:
//	$series_num		Number of the series, or blank if not known
//	$series			Set to the string 'Series $series_num' if series number is known; otherwise blank
//	$episode		Episode number or blank if not known
//	$episode_num	Set to the string 'Episode $episode_num' or blank if not known
//	$tva_series_num	TVAnytime series serial number (or blank)
//	$tva_prog_num	TVAnytime program serial number (or blank)
//	$tva_series		Set to the string 'Series $tva_series_num' or blank
//	$tva_prog		Set to the string 'Program $tva_prog_num' or blank
//	
//Program information:		
//	$genre			Broadcast genre (not usually much use!)
//	$name			Name of program
//	$title			Program title
//	$subtitle		Program extra information
//

define("VIDEO_PATH", 	'%VIDEO_PATH%') ;
define("AUDIO_PATH", 	'%AUDIO_PATH%') ;
define("VIDEO_TRASH", 	'%VIDEO_TRASH%') ;


#============================================================================================
# DATE/TIME
#============================================================================================

# Set the timezone to your location
define('DATE_TZ', "Europe/London") ;

#============================================================================================
# DVB-T
#============================================================================================

# You can modify this to specify either another frequency file or set it to a country code
define("DVBT_FREQFILE", "%DVBT_FREQFILE%") ;


#============================================================================================
# PROGRAM OPTIONS
#============================================================================================

# Set to 1 to enable advert removal/skipping; clear to 0 to prevent advert removal
define("ADSKIP", "%ADDSKIP%") ;


#============================================================================================
# DEBUG
#============================================================================================

# If defined, PHP application will log to this file
define("PHP_LOG", "%PHP_LOG%") ;





#############################################################################################
# FIXED - DO NOT CHANGE
#############################################################################################


#============================================================================================
# PVR
#============================================================================================
define("PVR_USER", 		'%PVR_USER%') ;
define("PVR_GROUP", 	'%PVR_GROUP%') ;
define("PVR_LOGDIR", 	'%PVR_LOGDIR%') ;
define("PVR_HOME", 		'/var/lib/%PVR_USER%') ;



#============================================================================================
# Server
#============================================================================================
define("SERVER_PORT", 	'%SERVER_PORT%') ;


#============================================================================================
# DIRS
#============================================================================================

# Directories
define("VIDEO_DIR", 	'%VIDEO_DIR%') ;
define("AUDIO_DIR", 	'%AUDIO_DIR%') ;
define("PVR_ROOT", 		"%PVR_ROOT%") ;


// Various common resources	
define("RESOURCES_DIR", '.') ;

define("LIB_DIR", RESOURCES_DIR.'/php') ;

define("CSS_DIR", RESOURCES_DIR.'/css') ;
define("JS_DIR", RESOURCES_DIR.'/js') ;
define("TEMPLATE_DIR", RESOURCES_DIR.'/tpl') ;


#============================================================================================
# MySQL
#============================================================================================
define("DATABASE", 		'%DATABASE%') ;

define("SQL_DBTYPE", 	'mysql') ;
define("SQL_HOST", 		'localhost') ;

define("TBL_LISTINGS", 	'listings') ;
define("TBL_CHANNELS", 	'channels') ;
define("TBL_RECORDING", 'record') ;
define("TBL_SCHEDULE", 	'schedule') ;
define("TBL_MULTIREC", 	'multirec') ;
define("TBL_IPLAY", 	'iplay') ;
define("TBL_RECORDED", 	'recorded') ;

#============================================================================================
# Perl libs etc
#============================================================================================

# Executables
$PERL_BIN = "%PERL_BIN%" ;

# Module
define("PM_VERSION", "%PM_VERSION%") ;

# Perl
define("PERL_LIB", 		"%PERL_LIB%") ;
define("PERL_SCRIPTS", 	"%PERL_SCRIPTS%") ;

# Record manager
##$DVB_RECORD_MGR = " " . PVR_ROOT . "/" .  SCRIPTS_DIR . "/dvb_record_mgr.pl -php " ;
$DVB_RECORD_MGR = "dvb_record_mgr -php " ;

define("RECPROG", "dvbt-multirecord") ;
define("IPLAYPROG", "dvbt-iplay") ;

#============================================================================================
# Record management command lines
#============================================================================================

# Command line to amend recordings
define("REC_MGR_REC", 	"$DVB_RECORD_MGR -rec ") ;
define("REC_MGR_INFO", 	"$DVB_RECORD_MGR -info ") ;


#============================================================================================
# DATE/TIME
#============================================================================================
$DATE_FORMAT = "DateFormat=non-US" ;


#============================================================================================
# DEBUG
#============================================================================================

# Server debug level
define('SERVER_DEBUG', %SERVER_DEBUG%) ;
?>
