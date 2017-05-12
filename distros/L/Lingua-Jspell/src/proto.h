/*
 * Copyright 1992, 1993, Geoff Kuenning, Granada Hills, CA
 * All rights reserved.
 *
 * Copyright 1994 by Ulisses Pinto & Jose' Joa~o Almeida, Universidade do Minho
 */

extern char *skiptoword(char * bufp);
extern char *       skipoverword(char * bufp);
extern void skip_ntroff_text_formaters(int hadlf, FILE *ofile);

extern int      addvheader(struct dent * ent);
extern void     askmode(void);
extern void     backup(void);
extern int      casecmp(char * a, char * b, int canonical);
extern void     chupcase(char * s);
extern void     checkfile(void);
extern void     checkline(FILE * ofile);
extern void     chk_aff(ichar_t * word, ichar_t * ucword, int len, 
			int ignoreflagbits, int allhits, int add_poss, int reconly);
extern int      combinecaps(struct dent * hdr, struct dent * newent);
extern int      compoundgood(ichar_t * word);
extern void     copyout(char ** cc, int cnt);
extern void     correct(char * ctok, ichar_t  * itok, char ** curchar);
extern char *   do_regex_lookup(char * expr,  int whence);
extern SIGNAL_TYPE done(int); 
extern void     dumpmode(void);
/* extern void     erase(void); */
extern int      expand_pre(char *croot, ichar_t *rootword, 
                                 MASKTYPE mask[], int option, char *extra);
extern int      expand_suf(char *croot, ichar_t *rootword, MASKTYPE mask[], 
                        int crossonly, int option, char *extra, char *pre_class);
extern int      findfiletype(char *name, int searchnames, int *deformatter);
extern void    flagpr(ichar_t *word, int preflag, int prestrip, int preadd, 
		      ichar_t *preclass, int sufflag, int sufadd, ichar_t *sufclass);
extern int      good(ichar_t *word, int ignoreflagbits, int allhits, 
		     int add_poss, int reconly);
extern int      hash(ichar_t *word, int hashtablesize);

#ifndef ICHAR_IS_CHAR 
extern int      icharcmp(ichar_t *s1, ichar_t *s2);
extern ichar_t *icharcpy(ichar_t *out, ichar_t *in);
extern int      icharlen(ichar_t *str);
extern int      icharncmp(ichar_t *s1, ichar_t *s2, int n);
#endif /* ICHAR_IS_CHAR */
extern int      ichartostr(char *out, ichar_t *in, int outlen, int canonical);
extern char *   ichartosstr(ichar_t *in, int canonical);
extern int      ins_root_cap(ichar_t *word, ichar_t *pattern,
			     int prestrip, int preadd, int sufstrip, int sufadd, 
			     struct dent *firstdent, struct flagent *pfxent, 
			     struct flagent *sufent);
extern void     inverse(void);
extern int      linit(void); 
extern struct dent * lookup(ichar_t *word, int dotree);
extern void     lowcase(ichar_t *string);
extern int      makedent(char *lbuf, int lbuflen, struct dent *d);
extern void     makepossibilities(ichar_t *word);
/* extern void     move(int row, int col); */
extern void     normal(void);
extern char *   printichar(int in);
#ifndef REGEX_LOOKUP
extern int        shellescape(char *buf);
#endif /* REGEX_LOOKUP */
extern char *   skipoverword(char *bufp);
extern void     stop(void);
extern int      stringcharlen(char *bufp, int canonical);
extern int      strtoichar(ichar_t *out, char *in, int outlen, int canonical);
extern ichar_t *strtosichar(char * in, int canonical);
extern void     terminit(void);
extern void     toutent(FILE *outfile, struct dent *hent, int onlykeep);
extern void     treeinit(char *persdict, char *LibDict);
extern void     treeinsert(char *word, int wordlen, int keep);
extern struct dent *treelookup(register ichar_t *word, hash_info *dic);
extern void     treeoutput(void);
extern void     upcase(ichar_t *string);
#ifndef NO_CAPITALIZATION_SUPPORT 
extern long     whatcap(ichar_t *word);
#endif 
extern char *   xgets(char *string, int size, FILE *stream);
extern void     yyinit(void);
extern int      yyopen(char *file);
extern int      yyparse(void);

extern void     myfree(void *area);
extern void *   mymalloc(unsigned int);

/* 
 * C library functions.  If possible, we get these from stdlib.h. 
 */
#ifdef NO_STDLIB_H
extern int      access(const char *file, int mode);
extern int      atoi(const char *string);
extern void *   calloc(unsigned int nelems, unsigned int elemsize);

#ifdef _POSIX_SOURCE 
extern int      chmod(const char *file, unsigned int mode);
#else /* _POSIX_SOURCE */
extern int      chmod(const char *file, unsigned long mode);
#endif /* POSIX_SOURCE */

extern int      close(int fd);
extern int      creat(const char *file, int mode);
extern int      execvp(const char *name, const char *argv[]);
extern void     _exit(int status);
extern void     exit(int status);
extern char *   fgets(char *string, int size, FILE *stream);
extern int      fork(void);
extern void     free(void *area);
extern char *   getenv(const char *varname);
extern int      ioctl(int fd, int func, char *arg);
extern int      kill(int pid, int sig);
extern int      link(const char *existing, const char *new);
extern long     lseek(int fd, long offset, int whence);
extern void *   malloc(unsigned int size);
extern void *   memcpy(void *dest, const void *src);
extern void *   memset(void *dest, int val, unsigned int len);
extern char *   mktemp(char *prototype);
extern int      open(const char *file, int mode);
extern void     perror(const char *msg);
extern void     qsort(void *array, unsigned int nelems, unsigned int elemsize, */
                            int (*cmp) (const void *a, const void *b));
extern int      read(int fd, void *buf, unsigned int n);
extern void *   realloc(void *area, unsigned int size); 
extern unsigned int sleep(unsigned int); 
extern char *   strcat(char *dest, const  char *src);
extern char *   strchr(const char *string, int ch);
extern int      strcmp(const char *s1, const char *s2);
extern char *   strcpy(char *dest, const char *src);
extern unsigned int strlen(const char *str);
extern int      strncmp(const char *s1, const char *s2, unsigned int len);
extern char *   strrchr(const char *string, int ch);
extern int      system(const char *command);
extern int      unlink(const char *file);
extern int      wait(int *statusp);
#else /* NO_STDLIB_H */
#include <stdlib.h>
#endif /* NO_STDLIB_H */

#ifdef REGEX_LOOKUP 
extern char *   regcmp(const char *expr, const char *terminator, ...);
extern char *   regex(const char *pat, const char *subject, ...);
#endif /* REGEX_LOOKUP */
extern int      tgetent(char *buf, const char * termname);
extern char *   tgoto(const char *cm, int col, int row);
void            add_my_poss(ichar_t *word, 
			    struct dent *dent, 
			    struct flagent *pflent, 
			    struct flagent *sflent,
			    struct flagent *sflent2);
void            init_gentable();
char            *cut_by_dollar(char *staux);
