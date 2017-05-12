/* Solve.i is a SWIG input file, syntax resembles -*- C++ -*-
 *
 * For more info on SWIG, visit http://www.swig.org/
 *
 * This file contains a subset of the definitions and functions in lpkit.h
 * for wrapping into the Perl module Math::LP::Solve
 *
 * =====================================================================
 * NOTE: Solve.c and Solve.pm are generated from this file. For a normal
 *       installation, you do not need this file. If you find bugs in or
 *       have useful additions to Solve.i, please send them to me
 *       <wim.verhaegen@ieee.org>, so I can incorporate them in the
 *       next release.
 * =====================================================================
 */
%{
/* the following macro's are double defined by Perl and lp_solve 
 * (needed because setting/unsetting the POLLUTE variable to Makefile.PL 
 *  has no effect)
 */
#undef FALSE
#undef TRUE
#undef invert

#include "lpkit.h"

/* since lp_solve uses (f)lex, the following is needed to keep the
 * autoloader happy
 */
int yywrap(void) 
{
  return 1;
}

/* Manipulation of string data fields of struct lprec is a bit awkward
 * The following functions take care of this problem
 */
static void _my_strcpy(char* dest, char* src) {
  strncpy(dest,src,MAXSTRL); /* cuts off too long strings */
  dest[MAXSTRL+1] = (char)0; /* ensures zero-termination */
}
char* lprec_lp_name_get(lprec* lp) {
  return lp->lp_name;
}
void lprec_lp_name_set(lprec* lp, char* name) {
  _my_strcpy(lp->lp_name,name);
}
char* lprec_row_name_get(lprec* lp, int i) {
  return (lp->row_name)[i];
}
void lprec_row_name_set(lprec* lp, int i, char* name) { 
  _my_strcpy((lp->row_name)[i],name);
}
char* lprec_col_name_get(lprec* lp, int i) {
  return (lp->col_name)[i];
}
void lprec_col_name_set(lprec* lp, int i, char* name) { 
  _my_strcpy((lp->col_name)[i],name);
}

/* filehandles */
FILE* open_file(char* filename, char* mode) {
  FILE* fd;
  if(!(fd = fopen(filename,mode))) {
    croak("Could not open file `%s' in mode `%s'",filename,mode);
  }
  return fd;
}
void close_file(FILE* fd) {
  fclose(fd);
}

/* Direct reading from stdin fails due to no EOF detection
 * The following functions are therefore deprecated */
/*
lprec* read_lp_from_stdin(short verbose, char* lp_name) {
  return read_lp_file(stdin,verbose,lp_name);
}
void write_lp_to_stdout(lprec* lp) {
  write_LP(lp,stdout);
}
lprec* read_mps_from_stdin(short verbose) {
  return read_mps(stdin,verbose);
}
void write_mps_to_stdout(lprec* lp) {
  write_MPS(lp,stdout);
}
*/
%}

/* definition of used constants */
#define DEF_INFINITE  1e24 /* limit for dynamic range */

/* constraint types */
#define LE      0
#define EQ      1
#define GE      2
#define OF      3

/* boolean values */
#define FALSE   0
#define TRUE    1

/* solve status values */
#define OPTIMAL     	0
#define MILP_FAIL   	1
#define INFEASIBLE  	2
#define UNBOUNDED   	3
#define FAILURE     	4
#define RUNNING     	5

/* lag_solve extra status values */
#define FEAS_FOUND   	6
#define NO_FEAS_FOUND 	7
#define BREAK_BB	8

%include pointer.i   /* for double*  */

