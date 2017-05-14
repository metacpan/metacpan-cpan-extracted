# Copyright (C) 1998 Bernhard Reiter and Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.

# This is the Extrusion -> polyrep code, used by VRMLC.pm to generate
# VRMLFunc.xs &c.

# Extrusion generates 2 triangles per each extrusion step (like elevgrid..)

'
/*****begin of Member Extrusion	*/
/* This code originates from the file VRMLExtrusion.pm */
int nspi = $f_n(spine);			/* number of spine points	*/
int nsec = $f_n(crossSection);		/* no. of points in the 2D curve*/
int nori = $f_n(orientation);		/* no. of given orientators
					   which rotate the calculated SCPs =
					   spine-aligned cross-section planes*/ 
int nsca = $f_n(scale);			/* no. of scale parameters	*/
struct SFColor *spine =$f(spine);	/* vector of spine vertices	*/
struct SFVec2f *curve =$f(crossSection);/* vector of 2D curve points	*/
struct SFRotation *orientation=$f(orientation);/*vector of SCP rotations*/

struct VRML_PolyRep *rep_=this_->_intern;/*internal rep, we want to fill*/

/* the next four variables will point at members of *rep		*/
int   *cindex;				/* field containing indices into
					   the coord vector. Three together
					   indicate which points form a 
					   triangle			*/
float *coord;				/* contains vertices building the
					   triangles as x y z values	*/
int   *norindex;			/* indices into *normal		*/
float *normal;				/* (filled in a different function)*/ 


int ntri = 2 * (nspi-1) * (nsec-1);	/* no. of triangles to be used
					   to represent all, but the caps */
int nctri=0;				/* no. of triangles for both caps*/

int ncolinear_at_begin=0;		/* no. of triangles which need
					to be skipped, because curve-points
					are in one line at start of curve*/
int ncolinear_at_end=0;			/* no. of triangles which need
					to be skipped, because curve-points
					are in one line at end of curve*/

int spi,sec,triind,pos_of_last_zvalue;	/* help variables 		*/
int next_spi, prev_spi;
int t;					/* another loop var		*/


int closed = 0;				/* is spine  closed?		*/
int curve_closed=0;			/* is the 2D curve closed?	*/
int spine_is_one_vertix;		/* only one real spine vertix	*/

float spxlen,spylen,spzlen;		/* help vars for scaling	*/

					/* def:struct representing SCPs	*/
struct SCP { 				/* spine-aligned cross-section plane*/
	struct pt y;			/* y axis of SCP		*/
	struct pt z;			/* z axis of SCP		*/
	int prev,next;			/* index in SCP[]
					prev/next different vertix for 
					calculation of this SCP		*/
	   };

struct SCP *SCP;			/* dyn. vector rep. the SCPs	*/

struct pt spm1,spc,spp1,spcp,spy,spz,spoz,spx;	/* help vertix vars	*/


/* do we have a closed curve?						*/
if(curve[0].c[0] == curve[nsec-1].c[0] &&
   curve[0].c[1] == curve[nsec-1].c[1])
	curve_closed=1;

/* check if the spline is closed					*/

if(spine[0].c[0] == spine[nspi-1].c[0] &&
   spine[0].c[1] == spine[nspi-1].c[1] &&
   spine[0].c[2] == spine[nspi-1].c[2]) 
	closed = 1;
 
 

/************************************************************************
 * calc number of triangles per cap, if caps are enabled and possible	
 */

