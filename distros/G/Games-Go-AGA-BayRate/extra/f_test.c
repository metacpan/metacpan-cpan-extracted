//
// Implement the example at http://www.gnu.org/software/gsl/manual/html_node/Multimin-Examples.html
//
#include <gsl/gsl_vector.h>
#include <gsl/gsl_multimin.h>

/* Paraboloid centered on (p[0],p[1]), with
   scale factors (p[2],p[3]) and minimum p[4] */

// debug aid
void
print_vector(const gsl_vector* v, int count) {

    int ii;
    if (count <= 0) {
        count = v->size;
    }
    for (ii = 0; ii < count; ii ++) {
        if (ii % 10 == 0) { printf("%3d:", ii); }
        printf(" % .24g", gsl_vector_get(v, ii));
        if (ii % 10 == 9) { printf("\n"); }
    }
    if (ii % 10 != 0) { printf("\n"); }
}

double
my_f (const gsl_vector *v, void *params)
{
  double x, y;
  double *p = (double *)params;

printf("my_f v:\n"); print_vector(v, 0);
  x = gsl_vector_get(v, 0);
  y = gsl_vector_get(v, 1);

  double ret = p[2] * (x - p[0]) * (x - p[0])
             + p[3] * (y - p[1]) * (y - p[1])
             + p[4];
printf("my_f returns % .24g,  v:\n", ret); print_vector(v, 0);
  return ret;
}

int
main (void)
{
  size_t iter = 0;
  int status;

  const gsl_multimin_fminimizer_type *T;
  gsl_multimin_fminimizer *s;

  /* Position of the minimum (1,2), scale factors 
     10,20, height 30. */
  double par[5] = { 1.0, 2.0, 10.0, 20.0, 30.0 };

  gsl_vector *x, *ss;
  gsl_multimin_function minex_func;

  minex_func.n = 2;
  minex_func.f = my_f;
  minex_func.params = par;

  /* Starting point, x = (5,7) */
  x = gsl_vector_alloc (2);
  gsl_vector_set (x, 0, 5.0);
  gsl_vector_set (x, 1, 7.0);

  /* Set initial step sizes to 1 */
  ss = gsl_vector_alloc (2);
  gsl_vector_set_all (ss, 1.0);

  T = gsl_multimin_fminimizer_nmsimplex;
  s = gsl_multimin_fminimizer_alloc (T, 2);

  gsl_multimin_fminimizer_set (s, &minex_func, x, ss);

  do
    {
      iter++;
      status = gsl_multimin_fminimizer_iterate (s);

      if (status)
        break;

      double size = gsl_multimin_fminimizer_size (s);
      status = gsl_multimin_test_size (size, 1e-2);

      if (status == GSL_SUCCESS)
        printf("\nConverged to minimum at\n");

      printf ("%5d %10.3e %10.3e f() = %7.3f size = %.3f\n",
              iter,
              gsl_vector_get (s->x, 0), 
              gsl_vector_get (s->x, 1), 
              s->fval, size);

    }
  while (status == GSL_CONTINUE && iter < 100);

  gsl_multimin_fminimizer_free (s);
  gsl_vector_free (x);
  gsl_vector_free (ss);

  return status;
}

