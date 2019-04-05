#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "C/matrix.h"
#include <assert.h>

#define NEW_MATRIX(t,m,r,c)   m=(Matrix*)malloc(sizeof(Matrix));\
                            m->rows = r; m->columns = c;\
                            m->values = (t*) malloc (r * c * sizeof(t));

#define GET(m,row,col)      m->values[ row * m->columns + col ]






Matrix *zeros(int rows, int columns) {
    int i;
    Matrix *M;

	if (!(rows > 0 && columns > 0)) {
      fprintf(stderr, "zeros: number of rows and columns should be positive\n");
      exit(1);
    }

    NEW_MATRIX(REAL, M, rows, columns)	

	for(i = 0; i < rows * columns; i++)
		M->values[i] = 0;
    return M;
}

Matrix *ones(int rows, int columns) {
    int i;
	Matrix *M;

	if (!(rows > 0 && columns > 0)) {
      fprintf(stderr, "ones: number of rows and columns should be positive\n");
      exit(1);
    }
	
    NEW_MATRIX(REAL, M, rows, columns)	
    
	for(i = 0; i < rows * columns; i++)
		M->values[i] = 1;

	return M;
}

Matrix *matrix_random(int rows, int columns) {
	int i;
	Matrix *M;	

	if (!(rows > 0 && columns > 0)) {
      fprintf(stderr, "matrix_random: number of rows and columns should be positive\n");
      exit(1);
    }

    NEW_MATRIX(REAL, M, rows, columns)	
	
	for(i = 0; i < rows * columns; i++)
		M->values[i] = (float)rand() /  RAND_MAX;
	
	return M;
}


Matrix *identity(int rows) {
	int i;
	Matrix *M = zeros(rows,rows);
	
	for(i = 0; i < rows * rows; i+= rows + 1)
		M->values[i] = 1;
	
	return M;
}

Matrix *concatenate(Matrix *A, Matrix *B, int axis){
	Matrix *C;
	int i, j, rows, cols;
	REAL v;
	// Vertical Concatenation
	if(axis)
	{
		if(A->rows != B->rows){
			fprintf(stderr, "Matrices with wrong dimensions\n");
			exit(1);
		}
		rows = A->rows;
		cols = A->columns + B->columns;
		NEW_MATRIX(REAL, C, rows, cols);
		for(i = 0; i < rows; i++){
			for(j = 0; j < cols; j++){
				if(j < A->columns){
					C->values[i*cols+j] = A->values[i*A->columns+j];
				}else{
					C->values[i*cols+j] = B->values[i*B->columns+j-A->columns];
				}
			}
		}
	}
	else{
		if(A->columns != B->columns){
			fprintf(stderr, "Matrices with wrong dimensions\n");
			exit(1);
		}
		rows = A->rows + B->rows;;
		cols = A->columns;
		NEW_MATRIX(REAL, C, rows, cols);
		for(j = 0; j < cols; j++){
			for(i = 0; i < rows; i++){
				if(i < A->rows){
					C->values[i*cols+j] = A->values[i*cols+j];
				}
				else{
					C->values[i*cols+j] = B->values[(i-A->rows)*cols +j ];
				}
			}
		}			
	}
	return C;
}