if($f(beginCap)||$f(endCap)) {
	if(curve_closed?nsec<4:nsec<3) {
		die("Only two real vertices in crossSection. Caps not possible!");
	}

	if(verbose && closed && curve_closed) {
		printf("Spine and crossSection-curve are closed - how strange! ;-)\n");
		/* maybe we want to fly in this tunnel? Or it is semi 
		   transparent somehow? It is possible to create
		   nice figures if you rotate the cap planes... */
	}

	if(!$f(convex)) { /* not convex	*/
		printf("[Extrusion crossSection polygon might be not convex!"
			"let`s try it anyway!]\n");
	/* XXX fix with help from some sort of tessilation		*/
	}

	if(curve_closed)	nctri=nsec-3;
	else			nctri=nsec-2;	


	/* check if there are colinear points at the beginning of the curve*/
	sec=0;
	while(sec+2<=nsec-1 && 
		/* to find out if two vectors a and b are colinear, 
		   try a.x*b.y=a.y*b.x					*/
		APPROX(0,    (curve[sec+1].c[0]-curve[0].c[0])
			    *(curve[sec+2].c[1]-curve[0].c[1])
			  -  (curve[sec+1].c[1]-curve[0].c[1])
			    *(curve[sec+2].c[0]-curve[0].c[0]))	
	     ) ncolinear_at_begin++, sec++;

	/* check if there are colinear points at the end of the curve
		in line with the very first point, because we want to
		draw the triangle to there.				*/
	sec=curve_closed?(nsec-2):(nsec-1);
	while(sec-2>=0 && 
		APPROX(0,    (curve[sec  ].c[0]-curve[0].c[0])
			    *(curve[sec-1].c[1]-curve[0].c[1])
			  -  (curve[sec  ].c[1]-curve[0].c[1])
			    *(curve[sec-1].c[0]-curve[0].c[0]))	
	     ) ncolinear_at_end++,sec--;

	nctri-= ncolinear_at_begin+ncolinear_at_end;
	if(nctri<1) {
		/* no triangle left :(	*/
		die("All in crossSection points colinear. Caps not possible!");
 	}
 
 
	/* so we have calculated nctri for one cap, but we might have two*/
	nctri= (($f(beginCap))?nctri:0) + (($f(endCap))?nctri:0) ;
}
 
/************************************************************************
 * prepare for filling *rep
 */
 
rep_->ntri = ntri + nctri;	/* Thats the no. of triangles representing
				the whole Extrusion Shape.		*/
 
/* get some memory							*/
cindex  = rep_->cindex   = malloc(sizeof(*(rep_->cindex))*3*(rep_->ntri));
coord   = rep_->coord    = malloc(sizeof(*(rep_->coord))*nspi*nsec*3);
 
normal  = rep_->normal   = malloc(sizeof(*(rep_->normal))*3*(rep_->ntri));
norindex= rep_->norindex = malloc(sizeof(*(rep_->norindex))*3*(rep_->ntri));
 
/*memory for the SCPs. Only needed in this function. Freed later	*/
SCP     = malloc(sizeof(struct SCP)*nspi);
 
/* in C always check if you got the mem you wanted...  >;->		*/
if(!(cindex && coord && normal && norindex && SCP )) {
	die("Not enough memory for Extrusion node triangles... ;(");
} 
 

/************************************************************************
 * calculate all SCPs 
 */

spine_is_one_vertix=0;

/* fill the prev and next values in the SCP structs first
 *
 *	this is so complicated, because spine vertices can be the same
 *	They should have exactly the same SCP, therefore only one of
 *	an group of sucessive equal spine vertices (now called SESVs)
 *	must be used for calculation.
 *	For calculation the previous and next different spine vertix
 *	must be known. We save that info in the prev and next fields of
 *	the SCP struct. 
 *	Note: We have start and end SESVs which will be treated differently
 *	depending on whether the spine is closed or not
 *
 */
 
for(spi=0; spi<nspi;spi++){
	for(next_spi=spi+1;next_spi<nspi;next_spi++) {
		VEC_FROM_CDIFF(spine[spi],spine[next_spi],spp1);
		if(!APPROX(VECSQ(spp1),0))
			break;
	}
	if(next_spi<nspi) SCP[next_spi].prev=next_spi-1;

	if(verbose) printf("spi=%d next_spi=%d\n",spi,next_spi); /**/
	prev_spi=spi-1;
	SCP[spi].next=next_spi;
	SCP[spi].prev=prev_spi;
	
	while(next_spi>spi+1) { /* fill gaps */
		spi++;
		SCP[spi].next=next_spi;
		SCP[spi].prev=prev_spi;
	}
}
/* now:	start-SEVS .prev fields contain -1				*/
/* 	and end-SEVS .next fields contain nspi				*/


