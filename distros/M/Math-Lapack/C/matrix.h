#include "C/config.h"

typedef struct s_matrix {
	int columns;
	int rows;
	REAL *values;
} Matrix;

typedef enum _axis {
    ALL = -1,
	HORIZONTAL = 0,
	VERTICAL = 1
} Axis;

REAL real_sum(REAL a, REAL b);

REAL real_sub(REAL a, REAL b);

REAL real_div(REAL a, REAL b);

REAL real_mul(REAL a, REAL b);

Matrix *zeros(int rows, int columns);

Matrix *ones(int rows, int columns);

Matrix *matrix_random(int rows, int columns);

Matrix *identity(int rows);

Matrix *dot(Matrix *A, Matrix *B, int A_t, int B_t);

void show_matrix(Matrix *M);

REAL get_max(Matrix*);
REAL mean(Matrix*);
REAL get_min(Matrix*);
REAL standard_deviation(Matrix*);

Matrix *normalize_std_deviation(Matrix*);
Matrix *normalize_mean(Matrix*);

void normalize_mean_data(Matrix *m, Matrix *data);
void normalize_std_deviation_data(Matrix *m, Matrix *data);

REAL get_element(Matrix*, int, int);
void set_element(Matrix*, int, int, REAL);

Matrix *sum_matrices(Matrix *A, Matrix *B);

Matrix *sub_matrices(Matrix *A, Matrix *B);

Matrix *div_matrices(Matrix *A, Matrix *B);

void destroy(Matrix *m);

Matrix *element_wise(Matrix *m, REAL f(REAL, void*), void* data);

Matrix *matrix_mul(Matrix *m,REAL v);

Matrix *matrix_div(Matrix *m,REAL v, int swap);

Matrix *matrix_sum(Matrix *A,REAL v);

Matrix *matrix_sub(Matrix *A,REAL v, int swap);

Matrix *matrix_pow(Matrix *m, REAL v);

Matrix *matrix_exp(Matrix *m);

Matrix *matrix_log(Matrix *m);

void save(Matrix *m, char *path);

Matrix *read_matrix(char *path);

Matrix *transpose(Matrix *m);

Matrix *inverse(Matrix *m);

Matrix *sum(Matrix *m, Axis axis);

Matrix *concatenate(Matrix *A, Matrix *B, int axis);
Matrix *slice(Matrix *m, int x0, int x1, int y0, int y1);

Matrix *sum_broadcasting(Matrix *A, Matrix *B, int order);

Matrix *sub_broadcasting(Matrix *A, Matrix *B, int order);

Matrix *div_broadcasting(Matrix *A, Matrix *B, int order);

Matrix *mul_matrices(Matrix *A, Matrix *B);

#ifdef USE_REAL
void dgemm_ (char*, char*, int*, int*, int*, double*, double*, int*, double*, int*, double*, double*, int*);
void dgetri_(int *, double *, int *, int *, double *, int *, int *);
void dgetrf_(int *, int *, double *, int *, int*, int*);
#else
void sgemm_ (char*, char*, int*, int*, int*, float*, float*, int*, float*, int*, float*, float*, int*);
void sgetri_(int *, float *, int *, int *, float *, int *, int *);
void sgetrf_(int *, int *, float *, int *, int*, int*);
#endif
