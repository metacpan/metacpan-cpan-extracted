/*
 * reimplementation of Daniel Bernstein's byte library.
 * placed in the public domain by Uwe Ohse, uwe@ohse.de.
 */
#ifndef CASE_H
#define CASE_H

extern int case_init_lwrdone;
extern void case_init_lwrtab(void);
extern char case_lwrtab[256];

extern void case_lowers(char *);
extern void case_lowerb(char *,unsigned int);
extern int case_diffs(const char *,const char *);
extern int case_diffb(const char *,unsigned int,const char *);
extern int case_starts(const char *,const char *);
extern int case_startb(const char *,unsigned int,const char *);

#define case_equals(s,t) (!case_diffs((s),(t)))

#endif