if(SCP[0].next==nspi) {
	spine_is_one_vertix=1;
	printf("All spine vertices are the same!\n");

	/* initialize all y and z values with zero, they will		*/
	/* be treated as colinear case later then			*/
	SCP[0].z.x=0; SCP[0].z.y=0; SCP[0].z.z=0;
	SCP[0].y=SCP[0].z;
	for(spi=1;spi<nspi;spi++) {
		SCP[spi].y=SCP[0].y;
		SCP[spi].z=SCP[0].z;
	}
}else{
	if(verbose) {
		for(spi=0;spi<nspi;spi++) {
			printf("SCP[%d].next=%d, SCP[%d].prev=%d\n",
				spi,SCP[spi].next,spi,SCP[spi].prev);
		}
	}
	
	/* find spine vertix different to the first spine vertix	*/
	spi=0; 		
	while(SCP[spi].prev==-1) spi++;

	/* find last spine vertix different to the last 		*/
	t=nspi-1; 
	while(SCP[t].next==nspi) t--;

	/* for all but the first + last really different spine vertix	*/
	for(; spi<=t; spi++) {
		/* calc y 	*/
		VEC_FROM_CDIFF(spine[SCP[spi].next],spine[SCP[spi].prev],SCP[spi].y);
		/* calc z	*/
		VEC_FROM_CDIFF(spine[SCP[spi].next],spine[spi],spp1);
		VEC_FROM_CDIFF(spine[SCP[spi].prev],spine[spi],spm1);
 		VECCP(spp1,spm1,SCP[spi].z);
 	}
 
 	if(closed) {
 		/* calc y for first SCP				*/
		VEC_FROM_CDIFF(spine[SCP[0].next],spine[SCP[nspi-1].prev],SCP[0].y); 
 		/* the last is the same as the first */	
 		SCP[nspi-1].y=SCP[0].y;	
        
		/* calc z */
		VEC_FROM_CDIFF(spine[SCP[0].next],spine[0],spp1);
		VEC_FROM_CDIFF(spine[SCP[nspi-1].prev],spine[0],spm1);
		VECCP(spp1,spm1,SCP[0].z);
		/* the last is the same as the first */	
		SCP[nspi-1].z=SCP[0].z;	
		
 	} else {
 		/* calc y for first SCP				*/
		VEC_FROM_CDIFF(spine[SCP[0].next],spine[0],SCP[0].y);

 		/* calc y for the last SCP			*/
		VEC_FROM_CDIFF(spine[nspi-1],spine[SCP[nspi-1].prev],SCP[nspi-1].y);
 
		/* z for the start SESVs is the same as for the next SCP */
		SCP[0].z=SCP[SCP[0].next].z; 
 		/* z for the last SCP is the same as for the one before the last*/
		SCP[nspi-1].z=SCP[SCP[nspi-1].prev].z; 
		
	} /* else */
	
	/* fill the other start SESVs SCPs*/
	spi=1; 
	while(SCP[spi].prev==-1) {
		SCP[spi].y=SCP[0].y;
		SCP[spi].z=SCP[0].z;
		spi++;
	}
	/* fill the other end SESVs SCPs*/
	t=nspi-2; 
	while(SCP[t].next==nspi) {
		SCP[t].y=SCP[nspi-1].y;
		SCP[t].z=SCP[nspi-1].z;
		t--;
	}

} /* else */


/* We have to deal with colinear cases, what means z=0			*/
pos_of_last_zvalue=-1;		/* where a zvalue is found */
for(spi=0;spi<nspi;spi++) {
	if(pos_of_last_zvalue>=0) { /* already found one?		*/
		if(APPROX(VECSQ(SCP[spi].z),0)) 
			SCP[spi].z= SCP[pos_of_last_zvalue].z;

		pos_of_last_zvalue=spi;	
	} else 
		if(!APPROX(VECSQ(SCP[spi].z),0)) {
			/* we got the first, fill the previous		*/
			if(verbose) printf("Found z-Value!\n");
			for(t=spi-1; t>-1; t--)
				SCP[t].z=SCP[spi].z;
 			pos_of_last_zvalue=spi;	
		}
}
 
if(verbose) printf("pos_of_last_zvalue=%d\n",pos_of_last_zvalue);
 
 
/* z axis flipping, if VECPT(SCP[i].z,SCP[i-1].z)<0 			*/
/* we can do it here, because it is not needed in the all-colinear case	*/
for(spi=(closed?2:1);spi<nspi;spi++) {
	if(VECPT(SCP[spi].z,SCP[spi-1].z)<0) {
		VECSCALE(SCP[spi].z,-1);
		if(verbose) 
		    printf("Extrusion.GenPloyRep: Flipped axis spi=%d\n",spi);
	}
} /* for */

