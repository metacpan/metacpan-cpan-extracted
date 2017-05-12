#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <math.h>
#include <stdio.h>

#define TF_DEBUG

typedef double *Math__SO3;

static char* croak_turn="Math::SO3::turn: Use as in: $rotation->turn(\"xr\" => 120, \"zr\" => 30)";

static char* croak_combine="Math::SO3::combine: Use as in: $rotation->combine($rotation_after)";

static char* croak_translate="Math::SO3::translate: Use as in: $rotation->translate_vectors($vec1, $vec2, @more_vecs)";

static char* croak_inv_translate="Math::SO3::translate: Use as in: $rotation->inv_translate_vectors($vec1, $vec2, @more_vecs)";

static char* croak_turning_angle_and_dir="Math::SO3::turning_angle_and_dir: Use as in: ($angle, $dir)=$rotation->turning_angle_and_dir(\"degrees\")";

static char* croak_euler_angles_zxz="Math::SO3::euler_angles_zxz: Use as in: ($phi, $theta, $psi)=$rotation->euler_angles_zxz(\"degrees\")";

static char* croak_turn_round_axis="Math::SO3::turn_round_axis: Use as in: $rotation->turn_round_axis(<axis>, <angle>, \"degrees\")";

static char* croak_invert="Math::SO3::invert: Use as in: $rotation->invert()";



static inline double my_acos(double x)
{
 if(x>1)return 0;
 if(x<-1)return M_PI;
 return acos(x);
}


