#include <stdarg.h>
#include "EXTERN.h"
#include "matrix.h"
#include "perl.h"
#include "XSUB.h"
#include "../Core/pdl.h"
#include "../Core/pdlcore.h"
#include "./p_funcs.h"
#include "./mespdl.h"
#include "./Meschach.h"


#define all_types( L , A , B , C )  \
		if( C == PDL_D )                \
					 L(A,double,B);           \
		else if( C == PDL_F )           \
					 L(A,float,B);            \
		else if( C == PDL_L )           \
					 L(A,long,B);             \
		else if( C == PDL_US )          \
					 L(A,unsigned short,B);  \
		else if( C == PDL_S )          \
					 L(A,short,B);           \
		else if( C == PDL_B )          \
					 L(A,unsigned char,B);   \
		else                           \
			croak("Cannot convert pdl n.%i to/from Real ",C)


int shrink_to_effective_size_m( MAT* inmat );
int shrink_to_effective_size_v( VEC* invec );
int shrink_to_effective_size_px( PERM* inper );

int not_simple(pdl *a);

int set_dims(pdl *outpdl, int nd,...);
int perlside( pdl *outpdl , 
						 int has_coerced, int moved_data, int changed_size, 
						 int changed_dims  ,
						 int nd, ... ) ;

/****************** Convert meschach to pdl object ******************* 

	mat2pdl (pdl* outpdl, MAT* inmat, int already_free, int may_coerce)


  To be done : Make ndims = 1   if matrix is    m x 1.

************************************************************************/

pdl* mat2pdl(pdl* outpdl, MAT* inmat, int dont_free, int may_coerce   
						 ){

	int k, m, n , needed_mem, has_coerced, changed_dims, moved_data,
	changed_size;
	HV *h;
	SV *d, **dp;
	AV *e;
	

	has_coerced= 0;  changed_dims= 0; moved_data= 0; changed_size= 0; 

	if(mespdl_verbose) { 
		printf("\nmat2pdl STARTS\n");
		printf(" outpdl=%p  inmat=%p   df=%d   mc=%d \n",
					 outpdl,inmat,dont_free,may_coerce); 
	}

																/* A million checks */
	if( inmat==(MAT*)NULL )	croak("mat2pdl with NULL MAT* ");
	if( outpdl==(pdl*)NULL ) croak("mat2pdl with NULL pdl* "); 


	m = inmat->m; n = inmat->n ;
	if(mespdl_verbose) {
		printf(" m=%d n=%d \n",m,n);
		printf(" ndims=%d ",outpdl->ndims) ;
		for(k=0;k<outpdl->ndims; k++)
			printf("%d ",outpdl->dims[k]);
		printf("\n");
		p_pdl(outpdl);
	}
																/* set pdl->data, nvals, datatype */
	
	if( pdl_howbig(outpdl->datatype) == sizeof(Real) || 
		 ( may_coerce && ( pdl_howbig(pdl_Real) == sizeof(Real) ) ) 
		 ){
		if(mespdl_verbose) 
			printf("### Keep Matrix Base Pointer \n");
																/* Keep matrix "base" pointer */
		if( !dont_free ) { 
			if(mespdl_verbose) 
				printf("### Free pdl->data  %p \n",outpdl->data);
			free( outpdl->data );
		}
												
		changed_size= shrink_to_effective_size_m(inmat);

		if( outpdl->data != inmat->base ) {
			moved_data =  1;
			outpdl->data = inmat->base ; /* DON'T FREE MAT->base */
		}
		mes_free_m( inmat , 0 );

		if( outpdl->datatype != pdl_Real ) {
			outpdl->datatype = pdl_Real ;
			has_coerced = 1;					/* MUST modify $outpdl{Datatype} */
		}

	} else {											/* Copy the data */

		if(mespdl_verbose) printf("### Copy ");


		needed_mem = m * n  ;
		if( needed_mem != outpdl->nvals ) {

			if( !dont_free ){
				if(mespdl_verbose) 
					printf("### Free pdl->data  %p \n",outpdl->data);
				free( outpdl->data ); 
			}

			outpdl->data = 
				malloc( needed_mem * pdl_howbig(outpdl->datatype) );
			if(mespdl_verbose) 
				printf("### Alloc pdl->data  %p \n",outpdl->data);

			moved_data = 1;
		}
																/* Time to write a ".g" ? */
#define loop_thru_pdl( t )                           \
for(k=0; k<needed_mem; k++)                          \
		 (( t *)outpdl->data)[k]= ( t ) inmat->base[k];  \

		else if( outpdl->datatype == PDL_D )
			loop_thru_pdl( double ) 
		if( outpdl->datatype == PDL_F )
			loop_thru_pdl( float ) 
		else if( outpdl->datatype == PDL_L )
			loop_thru_pdl( long ) 
		else if( outpdl->datatype == PDL_US )
			loop_thru_pdl( unsigned short ) 
		else if( outpdl->datatype == PDL_S )
			loop_thru_pdl( short ) 
		else if( outpdl->datatype == PDL_B )
			loop_thru_pdl( unsigned char ) 
		else
			croak("Cannot convert Real to pdl n.%i ",outpdl->datatype);  

#undef loop_thru_pdl
		if(mespdl_verbose)
			printf("### Freeing (M_FREE) %p %p \n",inmat->me,*(inmat->me),inmat);
		M_FREE(inmat); 
	}
	outpdl->nvals = m * n ;

																/****** set pdl->ndims, ndims *****/

	changed_dims = set_dims(outpdl,2,n,m);

																/***** Modify the Perl variable *****/ 
		

	perlside( outpdl, has_coerced, moved_data, changed_size, 
						changed_dims, 2, n, m );


	return(outpdl);
}


																/* TO BE DONE : allow possibility to */
																/* return a row vector */