Matrix *dot(Matrix *A, Matrix *B, int A_t, int B_t) {
	Matrix *C;
	int cols, rows, lda, ldb, ldc, m, n, k;
	char trans_A = 'N', trans_B = 'N';
    REAL *Av = B->values;
    REAL *Bv = A->values;
	REAL alpha = 1, beta = 0;

    // Compute A x B = AB
    // (AB)' = B' x A'
    if (!A_t && !B_t) {
			if(!(A->columns == B->rows)) {
				fprintf(stderr, "A columns != B rows\n");
				exit(1);
			}
      m = B->columns; // nr rows B'
      n = A->rows;    // nr columns A'
      k = B->rows;    // nr columns B'
      lda = m;
      ldb = k;
      NEW_MATRIX(REAL, C, A->rows, B->columns);
    }
    
    // Compute A x B' = AB'
    // (AB')' = B x A'
    else if (!A_t && B_t) {
			if(!(A->columns == B->columns)) {
					fprintf(stderr, "A columns != B columns");
					exit(1);
			}
      m = B->rows;    // nr rows B
      n = A->rows;    // nr columns A'
      k = B->columns; // nr columns B
      lda = k;
      ldb = k;
      trans_A = 'T';
      NEW_MATRIX(REAL, C, A->rows, B->rows);
    }

    // Compute A' x B = A'B
    // (A'B)' = B' x A
    else if (A_t && !B_t) {
			if(!(A->rows == B->rows)) {
					fprintf(stderr, "A rows != B rows");
					exit(1);
			}
      m = B->columns;    // nr rows B'
      n = A->columns;    // nr columns A
      k = B->rows;       // nr columns B'
      lda = m;
      ldb = n;
      trans_B = 'T';
      NEW_MATRIX(REAL, C, A->columns, B->columns);
    }
    // Compute A' x B' = A'B'
    // (A'B')' = B x A
    else {
			if(!(A->rows == B->columns)) {
					fprintf(stderr, "A rows != B columns");
					exit(1);
			}
      m = B->rows;    // nr rows B
      n = A->columns;    // nr columns A
      k = B->columns;       // nr columns B'
      lda = k;
      ldb = n;
      trans_B = 'T';
      trans_A = 'T';
      NEW_MATRIX(REAL, C, A->columns, B->rows);
    }


    ldc = m;
    
# ifdef USE_REAL
    dgemm_(&trans_A, &trans_B, &m, &n, &k, &alpha, Av, &lda, Bv, &ldb, &beta, C->values, &ldc);
# else
    sgemm_(&trans_A, &trans_B, &m, &n, &k, &alpha, Av, &lda, Bv, &ldb, &beta, C->values, &ldc);
# endif    
	return C;
}


void show_matrix(Matrix *M) {
	int i, j, r, c;
	REAL v;

	r = M->rows;
	c = M->columns;
	
	for(i = 0; i < c; i++)
		for( j = 0; j < r; j++)
			printf("M(%d,%d) = %.2f\n", i, j , M->values[i * r + j]);
}

REAL get_max(Matrix* m){
    REAL max = m->values[0];
    for(int i = 1; i < m->columns*m->rows; i++){
        if(m->values[i] > max){
            max = m->values[i];
        }
    }
    return max;
}

REAL get_min(Matrix*m){
	REAL min = m->values[0];
	for(int i = 1; i < m->columns*m->rows; i++){
		if(m->values[i] < min) min = m->values[i];
	}
	return min;
}

REAL mean(Matrix *m){
	REAL mean = 0;
	int s = m->columns*m->rows;
	for(int i = 0; i < s; i++){
		mean += m->values[i];
	}
	return (mean / s);
}

/*
 * Considerando Matrix [m,1]
 */
REAL standard_deviation(Matrix *m){
	REAL m_mean = mean(m);
	REAL std = 0;
	int s = m->columns * m->rows;
		
# ifdef USE_REAL
	for(int i = 0; i < s; i++){
		std += pow((m->values[i]-m_mean),2);
	}
# else
	for(int i = 0; i < s; i++){
		std += powf((m->values[i]-m_mean),2);
	}
# endif
	std /= (s-1);
	return sqrt(std);
}

/*
 * Matrix [m,n]
 * 
 * FIXME:
 *   Retornar Matrix com m->columns e 3 linhas
 *   Cada linha tem: min, max, mean
 *   
 */
Matrix *normalize_mean(Matrix *m){
	int cols = m->columns;
	int rows = m->rows;
	int r, c;
	REAL max, mean, min, value;
	Matrix *new;
	NEW_MATRIX(REAL, new, 2, m->columns);
	for(c = 0; c < cols; c++){
  		max = mean = min = GET(m, 0, c);
			for(r = 1; r < rows; r++){
       		value = GET(m, r, c);
					mean += value;
					if(value > max) max = value;
					if(value < min) min = value;
			}
			mean /= rows;
			new->values[c] = mean; //same as m->values[0 * cols + c]
			new->values[1 * cols + c] = max - min;	
			for(r = 0; r < rows; r++){
					m->values[r*cols+c] = (m->values[r*cols+c]-mean) / (max-min);
			}
	}
	return new;
}