static inline void do_turn(Math__SO3 so3, int axis, double angle)
{
  int i;
  double inv_norm, co, si, v1, v2, sprod;

  co=cos(angle);
  si=sin(angle);

  if(axis==0) /* x rotation */
    {
      /* The matrix M can map space coordinates to body coordinates via

            v' = M v

         So, if we turn the body round the body(!) x-axis, 
         we have to left-multiply M by

         (    1            0            0       )
         (    0            cos phi      sin phi )
         (    0           -sin phi      cos phi )

         Reason: general form should be obvious; the only question is 
         "where to place the minus sign". We have a 
         old-body-coords->new-body-coords transformation here, 
         therefore have to multiply v' = M v from the left with a matrix.

         When we rotate round x, starting from identity, the body vector with
         only z-coordinate=1 (0 0 1)^T will then have (expressed in 
         rotated-body components) a positive y component. That 
         determines sign. (y coord vector will have a negative z 
         component when expressed in new coords.)

         Now, how to do it: we may accept a bit "numeric drift", 
         but we can not accept our vectors getting nonorthogonal.
         Therefore, we turn and normalize and orthogonalize (Gram-Schmidt)
         x and y columns, and compute (without normalizing) 
         z as cross-product. We needn't normalize z,
         since the error will be small as x and y just have been normalized,
         and this error won't build up, since as a principle,
         we first normalize vectors when we add other rotations.

         Everything clear?
       */

      /* rotate and normalize "x" column */
      /* so3[0*3+0] remains unchanged */

      v1=so3[1*3+0];
      v2=so3[2*3+0];

      so3[1*3+0]=co*v1+si*v2;
      so3[2*3+0]=-si*v1+co*v2;
	
      inv_norm=1.0/sqrt( so3[0*3+0]*so3[0*3+0]
		        +so3[1*3+0]*so3[1*3+0]
		        +so3[2*3+0]*so3[2*3+0]);
      so3[0*3+0]*=inv_norm;
      so3[1*3+0]*=inv_norm;
      so3[2*3+0]*=inv_norm;

      /* rotate y column */

      /* so3[0*3+1] remains unchanged */

      v1=so3[1*3+1];
      v2=so3[2*3+1];

      so3[1*3+1]=co*v1+si*v2;
      so3[2*3+1]=-si*v1+co*v2;

      /* gram-schmidt orthogonalize y: y = y -(x*y)x */

      sprod= so3[0*3+0]*so3[0*3+1]
	    +so3[1*3+0]*so3[1*3+1]
	    +so3[2*3+0]*so3[2*3+1];

      so3[0*3+1]-=sprod*so3[0*3+0];
      so3[1*3+1]-=sprod*so3[1*3+0];
      so3[2*3+1]-=sprod*so3[2*3+0];

      /* normalize y */

      inv_norm=1.0/sqrt( so3[0*3+1]*so3[0*3+1]
		        +so3[1*3+1]*so3[1*3+1]
		        +so3[2*3+1]*so3[2*3+1]);
      so3[0*3+1]*=inv_norm;
      so3[1*3+1]*=inv_norm;
      so3[2*3+1]*=inv_norm;

      /* Z = X x Y */
      so3[0*3+2]=so3[1*3+0]*so3[2*3+1]-so3[2*3+0]*so3[1*3+1];
      so3[1*3+2]=so3[2*3+0]*so3[0*3+1]-so3[0*3+0]*so3[2*3+1];
      so3[2*3+2]=so3[0*3+0]*so3[1*3+1]-so3[1*3+0]*so3[0*3+1];
    }
  else if(axis==1) /* y rotation; simply do a cyclic change in code above. */
    {

      /* rotate and normalize "y" column */
      /* so3[1*3+1] remains unchanged */

      v1=so3[2*3+1];
      v2=so3[0*3+1];

      so3[2*3+1]=co*v1+si*v2;
      so3[0*3+1]=-si*v1+co*v2;

      inv_norm=1.0/sqrt( so3[1*3+1]*so3[1*3+1]
		        +so3[2*3+1]*so3[2*3+1]
		        +so3[0*3+1]*so3[0*3+1]);
      so3[1*3+1]*=inv_norm;
      so3[2*3+1]*=inv_norm;
      so3[0*3+1]*=inv_norm;

      /* rotate z column */

      /* so3[1*3+2] remains unchanged */

      v1=so3[2*3+2];
      v2=so3[0*3+2];

      so3[2*3+2]=co*v1+si*v2;
      so3[0*3+2]=-si*v1+co*v2;

      /* gram-schmidt orthogonalize z: z = z -(y*z)y */

      sprod= so3[1*3+1]*so3[1*3+2]
	    +so3[2*3+1]*so3[2*3+2]
	    +so3[0*3+1]*so3[0*3+2];

      so3[1*3+2]-=sprod*so3[1*3+1];
      so3[2*3+2]-=sprod*so3[2*3+1];
      so3[0*3+2]-=sprod*so3[0*3+1];

      /* normalize z */

      inv_norm=1.0/sqrt( so3[1*3+2]*so3[1*3+2]
		        +so3[2*3+2]*so3[2*3+2]
		        +so3[0*3+2]*so3[0*3+2]);
      so3[1*3+2]*=inv_norm;
      so3[2*3+2]*=inv_norm;
      so3[0*3+2]*=inv_norm;

      /* X = Y x Z */
      so3[1*3+0]=so3[2*3+1]*so3[0*3+2]-so3[0*3+1]*so3[2*3+2];
      so3[2*3+0]=so3[0*3+1]*so3[1*3+2]-so3[1*3+1]*so3[0*3+2];
      so3[0*3+0]=so3[1*3+1]*so3[2*3+2]-so3[2*3+1]*so3[1*3+2];
    }
  else /* z rotation */
    {
      /* rotate and normalize "z" column */
      /* so3[2*3+2] remains unchanged */

      v1=so3[0*3+2];
      v2=so3[1*3+2];

      so3[0*3+2]=co*v1+si*v2;
      so3[1*3+2]=-si*v1+co*v2;

      /* normalize z */
      inv_norm=1.0/sqrt( so3[2*3+2]*so3[2*3+2]
		        +so3[0*3+2]*so3[0*3+2]
		        +so3[1*3+2]*so3[1*3+2]);
      so3[2*3+2]*=inv_norm;
      so3[0*3+2]*=inv_norm;
      so3[1*3+2]*=inv_norm;

      /* rotate x column */

      /* so3[2*3+0] remains unchanged */

      v1=so3[0*3+0];
      v2=so3[1*3+0];

      so3[0*3+0]=co*v1+si*v2;
      so3[1*3+0]=-si*v1+co*v2;

      /* gram-schmidt orthogonalize x: x = x -(z*x)z */

      sprod= so3[2*3+2]*so3[2*3+0]
	    +so3[0*3+2]*so3[0*3+0]
	    +so3[1*3+2]*so3[1*3+0];

      so3[2*3+0]-=sprod*so3[2*3+2];
      so3[0*3+0]-=sprod*so3[0*3+2];
      so3[1*3+0]-=sprod*so3[1*3+2];

      /* normalize x */

      inv_norm=1.0/sqrt( so3[2*3+0]*so3[2*3+0]
		        +so3[0*3+0]*so3[0*3+0]
		        +so3[1*3+0]*so3[1*3+0]);
      so3[2*3+0]*=inv_norm;
      so3[0*3+0]*=inv_norm;
      so3[1*3+0]*=inv_norm;

      /* Y = Z x X */
      so3[2*3+1]=so3[0*3+2]*so3[1*3+0]-so3[1*3+2]*so3[0*3+0];
      so3[0*3+1]=so3[1*3+2]*so3[2*3+0]-so3[2*3+2]*so3[1*3+0];
      so3[1*3+1]=so3[2*3+2]*so3[0*3+0]-so3[0*3+2]*so3[2*3+0];
     }
}

#ifdef TF_DEBUG

/* just the same thing, but more primitive, and without all the
   normalization stuff. */