/* One case is missing: whole spine is colinear				*/
if(pos_of_last_zvalue==-1) {
	printf("Extrusion.GenPloyRep:Whole spine is colinear!\n");

	/* this is the default, if we don`t need to rotate		*/
	spy.x=0; spy.y=1; spy.z=0;	
	spz.x=0; spz.y=0; spz.z=1;

	if(!spine_is_one_vertix) {
		/* need to find the rotation from SCP[spi].y to (0 1 0)*/
		/* and rotate (0 0 1) and (0 1 0) to be the new y and z	*/
		/* values for all SCPs					*/
		/* I will choose roation about the x and z axis		*/
		float alpha,gamma;	/* angles for the rotation	*/
		
		/* search a non trivial vector along the spine */
		for(spi=1;spi<nspi;spi++) {
			VEC_FROM_CDIFF(spine[spi],spine[0],spp1);
			if(!APPROX(VECSQ(spp1),0))
 				break;
 		}
 			
		/* normalize the non trivial vector */	
		spylen=1/sqrt(VECSQ(spp1)); VECSCALE(spp1,spylen);
		if(verbose)
			printf("Reference vector along spine=[%lf,%lf,%lf]\n",
				spp1.x,spp1.y,spp1.z);


		if(!(APPROX(spp1.x,0) && APPROX(spp1.z,0))) {
			/* at least one of x or z is not zero		*/

			/* get the angle for the x axis rotation	*/
			alpha=asin(spp1.z);

			/* get the angle for the z axis rotation	*/
			if(APPROX(cos(alpha),0))
				gamma=0;
			else {
				gamma=acos(spp1.y / cos(alpha) );
				if(fabs(sin(gamma)-(-spp1.x/cos(alpha))
					)>fabs(sin(gamma)))
					gamma=-gamma;
			}

			/* do the rotation (zero values are already worked in)*/
 			if(verbose)
				printf("alpha=%f gamma=%f\n",alpha,gamma);
			spy.x=cos(alpha)*(-sin(gamma));
			spy.y=cos(alpha)*cos(gamma);
			spy.z=sin(alpha);

			spz.x=sin(alpha)*sin(gamma);
			spz.y=(-sin(alpha))*cos(gamma);
			spz.z=cos(alpha);
		} /* if(!spine_is_one_vertix */
	} /* else */
 
	/* apply new y and z values to all SCPs	*/
	for(spi=0;spi<nspi;spi++) {
		SCP[spi].y=spy;
		SCP[spi].z=spz;
	}
 
} /* if all colinear */
 
if(verbose) {
	for(spi=0;spi<nspi;spi++) {
		printf("SCP[%d].y=[%lf,%lf,%lf], SCP[%d].z=[%lf,%lf,%lf]\n",
			spi,SCP[spi].y.x,SCP[spi].y.y,SCP[spi].y.z,
			spi,SCP[spi].z.x,SCP[spi].z.y,SCP[spi].z.z);
	}
}
 

/************************************************************************
 * calculate the coords 
 */

/* test for number of scale and orientation parameters			*/
if(nsca>1 && nsca <nspi)
	printf("Extrusion.GenPolyRep: Warning!\n"
	"\tNumber of scaling parameters do not match the number of spines!\n"
	"\tWill revert to using only the first scale value.\n");

if(nori>1 && nori <nspi)
	printf("Extrusion.GenPolyRep: Warning!\n"
	"\tNumber of orientation parameters "
		"do not match the number of spines!\n"
	"\tWill revert to using only the first orientation value.\n");


for(spi = 0; spi<nspi; spi++) {
	double m[3][3];		/* space for the roation matrix	*/
	spy=SCP[spi].y; spz=SCP[spi].z;
	VECCP(spy,spz,spx);
	spylen = 1/sqrt(VECSQ(spy)); VECSCALE(spy, spylen);
	spzlen = 1/sqrt(VECSQ(spz)); VECSCALE(spz, spzlen);
	spxlen = 1/sqrt(VECSQ(spx)); VECSCALE(spx, spxlen);

	/* rotate spx spy and spz			*/
	if(nori) {
		int ori = (nori==nspi ? spi : 0);
		
		if(IS_ROTATION_VEC_NOT_NORMAL(orientation[ori]))
			printf("Extrusion.GenPolyRep: Warning!\n"
			  "\tRotationvector #%d not normal!\n"
			  "\tWon`t correct it, because it is bad VRML`97.\n",
			  ori+1); 
 			
		/* first variante:*/ 
		MATRIX_FROM_ROTATION(orientation[ori],m);
		VECMM(m,spx);
		VECMM(m,spy);
		VECMM(m,spz);
		/* */

		/* alternate code (second variant): */ 
		/*
		VECRROTATE(orientation[ori],spx);
		VECRROTATE(orientation[ori],spy);
		VECRROTATE(orientation[ori],spz);
		/* */
	} 
 
	for(sec = 0; sec<nsec; sec++) {
		struct pt point;
		float ptx = curve[sec].c[0];
		float ptz = curve[sec].c[1];
		if(nsca) {
			int sca = (nsca==nspi ? spi : 0);
			ptx *= $f(scale,sca).c[0];
			ptz *= $f(scale,sca).c[1];
 		}
		point.x = ptx;
		point.y = 0; 
		point.z = ptz;

	   coord[(sec+spi*nsec)*3+0] = 
	    spx.x * point.x + spy.x * point.y + spz.x * point.z
	    + $f(spine,spi).c[0];
	   coord[(sec+spi*nsec)*3+1] = 
	    spx.y * point.x + spy.y * point.y + spz.y * point.z
	    + $f(spine,spi).c[1];
	   coord[(sec+spi*nsec)*3+2] = 
	    spx.z * point.x + spy.z * point.y + spz.z * point.z
	    + $f(spine,spi).c[2];

	} /* for(sec */
} /* for(spi */
 
 
 