pdl* vec2pdl(pdl *outpdl, VEC *invec, 
						 int dont_free,			/* invec->data must not be freed */
						 int may_coerce,		/* if datatype are different, coerce */
						 int *no_dim				/* keep out->dims if nvals unchanged */
						 ){

	int k, d , needed_mem, has_coerced, changed_dims, moved_data,
	changed_size, dummy;
	HV *h;
	SV *e, **ep;
	AV *f;
	

	has_coerced= 0;  changed_dims= 0; moved_data= 0; changed_size= 0;  
  dummy= 0;
	if( no_dim == (int*)NULL ) no_dim = &dummy ;

	if(mespdl_verbose) { 
		printf("\nvec2pdl STARTS ");
		printf(" outpdl=%p  invec=%p   af=%d   mc=%d ",
					 outpdl,invec,dont_free,may_coerce); 
		fflush(stdout);
		v_output(invec);
	}

																/* check */
	if( invec==(VEC*)NULL  ) croak("vec2pdl with NULL VEC* ");
	if( outpdl==(pdl*)NULL ) croak("vec2pdl with NULL pdl* "); 


	d = invec->dim ;
	if(mespdl_verbose) printf(" dim=%d \n",d);

																/* set pdl->data, nvals, datatype */

	if( pdl_howbig(outpdl->datatype) == sizeof(Real) || 
		 ( may_coerce && ( pdl_howbig(pdl_Real) == sizeof(Real) ) ) 
		 ){	

		if(mespdl_verbose) 
			printf("### Keep Vector Base Pointer \n");
																/* Keep matrix "base" pointer */
		if( !dont_free ) { 
			if(mespdl_verbose) 
				printf("### Free pdl->data  %p \n",outpdl->data);
			free( outpdl->data ); 
		}

		changed_size= shrink_to_effective_size_v(invec);

		if( outpdl->data != invec->ve ) {
			moved_data =  1;
			outpdl->data = invec->ve ; /* DON'T FREE VEC->base */
		}
		mes_free_v( invec , 0 );

		if( outpdl->datatype != pdl_Real ) {
			outpdl->datatype =  pdl_Real;
			has_coerced = 1;					/* MUST modify $outpdl{Datatype} */
		}

	} else {											/* Copy the data */

		if(mespdl_verbose) printf("### Copy ");


		needed_mem = d  ;
		if( needed_mem != outpdl->nvals ) {
			if(mespdl_verbose) printf("### Must Reallocate \n");
			if( !dont_free ){
 			  if(mespdl_verbose) 
				  printf("### Free pdl->data  %p \n",outpdl->data);
        free( outpdl->data ); 
      }
			outpdl->data = 	
				malloc( needed_mem * pdl_howbig(outpdl->datatype) );
			if(mespdl_verbose) 
				printf("### Alloc pdl->data  %p \n",outpdl->data);

			moved_data = 1;
		}
																/* Time to write a ".g" ? */

#define loop_thru_pdl_v( X , T , Z )  \
for(k=0; k<needed_mem; k++)           \
	((T*) X->data)[k]=  (T) Z->ve[k]

 all_types(loop_thru_pdl_v,outpdl,invec,outpdl->datatype); 

#undef loop_thru_pdl_v

		if(mespdl_verbose)
			printf("### Freeing (V_FREE) %p %p \n",invec->ve,invec);		
		V_FREE(invec); 

	}
	
	if ( outpdl->nvals != d ){
		if( no_dim == &dummy )
			printf(" Warning : vec2pdl is unexpectedly re-sizing \n"); 
		*no_dim = 0;
	}
	outpdl->nvals = d ;

																/****** set pdl->ndims, ndims *****/
	if( ! *no_dim ) {
		changed_dims = set_dims(outpdl,2,1,d);

	}



																/***** Modify the Perl variable *****/ 
		

	perlside( outpdl, has_coerced, moved_data, changed_size, 
						changed_dims * ( *no_dim ? 0 : 1 )  , 2, 1, d );


	if(mespdl_verbose) printf("vec2pdl ENDS \n\n");

	return(outpdl);
}																/*** END vec2pdl ***/