static inline void do_turn_debug(Math__SO3 so3, int axis, double angle)
{
  int i;
  double inv_norm, co, si, v1, v2, sprod, old_mx[9];

  co=cos(angle);
  si=sin(angle);

  if(axis==0)			/* x rotation */
    {
      so3[1*3+0]= co*old_mx[1*3+0]+si*old_mx[2*3+0];
      so3[2*3+0]=-si*old_mx[1*3+0]+co*old_mx[2*3+0];
      so3[1*3+1]= co*old_mx[1*3+1]+si*old_mx[2*3+1];
      so3[2*3+1]=-si*old_mx[1*3+1]+co*old_mx[2*3+1];
      so3[1*3+2]= co*old_mx[1*3+2]+si*old_mx[2*3+2];
      so3[2*3+2]=-si*old_mx[1*3+2]+co*old_mx[2*3+2];
    }
  else if(axis==1)		/* y rotation */
    {
      so3[2*3+1]= co*old_mx[2*3+1]+si*old_mx[0*3+1];
      so3[0*3+1]=-si*old_mx[2*3+1]+co*old_mx[0*3+1];
      so3[2*3+2]= co*old_mx[2*3+2]+si*old_mx[0*3+2];
      so3[0*3+2]=-si*old_mx[2*3+2]+co*old_mx[0*3+2];
      so3[2*3+0]= co*old_mx[2*3+0]+si*old_mx[0*3+0];
      so3[0*3+0]=-si*old_mx[2*3+0]+co*old_mx[0*3+0];
    }
  else				/* z rotation */
    {
      so3[0*3+2]= co*old_mx[0*3+2]+si*old_mx[1*3+2];
      so3[1*3+2]=-si*old_mx[0*3+2]+co*old_mx[1*3+2];
      so3[0*3+0]= co*old_mx[0*3+0]+si*old_mx[1*3+0];
      so3[1*3+0]=-si*old_mx[0*3+0]+co*old_mx[1*3+0];
      so3[0*3+1]= co*old_mx[0*3+1]+si*old_mx[1*3+1];
      so3[1*3+1]=-si*old_mx[0*3+1]+co*old_mx[1*3+1];
    }
}
#endif


MODULE = Math::SO3		PACKAGE = Math::SO3		


void
invert(...)
	CODE:
	if(   items<1 
           || (items&1)==0
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)

	{
		croak(croak_invert);
	}
	else
	{
		Math__SO3 so3;
		double x;

		so3=(Math__SO3)SvPV(SvRV(ST(0)), PL_na);

		x=so3[0*3+1];so3[0*3+1]=so3[1*3+0];so3[1*3+0]=x;
		x=so3[0*3+2];so3[0*3+2]=so3[2*3+0];so3[2*3+0]=x;
		x=so3[1*3+2];so3[1*3+2]=so3[2*3+1];so3[2*3+1]=x;
	}


void
turn(...)
	CODE:
	if(   items<1 
           || (items&1)==0
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)
	{
	croak(croak_turn);
	}
	else
	{
		int i, axis;
		char *axis_str;
		double angle;
		Math__SO3 so3;

		so3=(Math__SO3)(SvPV(SvRV(ST(0)), PL_na));

		for(i=1;i<items;i+=2)
		{
		  axis_str=(char *)SvPV(ST(i), PL_na); /* XXX PL_na in perl5.005! */
		  if(axis_str[0]=='x')
		    {
		      axis=0;
		    }
		  else if(axis_str[0]=='y')
		    {
		      axis=1;
		    }
		  else if(axis_str[0]=='z')
		    {
		      axis=2;
		    }
		  else
		    {	
		      croak(croak_turn);
		    }

		  angle=SvNV(ST(1+i));

		  if(axis_str[1]=='d')
		    {
		      angle*=M_PI/180;
		    }
		  else if(axis_str[1]!=0 && axis_str[1]!='r')
		    {
		      croak(croak_turn);
		    }

		  do_turn(so3, axis, angle);
		}
	}