/* freeing SCP coordinates. not needed anymore.				*/
if(SCP) free(SCP);
 
/************************************************************************
 * setting the values of *cindex to the right coords
 */
 
triind = 0;
{
int x,z;
for(x=0; x<nsec-1; x++) {
 for(z=0; z<nspi-1; z++) {
  /* first triangle */
  cindex[triind*3+0] = x+z*nsec;
  cindex[triind*3+1] = x+(z+1)*nsec;
  cindex[triind*3+2] = (x+1)+z*nsec;
  norindex[triind*3+0] = triind;
  norindex[triind*3+1] = triind;
  norindex[triind*3+2] = triind;
  triind ++;
  /* second triangle*/
  cindex[triind*3+0] = x+(z+1)*nsec;
  cindex[triind*3+1] = (x+1)+(z+1)*nsec;
  cindex[triind*3+2] = (x+1)+z*nsec;
  norindex[triind*3+0] = triind;
  norindex[triind*3+1] = triind;
  norindex[triind*3+2] = triind;
  triind ++; 
 }
}
 
/* for the caps */
if($f(beginCap)) {
	/* XXX if(verbose)*/ printf("Extrusion.GenPloyRep:We have a beginCap!\n"); 
	for(x=0+ncolinear_at_begin; x<nsec-3-ncolinear_at_end; x++) {
		cindex[triind*3+0] = 0;
		cindex[triind*3+1] = x+2;
		cindex[triind*3+2] = x+1;
		norindex[triind*3+0] = triind;
		norindex[triind*3+1] = triind;
		norindex[triind*3+2] = triind;
		triind ++;
	}
	if(!curve_closed) {	/* non closed need one triangle more	*/
		cindex[triind*3+0] = 0;
		cindex[triind*3+1] = x+2;
		cindex[triind*3+2] = x+1;
		norindex[triind*3+0] = triind;
		norindex[triind*3+1] = triind;
		norindex[triind*3+2] = triind;
		triind ++;
 	}
}
 
if($f(endCap)) {
	/* XXX if(verbose)*/ printf("Extrusion.GenPloyRep:We have an endCap!\n"); 
	for(x=0+ncolinear_at_begin; x<nsec-3-ncolinear_at_end; x++) {
		cindex[triind*3+0] = 0  +(nspi-1)*nsec;
		cindex[triind*3+1] = x+2+(nspi-1)*nsec;
		cindex[triind*3+2] = x+1+(nspi-1)*nsec;
		norindex[triind*3+0] = triind;
		norindex[triind*3+1] = triind;
		norindex[triind*3+2] = triind;
		triind ++;
	}
	if(!curve_closed) {	/* non closed need one triangle more	*/
		cindex[triind*3+0] = 0  +(nspi-1)*nsec;
		cindex[triind*3+1] = x+2+(nspi-1)*nsec;
		cindex[triind*3+2] = x+1+(nspi-1)*nsec;
		norindex[triind*3+0] = triind;
		norindex[triind*3+1] = triind;
		norindex[triind*3+2] = triind;
		triind ++;
 	}
}
/* XXX if(verbose)*/
	printf("Extrusion.GenPloyRep: triind=%d  ntri=%d nctri=%d "
	"ncolinear_at_begin=%d ncolinear_at_end=%d\n",
	triind,ntri,nctri,ncolinear_at_begin,ncolinear_at_end);
 
} /* end of block */
 
calc_poly_normals_flat(rep_);
/*****end of Member Extrusion	*/
';
