/* $File: //member/autrijus/Locale-Hebrew-Calendar/hdate.c $ $Author: autrijus $
   $Revision: #1 $ $Change: 3539 $ $DateTime: 2003/01/14 20:55:43 $ */

/*
 | Hebrew dates since 2nd century A.D.
 | by Amos Shapir 1978 (rev. 1985)
 | The HEBREW option prints hebrew strings in l.c.
 | flags: -j - input date is Julian (default before 1582 (5342))
 |	  -h - translate hebrew date to general
 */
#include "hdate.h"

int jflg = 0, hflg = 0;

/*
 | compute general date structure from hebrew date
 */
struct hdate *
gdate(d, m, y)
	int m, y, d;
{
	static struct hdate h;
	int s;

	y -= 3744;
	s = dysiz(y);
	d += s;
	s = dysiz(y+1)-s;		/* length of year */
	d += (59*(m-1)+1)/2;	/* regular months */
	/* special cases */
	if(s%10>4 && m>2)
		d++;
	if(s%10<4 && m>3)
		d--;
	if(s>365 && m>6)
		d += 30;
	d -= 6002;
	if(!jflg) {	/* compute century */
		y = (d+36525)*4/146097-1;
		d -= y/4*146097+(y&3)*36524;
		y *= 100;
	} else {
		d += 2;
		y = 0;
	}
	/* compute year */
	s = (d+366)*4/1461-1;
	d -= s/4*1461+(s&3)*365;
	y += s;
	/* compute month */
	m = (d+245)*12/367-7;
	d -= m*367/12-30;
	if(++m >= 12) {
		m -= 12;
		y++;
	}
	h.hd_day = d;
	h.hd_mon = m;
	h.hd_year = y;
	return(&h);
}