void
combine(...)
	CODE:
	if(   items!=2 
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG
           || SvTYPE(SvRV(ST(1)))!=SVt_PVMG)

	{
	  croak(croak_combine);
	}
	else
	{
	 /* column 1 and 2 are computed as matrix product, 
            2 is orthogonalized, 3 is cross-product. */

		int i;
		Math__SO3 rot_b, rot_a;
		double inv_norm, sprod, buffer[9];

		rot_b=(Math__SO3)(SvPV(SvRV(ST(0)), PL_na));
		rot_a=(Math__SO3)(SvPV(SvRV(ST(1)), PL_na));

		for(i=0;i<9;i++)buffer[i]=rot_b[i];

		rot_b[0*3+0]= rot_a[0*3+0]*buffer[0*3+0]
                             +rot_a[0*3+1]*buffer[1*3+0]
                             +rot_a[0*3+2]*buffer[2*3+0];

		rot_b[1*3+0]= rot_a[1*3+0]*buffer[0*3+0]
                             +rot_a[1*3+1]*buffer[1*3+0]
                             +rot_a[1*3+2]*buffer[2*3+0];

		rot_b[2*3+0]= rot_a[2*3+0]*buffer[0*3+0]
                             +rot_a[2*3+1]*buffer[1*3+0]
                             +rot_a[2*3+2]*buffer[2*3+0];

		inv_norm=1.0/sqrt( rot_b[0*3+0]*rot_b[0*3+0]
                                  +rot_b[1*3+0]*rot_b[1*3+0]
                                  +rot_b[2*3+0]*rot_b[2*3+0]);

		rot_b[0*3+0]*=inv_norm;
		rot_b[1*3+0]*=inv_norm;
		rot_b[2*3+0]*=inv_norm;

		rot_b[0*3+1]= rot_a[0*3+0]*buffer[0*3+1]
                             +rot_a[0*3+1]*buffer[1*3+1]
                             +rot_a[0*3+2]*buffer[2*3+1];

		rot_b[1*3+1]= rot_a[1*3+0]*buffer[0*3+1]
                             +rot_a[1*3+1]*buffer[1*3+1]
                             +rot_a[1*3+2]*buffer[2*3+1];

		rot_b[2*3+1]= rot_a[2*3+0]*buffer[0*3+1]
                             +rot_a[2*3+1]*buffer[1*3+1]
                             +rot_a[2*3+2]*buffer[2*3+1];

		sprod= rot_b[0*3+0]*rot_b[0*3+1]
                      +rot_b[1*3+0]*rot_b[1*3+1]
		      +rot_b[2*3+0]*rot_b[2*3+1];

		rot_b[0*3+1]-=sprod*rot_b[0*3+0];
		rot_b[1*3+1]-=sprod*rot_b[1*3+0];
		rot_b[2*3+1]-=sprod*rot_b[2*3+0];

		rot_b[0*3+2]=rot_b[1*3+0]*rot_b[2*3+1]-rot_b[2*3+0]*rot_b[1*3+1];
		rot_b[1*3+2]=rot_b[2*3+0]*rot_b[0*3+1]-rot_b[0*3+0]*rot_b[2*3+1];
		rot_b[2*3+2]=rot_b[0*3+0]*rot_b[1*3+1]-rot_b[1*3+0]*rot_b[0*3+1];
	}


# turn_round_axis(rotation, axis, angle, <opt. "d" or "r">)
#
# How to do it:
#
# Initially, one might think that the simple formula
#
# e_r' = n*(n*e_r) + (e_r-n*(n*e_r))*cos(alpha)+ n x (e_r-n*(n*e_r))*sin(alpha)
#
# Could be implemented 1:1; this is, of course, not the case, since if e_r-n*(n*e_r)
# comes close to zero, taking the cross product with n will give strange results.
#
# Therefore, we write this as:
#
# e_r' = e_r*cos(alpha)+(1-cos(alpha))*n*(n*e_r)+ n x e_r*sin(alpha)
#
# Note: axis is given in the SPACE system!