/********************************************************************/
																/* Convert a permutation to a pdl */

pdl* perm2pdl(pdl* outpdl, PERM* inperm, int dont_free, int may_coerce   
						 ){

	int k, d , needed_mem, has_coerced, changed_dims, moved_data,
	changed_size;
	HV *h;
	SV *e, **ep;
	AV *f;
	

	has_coerced= 0;  changed_dims= 0; moved_data= 0; changed_size= 0; 

	if(mespdl_verbose) { 
		printf("\nperm2pdl STARTS ");
		printf(" outpdl=%p  inperm=%p   af=%d   mc=%d \n",
					 outpdl,inperm,dont_free,may_coerce); 
	}

																/* checks */
	if( inperm==(PERM*)NULL  )	croak("perm2pdl with NULL PERM* ");
	if( outpdl==(pdl*)NULL ) croak("perm2pdl with NULL pdl* "); 


	d = inperm->size ;
	if(mespdl_verbose) printf(" size=%d \n",d);

																/* set pdl->data, nvals, datatype */
	
	if( pdl_howbig(outpdl->datatype) == sizeof(u_int) || may_coerce )  {
		if(mespdl_verbose) 
			printf("### Keep Permutation Base Pointer \n");
																/* Keep matrix "base" pointer */
		if( !dont_free ) { 
			if(mespdl_verbose) 
				printf("### Free pdl->data  %p \n",outpdl->data);
			free ( outpdl->data );
		}

		changed_size= shrink_to_effective_size_px(inperm);

		if( outpdl->data != inperm->pe ) {
			moved_data =  1;
			outpdl->data = inperm->pe ; /* DON'T FREE PERM->pe */
		}
		mes_free_px( inperm , 0 );


		if( outpdl->datatype != pdl_u_int ) {
			outpdl->datatype = pdl_u_int ;
			has_coerced = 1;					/* MUST modify $outpdl{Datatype} */
		}

	} else {											/* Copy the data */

		if(mespdl_verbose) printf("### Copy ");


		needed_mem = d  ;
		if( needed_mem != outpdl->nvals ) {
			if(mespdl_verbose) printf("### Must Reallocate \n");
			if( !dont_free ) {
				if(mespdl_verbose) 
					printf("### Free outpdl->data  %p \n",outpdl->data);
				free( outpdl->data );
			}
			outpdl->data = 	
				malloc( needed_mem * pdl_howbig(outpdl->datatype) );
			if(mespdl_verbose) 
				printf("### Alloc pdl->data  %p \n",outpdl->data);

			moved_data = 1;
		}
																/* Time to write a ".g" ? */

#define loop_thru_pdl_px( X , T , Z )  \
for(k=0; k<needed_mem; k++)           \
	((T*) X->data)[k]=  (T) Z->pe[k]

 all_types(loop_thru_pdl_px,outpdl,inperm,outpdl->datatype); 

#undef loop_thru_pdl_px

		if(mespdl_verbose) 
			printf("### Free (PX_FREE)  %p \n",inperm->pe);
		PX_FREE(inperm);
	}
	outpdl->nvals = d ;

																/****** set pdl->ndims, ndims *****/

	changed_dims = set_dims(outpdl,1,d);

																/***** Modify the Perl variable *****/ 

	perlside( outpdl, has_coerced, moved_data, changed_size, 
						changed_dims  , 1, d );

	return(outpdl);
}																/****** END perm2pdl ******/


