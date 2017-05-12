//****************************************************************************
//	File:	EXT.xs
//	Type:	Extension library (for Perl and friends)
//	Author:	David Oberholtzer, (daveo@obernet.com)
//			Copyright (c)2005, David Oberholtzer.
//	Date:	2001/04/18
//	Rev:	$Id: EXT.xs,v 1.1 2003/06/18 02:29:32 daveo Exp daveo $
//	Use:	Access to  FAME textual messages
//****************************************************************************
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hli.h"
#include "EXT.h"

//***************************************************************************
//***************************************************************************
//	G L O B A L   V A R I A B L E S
//***************************************************************************
//***************************************************************************
static	int		status = 0;
static	char	errBuff[BIGBUF];
static	int		errBuffLen = -1;
static	int		xx_cnt = 0;


//***************************************************************************
//***************************************************************************
//		E x t e n s i o n   F u n c t i o n s
//***************************************************************************
//***************************************************************************

//===========================================================================
//		N E W   S T R I N G
//===========================================================================
char	*newString(char *src)
{
int		len;
char	*ptr;

		if (src) {
			len = strlen(src) + 1;
			ptr = (char *)safemalloc(sizeof(char) * len);
			strcpy(ptr, src);
		} else {
			ptr = (char *)safemalloc(sizeof(char));
			*ptr = '\0';
		}
		return(ptr);
}




//===========================================================================
//		F O R M A T   D A T E
//===========================================================================
char	*FormatDate(int	date, int freq, char *image, int fmonth, int flabel)
{
static	char	buf[SMALLBUF];
int				len;

		cfmdati(&status, freq, date, buf, image, fmonth, flabel);
		if (status != HSUCC) {
			strcpy(buf, ErrDesc(status));
		}
		return(buf);
}


//===========================================================================
//		F A M E   C L A S S   T X T
//===========================================================================
char	*ClassDesc(int fameclass)
{
char	*ptr;

		switch(fameclass) {
		  case HSERIE:
			ptr = "SERIES";
			break;
		  case HSCALA:
			ptr = "SCALAR";
			break;
		  case HFRMLA:
			ptr = "FORMULA";
			break;
		  case HITEM:
			ptr = "ITEM";
			break;
		  case HGLNAM:
			ptr = "LNAME";
			break;
		  case HGLFOR:
			ptr = "LFORMULA";
			break;
		  default:
			ptr = "<Unknown>";
			break;
		}
		return(ptr);
}