void
turn_round_axis(...)
	CODE:
	if((items!=3 && items!=4)
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG
           || (!(SvPOK(ST(1)))))
	{
	  croak(croak_turn_round_axis);
	}
	else
	{
	  double *so3, *axis, angle, co, si;
	  double r_base[3], r_sin[3];
          double e_r[3], e_n[3], inv_len, sprod, norm;

	  so3=(double *)SvPV(SvRV(ST(0)), PL_na);
	  axis=(double *)SvPV(ST(1), PL_na);

	  angle=-SvNV(ST(2));

	  if(items==4)
	  {
             char *angle_spec;

	     angle_spec=(char *)SvPV(ST(3), PL_na);
             if(angle_spec[0]=='d')
               {
                angle*=M_PI/180;
	       }
             else if(angle_spec[0]!='r' && angle_spec[0]!=0)
	       {
                croak(croak_turn_round_axis);
               }
          }
	  
          co=cos(angle);
	  si=sin(angle);

          inv_len=sqrt( axis[0]*axis[0]
                       +axis[1]*axis[1]
                       +axis[2]*axis[2]);

	  if(inv_len==0)
          {
           croak("Math::SO3::turn_round_axis: axis is null vector!");
          }

	  inv_len=1/inv_len;

          /* This algorithm deals with body coordinates. Therefore, 
             we have to translate the coordinates of the axis to
             body coordinates first. 
          */
          e_n[0]=inv_len*(axis[0]*so3[0*3+0]+axis[1]*so3[0*3+1]+axis[2]*so3[0*3+2]);
          e_n[1]=inv_len*(axis[0]*so3[1*3+0]+axis[1]*so3[1*3+1]+axis[2]*so3[1*3+2]);
          e_n[2]=inv_len*(axis[0]*so3[2*3+0]+axis[1]*so3[2*3+1]+axis[2]*so3[2*3+2]);


          /* 
             Now, turn every column vector. 
             They represent space-base in body coordinates.
           */

          inv_len=sqrt( so3[0*3+0]*so3[0*3+0]
                       +so3[1*3+0]*so3[1*3+0]
                       +so3[2*3+0]*so3[2*3+0]);

	  if(inv_len!=0)inv_len=1/inv_len;

          e_r[0]=so3[0*3+0]*inv_len;
          e_r[1]=so3[1*3+0]*inv_len;
          e_r[2]=so3[2*3+0]*inv_len;

          sprod=e_r[0]*e_n[0]+e_r[1]*e_n[1]+e_r[2]*e_n[2];

          r_base[0]=e_n[0]*sprod;
          r_base[1]=e_n[1]*sprod;
          r_base[2]=e_n[2]*sprod;

	  r_sin[0]=e_n[1]*e_r[2]-e_n[2]*e_r[1];
	  r_sin[1]=e_n[2]*e_r[0]-e_n[0]*e_r[2];
	  r_sin[2]=e_n[0]*e_r[1]-e_n[1]*e_r[0];

	  so3[0*3+0]=co*so3[0*3+0]+(1-co)*r_base[0]+si*r_sin[0];
	  so3[1*3+0]=co*so3[1*3+0]+(1-co)*r_base[1]+si*r_sin[1];
	  so3[2*3+0]=co*so3[2*3+0]+(1-co)*r_base[2]+si*r_sin[2];


          inv_len=sqrt( so3[0*3+1]*so3[0*3+1]
                       +so3[1*3+1]*so3[1*3+1]
                       +so3[2*3+1]*so3[2*3+1]);

	  if(inv_len!=0)inv_len=1/inv_len;

          e_r[0]=so3[0*3+1]*inv_len;
          e_r[1]=so3[1*3+1]*inv_len;
          e_r[2]=so3[2*3+1]*inv_len;

          sprod=e_r[0]*e_n[0]+e_r[1]*e_n[1]+e_r[2]*e_n[2];

          r_base[0]=e_n[0]*sprod;
          r_base[1]=e_n[1]*sprod;
          r_base[2]=e_n[2]*sprod;

	  r_sin[0]=e_n[1]*e_r[2]-e_n[2]*e_r[1];
	  r_sin[1]=e_n[2]*e_r[0]-e_n[0]*e_r[2];
	  r_sin[2]=e_n[0]*e_r[1]-e_n[1]*e_r[0];

	  so3[0*3+1]=co*so3[0*3+1]+(1-co)*r_base[0]+si*r_sin[0];
	  so3[1*3+1]=co*so3[1*3+1]+(1-co)*r_base[1]+si*r_sin[1];
	  so3[2*3+1]=co*so3[2*3+1]+(1-co)*r_base[2]+si*r_sin[2];


          inv_len=sqrt( so3[0*3+2]*so3[0*3+2]
                       +so3[1*3+2]*so3[1*3+2]
                       +so3[2*3+2]*so3[2*3+2]);

	  if(inv_len!=0)inv_len=1/inv_len;

          e_r[0]=so3[0*3+2]*inv_len;
          e_r[1]=so3[1*3+2]*inv_len;
          e_r[2]=so3[2*3+2]*inv_len;

          sprod=e_r[0]*e_n[0]+e_r[1]*e_n[1]+e_r[2]*e_n[2];

          r_base[0]=e_n[0]*sprod;
          r_base[1]=e_n[1]*sprod;
          r_base[2]=e_n[2]*sprod;

	  r_sin[0]=e_n[1]*e_r[2]-e_n[2]*e_r[1];
	  r_sin[1]=e_n[2]*e_r[0]-e_n[0]*e_r[2];
	  r_sin[2]=e_n[0]*e_r[1]-e_n[1]*e_r[0];

	  so3[0*3+2]=co*so3[0*3+2]+(1-co)*r_base[0]+si*r_sin[0];
	  so3[1*3+2]=co*so3[1*3+2]+(1-co)*r_base[1]+si*r_sin[1];
	  so3[2*3+2]=co*so3[2*3+2]+(1-co)*r_base[2]+si*r_sin[2];

	  /* XXX This is just a ugly hack to guarantee 
             multiple turn_round_axis() calls won't build up big
	     numerical error. Could improve speed by a factor 2
	     if I implemented the correction code from do_turn()
             in turn_round_axis().
          */
	 /*do_turn(so3, 0,0);*/
	}


# Destructively modify (translate) a set of column vectors,
# space coords -> body coords
#
# $so3->translate_vectors($vec1, $vec2, $vec3, ...)

