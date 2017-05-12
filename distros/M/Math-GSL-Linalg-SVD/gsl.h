typedef struct
{
    size_t size;
    double * data;
} gsl_block;

typedef struct
{
    size_t size;
    size_t stride;
    double * data;
    gsl_block * block;
    int owner;
} gsl_vector;

typedef struct
{
    size_t size1;
    size_t size2;
    size_t tda;
    double * data;
    gsl_block * block;
    int owner;
} gsl_matrix;

typedef struct {
    size_t size;
    double * d;
    double * sd;
    double * gc;
    double * gs;
} gsl_eigen_symmv_workspace;


/* /usr/include/gsl/gsl_matrix.h just contains headers for subtypes: grep  -B 5 -A 5 gsl_matrix_alloc  /usr/include/gsl/gsl_matrix_double.h */
extern gsl_matrix *     gsl_matrix_alloc            (const size_t n1, const size_t n2);

/* grep  -B 5 -A 5 gsl_vector_alloc  /usr/include/gsl/gsl_vector_double.h */
extern gsl_vector *     gsl_vector_alloc            (const size_t n);

/* grep  -B 5 -A 5 gsl_matrix_set  /usr/include/gsl/gsl_matrix_double.h */
extern void             gsl_matrix_set              (gsl_matrix * m, const size_t i, const size_t j, const double x);

/* grep  -B 5 -A 5 gsl_matrix_free  /usr/include/gsl/gsl_matrix_double.h */
extern void             gsl_matrix_free             (gsl_matrix * m);

/* grep  -B 5 -A 5 gsl_vector_free  /usr/include/gsl/gsl_vector_double.h */
extern void             gsl_vector_free             (gsl_vector * v);

/* grep -B 5 -A 5 gsl_linalg_SV_decomp /usr/include/gsl/gsl_linalg.h */
extern int              gsl_linalg_SV_decomp        (gsl_matrix * A, gsl_matrix * V, gsl_vector * S, gsl_vector * work);

extern double           gsl_matrix_get              (const gsl_matrix * m, const size_t i, const size_t j);

extern void             gsl_vector_set              (gsl_vector * v, const size_t i, double x);

extern double           gsl_vector_get              (const gsl_vector * v, const size_t i);

extern int              gsl_linalg_SV_decomp_mod    (gsl_matrix * A, gsl_matrix * X, gsl_matrix * V, gsl_vector * S, gsl_vector * work);

extern int              gsl_linalg_SV_decomp_jacobi (gsl_matrix * A, gsl_matrix * V, gsl_vector * S);

/* eigen decomposition stuff */

extern gsl_eigen_symmv_workspace *      gsl_eigen_symmv_alloc       (const size_t n);

extern int                              gsl_eigen_symmv             (gsl_matrix * A, gsl_vector * eval, gsl_matrix * evec, gsl_eigen_symmv_workspace * w);