/******************** Convert pdl to matrix objects *****************

MAT*  pdl2mat ( pdl* inpdl , int *copy_copied )

	If *copy_copied == 1  at call   time, data will be  copied,
			 otherwise, try not to copy;  
			 pdl_howbig(datatype)!=sizeof(Real) || ndims!=2 
			 forces copying. 

  If *copy_copied == 1 at return time, data has been copied.

	If  copy_copied == NULL	at call time, try not to copy. If forced to
			 copy, produce a warning.

	Croaks if inpdl is NULL

	The perl variable is not modified. If copy has not taken place, its
Data string is "taken" by the MAT. If it is freed or displaced by
matrix opertations, the perl variable should be 	considered useless
until a call to mat2pdl is done.

************************************************************************/

MAT* pdl2mat( pdl* inpdl, int* copy_copied ) {	

	MAT *outmat;

	int i,j,k,m,n,dummy;

	dummy=0; 
	if(copy_copied==(int*)NULL) copy_copied= &dummy;

	if( inpdl==(pdl*)NULL )	croak("inpdl is NULL");

  if(not_simple(inpdl)!=0)
		croak(" pdl2mat called with non-simple pdl ");

	if( inpdl->ndims == 2 ) {

		m= inpdl->dims[1];
		n= inpdl->dims[0];

	} else {

		m= 1;
		n= inpdl->nvals;
	}

	if(mespdl_verbose) {
		printf("\npdl2mat STARTS\n");
		printf(" ndims=%d ",inpdl->ndims) ;
		for(k=0;k<inpdl->ndims; k++)
			printf("%d ",inpdl->dims[k]);
		printf("\nm=%d n=%d \n",m,n);

	}


	if( (pdl_howbig(inpdl->datatype) != pdl_howbig(pdl_Real)) || 
		 *copy_copied ) { 

		*copy_copied = 1;
		if( copy_copied == &dummy )
			printf(" Warning : pdl2mat is unexpectedly allocating \n"); 

		outmat= m_get(m,n);

#define loop_thru_mat( a , x )                      \
	for(i=0, k=0; i<outmat->m; i++ )                  \
   	for(j=0; j<outmat->n; j++, k++ )                \
	     a->me[i][j]= ((Real)(x))

		if( inpdl->datatype == PDL_D )
			loop_thru_mat( outmat, ((double*)inpdl->data)[k] );

		else if( inpdl->datatype == PDL_F )
			loop_thru_mat( outmat, ( (float*)inpdl->data)[k] );

		else if( inpdl->datatype == PDL_L )
			loop_thru_mat(outmat, ( (long*)inpdl->data)[k] );

		else if( inpdl->datatype == PDL_US )
			loop_thru_mat(outmat, ( (unsigned short*)inpdl->data)[k] );

		else if( inpdl->datatype == PDL_S )
			loop_thru_mat(outmat, ( (short*)inpdl->data)[k] );

		else if( inpdl->datatype == PDL_B )
			loop_thru_mat(outmat, ( (unsigned char*)inpdl->data)[k] );

		else
			croak("Cannot convert pdl n.%i to Real ",inpdl->datatype); 

#undef loop_thru_mat

	} else {

		if( (outmat= (MAT*)malloc(sizeof(MAT))) == (MAT*)NULL )
			croak("Unable to allocate a MAT ");
		if(mespdl_verbose)
			printf("### Alloc outmat  %p \n",outmat);

		if( (outmat->me= (Real**) malloc( sizeof(Real*)*m*n )) == 
			 (Real**)NULL )
			croak("Unable to allocate outmat->me ");
		if(mespdl_verbose)
			printf("### Alloc outmat->me  %p \n",outmat->me);

		for( i=0; i<m; i++ ) 
			(outmat->me)[i]= ((Real*)inpdl->data) + n*i ;

		outmat->m= outmat->max_m= m;
		outmat->n= outmat->max_n= n;
		outmat->max_size= m*n;
		outmat->base= inpdl->data;
	}
	return(outmat);
}


