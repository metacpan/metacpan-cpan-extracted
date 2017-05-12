/* $File: //member/autrijus/Locale-Hebrew-Calendar/Calendar.xs $ $Author: autrijus $
   $Revision: #1 $ $Change: 3539 $ $DateTime: 2003/01/14 20:55:43 $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hdate.h"

MODULE = Locale::Hebrew::Calendar		PACKAGE = Locale::Hebrew::Calendar		
AV * 
_j2g(d, m, y)
int d
int m
int y
CODE:
	AV *a;
	struct hdate *g;

	g = gdate(d, m, y);

	a = newAV();
	av_push(a, newSViv(g->hd_day + 1));
	av_push(a, newSViv(g->hd_mon));
	av_push(a, newSViv(g->hd_year));
	RETVAL = a;
	OUTPUT:
	RETVAL

AV *
_g2j(d, m, y)
int d
int m
int y
CODE:
	AV *a;
	struct hdate *g;

	g = hdate(d, m, y);

	a = newAV();
	av_push(a, newSViv(g->hd_day + 1));
	av_push(a, newSViv(g->hd_mon));
	av_push(a, newSViv(g->hd_year));
	RETVAL = a;
	OUTPUT:
	RETVAL


