#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'E':
	if (strEQ(name, "EVAL"))
#ifdef PMf_EVAL
	    return PMf_EVAL;
#else
	    goto not_there;
#endif
	if (strEQ(name, "EXTENDED"))
#ifdef PMf_EXTENDED
	    return PMf_EXTENDED;
#else
	    goto not_there;
#endif
	    break;
    case 'F':
	if (strEQ(name, "FOLD"))
#ifdef PMf_FOLD
	    {
		sawi = TRUE;
		return PMf_FOLD;
	    }
#else
	    goto not_there;
#endif
	    break;
    case 'G':
	if (strEQ(name, "GLOBAL"))
#ifdef PMf_GLOBAL
	    return PMf_GLOBAL;
#else
	    goto not_there;
#endif
	    break;
    case 'K':
	if (strEQ(name, "KEEP"))
#ifdef PMf_KEEP
	    return PMf_KEEP;
#else
	    goto not_there;
#endif
	    break;
    case 'M':
	if (strEQ(name, "MULTILINE"))
#ifdef PMf_MULTILINE
	    return PMf_MULTILINE;
#else
	    goto not_there;
#endif
	    break;
    case 'S':
	if (strEQ(name, "SINGLELINE"))
#ifdef PMf_SINGLELINE
	    return PMf_SINGLELINE;
#else
	    goto not_there;
#endif
	    break;
    default:
	goto not_there;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

#ifndef DEBUGGING
#  include "regcomp.h"
/*
 - regdump - dump a regexp onto stderr in vaguely comprehensible form
 */
void
regdump(r)
regexp *r;
{
    register char *s;
    register char op = EXACTLY;	/* Arbitrary non-END op. */
    register char *next;


    s = r->program + 1;
    while (op != END) {	/* While that wasn't END last time... */
#ifdef REGALIGN
	if (!((long)s & 1))
	    s++;
#endif
	op = OP(s);
	fprintf(stderr,"%2d%s", s-r->program, regprop(s));	/* Where, what. */
	next = regnext(s);
	s += regarglen[(U8)op];
	if (next == NULL)		/* Next ptr. */
	    fprintf(stderr,"(0)");
	else 
	    fprintf(stderr,"(%d)", (s-r->program)+(next-s));
	s += 3;
	if (op == ANYOF) {
	    s += 32;
	}
	if (op == EXACTLY) {
	    /* Literal string, where present. */
	    s++;
	    (void)putc(' ', stderr);
	    (void)putc('<', stderr);
	    while (*s != '\0') {
		(void)putc(*s, stderr);
		s++;
	    }
	    (void)putc('>', stderr);
	    s++;
	}
	(void)putc('\n', stderr);
    }

    /* Header fields of interest. */
    if (r->regstart)
	fprintf(stderr,"start `%s' ", SvPVX(r->regstart));
    if (r->regstclass)
	fprintf(stderr,"stclass `%s' ", regprop(r->regstclass));
    if (r->reganch & ROPT_ANCH)
	fprintf(stderr,"anchored ");
    if (r->reganch & ROPT_SKIP)
	fprintf(stderr,"plus ");
    if (r->reganch & ROPT_IMPLICIT)
	fprintf(stderr,"implicit ");
    if (r->regmust != NULL)
	fprintf(stderr,"must have \"%s\" back %ld ", SvPVX(r->regmust),
	 (long) r->regback);
    fprintf(stderr, "minlen %ld ", (long) r->minlen);
    fprintf(stderr,"\n");
}