//===========================================================================
//		F A M E   E R R O R   M E S S A G E
//===========================================================================
//===========================================================================
char	*ErrDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HSUCC:
			ptr = "Success.";
			break;
		  case HINITD:
			ptr = "HLI has already been initialized.";
			break;
		  case HNINIT:
			ptr = "HLI has not been initialized.";
			break;
		  case HFIN:
			ptr = "HLI has already been finished, can't	reinitialize";
			break;
		  case HBFILE:
			ptr = "A bad file name was given.";
			break;
		  case HBMODE:
			ptr = "A bad or unauthorized file access mode was given";
			break;
		  case HBKEY:
			ptr = "A bad data base key was given.";
			break;
		  case HBSRNG:
			ptr = "A bad starting year or period was given for a range.";
			break;
		  case HBERNG:
			ptr = "A bad ending year or period was given for a range.";
			break;
		  case HBNRNG:
			ptr = "A bad number of observations was given for a range.";
			break;
		  case HNOOBJ:
			ptr = "The given object does not exist.";
			break;
		  case HBRNG:
			ptr = "A bad range was given.";
			break;
		  case HDUTAR:
			ptr = "The target object already exists.";
			break;
		  case HBOBJT:
			ptr = "Bad object type";
			break;
		  case HBFREQ:
			ptr = "Bad frequency";
			break;
		  case HTRUNC:
				ptr = "Oldest data truncated or a string was truncated";
			break;
		  case HNPOST:
			ptr = "The data base has not been posted or closed.";
			break;
		  case HFUSE:
			ptr = "The file is already in use.";
			break;
		  case HNFMDB:
			ptr = "The file is not a FAME data base.";
			break;
		  case HRNEXI:
			ptr = "Trying to read or update a file that does not exist.";
			break;
		  case HCEXI:
			ptr = "Trying to create a file that already exists.";
			break;
		  case HNRESW:
			ptr = "The name given is not a legal FAME name.";
			break;
		  case HBCLAS:
			ptr = "Bad object class";
			break;
		  case HBOBSV:
			ptr = "A bad OBSERVED attribute was given.";
			break;
		  case HBBASI:
			ptr = "A bad BASIS attribute was given.";
			break;
		  case HOEXI:
			ptr = "The data object already exists.";
			break;
		  case HBMONT:
			ptr = "A bad month was given.";
			break;
		  case HBFLAB:
			ptr = "A bad fiscal year label was given.";
			break;
		  case HBMISS:
			ptr = "A bad missing value type was given.";
			break;
		  case HBINDX:
			ptr = "A bad value index was given.";
			break;
		  case HNWILD:
			ptr = "Wildcarding has not been initialized";
			break;
		  case HBNCHR:
			ptr = "A bad number of characters was given.";
			break;
		  case HBGROW:
			ptr = "A bad growth factor was given.";
			break;
		  case HQUOTA:
			ptr = "no disk space is available.";
			break;
		  case HOLDDB:
			ptr = "Can't update or share an old data base";
			break;
		  case HMPOST:
			ptr = "The data base must be posted.";
			break;
		  case HSPCDB:
			ptr = "Can't write to a special data base.";
			break;
		  case HBFLAG:
			ptr = "A bad flag was given.";
			break;
		  case HPACK:
			ptr = "Can't perform operation on packed data base";
			break;
		  case HNEMPT:
			ptr = "The data base is not empty";
			break;
		  case HBATTR:
			ptr = "A bad attribute name was given.";
			break;
		  case HDUP:
			ptr = "A duplicate was ignored.";
			break;
		  case HBYEAR:
			ptr = "A bad year was given.";
			break;
		  case HBPER:
			ptr = "A bad period was given.";
			break;
		  case HBDAY:
			ptr = "A bad day was given.";
			break;
		  case HBDATE:
			ptr = "A bad date was given.";
			break;
		  case HBSEL:
			ptr = "A bad date selector was given.";
			break;
		  case HBREL:
			ptr = "A bad date relation value was given.";
			break;
		  case HBTIME:
			ptr = "A bad hour, minute or second was given.";
			break;
		  case HBCPU:
			ptr = "Unauthorized CPU ID or hardware type";
			break;
		  case HEXPIR:
			ptr = "Expired dead date.";
			break;
		  case HBPROD:
			ptr = "Unauthorized product.";
			break;
		  case HBUNIT:
			ptr = "A bad # of units was given";
			break;
		  case HBCNTX:
			ptr = "This operation not allowed in current context";
			break;
		  case HLOCKD:
			ptr = "This object is locked by the FAME session";
			break;
		  case HNETCN:
			ptr = "Could not connect to service on host.";
			break;
		  case HNFAME:
			ptr = "FAME process has terminated";
			break;
		  case HNBACK:
			ptr = "DB server on other machine terminated unexpectedly.";
			break;
		  case HSUSPN:
			ptr = "Access to a remote data base has been suspended.";
			break;
		  case HBSRVR:
			ptr = "Remote host does not support current	protocol version";
			break;
		  case HCLNLM:
			ptr = "FRDB server hard client limit exceeded";
			break;
		  case HBUSER:
			ptr = "Bad uname or passwd in filespec, or not authorized";
			break;
		  case HSRVST:
			ptr = "Could not start server process on remote host";
			break;
		  case HBOPT:
			ptr = "Bad option";
			break;
		  case HBOPTV:
			ptr = "Bad value for this option";
			break;
		  case HNSUPP:
			ptr = "Operation not supported on this data base";
			break;
		  case HBLEN:
			ptr = "A bad length	was given";
			break;
		  case HNULLP:
			ptr = "A NULL ptr was given";
			break;
		  case HREADO:
			ptr = "Invalid for read only hli";
			break;
		  case HNWFEA:
			ptr = "Data base contains features unknown to this HLI release";
			break;
		  case HBGLNM:
			ptr = "GLName or GLFormula error";
			break;
		  case HCLCHN:
			ptr = "A fatal I/O error or termination of server: channel closed";
			break;
		  case HDPRMC:
			ptr = "Call to cfmopre, it's already opened KIND REMOTE";
			break;
		  case HWKOPN:
			ptr = "cfmopwk called when a work data base is already open";
			break;
		  case HNUFRD:
			ptr = "FRDB user license cannot be acquired";
			break;
		  case HNOMEM:
			ptr = "Not enough memory for requested operation";
			break;
		  case HBFUNC:
			ptr = "Attempt to use obsolete function";
			break;
		  case HBPHAS:
			ptr = "A bad phase value for posting";
			break;
		  case HAPOST:
			ptr = "Db already in posted state";
			break;
		  case HUPDRD:
			ptr = "Db must be opened for either READ or UPDATE access";
			break;
		  case HP1REQ:
			ptr = "Phase1 Posting required for this database";
			break;
		  case HP2REQ:
			ptr = "Phase2 Posting required for this database";
			break;
		  case HUNEXP:
			ptr = "Unexpected error condition, check system error number";
			break;
		  case HBVER:
			ptr = "The license file does not support this version";
			break;
		  case HNFILE:
			ptr = "System file table is full";
			break;
		  case HMFILE:
			ptr = "Too many open files (for this procees)";
			break;
		  case HSCLLM:
			ptr = "FRDB server soft client limit exceeded";
			break;
		  case HDBCLM:
			ptr = "FRDB server data base client limit exceeded";
			break;
		  case HSNFIL:
			ptr = "FRDB server system file table full";
			break;
		  case HSMFIL:
			ptr = "FRDB server process has too many open files";
			break;
		  case HRESFD:
			ptr = "FRDB server could not open file descriptor";
			break;
		  case HTMOUT:
			ptr = "FRDB server did not respond within the time limit";
			break;
		  case HCHGAC:
			ptr = "Attempt to change access on database";
			break;
		  case HFMENV:
			ptr = "Check FAME environment variables";
			break;
		  case HLICFL:
			ptr = "A FAME licensing file was not found";
			break;
		  case HLICNS:
			ptr = "Unable to acquire a license to run the HLI";
			break;
		  case HRMTDB:
			ptr = "Function not valid for remote database WRITE access";
			break;
		  case HBCONN:
			ptr = "A bad connection key was given";
			break;
		  case HABORT:
			ptr = "Pending unit of work aborted";
			break;
		  case HNCONN:
			ptr = "Specified data base key is not open on a connection";
			break;
		  case HNMCA:
			ptr = "Remote server channel requires connection to an MCADBS";
			break;
		  case HBATYP:
			ptr = "A bad assertion type was specified";
			break;
		  case HBASRT:
			ptr = "A bad assertion was specified";
			break;
		  case HBPRSP:
			ptr = "A bad perspective was specified";
			break;
		  case HBGRP:
			ptr = "A bad grouping was specified";
			break;
		  case HNLOCL:
			ptr = "A local open of a FRDB writable database is not allowed";
			break;
		  case HDHOST:
			ptr = "Write server for database not running on this host";
			break;
		  case HOPENW:
			ptr = "Database already open for WRITE access";
			break;
		  case HOPEND:
			ptr = "Database already open for DIRECT access";
			break;
		  case HNTWIC:
			ptr = "The FRDB data base is already open in specified mode";
			break;
		  case HPWWOU:
			ptr = "Password specified without username";
			break;
		  case HLSERV:
			ptr = "Lost FDPS server REMEVAL sent to (??)";
			break;
		  case HLRESV:
			ptr = "Lost FDPS server reserved for REMEVAL";
			break;
		  case HIFAIL:
			ptr = "HLI internal failure";
			break;
		  case HFAMER:
			ptr = "Error from FAME-like server. Call cfmferr";
			break;

		  case HNOTYET:
			ptr = "FAME function not implemented in FameHLI yet";
			break;
		  default:
			ptr = "FAME Error code not recognized by FameHLI";
			break;
		}
		return(ptr);
}