void
translate_vectors(...)
	CODE:
	if(   items<1
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)

	{
	  croak(croak_translate);
	}
	else
	{
	  int i;
	  Math__SO3 so3;
	  double x,y,z, *vec;

	  so3=(Math__SO3)(SvPV(SvRV(ST(0)), PL_na));

	  for(i=1;i<items;i++)
	    {
	      if(!SvPOK(ST(i)))
		{
		  croak(croak_translate);
		}
	    }
	  for(i=1;i<items;i++)
	    {
	      vec=(double *)SvPV(ST(i),PL_na);
	      x=vec[0];
	      y=vec[1];
	      z=vec[2];
	      
	      vec[0]=so3[0*3+0]*x+so3[0*3+1]*y+so3[0*3+2]*z;
	      vec[1]=so3[1*3+0]*x+so3[1*3+1]*y+so3[1*3+2]*z;
	      vec[2]=so3[2*3+0]*x+so3[2*3+1]*y+so3[2*3+2]*z;
	    }
	}



# Destructively modify (translate) a set of column vectors,
# body coords -> space coords
#
# $so3->inv_translate_vectors($vec1, $vec2, $vec3, ...)

void
inv_translate_vectors(...)
	CODE:
	if(   items<1
           || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)

        {
	  croak(croak_inv_translate);
	}
	else
	{
	  int i;
	  Math__SO3 so3;
	  double x,y,z, *vec;

	  so3=(Math__SO3)(SvPV(SvRV(ST(0)), PL_na));

	  for(i=1;i<items;i++)
	    {
	      if(!SvPOK(ST(i)))
		{
		  croak(croak_inv_translate);
		}
	    }
	  for(i=1;i<items;i++)
	    {
	      vec=(double *)SvPV(ST(i),PL_na);
	      x=vec[0];
	      y=vec[1];
	      z=vec[2];
	      /* for orthogonal matrices, X^T = X^-1 */
	      vec[0]=so3[0*3+0]*x+so3[1*3+0]*y+so3[2*3+0]*z;
	      vec[1]=so3[0*3+1]*x+so3[1*3+1]*y+so3[2*3+1]*z;
	      vec[2]=so3[0*3+2]*x+so3[1*3+2]*y+so3[2*3+2]*z;
	    }
	}

# Return turning angle and direction vector corresponding to a given
# so3 matrix.
#
# We use two tricks:
#
# * the trace of a matrix is conjugation invariant, and (look at x rotation)
#   here it's just 1+2*cos(alpha); this gives us alpha.
#
# * We use a (normalized) vector v1=(1,0,0)^T, turn it once to get v2, 
#   turn it once more to get v3;
#   the normalized cross product (v3-v1)x(v2-v1) will be the rotation 
#   direction, unless it is too small; in this case, we redo the computation
#   with v1=(0,1,0)^T.
#   Note that this trick does not work with an angle of 180 degrees;
#   here, we take an arbitrary vector and its rotated image and compute the
#   normalized sum. Take a different vector if norm is zero. There are 
#   cases when we must do this three times.
#
#   XXX have to put a bit more thought into this. Does it really work that way,
#   or did I still miss a point?

