#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <time.h>


/* ------------------------------------------------------
 * Data structure of a matrix
 -------------------------------------------------------- */

#define STR_ELEM "%lf "   /* String to read/write the item elem_t */
#define ELEMSEP "%lf, "   /* String to write the result elem_t */

typedef double elem_t;

typedef struct matrix_t {
	unsigned rows, cols;
	unsigned start;        /* Lower array bound */
	unsigned end;          /* Upper array row bound */
	elem_t **data;
	elem_t **_data;        /* Pointer to the mem block */
} matrix_t;


/* ------------------------------------------------------
 * Prints error messages
 -------------------------------------------------------- */

void error(char *msg)
{
	printf("Error: %s\n", msg);
	exit(1);
}


/* ------------------------------------------------------
 * Prints an error when there is not enough memory to
 * allocate a matrix
 -------------------------------------------------------- */

void error_not_enough_memory(void)
{
	error("There is not enough memory to allocate a matrix");
}


/* ------------------------------------------------------
 * Allocates memory for "rows" pointers.
 * Then memory for "cols" numbers are allocated for rows
 * between "start" and "end"
 * Other rows aren't allocated
 -------------------------------------------------------- */

matrix_t *matrix_alloc(unsigned rows, unsigned cols, unsigned start, unsigned end)
{
	matrix_t *result = malloc(sizeof(matrix_t));
	unsigned row;

	if (!result)
		error_not_enough_memory();

	result->rows = rows;
	result->cols = cols;
	result->start = start;
	result->end = end;

	result->_data = malloc(rows * sizeof(elem_t *));
	if (!result->_data)
		error_not_enough_memory();

	result->data = result->_data - start;

	for (row = start; row < end; row++) {
		result->data[row] = malloc(sizeof(elem_t) * cols);
		if (!result->data[row])
			error_not_enough_memory();
	}

  return result;
}


/* ------------------------------------------------------
 * Reads a matrix from STDOUT 
 * ------------------------------------------------------ */

matrix_t *matrix_read_stdout()
{
	unsigned rows, cols, r, c;
	matrix_t *m;

	scanf("%u %u", &rows, &cols);

	m = matrix_alloc(rows, cols, 0, rows);

	for (r = 0; r < rows; r++) 
		for (c = 0; c < cols; c++) {
			scanf(STR_ELEM, &(m->data[r][c]));
		}
  return m;
}


/* ------------------------------------------------------
 * Prints the content of a matrix, in a Perl format
 -------------------------------------------------------- */

void matrix_print(matrix_t *m)
{
	unsigned row, col;

	if (!m) return;

  printf("[ ");
	for (row = m->start; row < m->end; row++) {
    printf("[ ");
		for (col = 0; col < m->cols; col++) {
		  printf(ELEMSEP, m->data[row][col]);
    }
    printf("],\n");
  }
  printf("]\n");
}


/* ------------------------------------------------------
 * Returns the scalar product between the row "row_m1" of
 * the matrix "m1" and the column "col_m2" of the matrix
 * "m2"
 -------------------------------------------------------- */

elem_t p_escalar(matrix_t *m1, matrix_t *m2, unsigned row_m1, unsigned col_m2)
{
	unsigned i;
	elem_t result = 0;

	for (i = 0; i < m1->cols; i++)
		result += m1->data[row_m1][i] * m2->data[i][col_m2];

	return result;
}


/* ------------------------------------------------------
 * Returns the product between the matrix "m1" and the
 * matrix "m2"
   ------------------------------------------------------ */

matrix_t *matrix_mult(matrix_t *m1, matrix_t *m2)
{
	matrix_t *r = NULL;
	unsigned rows, cols;
	unsigned row, col;

	if (!m1 || !m2)
		error("One of the matrix is null");

	rows = m1->end - m1->start;
	cols = m2->cols;

	r = matrix_alloc(rows, cols, m1->start, m1->end);
	
	for (row = m1->start; row < m1->end; row++)
		for (col = 0; col < cols; col++)
			r->data[row][col] = p_escalar(m1, m2, row, col);

	return r;
}


/* ------------------------------------------------------
 * Main program
 -------------------------------------------------------- */

int main(int argc, char *argv[])
{
	matrix_t *m1, *m2, *m3;
  struct timeval ini, end;
  double t1, t2;

	if (argc != 1) {
		printf("Arguments: matrix\n");
		exit(2);
	}

	m1 = matrix_read_stdout();
	m2 = matrix_read_stdout();

  //gettimeofday(&ini, NULL);
  m3 = matrix_mult(m1, m2);
  //gettimeofday(&end, NULL);
  
  //t1 = ini.tv_sec+(ini.tv_usec/1000000.0);
  //t2 = end.tv_sec+(end.tv_usec/1000000.0);
  //printf("Elapsed Time: %.6lf seconds\n", (t2 - t1));

	matrix_print(m3);

	return EXIT_SUCCESS;
}
