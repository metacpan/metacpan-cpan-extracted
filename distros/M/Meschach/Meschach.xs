#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "matrix.h"
#include "matrix2.h"
#include "perl.h"
#include "XSUB.h"
#include "../Core/pdl.h"
#include "../Core/pdlcore.h"
#include "./mespdl.h"
#include "./p_funcs.h"
#include "./Meschach.h"
																/* WHY ISN'T err_mesg declared in */
																/* err.h ? */
																/* There must be a function returning */
																/* err_mesg[i] ... TODO : Find it */

static	char	*err_mesg[] =
{	  "unknown error",						/* 0 */
	  "sizes of objects don't match",	/* 1 */
	  "index out of bounds",			/* 2 */
	  "can't allocate memory",		/* 3 */
	  "singular matrix",			    /* 4 */
	  "matrix not positive definite",	/* 5 */
	  "incorrect format input",		/* 6 */
	  "bad input file/device",		/* 7 */
	  "NULL objects passed",			/* 8 */
	  "matrix not square",				/* 9 */
	  "object out of range",			/* 10 */
	  "can't do operation in situ for non-square matrix",	/* 11 */
	  "can't do operation in situ",	/* 12 */
	  "excessive number of iterations",	/* 13 */
	  "convergence criterion failed",	/* 14 */
	  "bad starting value",				/* 15 */
	  "floating exception",				/* 16 */
	  "internal inconsistency (data structure)", /* 17 */
	  "unexpected end-of-file",		/* 18 */
	  "shared vectors (cannot release them)",	/* 19 */  
	  "negative argument",				/* 20 */
	  "cannot overwrite object",	/* 21 */
	  "breakdown in iterative method"	/* 22 */
	 };


#ifdef __cplusplus
}
#endif


#define SET_RETVAL_NV x.datatype<PDL_F ? (RETVAL=newSViv( (IV)result )) : (RETVAL=newSVnv( result ))


static Core* PDL; /* Structure hold core C functions */
SV* CoreSV;       /* Get's pointer to perl var holding core structure */


int mespdl_verbose;							

int pdl_u_int, pdl_Real;				/* pdl to meschach Type Conversion */ 
	
/* Don't forget "PDL::" 'cause otherwise, they'll be missing in */
 /* Meschach.so */
MODULE = PDL::Meschach		PACKAGE = PDL::Meschach

void
mp_mrand(a,coerce)
		 pdl *a
		 int coerce 

  	 CODE:
	   VEC *va;
		 int copy_a, no_dim;
		 
		 no_dim = 1;								/* Don't change size */
		 copy_a= 0 ; va= pdl2vec(a, &copy_a );

		 va = v_rand(va);

		 vec2pdl(a,va, 1-copy_a, coerce, &no_dim);


void
mp_smrand(seed)
		 int seed

		 CODE:
			 smrand(seed);


void
mp_ident(a,coerce)
		 pdl *a
		 int coerce 

  	 CODE:
	   MAT *ma;
		 int copy_a;
		 

		 copy_a= 0 ; ma= pdl2mat(a, &copy_a );

		 ma = m_ident(ma);

		 mat2pdl(a,ma, 1-copy_a, coerce);


																## Matrix Multiply ##
int
mp_mm(c,a,b,coerce)
		 pdl *c
 		 pdl *a
		 pdl *b
		 int coerce	 

		 CODE:
		 MAT *mc, *ma, *mb;
		 int copy_a,  copy_b,  copy_c, error;
		 
		 copy_a= (a->data==c->data) ? 1 : 0 ; ma= pdl2mat(a, &copy_a );
		 copy_b= (b->data==c->data) ? 1 : 0 ; mb= pdl2mat(b, &copy_b ); 
		 copy_c=0; mc= pdl2mat(c, &copy_c );  


		 error= 0;
		 catchall(mc= m_mlt(ma,mb,mc),
			 printf(" Caught Error %i %s\n",
							error= _err_num,err_mesg[_err_num]));
		 
		 if(mespdl_verbose) m_output(mc);

		 mat2pdl(c,mc, 1-copy_c , coerce);
	
		 mes_free_m(ma, copy_a );	
		 mes_free_m(mb, copy_b );	

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL

			 ## a <- b^c