//===========================================================================
//		F A M E   F R E Q   T X T
//===========================================================================
//===========================================================================
char	*FreqDesc(int freq)
{
char			*ptr = NULL;
int				base, nunits, year, month;
static	char	buffer[SMALLBUF];
char			*p;

		switch(freq) {
		  case HUNDFX: ptr = "Undefined Freq";			break;
		  case HDAILY: ptr = "DAILY";					break;
		  case HBUSNS: ptr = "BUSINESS";				break;
		  case HWKSUN: ptr = "WEEKLY (SUNDAY)";			break;
		  case HWKMON: ptr = "WEEKLY (MONDAY)";			break;
		  case HWKTUE: ptr = "WEEKLY (TUESDAY)";		break;
		  case HWKWED: ptr = "WEEKLY (WEDNESDAY)";		break;
		  case HWKTHU: ptr = "WEEKLY (THURSDAY)";		break;
		  case HWKFRI: ptr = "WEEKLY (FRIDAY)";			break;
		  case HWKSAT: ptr = "WEEKLY (SATURDAY)";		break;
		  case HTENDA: ptr = "TENDAY";					break;
		  case HWASUN: ptr = "BIWEEKLY (ASUNDAY)";		break;
		  case HWAMON: ptr = "BIWEEKLY (AMONDAY)";		break;
		  case HWATUE: ptr = "BIWEEKLY (ATUESDAY";		break;
		  case HWAWED: ptr = "BIWEEKLY (AWEDNESDAY)";	break;
		  case HWATHU: ptr = "BIWEEKLY (ATHURSDAY)";	break;
		  case HWAFRI: ptr = "BIWEEKLY (AFRIDAY)";		break;
		  case HWASAT: ptr = "BIWEEKLY (ASATURDAY)";	break;
		  case HWBSUN: ptr = "BIWEEKLY (BSUNDAY)";		break;
		  case HWBMON: ptr = "BIWEEKLY (BMONDAY)";		break;
		  case HWBTUE: ptr = "BIWEEKLY (BTUESDAY)";		break;
		  case HWBWED: ptr = "BIWEEKLY (BWEDNESDAY)";	break;
		  case HWBTHU: ptr = "BIWEEKLY (BTHURSDAY)";	break;
		  case HWBFRI: ptr = "BIWEEKLY (BFRIDAY)";		break;
		  case HWBSAT: ptr = "BIWEEKLY (BSATURDAY)";	break;
		  case HTWICM: ptr = "TWICEMONTHLY";			break;
		  case HMONTH: ptr = "MONTHLY";					break;
		  case HBMNOV: ptr = "BIMONTHLY (NOVEMBER)";	break;
		  case HBIMON: ptr = "BIMONTHLY (DECEMBER)";	break;
		  case HQTOCT: ptr = "QUARTERLY (OCTOBER)";		break;
		  case HQTNOV: ptr = "QUARTERLY (NOVEMBER)";	break;
		  case HQTDEC: ptr = "QUARTERLY (DECEMBER)";	break;
		  case HANJAN: ptr = "ANNUAL (JANUARY)";		break;
		  case HANFEB: ptr = "ANNUAL (FEBRUARY)";		break;
		  case HANMAR: ptr = "ANNUAL (MARCH)";			break;
		  case HANAPR: ptr = "ANNUAL (APRIL)";			break;
		  case HANMAY: ptr = "ANNUAL (MAY)";			break;
		  case HANJUN: ptr = "ANNUAL (JUNE)";			break;
		  case HANJUL: ptr = "ANNUAL (JULY)";			break;
		  case HANAUG: ptr = "ANNUAL (AUGUST)";			break;
		  case HANSEP: ptr = "ANNUAL (SEPTEMBER)";		break;
		  case HANOCT: ptr = "ANNUAL (OCTOBER)";		break;
		  case HANNOV: ptr = "ANNUAL (NOVEMBER)";		break;
		  case HANDEC: ptr = "ANNUAL (DECEMBER)";		break;
		  case HSMJUL: ptr = "SEMIANNUAL (JULY)";		break;
		  case HSMAUG: ptr = "SEMIANNUAL (AUGUST)";		break;
		  case HSMSEP: ptr = "SEMIANNUAL (SEPTEMBER)";	break;
		  case HSMOCT: ptr = "SEMIANNUAL (OCTOBER)";	break;
		  case HSMNOV: ptr = "SEMIANNUAL (NOVEMBER)";	break;
		  case HSMDEC: ptr = "SEMIANNUAL (DECEMBER)";	break;
		  case HAYPP : ptr = "YPP";						break;
		  case HAPPY : ptr = "PPY";						break;
		  case HSEC  : ptr = "SECONDLY";				break;
		  case HMIN  : ptr = "MINUTELY";				break;
		  case HHOUR : ptr = "HOURLY";					break;
		  case HCASEX: ptr = "CASE";					break;
		  default    : 
			cfmufrq(&status, freq, &base, &nunits, &year, &month);
			if (status == HSUCC) {
				strcpy(buffer, FreqDesc(base));
				if (nunits != 0) {
					p = buffer+strlen(buffer);
					sprintf(p, "(%d)", nunits);
				}
			} else {
				sprintf(buffer, "<Unknown> (%d)", freq);
			}
			ptr = buffer;
		}
		return(ptr);
}