void normalize_mean_data(Matrix *m, Matrix *data){
		int cols = m->columns;
		int rows = m->rows;
		int r,c;
		REAL mean, x;
		for( c = 0; c < cols; c++ ){
				mean = data->values[c];
				x = data->values[1 * cols + c];
				for ( r = 0; r < rows; r++ ){
						m->values[r*cols+c] = (m->values[r*cols+c]-mean) / x;	
				}
		}
}

Matrix *normalize_std_deviation(Matrix *m){
	int cols = m->columns;
	int rows = m->rows;
	int r, c;
	REAL mean, value, std;
	Matrix *new;
	NEW_MATRIX(REAL, new, 2, m->columns);
	for(c = 0; c < cols; c++){
			std=0;
			mean = GET(m, 0, c);
			for(r = 1; r < rows; r++){
				value = GET(m, r, c);
				mean += value;
			}
			mean /= rows;
			new->values[c] = mean;
			//calculate std deviation
			for(r = 0; r < rows; r++){
#ifdef USE_REAL	
					std += pow((m->values[r*cols+c] - mean),2);
#else
					std += powf((m->values[r*cols+c] - mean),2);            
#endif            
			}
			std /= (rows - 1);
#ifdef USE_REAL	
			std = sqrt(std);
#else
			std = sqrtf(std);
#endif
			new->values[1 * cols + c ] = std;
			for(r = 0; r < rows; r++){
					m->values[r*cols+c] =  (m->values[r*cols+c] - mean) / std;
			}
	}
	return new;
}

void normalize_std_deviation_data(Matrix *m, Matrix *data){
		int cols = m->columns;
		int rows = m->rows;
		int r,c;
		REAL mean, std;
		for( c = 0; c < cols; c++ ){
				mean = data->values[c];
				std = data->values[1 * cols + c];
				for ( r = 0; r < rows; r++ ){
						m->values[r*cols+c] = (m->values[r*cols+c]-mean) / std;	
				}
		}
}

REAL get_element(Matrix *m, int i, int j) {
	if(!(i > -1 && j > -1 && i < m->rows && j < m->columns)) {
		fprintf(stderr, "get_element: indexes out of bounds: %d vs %d\n", i, j);
		exit(1);
	}
	return m->values[ i * m->columns + j ];
}

void set_element(Matrix *m, int i, int j, REAL v) {
  if(!(i > -1 && j > -1)) {
    fprintf(stderr, "set_element: indexes out of bounds: %d vs %d\n", i, j);
    exit(1);
  }
    m->values[ i * m->columns + j ] = v;
}
	

Matrix *element_wise(Matrix *m, REAL f(REAL, void*), void* data) {
	Matrix *new;
	NEW_MATRIX(REAL, new, m->rows, m->columns);
    int i, j;
    for (i = 0; i < m->rows * m->columns; i++)
        new->values[i] = f(m->values[i], data);
    return new;
}

Matrix *broadcasting(Matrix *A, Matrix *B, Axis axis, REAL f(REAL, REAL)){
	Matrix *C;
	int i, j, rows, cols;
	rows = A->rows;
	cols = A->columns;
	NEW_MATRIX(REAL, C, rows, cols);

	// Horizontal broadcasting	
	if(axis == 1){
		for( i = 0; i < cols; i++){
			for ( j = 0; j < rows; j++){
				C->values[j * cols + i] = f(A->values[j * cols + i], B->values[i]);
			}
		}
	} // Vertical Broadcasting
	else if(axis == 2){
		for( i = 0; i < rows; i++){
			for( j = 0; j < cols; j++){
				C->values[i * cols + j] = f(A->values[i * cols + j], B->values[i]);
			}
		}
	} //Inverted Horizontal Broadcasting
	else if(axis == 3){
		for( i = 0; i < cols; i++ ){
			for(j = 0; j < rows; j++){
				C->values[j * cols + i] = f(B->values[i], A->values[j * cols + i]);
			}
		}
	} //Inverted Vertical Broadcasting
	else if(axis == 4){
		for( i = 0; i < rows; i++ ){
			for(j = 0; j < cols; j++){
				C->values[i * cols + j] = f(B->values[i], A->values[i * cols + j]);
			}
		}
	}
	else {
      fprintf(stderr, "broadcasting: not sure how to broadcast...\n");
      exit(1);
    }
	
	return C;
}