/* data structures */
typedef struct lprec
{
  /* nstring   lp_name; */		/* the name of the lp */

  short     verbose;            /* ## Verbose flag */
  short     print_duals;        /* ## PrintDuals flag for PrintSolution */
  short     print_sol;          /* ## used in lp_solve */
  short     debug;              /* ## Print B&B information */
  short     print_at_invert;    /* ## Print information at every reinversion */
  short     trace;              /* ## Print information on pivot selection */
  short     anti_degen;		/* ## Do perturbations */
  short     do_presolve;        /* perform matrix presolving */

  int	    rows;               /* Nr of constraint rows in the problem */
  int       rows_alloc;      	/* The allocated memory for Rows sized data */
  int       columns;            /* The number of columns (= variables) */
  int       columns_alloc;  
  int       sum;                /* The size of the variables + the slacks */
  int       sum_alloc;

  short     names_used;         /* Flag to indicate if names for rows and
				   columns are used */
  /* nstring*  row_name; */		/* rows_alloc+1 */
  /* nstring*  col_name; */		/* columns_alloc+1 */

 /* Row[0] of the sparce matrix is the objective function */

  int       non_zeros;          /* The number of elements in the sparce matrix*/
  int       mat_alloc;		/* The allocated size for matrix sized 
				   structures */
  matrec    *mat;               /* mat_alloc :The sparse matrix */
  int       *col_end;           /* columns_alloc+1 :Cend[i] is the index of the
		 		   first element after column i.
				   column[i] is stored in elements 
				   col_end[i-1] to col_end[i]-1 */
  int       *col_no;            /* mat_alloc :From Row 1 on, col_no contains the
				   column nr. of the
                                   nonzero elements, row by row */
  short     row_end_valid;	/* true if row_end & col_no are valid */
  int       *row_end;           /* rows_alloc+1 :row_end[i] is the index of the 
				   first element in Colno after row i */
  double    *orig_rh;           /* rows_alloc+1 :The RHS after scaling & sign
				  changing, but before `Bound transformation' */
  double    *rh;		/* rows_alloc+1 :As orig_rh, but after Bound 
				   transformation */
  double    *rhs;		/* rows_alloc+1 :The RHS of the current
				   simplex tableau */
  short     *must_be_int;       /* sum_alloc+1 :TRUE if variable must be 
				   Integer */
  double    *orig_upbo;         /* sum_alloc+1 :Bound before transformations */
  double    *orig_lowbo;	/*  "       "                   */
  double    *upbo;              /*  " " :Upper bound after transformation &
				      B&B work */
  double    *lowbo;             /*  "       "  :Lower bound after transformation
				   & B&B work */

  short     basis_valid;        /* TRUE is the basis is still valid */
  int       *bas;               /* rows_alloc+1 :The basis column list */
  short     *basis;             /* sum_alloc+1 : basis[i] is TRUE if the column
				   is in the basis */
  short     *lower;             /*  "       "  :TRUE is the variable is at its 
				   lower bound (or in the basis), it is FALSE
				   if the variable is at its upper bound */

  short     eta_valid;          /* TRUE if current Eta structures are valid */
  int       eta_alloc;          /* The allocated memory for Eta */
  int       eta_size;           /* The number of Eta columns */
  int       num_inv;            /* The number of real pivots */
  int       max_num_inv;        /* ## The number of real pivots between 
				   reinversions */
  double    *eta_value;         /* eta_alloc :The Structure containing the
				   values of Eta */
  int       *eta_row_nr;         /*  "     "  :The Structure containing the Row
				   indexes of Eta */
  int       *eta_col_end;       /* rows_alloc + MaxNumInv : eta_col_end[i] is
				   the start index of the next Eta column */

  short	    bb_rule;		/* what rule for selecting B&B variables */

  short     break_at_int;       /* TRUE if stop at first integer better than
                                   break_value */
  double    break_value;        

  double    obj_bound;          /* ## Objective function bound for speedup of 
				   B&B */
  int       iter;               /* The number of iterations in the simplex
				   solver (LP) */
  int       total_iter;         /* The total number of iterations (B&B)
				   (ILP) */
  int       max_level;          /* The Deepest B&B level of the last solution */
  int	    total_nodes;	/* total number of nodes processed in b&b */
  double    *solution;          /* sum_alloc+1 :The Solution of the last LP, 
				   0 = The Optimal Value, 
                                   1..rows The Slacks, 
				   rows+1..sum The Variables */
  double    *best_solution;     /*  "       "  :The Best 'Integer' Solution */
  double    *duals;             /* rows_alloc+1 :The dual variables of the
				   last LP */
  
  short     maximise;           /* TRUE if the goal is to maximise the 
				   objective function */
  short     floor_first;        /* TRUE if B&B does floor bound first */
  short     *ch_sign;           /* rows_alloc+1 :TRUE if the Row in the matrix
				   has changed sign 
                                   (a`x > b, x>=0) is translated to 
				   s + -a`x = -b with x>=0, s>=0) */ 

  short     scaling_used;	/* TRUE if scaling is used */
  short     columns_scaled;     /* TRUE is the columns are scaled too, Only use
		 		   if all variables are non-integer */
  double    *scale;             /* sum_alloc+1:0..Rows the scaling of the Rows,
				   Rows+1..Sum the scaling of the columns */

  int	    nr_lagrange;	/* Nr. of Langrangian relaxation constraints */
  double    **lag_row;		/* NumLagrange, columns+1:Pointer to pointer of 
				   rows */
  double    *lag_rhs;		/* NumLagrange :Pointer to pointer of Rhs */
  double    *lambda;		/* NumLagrange :Lambda Values */
  short     *lag_con_type;      /* NumLagrange :TRUE if constraint type EQ */
  double    lag_bound;		/* the lagrangian lower bound */

  short     valid;		/* Has this lp pased the 'test' */
  double    infinite;           /* ## numerical stuff */
  double    epsilon;            /* ## */
  double    epsb;               /* ## */
  double    epsd;               /* ## */
  double    epsel;              /* ## */
  hashtable *rowname_hashtab;   /* hash table to store row names */
  hashtable *colname_hashtab;   /* hash table to store column names */
} lprec;

