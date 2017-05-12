/* $File: //member/autrijus/Locale-Hebrew-Calendar/hcom.c $ $Author: autrijus $
   $Revision: #1 $ $Change: 3539 $ $DateTime: 2003/01/14 20:55:43 $ */

/* routines common to hdate and hcal */

#include "hdate.h"

char	*mname[]= {
#ifdef HEBREW
	"JANUARY", "FEBRUARY", "MARCH", "APRIL",
	"MAY", "JUNE", "JULY", "AUGUST",
	"SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER",
#else
	"January", "February", "March", "April",
	"May", "June", "July", "August",
	"September", "October", "November", "December",
#endif
};
char  *hmname[] = {
#ifdef HEBREW
	"תשרי", "חשוון", "כסלו",
	"טבת", "שבט", "אדר",
	"ניסן", "אייר", "סיוון",
	"תמוז", "אב", "אלול",
	"אדר א'", "אדר ב'"
#else
	"Tishrey", "Heshvan", "Kislev",
	"Tevet","Shvat", "Adar",
	"Nisan", "Iyar", "Sivan",
	"Tamuz", "Av", "Elul",
	"Adar a", "Adar b"
#endif
};


/*
 | compute date structure from no. of days since 1 Tishrei 3744
 */
/* constants, in 1/18th of minute */
#define HOUR 1080
#define DAY  (24*HOUR)
#define WEEK (7*DAY)
#define M(h,p) (h*HOUR+p)
#define MONTH (DAY+M(12,793))
struct hdate *
hdate(d, m, y)
	int m, y, d;
{
	static struct hdate h;
	int s;
	extern jflg;

	if((m -= 2) <= 0) {
		m += 12;
		y--;
	}
	/* no. of days, Julian calendar */
	d += 365*y+y/4+367*m/12+5968;
	/* Gregorian calendar */
	if(!jflg)
		d -= y/100-y/400-2;
	h.hd_dw = (d+1)%7;

	/* compute the year */
	y += 16;
	s = dysiz(y);
	m = dysiz(y+1);
	while(d >= m) {	/* computed year was underestimated */
		s = m;
		y++;
		m = dysiz(y+1);
	}
	d -= s;
	s = m-s;	/* size of current year */
	y += 3744;

	h.hd_flg = s%10-4;

	/* compute day and month */
	if(d >= s-236) {	/* last 8 months are regular */
		d -= s-236;
		m = d*2/59;
		d -= (m*59+1)/2;
		m += 4;
		if(s>365 && m<=5)	/* Adar of Meuberet */
			m += 8;
	} else {
		/* 1st 4 months have 117-119 days */
		s = 114+s%10;
		m = d*4/s;
		d -= (m*s+3)/4;
	}

	h.hd_day = d;
	h.hd_mon = m;
	h.hd_year = y;
	return(&h);
}


/* no. of days in y years */
dysiz(y)
	int y;
{
	int m, nm, dw, s, l;

	l = y*7+1;	/* no. of leap months */
	m = y*12+l/19;	/* total no. of months */
	nm = m*MONTH+M(1,779); /* molad at 197 cycles */
	s = m*28+nm/DAY-2;

	nm %= WEEK;
	l %= 19;
	dw = nm/DAY;
	nm %= DAY;

	/* special cases of Molad Zaken */
	if(nm >= 18*HOUR || l < 12 && dw==3 && nm>=M(9,204) ||
	 l < 7 && dw==2 && nm>=M(15,589))
		s++,dw++;
	/* ADU */
	if(dw == 1 || dw == 4 || dw == 6)
		s++;
	return s;
}


#ifdef HEBREW
char *
hnum(n)
	int n;
{
	static char hn[16];
	int char *p = hn;

	if(n >= 1000) {
		(void)hnum(n/1000);	/* result in hn */
		while(*p)
			p++;
		n %= 1000;
	}
	while(n >= 400) {
		*p++ = 'ת';
		n -= 400;
	}
	if(n >= 100) {
		*p++ = 'צ'+n/100;
		n %= 100;
	}
	if(n >= 10) {
		if(n == 15 || n == 16) {
                        *p++ = 'ט';
			n -= 9;
                }
		*p++ = " יכלמנסעפצ"[n/10];
		n %= 10;
	}
	if(n > 0)
		*p++ = 'א'+n-1;
	*p++ = 0;
	return hn;
}
#ifdef REV
char *
rev(as)
	char *as;
{
	int char *p, *s;
	int t;

	s = as;
	for(p=s;*p;p++);
	while(p > s) {
		t = *--p;
		*p = *s;
		*s++ = t;
	}
	return as;
}
#endif
#endif
