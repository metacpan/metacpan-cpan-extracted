/* -*- c -*- 
 * File: log.c
 * Author: Igor Vlasenko <vlasenko@imath.kiev.ua>
 * Created: Thu Sep  1 17:18:16 2005
 *
 * $Id$
 */

/* based on FFmpeg av_log API */

#include <stdio.h>
#include <string.h>
#include "tmpllog.h"

static int tmpl_log_level = TMPL_LOG_ERROR;
TMPLPRO_LOCAL FILE* tmpl_log_stream = NULL;

TMPLPRO_LOCAL void 
tmpl_log_default_callback(int level, const char* fmt, va_list vl)
{
    vfprintf(stderr, fmt, vl);
}

TMPLPRO_LOCAL void 
tmpl_log_stream_callback(int level, const char* fmt, va_list vl)
{
    vfprintf(tmpl_log_stream, fmt, vl);
    fflush(tmpl_log_stream);
}

static void (*tmpl_log_callback)(int, const char*, va_list) = tmpl_log_default_callback;

TMPLPRO_LOCAL
void 
tmpl_log(int level, const char *fmt, ...)
{
    va_list vl;
    va_start(vl, fmt);
    tmpl_vlog(level, fmt, vl);
    va_end(vl);
}

TMPLPRO_LOCAL
void 
tmpl_vlog(int level, const char *fmt, va_list vl)
{
    if(level>tmpl_log_level) return;
    tmpl_log_callback(level, fmt, vl);
}

TMPLPRO_LOCAL
int 
tmpl_log_get_level(void)
{
    return tmpl_log_level;
}

TMPLPRO_LOCAL
void 
tmpl_log_set_level(int level)
{
    tmpl_log_level = level;
}

TMPLPRO_LOCAL
void 
tmpl_log_set_callback(void (*callback)(int, const char*, va_list))
{
    tmpl_log_callback = callback;
}