void
turning_angle_and_dir(...)
	PPCODE:
	{
          double angle, *dir, v2[3], v3[3], norm;
          char *cdir;

	  if(   (items!=1 && items != 2)
             || SvTYPE(SvRV(ST(0)))!=SVt_PVMG
             || 0==(cdir=alloca(1+3*sizeof(double))))
          {
             croak(croak_turning_angle_and_dir);
          }
          else
	  {
	    Math__SO3 so3;
            so3=(Math__SO3)(SvPV(SvRV(ST(0)), PL_na));
            cdir[3*sizeof(double)]=0;
            dir=(double *)cdir;

            angle=my_acos(0.5*(so3[0*3+0]+so3[1*3+1]+so3[2*3+2]-1));
            if(angle==M_PI || angle==-M_PI)
            {
             /* first, try (1,0,0)^T */

             v2[0]=so3[0*3+0];
             v2[1]=so3[1*3+0];
             v2[2]=so3[2*3+0];

             dir[0]=v2[0]+1;
             dir[1]=v2[1];
             dir[2]=v2[2];

             norm=sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]);

             if(norm<0.0001)
               {
                /* try (0,1,0)^T */
                v2[0]=so3[0*3+1];
                v2[1]=so3[1*3+1];
                v2[2]=so3[2*3+1];

                dir[0]=v2[0];
                dir[1]=v2[1]+1;
                dir[2]=v2[2];

                norm=sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]);
               }

             if(norm<0.0001)
               {
                /* lot of bad luck: (x,y,0)-plane "nearly" perpendicular to
                   turning direction. Now we simply could take z-direction,
                   but maybe this is a somewhat bad estimate; so, 
                   we play the same game once again with the (1,0,1) vector.
                 */

                /* try (0,1,0)^T */
                v2[0]=so3[0*3+0]+so3[0*3+2];
                v2[1]=so3[1*3+0]+so3[1*3+2];
                v2[2]=so3[2*3+0]+so3[2*3+2];

                dir[0]=v2[0]+1;
                dir[1]=v2[1];
                dir[2]=v2[2]+1;

                norm=sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]);
               }


             dir[0]/=norm;
             dir[1]/=norm;
             dir[2]/=norm;
            }
            else
            {

              v2[0]=so3[0*3+0];
              v2[1]=so3[1*3+0];
              v2[2]=so3[2*3+0];
  
              v3[0]=so3[0*3+0]*v2[0]+so3[0*3+1]*v2[1]+so3[0*3+2]*v2[2];
  	      v3[1]=so3[1*3+0]*v2[0]+so3[1*3+1]*v2[1]+so3[1*3+2]*v2[2];
  	      v3[2]=so3[2*3+0]*v2[0]+so3[2*3+1]*v2[1]+so3[2*3+2]*v2[2];
  
              dir[0]=v3[1]*v2[2]-v3[2]*v2[1];
              dir[1]=v3[2]*(v2[0]-1)-(v3[0]-1)*v2[2];
              dir[2]=(v3[0]-1)*v2[1]-v3[1]*(v2[0]-1);
  
              norm=sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]);
              if(norm<0.0001) 
              {
               /* "too close" -- gives numeric roundoff errors; 
                  redo with y vec */
  
                v2[0]=so3[0*3+1];
                v2[1]=so3[1*3+1];
                v2[2]=so3[2*3+1];
    
              v3[0]=so3[0*3+0]*v2[0]+so3[0*3+1]*v2[1]+so3[0*3+2]*v2[2];
    	      v3[1]=so3[1*3+0]*v2[0]+so3[1*3+1]*v2[1]+so3[1*3+2]*v2[2];
    	      v3[2]=so3[2*3+0]*v2[0]+so3[2*3+1]*v2[1]+so3[2*3+2]*v2[2];
    
                dir[0]=(v3[1]-1)*v2[2]-v3[2]*(v2[1]-1);
                dir[1]=v3[2]*v2[0]-v3[0]*v2[2];
                dir[2]=v3[0]*(v2[1]-1)-(v3[1]-1)*v2[0];
    
                norm=sqrt(dir[0]*dir[0]+dir[1]*dir[1]+dir[2]*dir[2]);
              }
  
              if(norm<0.0001) /* can only happen for identity. */
              {
               dir[0]=0;
               dir[0]=0;
               dir[0]=1;
              }
              else
              {
                dir[0]/=norm;
                dir[1]/=norm;
                dir[2]/=norm;
              }
            }  
            EXTEND(sp,2);
            if(items==2)
            {
             char *angle_spec;

             angle_spec=(char *)SvPV(ST(1), PL_na);
             if(angle_spec[0]=='d')
               {
                angle*=180/M_PI;
               }
             else if(angle_spec[0]!='r' && angle_spec[0]!=0)
               {
                croak(croak_turning_angle_and_dir);
               }
            }
            PUSHs(sv_2mortal(newSVnv(angle)));
            PUSHs(sv_2mortal(newSVpv(cdir,3*sizeof(double))));
	  }
        }

# Standard euler angles
#
# alas, at first I tried to do all the unwinding in my head. Then, in
# the testing phase, I noticed that it worked "in most cases"; what I
# had gotten wrong were basically the constraints on the intermediate
# angle. False hubris. Now, let's do it the dumb way by formula:
# zxz Euler angles are (phi, theta, psi) = (p,q,r) {Euler's nomenclature}
# Therefore,
#                   ( cos r cos p - sin r cos q sin p  | cos r sin p + sin r cos q cos p  | sin r sin q )
#                   (                                  |                                  |             )
# Dz(r)Dx(q)Dz(p) = ( -sin r cos p - cos r cos q sin p | -sin r sin p + cos r cos q cos p | cos r sin q )
#                   (                                  |                                  |             )
#                   (  sin q sin p                     | -sin q cos p                     | cos q       )
#
# What we do:
#
# (1) Determine q (theta) from [2][2] element.
# (2) Determine r (psi)   from [0][2] and [1][2] elements. If theta=0, we can also set psi=0. 
#     (Since all that remains is a z-rotation or z-rotation with 180deg x-rotation, 
#     both characterized by a single angle)
# (3) Do some math to determine phi from [1][0] and [1][1] elements if theta=0, 
#     otherwise use [2][0] and [2][1] elements.


