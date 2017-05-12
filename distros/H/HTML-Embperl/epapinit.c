/*###################################################################################
#
#   Embperl - Copyright (c) 1997-2001 Gerald Richter / ECOS
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#   For use with Apache httpd and mod_perl, see also Apache copyright.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: epapinit.c,v 1.3 2001/11/02 10:03:48 richter Exp $
#
###################################################################################*/


#include "ep.h"

#ifdef APACHE


static void embperl_ApacheInit (server_rec *s, pool *p) ;
static void embperl_ApacheInitCleanup (void * p) ;


static const command_rec embperl_cmds[] =
{
    {NULL}
};


/* static module MODULE_VAR_EXPORT embperl_module = { */
static module embperl_module = {
    STANDARD_MODULE_STUFF,
    embperl_ApacheInit,         /* initializer */
    NULL,                       /* dir config creater */
    NULL,                       /* dir merger --- default is to override */
    NULL,                       /* server config */
    NULL,                       /* merge server configs */
    embperl_cmds,               /* command table */
    NULL,                       /* handlers */
    NULL,                       /* filename translation */
    NULL,                       /* check_user_id */
    NULL,                       /* check auth */
    NULL,                       /* check access */
    NULL,                       /* type_checker */
    NULL,			/* fixups */
    NULL,                       /* logger */
    NULL,                       /* header parser */
    NULL,                       /* child_init */
    NULL,                       /* child_exit */
    NULL                        /* post read-request */
};


void embperl_ApacheAddModule ()

    {
    ap_add_module (&embperl_module) ;
    }

static void embperl_ApacheInit (server_rec *s, pool *p)

    {
    pool * subpool = ap_make_sub_pool(p);

    ap_register_cleanup(subpool, NULL, embperl_ApacheInitCleanup, embperl_ApacheInitCleanup);
    ap_add_version_component ("Embperl/"VERSION) ;
    }

static void embperl_ApacheInitCleanup (void * p)

    {
    /* make sure embperl module is removed before mod_perl */
    ap_remove_module (&embperl_module) ;
    }

#endif
