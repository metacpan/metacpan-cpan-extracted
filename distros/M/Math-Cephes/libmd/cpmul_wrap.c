/*							cpmul.c
 *
 *	wrapper to cpmul.c
 *
 *
 *
 * SYNOPSIS:
 *
 * cpmul_wrap(ar, ai, da, br, bi, db, cr, ci, dc)
 * double ar[], ai[], br[], bi[], cr[], ci[]
 * int da, db, dc
 *
 */

/*							cpmul	*/

#ifdef ANSIPROT
extern void * malloc (long);
extern void free (void *);
#else
void * malloc();
void free ();
#endif

typedef struct
	{
	double r;
	double i;
	}cmplx;

int 
cpmul_wrap( ar, ai, da, br, bi, db, cr, ci, dc )
     double *ar, *ai, *br, *bi, *cr, *ci;
     int da, db;
     int *dc;
{
  int i, ret;
  cmplx *a, *b, *c;
  extern int cpmul( cmplx a[], int da, cmplx b[], int db, cmplx c[], int *dc);

  a = (cmplx *) malloc (da * sizeof(cmplx));
  b = (cmplx *) malloc (db * sizeof(cmplx));
  c = (cmplx *) malloc (*dc * sizeof(cmplx));

  for (i=0; i<da; i++) {
    a[i].r = ar[i];
    a[i].i = ai[i];
  }
  for (i=0; i<db; i++) {
    b[i].r = br[i];
    b[i].i = bi[i];
  }
  for (i=0; i<*dc; i++) {
    c[i].r = cr[i];
    c[i].i = ci[i];
  }

  ret = cpmul( a, da-1, b, db-1, c, dc);
  if (ret > 0) return ret;
  
  for (i=0; i<=*dc; i++) {
    cr[i] = c[i].r;
    ci[i] = c[i].i;
  }
  free(a);
  free(b);
  free(c);
  return *dc;

}