void
euler_angles_zxz(...)
	PPCODE:
         {
	  if(   (items!=1 && items!=2)
             || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)
          {
             croak(croak_euler_angles_zxz);
          }
          else
          {
            int i;
            double phi, theta, psi, cos_theta, sin_theta, cos_psi, sin_psi, sin_phi, cos_phi;
            Math__SO3 so3;

            so3=(double *)(SvPV(SvRV(ST(0)),PL_na));
	    cos_theta=so3[2*3+2];
            theta=my_acos(cos_theta);
            sin_theta=sin(theta);

            if(sin_theta==0)
            {
	     psi=sin_psi=0; cos_psi=1;

             /* note that cos_psi=1, cos_theta=+-1, sin_psi=0 here; looking close reveals that
                the [0][0] element is just cos_phi, and [0][1] element is sin_phi */

             sin_phi=so3[0*3+1];
             cos_phi=so3[0*3+0];

             phi=atan2(sin_phi, cos_phi);
            }
            else
            {
	     sin_psi=so3[0*3+2]/sin_theta;
	     cos_psi=so3[1*3+2]/sin_theta;
             psi=atan2(sin_psi, cos_psi);

             sin_phi=so3[2*3+0]/sin_theta;
             cos_phi=-so3[2*3+1]/sin_theta;

             phi=atan2(sin_phi, cos_phi);
            }

            if(phi<0)phi+=2*M_PI;
            if(psi<0)psi+=2*M_PI;

            if(items==2)
            {
             char *angle_spec;

             angle_spec=(char *)SvPV(ST(1), PL_na);
             if(angle_spec[0]=='d')
               {
                phi*=180/M_PI;
                theta*=180/M_PI;
                psi*=180/M_PI;
               }
             else if(angle_spec[0]!='r' && angle_spec[0]!=0)
               {
                croak(croak_euler_angles_zxz);
               }
            }

            EXTEND(sp,3);
            PUSHs(sv_2mortal(newSVnv(phi)));
            PUSHs(sv_2mortal(newSVnv(theta)));
            PUSHs(sv_2mortal(newSVnv(psi)));
          }
         }



# this gives heading, pitch, roll. (h,p,r)
#
# Constraints: -90deg<pitch<=90deg
#
#                   ( cos r cos h - sin r sin p sin h | cos r sin h + sin r sin p cos h | - sin r cos p )
#                   (                                                                                   )
# Dy(r)Dx(p)Dz(h) = ( -cos p sin h                    | cos p cos h                     | sin p         )
#                   (                                                                                   )
#                   ( sin r cos h + cos r sin p sin h | sin r sin h - cos r sin p cos h | cos r cos p   )
#
# Strategy:
#
# (1) use [0][2] and [2][2] to determine abs cos p
# (2) use [1][2] to determine if p>=0 or p<0
# (3) if cos_p!=0, use [1][x] and [x][2] to determine pitch, roll
# (4) otherwise, things get bad.
#     Case #1: sin_p>0 (approx. 1)
#
#     [0][0]: cos r cos h - sin r sin h     => cos (r+h)
#     [0][2]: sin r cos h + cos r sin h     => sin (r+h)
#
#     Case #2: sin_p<0 (approx. 1)
#
#     [0][0]: cos r cos -h - sin r sin -h     => cos (r-h)
#     [0][2]: sin r cos -h + cos r sin -h     => sin (r-h)
#
# Heading does not make sense for an airplane going straight up or straight down.
# Therefore, we take this last angle to be all roll.
#
# => heading=0, roll=atan2(sin_roll, cos_roll)

void 
euler_angles_yxz(...)
	PPCODE:
	{
          int i;
          double heading, pitch, roll, cos_heading, cos_pitch, cos_roll, sin_heading, sin_pitch, sin_roll;
          Math__SO3 so3;

	  if(   (items!=1 && items!=2)
             || SvTYPE(SvRV(ST(0)))!=SVt_PVMG)
          {
             croak(croak_euler_angles_zxz);
          }
          else
          {
            so3=(double *)(SvPV(SvRV(ST(0)),PL_na));

	    cos_pitch=sqrt(so3[0*3+2]*so3[0*3+2]+so3[2*3+2]*so3[2*3+2]); /* abs cos p */
            pitch=my_acos(cos_pitch);
            sin_pitch=so3[1*3+2];
            if(sin_pitch<0)pitch=-pitch;
            
            if(cos_pitch==0)
	    {
	     heading=0;

             sin_roll=so3[0*3+2];
             cos_roll=so3[0*3+0];

             roll=atan2(sin_roll, cos_roll);
            }
            else
            {
             sin_heading=-so3[1*3+0]/cos_pitch;
             cos_heading=so3[1*3+1]/cos_pitch;

             sin_roll=-so3[0*3+2]/cos_pitch;
             cos_roll=so3[2*3+2]/cos_pitch;

             heading=atan2(sin_heading, cos_heading);
             roll=atan2(sin_roll, cos_roll);
            }

            if(roll<0)roll+=2*M_PI;
            if(heading<0)heading+=2*M_PI;

            if(items==2)
            {
             char *angle_spec;

             angle_spec=(char *)SvPV(ST(1), PL_na);
             if(angle_spec[0]=='d')
               {
                heading*=180/M_PI;
                pitch*=180/M_PI;
                roll*=180/M_PI;
               }
             else if(angle_spec[0]!='r' && angle_spec[0]!=0)
               {
                croak(croak_euler_angles_zxz);
               }
            }

            EXTEND(sp,3);
            PUSHs(sv_2mortal(newSVnv(heading)));
            PUSHs(sv_2mortal(newSVnv(pitch)));
            PUSHs(sv_2mortal(newSVnv(roll)));
          }
        }
