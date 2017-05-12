################################################################################ iup_mglplot.h

#### Original C function from <iup_mglplot.h>
# Ihandle* IupMglPlot(void);
Ihandle*
_IupMglPlot()
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		RETVAL = IupMglPlot();
#else
		warn("Error: IUP was built without IupMglPlot() support");
		RETVAL = NULL;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_mglplot.h> # void IupMglPlotOpen(void);
void
_IupMglPlotOpen()
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotOpen();
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotBegin(Ihandle *ih, int dim);
void
_IupMglPlotBegin(Ihandle* ih, int dim)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotBegin(ih,dim);
#endif

#### Original C function from <iup_mglplot.h> # int IupMglPlotEnd(Ihandle *ih);
int
_IupMglPlotEnd(ih)
		Ihandle* ih;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		RETVAL=IupMglPlotEnd(ih);
#else
		RETVAL=0;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_mglplot.h> # int IupMglPlotNewDataSet(Ihandle *ih, int dim);
int
_IupMglPlotNewDataSet(Ihandle *ih, int dim)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		RETVAL=IupMglPlotNewDataSet(ih,dim);
#else
		RETVAL=0;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_mglplot.h> # void IupMglPlotAdd1D(Ihandle *ih, const char* name, double y);
void
_IupMglPlotAdd1D(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupMglPlotAdd1D(ih,mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupMglPlotAdd1D(ih,mySV2STR(xlist), mySV2FLT(ylist));
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotInsert1D(Ihandle* ih, int ds_index, int sample_index, const char** names, const double* y, int count);
void
_IupMglPlotInsert1D(Ihandle* ih, int ds_index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		const char ** xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount || xcount==0) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = (xcount>0) ? malloc( pcount*sizeof(char*) ) : NULL;
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    if (xpointers) xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupMglPlotInsert1D(ih,ds_index,sample_index,xpointers,ypointers,pcount);
		  if (xpointers) free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSet1D(Ihandle* ih, int ds_index, const char** names, const double* y, int count);
void
_IupMglPlotSet1D(Ihandle* ih, int ds_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		const char ** xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount || xcount==0) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = (xcount>0) ? malloc( pcount*sizeof(char*) ) : NULL;
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    if (xpointers) xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupMglPlotSet1D(ih,ds_index,xpointers,ypointers,pcount);
		  if (xpointers) free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotAdd2D(Ihandle *ih, double x, double y);
void
_IupMglPlotAdd2D(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupMglPlotAdd2D(ih,mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupMglPlotAdd2D(ih,mySV2FLT(xlist), mySV2FLT(ylist));
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotInsert2D(Ihandle* ih, int ds_index, int sample_index, const double* x, const double* y, int count);
void
_IupMglPlotInsert2D(Ihandle* ih, int ds_index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		double * xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(double) );
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupMglPlotInsert2D(ih,ds_index,sample_index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSet2D(Ihandle* ih, int ds_index, const double* x, const double* y, int count);
void
_IupMglPlotSet2D(Ihandle* ih, int ds_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		double * xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(double) );
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupMglPlotSet2D(ih,ds_index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotAdd3D(Ihandle *ih, double x, double y, double z);
void
_IupMglPlotAdd3D(Ihandle* ih, SV* xlist, SV* ylist, SV* zlist)
	INIT:
		int pcount, xcount, ycount, zcount, i;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && 
                     (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) &&
                     (SvROK(ylist) && SvTYPE(SvRV(zlist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  zcount = (1+av_len((AV *)SvRV(zlist)));
		  if (xcount>ycount) pcount = ycount; else pcount = xcount;
		  if (pcount>zcount) pcount = zcount;
		  for(i=0; i<pcount; i++) { 
		    IupMglPlotAdd3D(ih, mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0)),
                                        mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)), 
                                        mySV2FLT(*av_fetch((AV *)SvRV(zlist), i, 0)) );
		  }
		}
		else {
		  IupMglPlotAdd3D(ih,mySV2FLT(xlist), mySV2FLT(ylist), mySV2FLT(zlist));
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotInsert3D(Ihandle* ih, int ds_index, int sample_index, const double* x, const double* y, const double* z, int count);
void
_IupMglPlotInsert3D(Ihandle* ih, int ds_index, int sample_index, SV* xlist, SV* ylist, SV* zlist)
	INIT:
		int pcount, xcount, ycount, zcount, i;
		double * xpointers;
		double * ypointers;
                double * zpointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		zcount = (SvROK(ylist) && SvTYPE(SvRV(zlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(zlist))) : 0;
		if (xcount>ycount) pcount = ycount; else pcount = xcount;
		if (pcount>zcount) pcount = zcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(double) );
		  ypointers = malloc( pcount*sizeof(double) );
		  zpointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		    zpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(zlist), i, 0));
		  }
		  IupMglPlotInsert3D(ih,ds_index,sample_index,xpointers,ypointers,zpointers,pcount);
		  free(xpointers);
		  free(ypointers);
		  free(zpointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSet3D(Ihandle* ih, int ds_index, const double* x, const double* y, const double* z, int count);
void
_IupMglPlotSet3D(Ihandle* ih, int ds_index, SV* xlist, SV* ylist, SV* zlist)
	INIT:
		int pcount, xcount, ycount, zcount, i;
		double * xpointers;
		double * ypointers;
		double * zpointers;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		zcount = (SvROK(ylist) && SvTYPE(SvRV(zlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(zlist))) : 0;
		if (xcount>ycount) pcount = ycount; else pcount = xcount;
		if (pcount>zcount) pcount = zcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(double) );
		  ypointers = malloc( pcount*sizeof(double) );
		  zpointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		    zpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(zlist), i, 0));
		  }
		  IupMglPlotSet3D(ih,ds_index,xpointers,ypointers,zpointers,pcount);
		  free(xpointers);
		  free(ypointers);
		  free(zpointers);
		}
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotTransform(Ihandle* ih, double x, double y, double z, int *ix, int *iy);
void
_IupMglPlotTransform(Ihandle* ih, double x, double y, double z)
	INIT:
		int ix, iy;
	PPCODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotTransform(ih,x,y,z,&ix,&iy);
		XPUSHs(sv_2mortal(newSViv(ix)));
		XPUSHs(sv_2mortal(newSViv(iy)));
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotTransformTo(Ihandle* ih, int ix, int iy, double *x, double *y, double *z);
void
_IupMglPlotTransformTo(Ihandle* ih, int ix, int iy)
	INIT:
		double x, y, z;
	PPCODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotTransformTo(ih,ix,iy,&x,&y,&z);
		XPUSHs(sv_2mortal(newSVnv(x)));
		XPUSHs(sv_2mortal(newSVnv(y)));
		XPUSHs(sv_2mortal(newSVnv(z)));
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotPaintTo(Ihandle *ih, const char* format, int w, int h, double dpi, void *data);
void
_IupMglPlotPaintTo(Ihandle* ih, char* format, int w, int h, double dpi, char *data)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotPaintTo(ih,format,w,h,dpi,data); /* data == filename*/
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotDrawMark(Ihandle* ih, double x, double y, double z);
void
_IupMglPlotDrawMark(Ihandle* ih, double x, double y, double z)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotDrawMark(ih,x,y,z);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotDrawLine(Ihandle* ih, double x1, double y1, double z1, double x2, double y2, double z2);
void
_IupMglPlotDrawLine(Ihandle* ih, double x1, double y1, double z1, double x2, double y2, double z2)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotDrawLine(ih,x1,y1,z1,x2,y2,z2);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotDrawText(Ihandle* ih, const char* text, double x, double y, double z);
void
_IupMglPlotDrawText(Ihandle* ih, const char* text, double x, double y, double z)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotDrawText(ih,text,x,y,z);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSetFormula(Ihandle* ih, int ds_index, const char* formulaX, const char* formulaY, const char* formulaZ, int count);
void
_IupMglPlotSetFormula(Ihandle* ih, int ds_index, int count, char* formulaX, char* formulaY, char* formulaZ)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		IupMglPlotSetFormula(ih,ds_index,formulaX,formulaY,formulaZ,count);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotLoadData(Ihandle* ih, int ds_index, const char* filename, int count_x, int count_y, int count_z);
void
_IupMglPlotLoadData(Ihandle* ih, int ds_index, char* filename, ...)
	INIT:
		int count_x, count_y, count_z;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
                count_x = (items>3) ? myST2INT(3) : 0;
                count_y = (items>4) ? myST2INT(4) : 0;
                count_z = (items>5) ? myST2INT(5) : 0;
                IupMglPlotLoadData(ih,ds_index,filename,count_x,count_y,count_z);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSetFromFormula(Ihandle* ih, int ds_index, const char* formula, int count_x, int count_y, int count_z);
void
_IupMglPlotSetFromFormula(Ihandle* ih, int ds_index, char* formula, ...)
	INIT:
		int count_x, count_y, count_z;
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
                count_x = (items>3) ? myST2INT(3) : 0;
                count_y = (items>4) ? myST2INT(4) : 0;
                count_z = (items>5) ? myST2INT(5) : 0;
                IupMglPlotSetFromFormula(ih,ds_index,formula,count_x,count_y,count_z);
#endif

#### Original C function from <iup_mglplot.h> # void IupMglPlotSetData(Ihandle* ih, int ds_index, const double* data, int count_x, int count_y, int count_z);
void
_IupMglPlotSetData(Ihandle* ih, int ds_index, SV* data, int count_x, int count_y, int count_z)
	CODE:
#ifdef HAVELIB_IUP_MGLPLOT
		croak("XXX-FIXME IupMglPlotSetData not implemented");
                //XXX-TODO iup.MglPlotSetData(ih: ihandle, ds_index: number, data: table of number) [in Lua]
                //IupMglPlotSetData(ih,ds_index,data,count_x,count_y,count_z); /*XXX-FIXME*/
#endif
