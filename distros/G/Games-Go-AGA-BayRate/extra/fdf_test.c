//
// Implement the example at http://www.gnu.org/software/gsl/manual/html_node/Multimin-Examples.html
//
#include <gsl/gsl_vector_double.h>
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

//printf("my_f v:\n"); print_vector(v, 0);
  x = gsl_vector_get(v, 0);
  y = gsl_vector_get(v, 1);

  double ret = p[2] * (x - p[0]) * (x - p[0])
             + p[3] * (y - p[1]) * (y - p[1])
             + p[4];
//printf("my_f returns % .24g,  v:\n", ret); print_vector(v, 0);
  return ret;
}

/* The gradient of f, df = (df/dx, df/dy). */
void
my_df (const gsl_vector *v, void *params, gsl_vector *df)
{
  double x, y;
  double *p = (double *)params;

//printf("my_df: v:\n");  print_vector(v, 0);
//printf("my_df: df:\n"); print_vector(df, 0);
  x = gsl_vector_get(v, 0);
  y = gsl_vector_get(v, 1);

  gsl_vector_set(df, 0, 2.0 * p[2] * (x - p[0]));
  gsl_vector_set(df, 1, 2.0 * p[3] * (y - p[1]));
//printf("my_df returns df:\n"); print_vector(df, 0);
}

/* Compute both f and df together. */
void
my_fdf (const gsl_vector *x, void *params, double *f, gsl_vector *df)
{
//printf("my_fdf: v:\n");  print_vector(x, 0);
//printf("my_fdf: df:\n"); print_vector(df, 0);
  *f = my_f(x, params);
  my_df(x, params, df);
//printf("my_fdf returns f=% .24g, df:\n", *f ); print_vector(df, 0);
}

int
main (void)
{
  size_t iter = 0;
  int status;

  const gsl_multimin_fdfminimizer_type *T;
  gsl_multimin_fdfminimizer *s;

  /* Position of the minimum (1,2), scale factors 
     10,20, height 30. */
  double par[5] = { 1.0, 2.0, 10.0, 20.0, 30.0 };

  gsl_vector *x;
  gsl_multimin_function_fdf my_func;

  my_func.n = 2;
  my_func.f = my_f;
  my_func.df = my_df;
  my_func.fdf = my_fdf;
  my_func.params = par;

  /* Starting point, x = (5,7) */
  x = gsl_vector_alloc (2);
  gsl_vector_set (x, 0, 5.0);
  gsl_vector_set (x, 1, 7.0);

  T = gsl_multimin_fdfminimizer_conjugate_fr;
  s = gsl_multimin_fdfminimizer_alloc (T, 2);

  gsl_multimin_fdfminimizer_set (s, &my_func, x, 0.01, 1e-4);

  do
    {
      iter++;
      status = gsl_multimin_fdfminimizer_iterate (s);

      if (status)
        break;

      status = gsl_multimin_test_gradient (s->gradient, 1e-3);

      if (status == GSL_SUCCESS)
        printf("\nConverged to minimum at\n");

      printf ("%5d %.5f %.5f %10.5f\n", iter,
              gsl_vector_get (s->x, 0), 
              gsl_vector_get (s->x, 1), 
              s->f);

    }
  while (status == GSL_CONTINUE && iter < 100);

  gsl_multimin_fdfminimizer_free (s);
  gsl_vector_free (x);

  return 0;
}