REAL real_sum(REAL a, REAL b){
	return a + b;
}

REAL real_sub(REAL a, REAL b){
	return a - b;
}

REAL real_mul(REAL a, REAL b){
	return a * b;
}

REAL real_div(REAL a, REAL b){
	if(b == 0){
		fprintf(stderr, "Impossible divide by zero\n");
		exit(1);
	}
	return a / b;
}

Matrix *sum_matrices(Matrix *A, Matrix *B){
	Matrix *C;
	int i, rows, cols;
	if(A->rows == B->rows && A->columns == B->columns)
	{
		rows = A->rows;
		cols = A->columns;
		NEW_MATRIX(REAL, C, rows, cols)	
	
		for(i = 0; i < rows * cols; i++)
			C->values[i] = A->values[i] + B->values[i];
	}
	else if(A->columns == B->columns && A->rows > 1 && B->rows == 1)
	{
		C = broadcasting(A, B, 1, real_sum);
	}
	else if(A->columns == B->columns && B->rows > 1 && A->rows == 1)
	{
		C = broadcasting(B, A, 1, real_sum);
	}
	else if(A->rows == B->rows && A->columns > 1 && B->columns == 1){
		C = broadcasting(A, B, 2, real_sum);
	}
	else if(A->rows == B->rows && B->columns > 1 && A->columns == 1){
		C = broadcasting(B, A, 2, real_sum);
	}
	else{
      fprintf(stderr, "Add Matrices: dimensions mismatch\n");
      exit(1);
	}
	return C;
}

Matrix *mul_matrices(Matrix *A, Matrix *B) {
	Matrix *C;
	int i, rows, cols;
	if(A->rows == B->rows && A->columns == B->columns)
	{
		rows = A->rows;
		cols = A->columns;
		NEW_MATRIX(REAL, C, rows, cols)	
	
		for(i = 0; i < rows * cols; i++)
			C->values[i] = A->values[i] * B->values[i];
	}
	else if(A->columns == B->columns && A->rows > 1 && B->rows == 1)
	{
		C = broadcasting(A, B, 1, real_mul);
	}
	else if(A->columns == B->columns && B->rows > 1 && A->rows == 1)
	{
		C = broadcasting(B, A, 1, real_mul);
	}
	else if(A->rows == B->rows && A->columns > 1 && B->columns == 1){
		C = broadcasting(A, B, 2, real_mul);
	}
	else if(A->rows == B->rows && B->columns > 1 && A->columns == 1){
		C = broadcasting(B, A, 2, real_mul);
	}
	else{
      fprintf(stderr, "mul_matrices: dimensions mismatch\n");
		exit(1);
	}
	return C;
}


Matrix *sub_matrices(Matrix *A, Matrix *B){
	Matrix *C;
	int i, rows, cols;
    
	if (A->rows == B->rows && A->columns == B->columns)
	{
		rows = A->rows;
		cols = A->columns;
		NEW_MATRIX(REAL, C, rows, cols)
	
		for(i = 0; i < rows * cols; i++)
			C->values[i] = A->values[i] - B->values[i];
	}
	else if(A->columns == B->columns && A->rows > 1 && B->rows == 1)
	{
		C = broadcasting(A, B, 1, real_sub);
	}
	else if(A->columns == B->columns && B->rows > 1 && A->rows == 1)
	{
		C = broadcasting(B, A, 3, real_sub);
	}
	else if(A->rows == B->rows && A->columns > 1 && B->columns == 1){
		C = broadcasting(A, B, 2, real_sub);
	}
	else if(A->rows == B->rows && B->columns > 1 && A->columns == 1){
		C = broadcasting(B, A, 4, real_sub);
	}
	else{
      fprintf(stderr, "sub_matrices: dimensions mismatch\n");
		exit(1);
	}
	return C;
}