/******** Same as pdl2mat, but converts to a vector ********/
VEC* pdl2vec( pdl* inpdl, int* copy_copied ) {	

	VEC *outvec;

	int d,i,dummy;

	if(mespdl_verbose) { 
		printf("\npdl2vec STARTS ");
		printf(" inpdl=%p   cc=%d ",inpdl,*copy_copied); 
		fflush(stdout);
	}

	dummy=0; 
	if (copy_copied==(int*)NULL) copy_copied= &dummy;

	if( inpdl==(pdl*)NULL )	croak("inpdl is NULL in pdl2vec ");

  if(not_simple(inpdl)!=0)
		croak(" pdl2vec called with non-simple pdl ");

	d= inpdl->nvals;

	if(mespdl_verbose) printf(" d=%d \n",d); 

	
	if( (pdl_howbig(inpdl->datatype) != pdl_howbig(pdl_Real)) || 
		 *copy_copied ) { 

		if(mespdl_verbose) 
			printf("### Copy from size %d (pdl n. %d) to %d (pdl n. %d) \n",
						 pdl_howbig(inpdl->datatype), inpdl->datatype,
						 pdl_howbig(pdl_Real),pdl_Real);

		*copy_copied = 1;
		if( copy_copied == &dummy )
			printf(" Warning : pdl2vec is unexpectedly allocating \n"); 

		outvec= v_get(d);

		if(mespdl_verbose) 	printf("### START Looping \n");

#define loop_thru_vec( X , T , Z)    \
	for(i=0; i<X->dim; i++ )      \
	     X->ve[i]= ((Real)(( (T*) Z->data )[i]))

		all_types(loop_thru_vec,outvec,inpdl,inpdl->datatype);
#undef loop_thru_vec

		if(mespdl_verbose) 	printf("### Done Looping \n");
		

	} else {

		if( (outvec= (VEC*)malloc(sizeof(VEC))) == (VEC*)NULL )
			croak("Unable to allocate a VEC ");
		if(mespdl_verbose)
			printf("### Alloc outvec  %p \n",outvec);

		outvec->dim= outvec->max_dim= d;
		outvec->ve= inpdl->data;
	}
	if(mespdl_verbose) printf("pdl2vec ENDS \n"); 
	return(outvec);
}

/* Same as pdl2vec, but converts to a PERM */

