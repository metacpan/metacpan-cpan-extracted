################################################################################ iup_pplot.h

#### Original C function from <iup_pplot.h>
# Ihandle* IupPPlot(void);
Ihandle*
_IupPPlot()
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		RETVAL = IupPPlot();
#else
		warn("Error: IUP was built without IupPPlot() support");
		RETVAL = NULL;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_pplot.h>
# void IupPPlotOpen(void);
void
_IupPPlotOpen()
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotOpen();
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotBegin(Ihandle *ih, int strXdata);
void
_IupPPlotBegin(ih,strXdata)
		Ihandle* ih;
		int strXdata;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotBegin(ih,strXdata);
#endif

#### Original C function from <iup_pplot.h>
# int IupPPlotEnd(Ihandle *ih);
int
_IupPPlotEnd(ih)
		Ihandle* ih;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		RETVAL=IupPPlotEnd(ih);		
#else
		RETVAL=0;
#endif
	OUTPUT:
		RETVAL

#### Original C function from <iup_pplot.h>
# void IupPPlotAdd(Ihandle *ih, float x, float y);
# void IupPPlotAddStr(Ihandle *ih, const char* x, float y);
void
_IupPPlotAdd(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupPPlotAdd(ih,mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupPPlotAdd(ih,mySV2FLT(xlist), mySV2FLT(ylist));
		}
#endif

void
_IupPPlotAddStr(Ihandle* ih, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		if ( (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) && (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ) {
		  xcount = (1+av_len((AV *)SvRV(xlist)));
		  ycount = (1+av_len((AV *)SvRV(ylist)));
		  pcount = (xcount>ycount) ? ycount : xcount;
		  for(i=0; i<pcount; i++) { 
		    IupPPlotAddStr(ih,mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0)), mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0)));
		  }
		}
		else {
		  IupPPlotAddStr(ih,mySV2STR(xlist), mySV2FLT(ylist));
		}
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotAddPoints(Ihandle* ih, int index, float *x, float *y, int count);
# void IupPPlotAddStrPoints(Ihandle* ih, int index, const char** x, float* y, int count);
void
_IupPPlotAddPoints(Ihandle* ih, int index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		float * xpointers;
		float * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(float) );
		  ypointers = malloc( pcount*sizeof(float) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPPlotAddPoints(ih,index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

void
_IupPPlotAddStrPoints(Ihandle* ih, int index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		char ** xpointers;
		float * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(char*) );
		  ypointers = malloc( pcount*sizeof(float) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPPlotAddStrPoints(ih,index,(const char **)xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotInsertStr(Ihandle *ih, int index, int sample_index, const char* x, float y);
# void IupPPlotInsert(Ihandle *ih, int index, int sample_index, float x, float y);
void
_IupPPlotInsert(Ihandle* ih, int index, int sample_index, float x, float y)
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotInsert(ih,index,sample_index,x,y);
#endif

void
_IupPPlotInsertStr(Ihandle* ih, int index, int sample_index, char* x, float y)
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotInsertStr(ih,index,sample_index,x,y);
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotInsertStrPoints(Ihandle* ih, int index, int sample_index, const char** x, float* y, int count);
# void IupPPlotInsertPoints(Ihandle* ih, int index, int sample_index, float *x, float *y, int count);
void
_IupPPlotInsertPoints(Ihandle* ih, int index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		float * xpointers;
		float * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(float) );
		  ypointers = malloc( pcount*sizeof(float) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPPlotInsertPoints(ih,index,sample_index,xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

void
_IupPPlotInsertStrPoints(Ihandle* ih, int index, int sample_index, SV* xlist, SV* ylist)
	INIT:
		int pcount, xcount, ycount, i;
		char ** xpointers;
		float * ypointers;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		xcount = (SvROK(xlist) && SvTYPE(SvRV(xlist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(xlist))) : 0;
		ycount = (SvROK(ylist) && SvTYPE(SvRV(ylist))==SVt_PVAV) ? (1+av_len((AV *)SvRV(ylist))) : 0;
		pcount = (xcount>ycount) ? ycount : xcount;
		if (pcount>0) {
		  xpointers = malloc( pcount*sizeof(char*) );
		  ypointers = malloc( pcount*sizeof(float) );
		  for(i=0; i<pcount; i++) { 
		    xpointers[i] = mySV2STR(*av_fetch((AV *)SvRV(xlist), i, 0));
		    ypointers[i] = mySV2FLT(*av_fetch((AV *)SvRV(ylist), i, 0));
		  }
		  IupPPlotInsertStrPoints(ih,index,sample_index,(const char **)xpointers,ypointers,pcount);
		  free(xpointers);
		  free(ypointers);
		}
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotTransform(Ihandle* ih, float x, float y, int *ix, int *iy);
void
_IupPPlotTransform(ih,x,y);
		Ihandle* ih;
		float x;
		float y
	INIT:
		int ix;
		int iy;
	PPCODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotTransform(ih,x,y,&ix,&iy);
		XPUSHs(sv_2mortal(newSViv(ix)));
		XPUSHs(sv_2mortal(newSViv(iy)));
#endif

#### Original C function from <iup_pplot.h>
# void IupPPlotPaintTo(Ihandle *ih, void *cnv);
void
_IupPPlotPaintTo(ih,cnv)
		Ihandle *ih;
		void *cnv;
	CODE:
#ifdef HAVELIB_IUP_PPLOT
		IupPPlotPaintTo(ih,cnv);
#endif
