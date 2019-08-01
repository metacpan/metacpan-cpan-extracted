#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <log4cplus/clogger.h>

#include "LLCconfig.h"
#include "const-c.inc"

#define MY_CXT_KEY "Lib::Log4cplus::_guts" XS_VERSION
typedef struct {
    int count;
    SV *initializer;
} my_cxt_t;

START_MY_CXT

MODULE = Lib::Log4cplus::Initializer		PACKAGE = Lib::Log4cplus::Initializer

void
DESTROY(initializer)
    void *initializer;
CODE:
    if(initializer)
	log4cplus_deinitialize(initializer);

MODULE = Lib::Log4cplus		PACKAGE = Lib::Log4cplus

INCLUDE: const-xs.inc

BOOT:
{
    MY_CXT_INIT;
    MY_CXT.count = 0;
    MY_CXT.initializer = newSV(0);
    sv_setref_pv(MY_CXT.initializer, "Lib::Log4cplus::Initializer", log4cplus_initialize());
#if defined(HAVE_LOG4CPLUS_ADD_LOG_LEVEL) && defined(HAVE_LOG4CPLUS_REMOVE_LOG_LEVEL)
    log4cplus_add_log_level(CRITICAL_LOG_LEVEL, "CRIT");
    log4cplus_add_log_level(NOTICE_LOG_LEVEL, "NOTICE");
    log4cplus_add_log_level(BASIC_LOG_LEVEL, "BASIC");
#endif
}

void
CLONE(...)
CODE:
{
    MY_CXT_CLONE;
    MY_CXT.initializer = newSV(0);
    sv_setref_pv(MY_CXT.initializer, "Lib::Log4cplus::Initializer", log4cplus_initialize());
}

void
file_configure (pathname)
	const char *pathname;
PROTOTYPE:
	$
CODE:
{
    int ret_code;
    if(NULL == pathname)
	XSRETURN_UNDEF;
#ifdef HAVE_LOG4CPLUS_FILE_RECONFIGURE
    ret_code = log4cplus_file_reconfigure(pathname);
#else
    ret_code = log4cplus_file_configure(pathname);
#endif
    ST(0) = sv_2mortal(newSViv(ret_code));
    XSRETURN(1);
}

void
static_configure (configuration)
	const char *configuration;
PROTOTYPE:
	$
CODE:
{
    int ret_code;
    if(NULL == configuration)
	XSRETURN_UNDEF;
#ifdef HAVE_LOG4CPLUS_STR_RECONFIGURE
    ret_code = log4cplus_str_reconfigure(configuration);
#else
    ret_code = log4cplus_str_configure(configuration);
#endif
    ST(0) = sv_2mortal(newSViv(ret_code));
    XSRETURN(1);
}

void
basic_configure (out_to_stderr)
	int out_to_stderr;
PROTOTYPE:
CODE:
{
#ifdef HAVE_LOG4CPLUS_BASIC_RECONFIGURE
    int ret_code = log4cplus_basic_reconfigure(out_to_stderr);
#else
    int ret_code = log4cplus_basic_configure();
#endif
    ST(0) = sv_2mortal(newSViv(ret_code));
    XSRETURN(1);
}

void
logger_exists (category)
	const char *category;
PROTOTYPE:
	$
CODE:
{
    int exists = NULL != category ? log4cplus_logger_exists(category) : 1;
    if(exists)
	XSRETURN_YES;
    else
	XSRETURN_NO;
}

void
logger_is_enabled_for (category, log_level)
	const char *category;
	int log_level;
PROTOTYPE:
	$$
CODE:
{
    int is_enabled = log4cplus_logger_is_enabled_for(category, log_level);
    if(is_enabled)
	XSRETURN_YES;
    else
	XSRETURN_NO;
}

void
logger_log (category, log_level, message)
	const char *category;
	int log_level;
	const char *message;
PROTOTYPE:
	$$$
CODE:
{
    int ret_code = NULL != message ? log4cplus_logger_log_str(category, log_level, message) : EINVAL;
    ST(0) = sv_2mortal(newSViv(ret_code));
    XSRETURN(1);
}

void
logger_force_log (category, log_level, message)
	const char *category;
	int log_level;
	const char *message;
PROTOTYPE:
	$$$
CODE:
{
    int ret_code = NULL != message ? log4cplus_logger_force_log_str(category, log_level, message) : EINVAL;
    ST(0) = sv_2mortal(newSViv(ret_code));
    XSRETURN(1);
}

void
log4cplus_add_log_level(loglevel, loglevel_name)
	unsigned int loglevel;
	const char *loglevel_name;
PROTOTYPE:
	$$
CODE:
{
#ifdef HAVE_LOG4CPLUS_ADD_LOG_LEVEL
    int ret_code = log4cplus_add_log_level(loglevel, loglevel_name);
    ST(0) = sv_2mortal(newSViv(ret_code));
#else
    ST(0) = sv_2mortal(newSViv(ENOTSUP));
#endif
    XSRETURN(1);
}

void
log4cplus_remove_log_level(loglevel, loglevel_name)
	unsigned int loglevel;
	const char *loglevel_name;
PROTOTYPE:
	$$
CODE:
{
#ifdef HAVE_LOG4CPLUS_REMOVE_LOG_LEVEL
    int ret_code = log4cplus_remove_log_level(loglevel, loglevel_name);
    ST(0) = sv_2mortal(newSViv(ret_code));
#else
    ST(0) = sv_2mortal(newSViv(ENOTSUP));
#endif
    XSRETURN(1);
}