PERM* pdl2perm( pdl* inpdl, int* copy_copied ) {	

	PERM *outperm;

	int d,i,dummy;

	dummy=0; 
	if(copy_copied==(int*)NULL) copy_copied= &dummy;

	if( inpdl==(pdl*)NULL )	croak("inpdl is NULL in pdl2perm ");

  if(not_simple(inpdl)!=0)
		croak(" pdl2perm called with non-simple pdl ");

	d= inpdl->nvals;
	

	if( pdl_howbig(inpdl->datatype) != sizeof(u_int) || *copy_copied ) {

		*copy_copied = 1;
		if( copy_copied == &dummy )
			printf(" Warning : pdl2perm is unexpectedly allocating \n"); 

		outperm= px_get(d);

#define loop_thru_perm( X , T , Z)    \
	for(i=0; i<X->size; i++ )      \
	     X->pe[i]= ( (T*) Z->data )[i]

		all_types(loop_thru_perm,outperm,inpdl,inpdl->datatype);

#undef loop_thru_perm

	} else {

		if( (outperm= (PERM*)malloc(sizeof(PERM))) == (PERM*)NULL )
			croak("Unable to allocate a PERM ");
		if(mespdl_verbose)
			printf("### Alloc outperm  %p \n",outperm);

		outperm->size= outperm->max_size= d;
		outperm->pe= inpdl->data;
	}
	return(outperm);
}


/****************** Freeing part of meschach object ******************/

/* Frees the MAT*; does not free not the data if free_base==0 */
int mes_free_m(MAT* mat , int free_base ) {
	if(mat==(MAT*)NULL)
		return(1);

	if ( free_base ) { 
		if(mespdl_verbose)
			printf("### Freeing (M_FREE) %p %p %p \n",mat->me,*(mat->me),mat);
		M_FREE(mat);
	} else {
		if(mespdl_verbose)
			printf("### Freeing (free) me= %p , mat=%p\n",mat->me,mat);
		free(mat->me);
		free(mat);
		return(1);
	}
}


int mes_free_v(VEC* vec, int free_ve ) {
	if(vec==(VEC*)NULL)
		return(1);
	if( free_ve ) {
		if(mespdl_verbose)
			printf("### Freeing (V_FREE) ve=%p   vec=%p \n",vec->ve,vec);		
		V_FREE(vec) ; 
	} else {
		if(mespdl_verbose)
			printf("### Freeing (free) vec=%p \n",vec);		
		free(vec); 
	}
	return(1);
}

int mes_free_px(PERM* perm, int free_pe ) {
	if(perm==(PERM*)NULL)
		return(1);
	if( free_pe ) {
		if(mespdl_verbose)
			printf("### Freeing (PX_FREE) pe=%p   perm=%p \n",perm->pe,perm);
		PX_FREE(perm) ;
	} else {
		if(mespdl_verbose)
			printf("### Freeing (free) perm=%p \n",perm);		
		free(perm);
	}
	return(1);
}



																/* Eventually reduce the matrix to its */
																/* effective size. Return 1 if size */
																/* has changed, 0 otherwise.  */
int shrink_to_effective_size_m( MAT* inmat ) {

	int i;

	if( ( inmat->max_m!=inmat->m ) || ( inmat->max_n!=inmat->n )){  
		if(mespdl_verbose)
			printf(" downsizing from %d %d to %d %d \n",
						 inmat->max_m,inmat->max_n,inmat->m,inmat->n);

		inmat->max_size= inmat->m*inmat->n;
		inmat->base= RENEW(inmat->base, inmat->max_size, Real);
		inmat->max_m= inmat->m;
		inmat->max_n= inmat->n;

		if( inmat->m != inmat->max_m ){

			if(mespdl_verbose)
				printf("### Free inmat->me  %p \n",inmat->me);
			free(inmat->me);

			inmat->me= (Real**)malloc(sizeof(Real*) * inmat->m);
			if(mespdl_verbose)
				printf("### Alloc inmat->me  %p \n",inmat->me);
		}
		for(i=0;i<inmat->m; i++)
			inmat->me[i]= inmat->base + i*inmat->n; 
		if(mespdl_verbose) m_output(inmat);
		return(1);
	} else 
		return(0);

}

