#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <src/Brownian.h>


#include "const-c.inc"

MODULE = Math::Random::Brownian		PACKAGE = Math::Random::Brownian		

INCLUDE: const-xs.inc

AV *
__hosking(n, H, L, cum, seed1, seed2)
          long n
          double H
          double L
          int cum
          long seed1
          long seed2
          PREINIT:
           int i;
           double m;
           double *output;
           AV *results;
          CODE:
           m = pow(2.0,n);
           New(0,output,m,double);
           hosking(&n,&H,&L,&cum,&seed1,&seed2,output);
         
           /* Declare results as mortal to avoid passing */
           /* it back with REFCNT = 2 */ 
           results = (AV*)sv_2mortal((SV*)newAV());
           for(i=0;i<m;i++)
           {
            av_push(results,newSVnv(output[i]));
           }
           /* Push the new random seeds on to the bottom of the return array */
           av_push(results,newSVnv(seed1));
           av_push(results,newSVnv(seed2));
           Safefree(output);
           RETVAL = results;

          OUTPUT:
           RETVAL

AV *
__circulant(n, H, L, cum, seed1, seed2)
          long n
          double H
          double L
          int cum
          long seed1
          long seed2
          PREINIT:
           int i;
           double m;
           double *output;
           AV *results;
          CODE:
           m = pow(2.0,n);
           New(0,output,m,double);
           circulant(&n,&H,&L,&cum,&seed1,&seed2,output);
         
           /* Declare results as mortal to avoid passing */
           /* it back with REFCNT = 2 */ 
           results = (AV*)sv_2mortal((SV*)newAV());
           for(i=0;i<m;i++)
           {
            av_push(results,newSVnv(output[i]));
           }
           /* Push the new random seeds on to the bottom of the return array */
           av_push(results,newSVnv(seed1));
           av_push(results,newSVnv(seed2));
           Safefree(output);
           RETVAL = results;

          OUTPUT:
           RETVAL

AV *
__apprcirc(n, H, L, cum, seed1, seed2)
          long n
          double H
          double L
          int cum
          long seed1
          long seed2
          PREINIT:
           int i;
           double m;
           double *output;
           AV *results;
          CODE:
           m = pow(2.0,n);
           New(0,output,m,double);
           apprcirc(&n,&H,&L,&cum,&seed1,&seed2,output);
         
           /* Declare results as mortal to avoid passing */
           /* it back with REFCNT = 2 */ 
           results = (AV*)sv_2mortal((SV*)newAV());
           for(i=0;i<m;i++)
           {
            av_push(results,newSVnv(output[i]));
           }
           /* Push the new random seeds on to the bottom of the return array */
           av_push(results,newSVnv(seed1));
           av_push(results,newSVnv(seed2));
           Safefree(output);
           RETVAL = results;

          OUTPUT:
           RETVAL

AV *
__paxson(n, H, L, cum, seed1, seed2)
          long n
          double H
          double L
          int cum
          long seed1
          long seed2
          PREINIT:
           int i;
           double m;
           double *output;
           AV *results;
          CODE:
           m = pow(2.0,n);
           New(0,output,m,double);
           paxson(&n,&H,&L,&cum,&seed1,&seed2,output);
         
           /* Declare results as mortal to avoid passing */
           /* it back with REFCNT = 2 */ 
           results = (AV*)sv_2mortal((SV*)newAV());
           for(i=0;i<m;i++)
           {
            av_push(results,newSVnv(output[i]));
           }
           /* Push the new random seeds on to the bottom of the return array */
           av_push(results,newSVnv(seed1));
           av_push(results,newSVnv(seed2));
           Safefree(output);
           RETVAL = results;

          OUTPUT:
           RETVAL