/* functions on lprec objects */
lprec* make_lp(int rows, int columns);
lprec* read_lp_file(FILE *input, short verbose = 0, char* lp_name = "no_name");
void delete_lp(lprec* lp);
lprec* copy_lp(lprec* lp);
void set_mat(lprec* lp, int row, int column, double value);
void set_obj_fn(lprec* lp, double* row);
void str_set_obj_fn(lprec* lp, char* row);
void add_constraint(lprec* lp, double* row, short constr_type, double rh);
void str_add_constraint(lprec* lp, char* row_string, short constr_type, double rh);
void del_constraint(lprec* lp,int del_row);
void add_lag_con(lprec* lp, double* row, short con_type, double rhs);
void str_add_lag_con(lprec* lp, char* row, short con_type, double rhs);
void add_column(lprec* lp, double* column);
void str_add_column(lprec* lp, char* col_string);
void del_column(lprec* lp, int column);
void set_upbo(lprec* lp, int column, double value);
void set_lowbo(lprec* lp, int column, double value);
void set_int(lprec* lp, int column, short must_be_int);
void set_rh(lprec* lp, int row, double value);
void set_rh_vec(lprec* lp, double* rh);
void str_set_rh_vec(lprec* lp, char* rh_string);
void set_maxim(lprec* lp);
void set_minim(lprec* lp);
void set_constr_type(lprec* lp, int row, short con_type);
void set_row_name(lprec* lp, int row, char* new_name);
void set_col_name(lprec* lp, int column, char* new_name);
void auto_scale(lprec* lp);
void unscale(lprec* lp);
int solve(lprec* lp);
int lag_solve(lprec* lp, double start_bound, int num_iter, short verbose);
void reset_basis(lprec* lp);
double mat_elm(lprec* lp, int row, int column);
void get_row(lprec* lp, int row_nr, double* row);
void get_column(lprec* lp, int col_nr, double* column);
void get_reduced_costs(lprec* lp, double* rc);
short is_feasible(lprec* lp, double* values);
short column_in_lp(lprec* lp, double* column);
lprec* read_mps(FILE *input, short verbose = 0);
void write_MPS(lprec* lp, FILE *output);
void write_LP(lprec* lp, FILE *output);
void print_lp(lprec* lp);
void print_solution(lprec* lp);
void print_duals(lprec* lp);
void print_scales(lprec* lp);

/* extra defined functions */
char* lprec_lp_name_get(lprec* lp);
void lprec_lp_name_set(lprec* lp, char* name);
char* lprec_row_name_get(lprec* lp, int i);
void lprec_row_name_set(lprec* lp, int i, char* name);
char* lprec_col_name_get(lprec* lp, int i);
void lprec_col_name_set(lprec* lp, int i, char* name);
FILE* open_file(char* filename, char* mode = "r");
void close_file(FILE* fd);
/*
lprec* read_lp_from_stdin(short verbose = 0, char* lp_name = "no_name");
void write_lp_to_stdout(lprec* lp);
lprec* read_mps_from_stdin(short verbose = 0);
void write_mps_to_stdout(lprec* lp);
*/