int shrink_to_effective_size_v( VEC* invec ) {

	if( invec->max_dim!=invec->dim ){  
		if(mespdl_verbose)
			printf(" downsizing from %d to %d \n",
						 invec->max_dim,invec->dim); 

		invec->ve= RENEW(invec->ve, invec->dim, Real);
		invec->max_dim= invec->dim;

		if(mespdl_verbose) v_output(invec);
		return(1);
	} else 
		return(0);

}

int shrink_to_effective_size_px( PERM* inperm ) {

	if( inperm->max_size!=inperm->size ){  
		if(mespdl_verbose)
			printf(" downsizing from %d to %d \n",
						 inperm->max_size,inperm->size); 

		inperm->pe= RENEW(inperm->pe, inperm->size, u_int);
		inperm->max_size= inperm->size;

		if(mespdl_verbose) px_output(inperm);
		return(1);
	} else 
		return(0);

}


																/* Check that pdl is a trivial one */ 
int not_simple( pdl *a ){
	int i,k;

	/* HERE There's a problem; 
     Remove next statement as soon as incs mystery clears.
		 Probably with PDL-1.04.
		 */
	 return(0); 

	for(k=0, i=1; k<a->ndims; k++){
		if( a->incs[k] != i ){

																/* For debug only */
/*			printf(" non-simple : 	incs[%d]==%d!=%d\n",
							 k,a->incs[k],i);
 			p_pdl(a);
*/
			return(k+1);
		}
		i *= a->dims[k];
	}
/*	if(mespdl_verbose && a->offs) printf(" non-simple : offs : %d\n",
																			 a->offs);
*/
	return( - a->offs );
}


																/* set pdl->ndims, dims, incs */
int set_dims(pdl* outpdl,int nd,...){
	va_list ap;
	int *d, i,j, r;
	
	if( nd<=0 )
		croak("set_dims with d==%d<=0 ",nd);

	if( !(d= (int*)malloc(nd*sizeof(int))))
		croak("set_dims unable to allocate d");
	if(mespdl_verbose)
		printf("### Alloc d  %p \n",d);

	if(mespdl_verbose)  {
		if(nd==1) printf("set_dims vector\n"); 
		else if(nd==2)  printf("set_dims matrix\n"); 
		fflush(stdout); 
	}

	r=0;

	va_start(ap,nd);
	if(mespdl_verbose)  printf(" d= ");
	for(i=0; i<nd; i++){
		d[i]= va_arg(ap,int);
		if(mespdl_verbose)  {
			printf(" %d ",d[i]); fflush(stdout); 
		}
	}
	va_end(ap);
	if(mespdl_verbose)  printf("\n");

	if( outpdl->ndims != nd ) {

		pdl_setdims(outpdl,d, nd, (int*)NULL) ;

/*		if(mespdl_verbose)
			printf("### Free outpdl->dims  %p \n", outpdl->dims);
		free(outpdl->dims); 
		outpdl->dims= d;
		outpdl->ndims= nd;


		if( (int*)NULL == (outpdl->incs= 
				 (int*)realloc( (char*)outpdl->incs, nd*sizeof(int)))
			 ) croak("set_dims fails upon incs "); 
		if(mespdl_verbose)
			printf("### Realloc outpdl->incs  %p \n", outpdl->incs);
*/
		r= 2;

	} else {

		pdl_setdims(outpdl,d, nd, (int*)NULL);
		r = 1;
		/*
		for(i=0; i<nd; i++)
			if (outpdl->dims[i] != d[i] ){
				outpdl->dims[i] = d[i];
					if(mespdl_verbose)  {
						printf("X"); fflush(stdout); 
					}
				r = 1;
			}
		*/
	}

/*	if(r)
		for( i=0, j=1; i<nd; i++ ){
			outpdl->incs[i]= j;
			j*=d[i];
		}
*/
/*	if(r!=2) {
*/
		if(mespdl_verbose)
			printf("### Free d  %p \n", d);
		free(d); 
/*	}
*/		

	return(r);
	

}



																/***** Modify the Perl variable *****/ 