int
mp_pow(a,b,c,coerce)
 		 pdl *a
		 pdl *b
		 int c	 
		 int coerce	 

		 CODE:
		 MAT *ma, *mb;
		 int copy_a,  copy_b, error;
		 
		 copy_a= 0 ; ma= pdl2mat(a, &copy_a );
											/* No apparent problem if ma->data == mb->data */
		 copy_b= /* (b->data==a->data) ? 1 : */ 0 ; mb= pdl2mat(b, &copy_b ); 


		 error= 0;
		 catchall(ma= m_pow(mb,c,ma),
			 printf(" Caught Error %i %s\n",
							error= _err_num,err_mesg[_err_num]));
		 
		 mat2pdl(a,ma, 1-copy_a , coerce);
	
		 mes_free_m(mb, copy_b );	

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL




int 
mp_inv(inv_a, a,coerce)
		 pdl *inv_a
		 pdl *a
		 int coerce
	 
		 CODE:
			 MAT *ma, *mi;
		 int copy_a, copy_i, error;


																/* having inv_a->me == a->me seems not */
																/* to be a problem */
		 /* copy_a= (a->data==c->data) ? 1 : 0 ; */ 
		 copy_a= 0; ma= pdl2mat(a, &copy_a );
		 copy_i= 0; mi= pdl2mat( inv_a, &copy_i );

		 catchall( mi = m_inverse(ma,mi) ,
			 printf(" Caught Error %i %s\n",
							error = _err_num,err_mesg[_err_num])
		 );
		 
		 mes_free_m( ma , copy_a );

		 mat2pdl(inv_a,mi,1-copy_i,coerce);

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL


																## Cholesky Factorization ##
int 
mp_chfac(a)
		 pdl *a
	 
		 CODE:
			 MAT *ma;
		 int copy_a, error;
		 
		 copy_a= 0; ma= pdl2mat( a, &copy_a );

		 catchall( ma = CHfactor(ma) ,
			 printf(" Caught Error %i %s\n",
							error = _err_num,err_mesg[_err_num])
		 );
		 
		 mat2pdl(a,ma,1-copy_a,1);

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL


int
mp_chsolve(x, b, ch )
		 pdl *x
		 pdl *b
		 pdl *ch

		 CODE:

		 MAT *mch;
		 VEC *vx, *vb;
		 
		 int chdim_x, copy_x, copy_ch, copy_b, error;
			 

		 copy_x= 0; vx= pdl2vec( x, &copy_x );

		 copy_ch= 0; mch = pdl2mat( ch, &copy_ch );
		 copy_b= 0;  vb= pdl2vec( b, &copy_b );

		 error= 0;
		 catchall( 
       vx = CHsolve(mch,vb,vx),
			 printf(" mp_chsolve Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 if( error ){
			 printf("CH==\n"); m_output(mch);
			 printf("b ==\n"); v_output(vb);
			 printf("x ==\n"); v_output(vx);
		 }

		 mes_free_m( mch, copy_ch );
		 mes_free_v( vb, copy_b );

		 chdim_x= 1;
		 vec2pdl( x, vx, 1-copy_x, 1, &chdim_x );

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL



int
mp_qrfac(qr, v )
		 pdl *qr
		 pdl *v

		 CODE:
			 MAT *mqr;
		 VEC *vv;
		 
		 int copy_qr, copy_v, chdim_v, error= 1;
			 
		 copy_qr= 0; mqr= pdl2mat( qr, &copy_qr );
		 copy_v= 0; vv= pdl2vec( v, &copy_v );
		 if( vv->dim != mqr->m ) v_resize( vv, mqr->m );

		 catchall( mqr = QRfactor(mqr,vv) ,
			 printf(" Caught Error %i %s\n",
							_err_num,err_mesg[_err_num])
		 );

		 mat2pdl(qr, mqr, 1-copy_qr, 1);
		 chdim_v= 1;
		 vec2pdl(v, vv ,1-copy_v, 1, &chdim_v );

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL

int
mp_qrsolve(x, b, qr, v )
		 pdl *x
		 pdl *b
		 pdl *qr
		 pdl *v

		 CODE:

		 MAT *mqr;
		 VEC *vx, *vb, *vv;
		 
		 int chdim_x, copy_x, copy_qr, copy_v, copy_b, error;
			 

		 copy_x= 0; vx= pdl2vec( x, &copy_x );

		 copy_qr= 0; mqr = pdl2mat( qr, &copy_qr );
		 copy_v= 0;  vv=  pdl2vec( v, &copy_v );
		 copy_b= 0;  vb= pdl2vec( b, &copy_b );

		 error= 0;
		 catchall( 
       vx = QRsolve(mqr,vv,vb,vx),
			 printf(" mp_qrsolve Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 if( error ){
			 printf("QR==\n"); m_output(mqr);
			 printf("V ==\n"); v_output(vv);
			 printf("b ==\n"); v_output(vb);
			 printf("x ==\n"); v_output(vx);
		 }

		 mes_free_m( mqr, copy_qr );
		 mes_free_v( vv, copy_v );
		 mes_free_v( vb, copy_b );

		 chdim_x= 1;
		 vec2pdl( x, vx, 1-copy_x, 1, &chdim_x );

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL



double
mp_qrcond( qr )
		 pdl *qr

		 CODE:

		 MAT *mqr;
		 double c;

		 int copy_qr, error;
			 

		 copy_qr= 0; mqr = pdl2mat( qr, &copy_qr );

		 error= 0;

		 catchall( 
       c = QRcondest(mqr),
			 printf(" mp_qrcond Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 if( error ){
			 printf("QR ==\n");   			 m_output(mqr);
		 }

		 mes_free_m( mqr, copy_qr );

		 RETVAL = c;
	 OUTPUT:
		 RETVAL




int
mp_lufac(a, b )
		 pdl *a
		 pdl *b

		 CODE:
			 MAT *ma;
		 PERM *pb;
		 
		 int copy_a, copy_b, error;
			 
		 copy_a= 0; ma= pdl2mat( a, &copy_a );
		 copy_b= 0; pb= pdl2perm( b, &copy_b );
		 if( pb->size != ma->m ) px_resize( pb, ma->m );

		 error= 0;
		 catchall( ma = LUfactor(ma,pb) ,
			 printf(" Caught Error %i %s\n",
							_err_num,err_mesg[_err_num])
		 );

		 mat2pdl(a, ma, 1-copy_a, 1);
		 perm2pdl(b, pb ,1-copy_b, 1);

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL


			 ## Solve a.x = b when given the LU decomposition of a, ##
       ## 'lu' and  'p'  ##
int
mp_lusolve(x, b, lu, p )
		 pdl *x
		 pdl *b
		 pdl *lu
		 pdl *p

		 CODE:

		 MAT *mlu;
		 VEC *vx, *vb;
		 PERM *pp;
		 
		 int chdim_x, copy_x, copy_lu, copy_p, copy_b, error;
			 

		 copy_x= 0; vx= pdl2vec( x, &copy_x );

		 copy_lu= 0; mlu = pdl2mat( lu, &copy_lu );
		 copy_p= 0;  pp=  pdl2perm( p, &copy_p );

																/* Assume b is unchanged */
		 copy_b= 0; vb= pdl2vec( b, &copy_b );

		 error= 0;

		 catchall( 
       vx = LUsolve(mlu,pp,vb,vx),
			 printf(" mp_lusolve0 Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 if( error ){
			 printf("LU ==\n");   			 m_output(mlu);
			 printf("Permutation ==\n"); px_output(pp);
			 printf("b ==\n");    		   v_output(vb);
			 printf("x ==\n");    		   v_output(vx);
		 }

		 mes_free_m( mlu, copy_lu );
		 mes_free_px( pp, copy_p );

		 mes_free_v( vb, copy_b );

		 chdim_x= 1;
		 vec2pdl( x, vx, 1-copy_x, 1, &chdim_x );

		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL

double
mp_lucond( lu, p )
		 pdl *lu
		 pdl *p

		 CODE:

		 MAT *mlu;
		 PERM *pp;
		 double c;

		 int copy_lu, copy_p, error;
			 

		 copy_lu= 0; mlu = pdl2mat( lu, &copy_lu );
		 copy_p= 0;  pp=  pdl2perm( p, &copy_p );

		 error= 0;

		 catchall( 
       c = LUcondest(mlu,pp),
			 printf(" mp_lucond Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 if( error ){
			 printf("LU ==\n");   			 m_output(mlu);
			 printf("Permutation ==\n"); px_output(pp);
		 }

		 mes_free_m( mlu, copy_lu );
		 mes_free_px( pp, copy_p );

		 RETVAL = c;
	 OUTPUT:
		 RETVAL



######################################################################

## if a is a symmetric matrix,  ##
##   puts its eigenvectors in q ##
##   and  its  eigenvalues in l ##

int 
mp_symmeig( q, l, a )
		 pdl *q
		 pdl *l
		 pdl *a

		 CODE:

		 MAT *ma, *mq;
		 VEC *vl;
		 
		 int  chdim_l, copy_l, copy_a, copy_q, error;
			 

		 copy_l= 0; vl = pdl2vec( l, &copy_l );
		 copy_a= 0;	ma = pdl2mat( a, &copy_a );
		 copy_q= 0; mq = pdl2mat( q, &copy_q );

		 error= 0;

		 catchall( 
       {  vl = symmeig(ma,mq,vl );
				},
			 printf(" Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 mes_free_m( ma, copy_a );

		 chdim_l = 1;
		 vec2pdl( l, vl, 1-copy_l, 1,  &chdim_l );

		 mat2pdl( q, mq, 1-copy_q, 1 );


		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL



## Singular Values Decomposition of a (mxn) ##
## u^T a v = diag(l)(mxn)                   ##
## u (mxm), v (nxn) are orthogonal          ##
 
int 
mp_svd( u, v, l, a )
		 pdl *u
		 pdl *v
		 pdl *l
		 pdl *a

		 CODE:

		 MAT *ma, *mu, *mv;
		 VEC *vl;
		 
		 int  chdim_l, copy_l, copy_a, copy_u, copy_v, error;
		 int  dl;


		 copy_a= 0;	ma = pdl2mat( a, &copy_a );

		 copy_l= 0; vl = pdl2vec( l, &copy_l );
		 dl = (ma->n < ma->m) ? ma->n : ma->m ; 
		 if( vl->dim != dl ) v_resize(vl,dl);

		 copy_u= 0;	 mu = pdl2mat( u, &copy_u );
		 if( mu->m != ma->m || mu->n != ma->m ) m_resize(mu,ma->m,ma->m);


		 copy_v= 0; mv = pdl2mat( v, &copy_v ); 
		 if( mv->m != ma->n || mv->n != ma->n ) m_resize(mv,ma->n,ma->n);

		 error= 0;

		 catchall( 
       {  vl = svd(ma,mu,mv,vl );
				},
			 printf(" Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 mes_free_m( ma, copy_a );

		 chdim_l = 1;
		 vec2pdl( l, vl, 1-copy_l, 1,  &chdim_l );
		 
		 mat2pdl( u, mu, 1-copy_u, 1 );
		 mat2pdl( v, mv, 1-copy_v, 1 );


		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL

int 
mp_svd0( l, a )
		 pdl *l
		 pdl *a

		 CODE:

		 MAT *ma;
		 VEC *vl;
		 
		 int  chdim_l, copy_l, copy_a, error;
		 int  dl;


		 copy_a= 0;	ma = pdl2mat( a, &copy_a );

		 copy_l= 0; vl = pdl2vec( l, &copy_l );
		 dl = (ma->n < ma->m) ? ma->n : ma->m ; 
		 if( vl->dim != dl ) v_resize(vl,dl);

		 error= 0;

		 catchall( 
       {  vl = svd(ma,(MAT*)NULL,(MAT*)NULL,vl );
				},
			 printf(" Caught Matrix Error %i %s\n",
								error = _err_num,err_mesg[_err_num]) 	 
		 );

		 mes_free_m( ma, copy_a );

		 chdim_l = 1;
		 vec2pdl( l, vl, 1-copy_l, 1,  &chdim_l );
		 
		 RETVAL = ! error;
	 OUTPUT:
		 RETVAL




######################################################################

																## Detailed printout of pdl and ##
																## corresponding Perl object ##
void 
ppdl(a)
pdl *a
				CODE:
				p_pdl(a);
	
###########################################################################

																## various testing routines  ##
																## pdl to MAT to pdl. ce = CoercE ? ##
int
to_fro_m( a , b , ce )
pdl *a 
pdl *b 
int ce
 CODE:
	MAT *mb;
  int c2;

  c2= 1;
  mb = pdl2mat( b , &c2 );
  mat2pdl(a , mb, 0 , ce );
  RETVAL= c2;
  OUTPUT:
	RETVAL

																#* pdl to VEC to pdl. ce = CoercE ? *#
int
to_fro_v( a , b , ce )
pdl *a 
pdl *b 
int ce
 CODE:
	VEC *vb;
  int c2, rs;

  c2= 1;
  rs= 0;
  vb = pdl2vec( b , &c2 );
  vec2pdl(a , vb, 0 , ce , &rs );
  RETVAL= c2;
  OUTPUT:
	RETVAL

																#* pdl to PEMR to pdl. ce = CoercE ? *#
int
to_fro_px( a , b , ce )
pdl *a 
pdl *b 
int ce
 CODE:
	PERM *vb;
  int c2;

  c2= 1;
  vb = pdl2perm( b , &c2 );
  /* px_output(vb); */
  perm2pdl(a , vb, 0 , ce );
  RETVAL= c2;
  OUTPUT:
	RETVAL

######################################################################

int
gset_verbose(v)
int v
				CODE:
				if(v>=0) mespdl_verbose= v;
        RETVAL= mespdl_verbose;
        OUTPUT:
	      RETVAL


######################################################################


BOOT:

	 mespdl_verbose= 0;


   /* Get pointer to structure of core shared C routines */

   CoreSV = perl_get_sv("PDL::SHARE",FALSE);  /* SV* value */
   if (CoreSV==NULL)
      croak("This module requires use of PDL::Core first");

   PDL = (Core*) (void*) SvIV( CoreSV );  /* Core* value */

   smrand(1);										/* Ready Random Generator */

																/* Type equivalence : u_int */
    if( pdl_howbig(PDL_US) ==  sizeof(u_int) ) 
			pdl_u_int = PDL_US ;
		else if ( pdl_howbig(PDL_L) ==  sizeof(u_int) )
      pdl_u_int = PDL_L ;
    else if( pdl_howbig(PDL_US) >  sizeof(u_int) ) 
			pdl_u_int = PDL_US ;
		else if ( pdl_howbig(PDL_L) >  sizeof(u_int) )
      pdl_u_int = PDL_L ;
		else
			croak("pdl lacks an integer type of size %i." 
						"It has %i and %i though; See the Caveat file\n",
						sizeof(u_int),pdl_howbig(PDL_US),pdl_howbig(PDL_L)) ; 


																/* Type equivalence : Real */
    if( pdl_howbig(PDL_F) ==  sizeof(Real) ) 
			pdl_Real = PDL_F ;
		else if ( pdl_howbig(PDL_D) ==  sizeof(Real) )
      pdl_Real = PDL_D ;
		else if ( pdl_howbig(PDL_F) >  sizeof(Real) ) 
			pdl_Real = PDL_F ;
		else if ( pdl_howbig(PDL_D) >  sizeof(Real) )
      pdl_Real = PDL_D ;
		else
			croak("pdl lacks a floating point type of size >= %i." 
						"It has %i and %i though; See the Caveat file\n",
						sizeof(Real),pdl_howbig(PDL_F),pdl_howbig(PDL_D)) ; 


   if(mespdl_verbose) {
     printf(" Types :\n Real : size=%d <==> PDL N. %d :size=%d \n",
						sizeof(Real),pdl_Real,pdl_howbig(pdl_Real));

     printf(" pdl_howbig : %d => %d    %d => %d \n",
						PDL_F,pdl_howbig(PDL_F),PDL_D,pdl_howbig(PDL_D)); 

     printf(" sizeof Real = %d \n",sizeof(Real));

     printf(" u_int : size=%d <--> PDL N. %d :size=%d \n",
						sizeof(u_int),pdl_u_int,pdl_howbig(pdl_u_int));

     printf(" pdl_howbig : %d => %d    %d => %d \n",
						PDL_US,pdl_howbig(PDL_US),PDL_L,pdl_howbig(PDL_L)); 

     printf(" sizeof u_int = %d \n\n",sizeof(u_int));


     }
