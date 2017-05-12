#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "gmp.c" /* Brute force and ignorance */

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}

MODULE = Games::Go::GMP		PACKAGE = Games::Go::GMP		


double
constant(sv,arg)
    PREINIT:
	STRLEN		len;
    INPUT:
	SV *		sv
	char *		s = SvPV(sv, len);
	int		arg
    CODE:
	RETVAL = constant(s,len,arg);
    OUTPUT:
	RETVAL


GmpResult
gmp_check(ge, sleep, out1, out2, error)
	Gmp *	ge
	int	sleep
	int *	out1
	int *	out2
	const char **	error

int
gmp_chineseRules(ge)
	Gmp *	ge

Gmp *
gmp_create(inFile, outFile)
	int	inFile
	int	outFile

void
gmp_destroy(ge)
	Gmp *	ge

int
gmp_handicap(ge)
	Gmp *	ge

int
gmp_iAmWhite(ge)
	Gmp *	ge

float
gmp_komi(ge)
	Gmp *	ge

const char *
gmp_resultString(result)
	GmpResult	result

void
gmp_sendMove(ge, x, y)
	Gmp *	ge
	int	x
	int	y

void
gmp_sendPass(ge)
	Gmp *	ge

void
gmp_sendUndo(ge, numUndos)
	Gmp *	ge
	int	numUndos

int
gmp_size(ge)
	Gmp *	ge

void
gmp_startGame(ge, size, handicap, komi, chineseRules, iAmWhite)
	Gmp *	ge
	int	size
	int	handicap
	float	komi
	int	chineseRules
	int	iAmWhite