int perlside( pdl *outpdl , 
						 int has_coerced, int moved_data, int changed_size, 
						 int changed_dims,  
						 int nd, ... ) {
	va_list ap;
	int *dim, i,j, sz;
	HV *h;
	SV *d, **dp;
	AV *e;		
		 
	if(mespdl_verbose)  {
		printf(" Perlside c%d   m%d   s%d    d%d    n%d \n",
					 has_coerced, moved_data, changed_size, 
					 changed_dims, nd); fflush(stdout);
		fflush(stdout);
		}

	if( nd<=0 )
		croak("set_dims with nd==%d<=0 ",nd);

	if( !(dim= (int*)malloc(nd*sizeof(int))))
		croak("set_dims unable to allocate dim");
	if(mespdl_verbose)
		printf("### Alloc dim  %p \n",dim);

	va_start(ap,nd);
	if(mespdl_verbose) printf(" dim = ");
	for( sz=1 , i=0 ;   i<nd  ;  i++){ 
		dim[i]= va_arg(ap,int);
		sz*= dim[i];
		if(mespdl_verbose)  {
			printf(" %d ",dim[i]); fflush(stdout);
		}
	}
	va_end(ap);
	if(mespdl_verbose) printf("\n");

	h= (HV*)SvRV((SV*)outpdl->sv); /* Coherence on perl side */

	if( has_coerced ) {						
		if(mespdl_verbose) 
			printf("### Has Coerced \n");
		if( !( (dp= hv_fetch(h,"Datatype",8,0)) && (SvIOK(d=*dp))) )
			croak(" Unable to get to Datatype for modification %p %i ",
						dp, dp? SvTYPE(d):0) ;
		sv_setiv( d, outpdl->datatype );
	}
																/* Data */
	if( has_coerced || moved_data || changed_size ) {
		if(mespdl_verbose) 
			printf("### Has Moved/Coerced/Resized  Data \n");
		if( !( (dp= hv_fetch(h,"Data",4,0)) && (SvPOK(d=*dp))) )
			croak(" Unable to get to Data for modification %p %i ",
						dp, dp? SvTYPE(d):0) ;
		
		SvPVX(d) = (char*) outpdl->data; /* Todo : Optimize : Useless if */
																		 /* only changed_size  */  
		SvLEN(d) =  sz*pdl_howbig(outpdl->datatype);
		SvCUR(d) =  sz*pdl_howbig(outpdl->datatype);
	}

	if( changed_dims ) {					/* Dimension */
		if(mespdl_verbose) printf("### Has Changed Dims \n");
		/* Dims */
		if( !( (dp= hv_fetch(h,"Dims",4,0)) && (SvTYPE(d=*dp) == SVt_RV)) )
			croak(" Unable to get to Dims for modification %p %i",
						dp, dp? SvTYPE(d):0);
		e= (AV*)SvRV(d);
		
		if( changed_dims == 2 ) av_clear(e);

		for(i=0; i<nd; i++)
			av_store(e,i,newSViv(dim[i]));

		if(  (dp= hv_fetch(h,"Incs",4,0)) && (SvTYPE(d=*dp) == SVt_RV) )
			  {
					e= (AV*)SvRV(d);
		
					if( changed_dims == 2 ) av_clear(e);

					for(i=0,j=1; i<nd; i++, j*=dim[i])
						av_store(e,i,newSViv(dim[i]));
				}

	}
	if(mespdl_verbose)
		printf("### Free (free) dim=%p \n",dim);
	free(dim); 
}
