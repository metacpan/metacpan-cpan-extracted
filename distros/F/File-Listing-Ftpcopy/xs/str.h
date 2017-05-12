/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef STR_H
#define STR_H

extern unsigned int str_copy(char *to,const char *from);
extern int str_diff(const char *,const char *);
extern int str_diffn(const char *,const char *,unsigned int);
extern unsigned int str_len(const char *);
extern unsigned int str_chr(const char *,int searched);
extern unsigned int str_rchr(const char *,int searched);
extern int str_start(const char *lo_ng,const char *may_be_head);

#define str_equal(s,t) (!str_diff((s),(t)))

#endif