Matrix *div_matrices(Matrix *A, Matrix *B){
	Matrix *C;
	int i, rows, cols;
	if(A->rows == B->rows && A->columns == B->columns)
	{
		rows = A->rows;
		cols = A->columns;
		NEW_MATRIX(REAL, C, rows, cols)	
	
		for(i = 0; i < rows * cols; i++)
			C->values[i] = A->values[i] / B->values[i];
	}
	else if(A->columns == B->columns && A->rows > 1 && B->rows == 1)
	{
		C = broadcasting(A, B, 1, real_div);
	}
	else if(A->columns == B->columns && B->rows > 1 && A->rows == 1)
	{
		C = broadcasting(B, A, 3, real_div);
	}
	else if(A->rows == B->rows && A->columns > 1 && B->columns == 1){
		C = broadcasting(A, B, 2, real_div);
	}
	else if(A->rows == B->rows && B->columns > 1 && A->columns == 1){
		C = broadcasting(B, A, 4, real_div);
	}
	else{
      fprintf(stderr, "div_matrices: dimensions mismatch\n");
		exit(1);
	}
	return C;
}



void destroy(Matrix *m){
	free(m->values);
	free(m);
}

REAL mul(REAL a, void* v){
	return a * *((REAL*)v);
}

REAL divs(REAL a, void* v){
	return a / *((REAL*)v);
}

REAL divs_swap(REAL a, void* v){
    return *((REAL*)v) / a;
}

REAL add(REAL a, void* v){
	return a + *((REAL*)v);
}

REAL sub(REAL a, void* v){
	return a - *((REAL*)v);
}
REAL sub_swap(REAL a, void* v){
	return *((REAL*)v) - a;
}



REAL power(REAL a, void* v){
# ifdef USE_REAL
	return pow(a,*((REAL*)v));
# else
	return powf(a,*((REAL*)v));
# endif
}

REAL exponential(REAL a, void* v){
# ifdef USE_REAL
	return exp(a);
# else
	return expf(a);
# endif
}

REAL logarithm(REAL a, void* v){
# ifdef USE_REAL
	return log(a);
# else
	return logf(a);
#endif
}

Matrix *matrix_mul(Matrix *m,REAL v){
	return element_wise(m, mul, &v);
}

Matrix *matrix_div(Matrix *m,REAL v, int swap){
  if (swap)
    return element_wise(m, divs_swap, &v);
  else
	return element_wise(m, divs, &v);
}

Matrix *matrix_sum(Matrix *m,REAL v){
  return element_wise(m, add, &v);
}


Matrix *matrix_sub(Matrix *m,REAL v, int swap){
  if (swap) {
    return element_wise(m, sub_swap, &v);
  } else {
	return element_wise(m, sub, &v);
  }
}

Matrix *matrix_exp(Matrix *m){
	return element_wise(m, exponential, NULL);
}

Matrix *matrix_pow(Matrix *m, REAL v){
	return element_wise(m, power, &v);
}

Matrix *matrix_log(Matrix *m){
	return element_wise(m, logarithm, NULL);
}

void save(Matrix *m, char *path){
	FILE *f;
	f = fopen(path, "w");

	if(f == NULL) {
      fprintf(stderr, "save: can't create file\n");
      exit(1);
    }

	fwrite(&m->rows, sizeof(int), 1, f);
	fwrite(&m->columns, sizeof(int), 1, f);
	fwrite(m->values, m->rows * m->columns * sizeof(REAL), 1, f);
	
	fclose(f);
}

Matrix *read_matrix(char *path){
	Matrix *M;
	int rows, cols;
	FILE *f;
	f = fopen(path, "r");
	
	if(f == NULL) {
      fprintf(stderr, "read_matrix: can't open file\n");
		exit(1);
    }

	if(!fread(&rows, sizeof(int), 1, f)) {
      fprintf(stderr, "read_matrix: FIXME\n");
      exit(1);
    }
	if(!fread(&cols, sizeof(int), 1, f)) {
      fprintf(stderr, "read_matrix: FIXME\n");
      exit(1);
    }
	NEW_MATRIX(REAL, M,rows, cols);
	size_t nr_bytes = rows * cols * sizeof(REAL); 
	if(nr_bytes != fread(M->values, 1, nr_bytes, f)) {
      fprintf(stderr, "read_matrix: FIXME\n");
      exit(1);
    }

	fclose(f);
	return M;
}

Matrix *transpose(Matrix *m){
	int rows, cols, i, j;
	Matrix *t;
	rows = m->rows;
	cols = m->columns;

	NEW_MATRIX(REAL, t, cols, rows);
	
	for( i = 0; i < rows; i++)
		for( j = 0; j < cols; j++)
			t->values[j * rows +i]  = m->values[i * cols + j];
	
	return t;
}


