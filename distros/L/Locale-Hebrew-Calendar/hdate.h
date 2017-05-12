/* $File: //member/autrijus/Locale-Hebrew-Calendar/hdate.h $ $Author: autrijus $
   $Revision: #1 $ $Change: 3539 $ $DateTime: 2003/01/14 20:55:43 $ */

#define MINWEST 300	/* minutes west of GMT */
/*#define HEBREW 	/* output for Hebrew printer */
/* #define REV	/* " that is not bi-directional */
/* #define BIGLONG	/* if your longs >= 34 bits */

 struct hdate {
	int hd_day;
	int hd_mon;
	int hd_year;
	int hd_dw;
	int hd_flg;
} *hdate();

extern char *mname[], *hmname[];
#ifdef HEBREW
	char *hnum();
#ifdef REV
char *rev();
#else
#define rev(s) s
#endif
#endif