//===========================================================================
//		F A M E   T Y P E   T X T
//===========================================================================
//		FAME Data Object Types
//===========================================================================
char	*TypeDesc(int code)
{
char	*ptr;
int		x = HRMODE;

		switch(code) {
		  case HUNDFT:
			ptr = "Undefined Type";
			break;
		  case HNUMRC:
			ptr = "NUMERIC";
			break;
		  case HNAMEL:
			ptr = "NAMELIST";
			break;
		  case HBOOLN:
			ptr = "BOOLEAN";
			break;
		  case HSTRNG:
			ptr = "STRING";
			break;
		  case HPRECN:
			ptr = "PRECISION";
			break;
		  case HDATE:
			ptr = "General DATE";
			break;
		  case HRECRD:
			ptr = "RECORD";
			break;
		  default:
			ptr = FreqDesc(code);
			break;
		}
		return(ptr);
}


//===========================================================================
//*** FAME Data Base File Access Modes ***/
//===========================================================================
char	*AccessModeDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HRMODE:
			ptr = "READ";
			break;
		  case HCMODE:
			ptr = "CREATE";
			break;
		  case HOMODE:
			ptr = "OVERWRITE";
			break;
		  case HUMODE:
			ptr = "UPDATE";
			break;
		  case HSMODE:
			ptr = "SHARED";
			break;
		  case HWMODE:
			ptr = "WRITE";
			break;
		  case HDMODE:
			ptr = "DIRECT WRITE";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}