Matrix *inverse(Matrix *m){
        int j, n, info;
        Matrix *i;
        n = m->rows;
        int ipiv[n];
        REAL work[n * n];

        NEW_MATRIX(REAL, i, m->rows, m->columns);

        for(j = 0; j < m->rows * m->columns; j++)
                i->values[j] = m->values[j];

# ifdef USE_REAL
        dgetrf_(&n, &n, i->values, &n, ipiv, &info);
# else
        sgetrf_(&n, &n, i->values, &n, ipiv, &info);  
# endif
        if(info != 0) {
          fprintf(stderr, "inverse: ...?");
          exit(1);
        }

# ifdef USE_REAL
	    dgetri_(&n, i->values, &n, ipiv, work, &n, &info);
# else
        sgetri_(&n, i->values, &n, ipiv, work, &n, &info);
# endif

        if(info != 0) {
          fprintf(stderr, "inverse: ...?");
          exit (1);
        }

        return i;
}

Matrix *sum(Matrix *m, Axis axis){
	Matrix *s;
	int i, j, cols, rows;
	cols = m->columns;
	rows = m->rows;
# ifdef USE_REAL
	double value = 0.0;
# else
	float value = 0.0;
# endif
   if (axis == HORIZONTAL) {
		NEW_MATRIX(REAL, s, rows, 1);
		for(i = 0; i < rows; i++){
			value = 0;	
			for(j = 0; j < cols; j++){
				value += GET(m, i, j);
			}
			s->values[i] = value;
		}
	}
	else if(axis == VERTICAL){
		NEW_MATRIX(REAL, s, 1, cols);
		for( i = 0; i < cols; i++){
			value = 0;
			for(j = 0; j < rows; j++){
				value += GET(m, j, i);
			}
			s->values[i] = value;
		}
	}
    //sum all elements
    else{
        NEW_MATRIX(REAL, s, 1, 1);
        s->values[0] = 0;
        for(i = 0; i < cols * rows; i++){
            s->values[0] += m->values[i];
        }
    }
	return s;
}

int debug_slice(int rows, int min_row, int max_row, int cols, int min_col, int max_col){
    if(!(min_row <= max_row))
    {
        fprintf(stderr, "min_row %d X max_row %d\n", min_row, max_row);
        return 0;
    }
    if(!(max_row < rows)){
        fprintf(stderr, "max_row %d X rows %d\n", max_row, rows);
        return 0;
    }
    if(!(min_col <= max_col))
    {
        fprintf(stderr, "min_col %d X max_col %d\n", min_col, max_col);
        return 0;
    }
    if(!(max_col < cols))
    {
        fprintf(stderr, "max_col %d X cols %d\n", max_col, cols);
        return 0;
    }
    return 1;
}

Matrix *slice(Matrix *m, int x0, int x1, int y0, int y1){
    Matrix *s;
    int s_rows, s_cols, cols, rows, min_row, max_row, min_col, max_col;
    rows = m->rows;
    cols = m->columns;
    if(x0 == -1) min_row = 0;
    else min_row = x0;
    
    if(x1 == -1) { max_row = rows - 1;}
    else max_row = x1;
    
    if(y0 == -1) min_col = 0;
    else min_col = y0;
    
    if(y1 == -1) { max_col = cols - 1;}
    else max_col = y1;
    
    if(!debug_slice(rows, min_row, max_row, cols, min_col, max_col))
    {
        fprintf(stderr, "Wrong values for slicing\n");
        exit(1);
    }
    //if(!(min_row <= max_row && max_row < m->rows && min_col <= max_col && max_col < m->columns)){
    //    fprintf(stderr, "Wrong values for slicing\n");
    //    exit(1);
    //}

    s_rows = max_row - min_row + 1;
    s_cols = max_col - min_col + 1;

    NEW_MATRIX(REAL, s, s_rows, s_cols);

    for(int i = min_row, r = 0; i <= max_row; i++, r++)
        for(int j = min_col, c = 0; j <= max_col; j++, c++)
            s->values[r * s_cols + c] = m->values[i * cols + j];
    
    return s;
}
