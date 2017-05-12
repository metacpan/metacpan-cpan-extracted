/*
 * DVB debug utils
 */

#ifndef DVB_DEBUG
#define DVB_DEBUG

#include <stdio.h>
#include <stdarg.h>

#ifndef WIN32
#ifdef HAVE_DVB
#include "dvb_struct.h"
#endif
#endif

extern int dvb_debug;

/*------------------------------------------------------------------*/
// Timer
struct timespec *dbg_timer_start() ;
struct timespec *dbg_timer_stop() ;
struct timespec *dbg_timer_duration() ;
char *dbg_sprintf_timer(const char *format, struct timespec *t) ;
char *dbg_sprintf_duration(const char *format) ;

void fprintf_timestamp(FILE *stream, const char *format, ...) ;
void printf_timestamp(const char *format, ...) ;


/*------------------------------------------------------------------*/
#ifndef WIN32
#ifdef HAVE_DVB

void dump_fe_info(struct dvb_state *h);
void _fn_start(char *name) ;
void _fn_end(char *name, int rc) ;
void _indent(int level) ;
void _prt_indent(char *name) ;

void _dump_frontend_info(int indent, struct dvb_frontend_info *info) ;
void _dump_frontend_params(int indent, struct dvb_frontend_parameters *p) ;
void _dump_demux_filter(int indent, struct demux_filter *f) ;
void _dump_state(char *name, char *msg, struct dvb_state *h) ;

#endif
#endif
/*------------------------------------------------------------------*/

#endif