//===========================================================================
//* Four unimplemented/unsupported modes removed */
//===========================================================================

//===========================================================================
/* For DATE objects, the type is usually the frequency of the date; */
/* HDATE is used only when the general type is required.            */
/* Record types (HRECRD) are NOT supported in FORTRAN interface.    */
//===========================================================================


//===========================================================================
/*** FAME BASIS Attribute Settings ***/
//===========================================================================

char	*BasisDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HBSUND:
			ptr = "Undefined Basis";
			break;
		  case HBSDAY:
			ptr = "DAILY";
			break;
		  case HBSBUS:
			ptr = "BUSINESS";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}



//===========================================================================
/*** FAME OBSERVED Attribute Settings ***/
//===========================================================================

char	*ObservedDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HOBUND:
			ptr = "Undefined Observed";
			break;
		  case HOBBEG:
			ptr = "BEGINNING";
			break;
		  case HOBEND:
			ptr = "ENDING";
			break;
		  case HOBAVG:
			ptr = "AVERAGED";
			break;
		  case HOBSUM:
			ptr = "SUMMED";
			break;
		  case HOBANN:
			ptr = "ANNUALIZED";
			break;
		  case HOBFRM:
			ptr = "FORMULA";
			break;
		  case HOBHI:
			ptr = "HIGH";
			break;
		  case HOBLO:
			ptr = "LOW";
			break;
		  default:
			ptr = "Unknown OBSERVED code";
			break;
		}
		return(ptr);
}

//===========================================================================
/*** FAME Frequencies ***/
//===========================================================================