/*
- regprop - printable representation of opcode
*/
char *
regprop(op)
char *op;
{
    register char *p = 0;

    (void) strcpy(buf, ":");

    switch (OP(op)) {
    case BOL:
	p = "BOL";
	break;
    case MBOL:
	p = "MBOL";
	break;
    case SBOL:
	p = "SBOL";
	break;
    case EOL:
	p = "EOL";
	break;
    case MEOL:
	p = "MEOL";
	break;
    case SEOL:
	p = "SEOL";
	break;
    case ANY:
	p = "ANY";
	break;
    case SANY:
	p = "SANY";
	break;
    case ANYOF:
	p = "ANYOF";
	break;
    case BRANCH:
	p = "BRANCH";
	break;
    case EXACTLY:
	p = "EXACTLY";
	break;
    case NOTHING:
	p = "NOTHING";
	break;
    case BACK:
	p = "BACK";
	break;
    case END:
	p = "END";
	break;
    case ALNUM:
	p = "ALNUM";
	break;
    case NALNUM:
	p = "NALNUM";
	break;
    case BOUND:
	p = "BOUND";
	break;
    case NBOUND:
	p = "NBOUND";
	break;
    case SPACE:
	p = "SPACE";
	break;
    case NSPACE:
	p = "NSPACE";
	break;
    case DIGIT:
	p = "DIGIT";
	break;
    case NDIGIT:
	p = "NDIGIT";
	break;
    case CURLY:
	(void)sprintf(buf+strlen(buf), "CURLY {%d,%d}", ARG1(op),ARG2(op));
	p = NULL;
	break;
    case CURLYX:
	(void)sprintf(buf+strlen(buf), "CURLYX {%d,%d}", ARG1(op),ARG2(op));
	p = NULL;
	break;
    case REF:
	(void)sprintf(buf+strlen(buf), "REF%d", ARG1(op));
	p = NULL;
	break;
    case OPEN:
	(void)sprintf(buf+strlen(buf), "OPEN%d", ARG1(op));
	p = NULL;
	break;
    case CLOSE:
	(void)sprintf(buf+strlen(buf), "CLOSE%d", ARG1(op));
	p = NULL;
	break;
    case STAR:
	p = "STAR";
	break;
    case PLUS:
	p = "PLUS";
	break;
    case MINMOD:
	p = "MINMOD";
	break;
    case GBOL:
	p = "GBOL";
	break;
    case UNLESSM:
	p = "UNLESSM";
	break;
    case IFMATCH:
	p = "IFMATCH";
	break;
    case SUCCEED:
	p = "SUCCEED";
	break;
    case WHILEM:
	p = "WHILEM";
	break;
    default:
	FAIL("corrupted regexp opcode");
    }
    if (p != NULL)
	(void) strcat(buf, p);
    return(buf);
}
#endif /* DEBUGGING */

#define regexec(prog, string, len, minend, safebase) \
         pregexec((prog), (string), (string) + (len), (string), \
		  (minend), Nullsv, (safebase))
#define regfree pregfree
#define nparens(rx) ((rx)->nparens)
#define matches(rx) ((rx)->nparens)
#define lastparen(rx) ((rx)->lastparen)

static regexp *
regcomp(exp,pmflags)
char* exp;
U16 pmflags;
{
    PMOP fakepmop;

    fakepmop.op_pmflags = pmflags;
    return pregcomp(exp, exp + strlen(exp), &fakepmop);
}

MODULE = Devel::RegExp		PACKAGE = Devel::RegExp


double
constant(name,arg)
	char *		name
	int		arg


regexp *
regcomp(exp, flag = 0)
char* exp
U16 flag

void
regdump(r)
regexp *r

char *
regprop(op)
char *op

void
regfree(r)
regexp *r

I32
regexec(prog, stringarg, len = strlen(stringarg), minend = 0, safebase = FALSE)
regexp *prog
char *stringarg
I32 len
I32 minend
I32 safebase

void
match(rx, match = -1, base = NULL)
regexp *rx
I32 match
char *base
PPCODE:
     {
	 I32 mx;
	 char *s = rx->subbase, *b, *e;

	 if (s == 0) {
	     if (base == NULL) die("Cannot do regmatch without a saved base");
	     s = base;
	 }
	 if (match == -1) {
	     EXTEND(sp, 2 * rx->nparens);
	     match = 0;
	     mx = rx->nparens;
	 } else if (match < 0) {
	     die("regmatch(rx, match, ...) called with negative match = %i", match);
	 } else if (match <= rx->nparens) {
	     mx = match;
	 } else {
	     die("in regmatch(rx, match, ...) match = %i is too big", match);
	 }
	 while (match <= mx) {
	     b = rx->startp[match];
	     e = rx->endp[match];
	     if (b && e) {
		 PUSHs(sv_2mortal(newSViv(b - s)));
		 PUSHs(sv_2mortal(newSViv(e - s)));
	     } else {
		 PUSHs(&sv_undef);
		 PUSHs(&sv_undef);
	     }
	     match++;
	 }
     }

I32
nparens(rx)
regexp *rx


I32
matches(rx)
regexp *rx

I32
lastparen(rx)
regexp *rx
