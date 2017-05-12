################################################################################ iup_plot.h

#### Original C function from <iup_plot.h>
# Ihandle* IupPlot(void);
Ihandle*
_IupPlot()
	CODE:
#ifdef HAVELIB_IUP_PLOT
		RETVAL = IupPlot();
#else
		warn("Error: IUP was built without IupPlot() support");
		RETVAL = NULL;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_plot.h>
# void IupPlotOpen(void);
void
_IupPlotOpen()
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotOpen();
#endif

#### Original C function from <iup_plot.h>
# void IupPlotBegin(Ihandle *ih, int strXdata);
void
_IupPlotBegin(ih,strXdata)
		Ihandle* ih;
		int strXdata;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotBegin(ih,strXdata);
#endif

#### Original C function from <iup_plot.h>
# int IupPlotEnd(Ihandle *ih);
int
_IupPlotEnd(ih)
		Ihandle* ih;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		RETVAL=IupPlotEnd(ih);
#else
		RETVAL=0;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_plot.h>
# void IupPlotAdd(Ihandle* ih, double x, double y);
# void IupPlotAddStr(Ihandle* ih, const char* x, double y);
# void IupPlotAddSegment(Ihandle* ih, double x, double y); [in C]

void
_IupPlotAdd(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupPlotAdd(ih,mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupPlotAdd(ih,mySV2FLT(xlist), mySV2FLT(ylist));
		}
#endif

void
_IupPlotAddStr(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupPlotAddStr(ih,mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupPlotAddStr(ih,mySV2STR(xlist), mySV2FLT(ylist));
		}
#endif

void
_IupPlotAddSegment(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupPlotAddSegment(ih,mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupPlotAddSegment(ih,mySV2FLT(xlist), mySV2FLT(ylist));
		}
#endif

#### Original C function from <iup_plot.h>
# void IupPlotAddSamples(Ihandle *ih, int ds_index, double* x, double* y, int count); [in C]
# void IupPlotAddStrSamples(Ihandle *ih, int ds_index, const char** x, double* y, int count);
void
_IupPlotAddSamples(Ihandle* ih, int index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		double * xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PLOT
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
		  IupPlotAddSamples(ih,index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

void
_IupPlotAddStrSamples(Ihandle* ih, int index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		char ** xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(char*) );
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPlotAddStrSamples(ih,index,(const char **)xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_plot.h>
# void IupPlotInsert(Ihandle *ih, int ds_index, int sample_index, double x, double y); [in C]
# void IupPlotInsertStr(Ihandle *ih, int ds_index, int sample_index, const char* x, double y);
# void IupPlotInsertSegment(Ihandle *ih, int ds_index, int sample_index, double x, double y);

void
_IupPlotInsert(Ihandle* ih, int ds_index, int sample_index, double x, double y)
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotInsert(ih,ds_index,sample_index,x,y);
#endif

void
_IupPlotInsertStr(Ihandle* ih, int ds_index, int sample_index, char* x, double y)
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotInsertStr(ih,ds_index,sample_index,x,y);
#endif

void
_IupPlotInsertSegment(Ihandle* ih, int ds_index, int sample_index, double x, double y)
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotInsertSegment(ih,ds_index,sample_index,x,y);
#endif

#### Original C function from <iup_plot.h>
# void IupPlotInsertSamples(Ihandle *ih, int ds_index, int sample_index, double* x, double* y, int count); [in C]
# void IupPlotInsertStrSamples(Ihandle *ih, int ds_index, int sample_index, const char** x, double* y, int count);

void
_IupPlotInsertSamples(Ihandle* ih, int index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		double * xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PLOT
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
		  IupPlotInsertSamples(ih,index,sample_index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

void
_IupPlotInsertStrSamples(Ihandle* ih, int index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		char ** xpointers;
		double * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(char*) );
		  ypointers = malloc( pcount*sizeof(double) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPlotInsertStrSamples(ih,index,sample_index,(const char **)xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_plot.h>
# void IupPlotTransform(Ihandle* ih, double x, double y, double *cnv_x, double *cnv_y); [in C]
void
_IupPlotTransform(ih,x,y);
		Ihandle* ih;
		double x;
		double y
	INIT:
		double cnv_x;
		double cnv_y;
	PPCODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotTransform(ih,x,y,&cnv_x,&cnv_y);
		XPUSHs(sv_2mortal(newSVnv(cnv_x)));
		XPUSHs(sv_2mortal(newSVnv(cnv_y)));
#endif

#### Original C function from <iup_plot.h>
# void IupPlotTransformTo(Ihandle* ih, double cnv_x, double cnv_y, double *x, double *y); [in C]
void
_IupPlotTransformTo(ih,cnv_x,cnv_y);
		Ihandle* ih;
		double cnv_x;
		double cnv_y;
	INIT:
		double x;
		double y;
	PPCODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotTransformTo(ih,cnv_x,cnv_y,&x,&y);
		XPUSHs(sv_2mortal(newSVnv(cnv_x)));
		XPUSHs(sv_2mortal(newSVnv(cnv_y)));
#endif

#### Original C function from <iup_plot.h>
# void IupPlotPaintTo(Ihandle *ih, void *cnv);
void
_IupPlotPaintTo(ih,cnv)
		Ihandle *ih;
		void *cnv;
	CODE:
#ifdef HAVELIB_IUP_PLOT
		IupPlotPaintTo(ih,cnv);
#endif


#### XXX-TODO
#### Original C function from <iup_plot.h>
# int IupPlotLoadData(Ihandle *ih, const char* filename, int strXdata);
# void IupPlotGetSample(Ihandle *ih, int ds_index, int sample_index, double *x, double *y); [in C]
# void IupPlotGetSampleStr(Ihandle *ih, int ds_index, int sample_index, const char* *x, double *y);
# int IupPlotGetSampleSelection(Ihandle *ih, int ds_index, int sample_index); [in C]
# double IupPlotGetSampleExtra(Ihandle *ih, int ds_index, int sample_index); [in C]
# void IupPlotSetSample(Ihandle *ih, int ds_index, int sample_index, double x, double y); [in C]
# void IupPlotSetSampleStr(Ihandle *ih, int ds_index, int sample_index, const char* x, double y);
# void IupPlotSetSampleSelection(Ihandle *ih, int ds_index, int sample_index, int selected);
# void IupPlotSetSampleExtra(Ihandle *ih, int ds_index, int sample_index, double extra); [in C]
# int IupPlotFindSample(Ihandle* ih, double cnv_x, double cnv_y, int *ds_index, int *sample_index); [in C]
# void IupPlotSetFormula(Ihandle* ih, int sample_count, const char* formula, const char* init); [in C]