//===========================================================================
/* The constants defined here can be used for all frequencies */
/* except for PPY and YPP.  For PPY and YPP, and intra-day    */
/* frequencies where the number of units per period is not 1, */
/* use cfmpfrq to pack the necessary information into an      */
/* integer frequency, and cfmufrq to unpack the frequency.    */
//===========================================================================

//===========================================================================
/*** Months ***/
//===========================================================================
char	*MonthsDesc(int observed)
{
char	*ptr;

		switch(observed) {
		  case HJAN:
			ptr = "JANUARY";
			break;
		  case HFEB:
			ptr = "FEBRUARY";
			break;
		  case HMAR:
			ptr = "MARCH";
			break;
		  case HAPR:
			ptr = "APRIL";
			break;
		  case HMAY:
			ptr = "MAY";
			break;
		  case HJUN:
			ptr = "JUNE";
			break;
		  case HJUL:
			ptr = "JULY";
			break;
		  case HAUG:
			ptr = "AUGUST";
			break;
		  case HSEP:
			ptr = "SEPTEMBER";
			break;
		  case HOCT:
			ptr = "OCTOBER";
			break;
		  case HNOV:
			ptr = "NOVEMBER";
			break;
		  case HDEC:
			ptr = "DECEMBER";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}


//===========================================================================
/* Old fiscal year end months */
//===========================================================================
char	*OldFYEndDesc(int code)
{
		return(MonthsDesc(code));
}



//===========================================================================
/*** Weekdays ***/
//===========================================================================
char	*WeekdayDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HSUN:
			ptr = "SUNDAY";
			break;
		  case HMON:
			ptr = "MONDAY";
			break;
		  case HTUE:
			ptr = "TUESDAY";
			break;
		  case HWED:
			ptr = "WEDNESDAY";
			break;
		  case HTHU:
			ptr = "THURSDAY";
			break;
		  case HFRI:
			ptr = "FRIDAY";
			break;
		  case HSAT:
			ptr = "SATURDAY";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}



//===========================================================================
/*** Bi-Weekdays ***/
//===========================================================================
char	*BiWeekdayDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HASUN:
			ptr = "ASUNDAY";
			break;
		  case HAMON:
			ptr = "AMONDAY";
			break;
		  case HATUE:
			ptr = "ATUESDAY";
			break;
		  case HAWED:
			ptr = "AWEDNESDAY";
			break;
		  case HATHU:
			ptr = "ATHURSDAY";
			break;
		  case HAFRI:
			ptr = "AFRIDAY";
			break;
		  case HASAT:
			ptr = "ASATURDAY";
			break;
		  case HBSUN:
			ptr = "BSUNDAY";
			break;
		  case HBMON:
			ptr = "BMONDAY";
			break;
		  case HBTUE:
			ptr = "BTUESDAY";
			break;
		  case HBWED:
			ptr = "BWEDNESDAY";
			break;
		  case HBTHU:
			ptr = "BTHURSDAY";
			break;
		  case HBFRI:
			ptr = "BFRIDAY";
			break;
		  case HBSAT:
			ptr = "BSATURDAY";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}



//===========================================================================
/*** FAME fiscal year labels ***/
//===========================================================================
char	*FYLabelDesc(int code)
{
char	*ptr;

		switch(code) {
		  case HFYFST:
			ptr = "FIRST";
			break;
		  case HFYLST:
			ptr = "LAST";
			break;
		  case HFYAUT:
			ptr = "AUTO";
			break;
		  default:
			ptr = "Unrecognized code";
			break;
		}
		return(ptr);
}




//***************************************************************************
//***************************************************************************
//	P E R L - H L I   M O D U L E   S T A R T S
//***************************************************************************
//**************************************************************************/

MODULE = FameHLI::API::EXT		PACKAGE = FameHLI::API::EXT		PREFIX = perl_

BOOT:
#ifdef	CFMINI_EVERYWHERE
//		Since we are linked to our own HLI we can call cfmini
		cfmini(&status);
#endif
		status = 0;


#*
#*
#*	P U B L I C   F U N C T I O N S
#*
#*

##***************************************************************************
##***************************************************************************
##	A D D E D   F U N C T I O N S
##***************************************************************************
##		cfmini(&rc);
##***************************************************************************
int
perl_BootstrapEXT()

	PREINIT:
int		rc	=	HSUCC;

	CODE:
		printf("BootstrapEXT is deprecated\n");
		RETVAL = rc;

	OUTPUT:
		RETVAL


##===========================================================================
##      F O R M A T   D A T E
##===========================================================================
char*
perl_FormatDate(date, freq=HBUSNS, image="<YEAR>/<MZ>/<DZ>", fmonth=HDEC, flabel=HFYFST)
int		date
int		freq
char	*image
int		fmonth
int		flabel

	PREINIT:
char	*out;
char	*ptr;
int		len;

	CODE:
		ptr = FormatDate(date, freq, image, fmonth, flabel);
		len = strlen(ptr);
		out = (char *)safemalloc(len+1);
		strcpy(out, ptr);
		RETVAL = out;

	OUTPUT:
		RETVAL


##===========================================================================
##		F A M E   C L A S S   T X T
##===========================================================================
char*
perl_ClassDesc(code)
int code

	PREINIT:
char	*buffer = NULL;

	CODE:
		buffer = newString(ClassDesc(code));
		RETVAL = buffer;

	OUTPUT:
		RETVAL


##===========================================================================
##		F A M E   E R R O R   M E S S A G E
##===========================================================================
##===========================================================================
char*
perl_ErrDesc(code)
int code

	CODE:
		RETVAL = newString(ErrDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##		F A M E   F R E Q   T X T
##===========================================================================
##	BROKE
##===========================================================================
char*
perl_FreqDesc(code)
int code

	CODE:
		RETVAL = newString(FreqDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##		F A M E   T Y P E   T X T
##===========================================================================
##		FAME Data Object Types
##===========================================================================
char*
perl_TypeDesc(code)
int code

	CODE:
		RETVAL = newString(TypeDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##** FAME Data Base File Access Modes 
##===========================================================================
char*
perl_AccessModeDesc(code)
int code

	CODE:
		RETVAL = newString(AccessModeDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
## Four unimplemented/unsupported modes removed */
##
## For DATE objects, the type is usually the frequency of the date; */
## HDATE is used only when the general type is required.            */
## Record types (HRECRD) are NOT supported in FORTRAN interface.    */
##===========================================================================


##===========================================================================
##** FAME BASIS Attribute Settings ***/
##===========================================================================

char*
perl_BasisDesc(code)
int code

	CODE:
		RETVAL = newString(BasisDesc(code));
	OUTPUT:
		RETVAL



##===========================================================================
##** FAME OBSERVED Attribute Settings ***/
##===========================================================================
char*
perl_ObservedDesc(code)
int code

	CODE:
		RETVAL = newString(ObservedDesc(code));
	OUTPUT:
		RETVAL

#/*** FAME Frequencies ***/

##===========================================================================
##* The constants defined here can be used for all frequencies
##* except for PPY and YPP.  For PPY and YPP, and intra-day
##* frequencies where the number of units per period is not 1,
##* use cfmpfrq to pack the necessary information into an
##* integer frequency, and cfmufrq to unpack the frequency.
##===========================================================================

##===========================================================================
##*** Months 
##===========================================================================
char*
perl_MonthsDesc(code)
int code

	CODE:
		RETVAL = newString(MonthsDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##* Old fiscal year end months
##===========================================================================
char*
perl_OldFYEndDesc(code)
int code

	CODE:
		RETVAL = newString(MonthsDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##*** Weekdays
##===========================================================================
char*
perl_WeekdayDesc(code)
int code

	CODE:
		RETVAL = newString(WeekdayDesc(code));
	OUTPUT:
		RETVAL


##===========================================================================
##*** Bi-Weekdays
##===========================================================================
char*
perl_BiWeekdayDesc(code)
int code

	CODE:
		RETVAL = newString(BiWeekdayDesc(code));
	OUTPUT:
		RETVAL



##===========================================================================
##*** FAME fiscal year labels
##===========================================================================
char*
perl_FYLabelDesc(code)
int		code

	CODE:
		RETVAL = newString(FYLabelDesc(code));
	OUTPUT:
		RETVAL



