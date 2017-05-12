MODULE = IUP::Internal::Canvas        PACKAGE = IUP::Internal::Canvas

### special internal functions ###

cdCanvas*
_cdCreateCanvas_CD_IUP(ih)
                Ihandle* ih;
        CODE:
#ifdef HAVELIB_IUPCD
                RETVAL = cdCreateCanvas(CD_IUP, ih);
                if (RETVAL) cdCanvasSetAttribute(RETVAL, "UTF8MODE", "1");
#else
                warn("Warning: cdCreateCanvas() not available");
                RETVAL = NULL;
#endif
        OUTPUT:
                RETVAL

cdCanvas*
_cdCreateCanvas_BASIC(format, params)
                char* format;
                char* params;
        CODE:
                if (!format) RETVAL = NULL;
                else if (strcmp(format,"CGM") == 0)        RETVAL = cdCreateCanvas(CD_CGM, params);
                else if (strcmp(format,"DEBUG") == 0)      RETVAL = cdCreateCanvas(CD_DEBUG, params);
                else if (strcmp(format,"DGN") == 0)        RETVAL = cdCreateCanvas(CD_DGN, params);
                else if (strcmp(format,"DXF") == 0)        RETVAL = cdCreateCanvas(CD_DXF, params);
                else if (strcmp(format,"EMF") == 0)        RETVAL = cdCreateCanvas(CD_EMF, params);
                else if (strcmp(format,"METAFILE") == 0)   RETVAL = cdCreateCanvas(CD_METAFILE, params);
                else if (strcmp(format,"PS") == 0)         RETVAL = cdCreateCanvas(CD_PS, params);
                else if (strcmp(format,"SVG") == 0)        RETVAL = cdCreateCanvas(CD_SVG, params);
                else if (strcmp(format,"WMF") == 0)        RETVAL = cdCreateCanvas(CD_WMF, params);
                else RETVAL = NULL;
                if (RETVAL) cdCanvasSetAttribute(RETVAL, "UTF8MODE", "1");
        OUTPUT:
                RETVAL

cdCanvas*
_cdCreateCanvas_IMAGERGB_empty(width,height,has_alpha,resolution)
                int width;
                int height;
                int has_alpha;
                double resolution;
        INIT:
                char tmp[1024];
                char res[1024];
        CODE:
                if (width>0 && height>0) {
                  if (resolution>0.0001)
                    snprintf(tmp,1000,"%dx%d -r%g",width,height,resolution);
                  else 
                    snprintf(tmp,1000,"%dx%d",width,height);
                  if (has_alpha==1) strcat(tmp," -a");
                  /*warn("XXX-DEBUG (_cdCreateCanvas_IMAGERGB_empty): param='%s'\n",tmp);*/
                  RETVAL = cdCreateCanvas(CD_IMAGERGB, tmp);
                  if (RETVAL) cdCanvasSetAttribute(RETVAL, "UTF8MODE", "1");
                }
                else 
                  RETVAL = NULL;
        OUTPUT:
                RETVAL

float
_cdCreateCanvas_IMAGERGB_dpi_helper(file_name)
                char *file_name;
        CODE:
                int error;
                imImage *image = imFileImageLoadBitmap(file_name, 0, &error);
                RETVAL = -1; /* = error */
                if (!error && image) {
                  float *resx = (float*)imImageGetAttribute(image, "XResolution", NULL, NULL);
                  char *unit = (char*)imImageGetAttribute(image, "ResolutionUnit", NULL, NULL);
                  if (strcmp(unit,"DPI")==0)          
                    RETVAL = *resx;
                  else if (strcmp(unit,"DPC")==0)                            
                    RETVAL = (*resx)*(2.54);
                }
        OUTPUT:
                RETVAL

cdCanvas*
_cdCreateCanvas_IMAGERGB_from_bitmap(bitmap,resolution)
                IUP::Canvas::Bitmap bitmap;
                double resolution;
        PREINIT:
                unsigned char* r;
                unsigned char* g;
                unsigned char* b;
                unsigned char* a;
                int width = 0;
                int height = 0;
                int has_alpha = 0;
                int valid = 0;
                char tmp[1024];
                char res[512];
        CODE:
                if (bitmap) {
                  width = bitmap->w;
                  height = bitmap->h;
                  if (bitmap->type == CD_RGB) {
                    r = cdBitmapGetData(bitmap, CD_IRED);
                    g = cdBitmapGetData(bitmap, CD_IGREEN);
                    b = cdBitmapGetData(bitmap, CD_IBLUE);
                    a = NULL;
                    has_alpha = 0;
                    valid = 1;
                  }
                  else if(bitmap->type == CD_RGBA) {
                    r = cdBitmapGetData(bitmap, CD_IRED);
                    g = cdBitmapGetData(bitmap, CD_IGREEN);
                    b = cdBitmapGetData(bitmap, CD_IBLUE);
                    a = cdBitmapGetData(bitmap, CD_IALPHA);
                    has_alpha = 1;
                    valid = 1;
                  }
                  else {
                    warn("Error: bitmap type needs to be RGB or RGBA");
                  }
                }
                RETVAL = NULL;
                if (width>0 && height>0 && valid) {
                  if (has_alpha)
                    snprintf(tmp,500,"%dx%d %p %p %p %p -a",width,height,r,g,b,a);
                  else
                    snprintf(tmp,500,"%dx%d %p %p %p",width,height,r,g,b);
                  if (resolution>0.0001) {
                    snprintf(res,500," -r%g",resolution);
                    strcat(tmp,res);
                  }
                  /*warn("XXX-DEBUG (_cdCreateCanvas_IMAGERGB_from_bitmap): param='%s'\n",tmp);*/
                  RETVAL = cdCreateCanvas(CD_IMAGERGB, tmp);
                  if (RETVAL) cdCanvasSetAttribute(RETVAL, "UTF8MODE", "1");
                  /*warn("XXX-DEBUG: rv=%p",RETVAL);*/
                  /*if (cdCanvasGetContext(RETVAL) != CD_IMAGERGB) warn("XXX-DEBUG: invalid canvas, must be CD_IMAGERGB");*/
                }                
        OUTPUT:
                RETVAL

int
cdDumpBitmap(canvas,filename,format)
                SV* canvas;
                char *filename;
                char *format;
        INIT:
                unsigned char* data_buffer = NULL;
                                unsigned char* data = NULL;
                imImage *image;
                                int width = 0, height = 0;
                double width_mm = 0, height_mm = 0;
                int has_alpha = 0;
                int color_space, plane_size, plane_count, w, h, type;                
                float resx, resy;
        CODE:                                                
                cdCanvas *c = ref2cnv(canvas);
                RETVAL = 999; /* = error */
                if (cdCanvasGetContext(c) != CD_IMAGERGB) {
                  warn("Error: cdDumpBitmap() can be used only on 'IUP::Canvas::FileBitmap' canvas");
                }
                else {
                  cdCanvasGetSize(c,&width, &height, &width_mm, &height_mm);
                  resx = 25.4*width/width_mm;
                  resy = 25.4*height/height_mm;
                  plane_size = sizeof(unsigned char)*width*height;
                  type = (cdAlphaImage(c)) ? CD_RGBA : CD_RGB;                                    
                  plane_count = (type==CD_RGBA) ? 4 : 3;
                  color_space = (type==CD_RGBA) ? (IM_RGB | IM_ALPHA) : IM_RGB;
                  data = cdCanvasGetAttribute(c, "REDIMAGE"); /*also a pointer to the full buffer*/
                  /*
                   * warn("XXX-DEBUG: w=%d|%f h=%d|%f plane_size=%d plane_count=%d\n",width,width_mm,height,height_mm,plane_size,plane_count);
                   * warn("XXX-DEBUG: xres=%f DPI, yres=%f DPI\n", xres, yres);
                   */
                  if(data) {
                    image = imImageInit(width, height, color_space, IM_BYTE, data, NULL, 0);
                    /* set resolution */
                    imImageSetAttribute(image, "XResolution", IM_FLOAT, 1, &resx);
                    imImageSetAttribute(image, "YResolution", IM_FLOAT, 1, &resy);
                    imImageSetAttribute(image, "ResolutionUnit", IM_BYTE, -1, "DPI");
                    /* save image file */
                    RETVAL = imFileImageSave(filename, format, image);                    
                    image->data[0] = NULL; /* to avoid duplicate memory release */
                    imImageDestroy(image);
                    /*warn("XXX-DEBUG: imFileImageSave rv=%d\n",RETVAL);*/
                  }
                }                
        OUTPUT:
                RETVAL

void
_cdKillCanvas(canvas)
                SV* canvas;
        CODE:
                cdKillCanvas(ref2cnv(canvas));

### generated part - start ###

#### Original C function from <.../cd/include/cd.h>
# char* cdVersion(void);
char*
cdVersion(pkg)
                SV* pkg;
        CODE:
                RETVAL = cdVersion();
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# char* cdVersionDate(void);
char*
cdVersionDate(pkg)
                SV* pkg;
        CODE:
                RETVAL = cdVersionDate();
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdVersionNumber(void);
int
cdVersionNumber(pkg)
                SV* pkg;
        CODE:
                RETVAL = cdVersionNumber();
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# cdContext* cdCanvasGetContext(cdCanvas* canvas);
IUP::Canvas::InternalContext
cdGetContext(canvas)
                SV* canvas;
        INIT:
                char *CLASS = "IUP::Canvas::InternalContext"; /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                RETVAL = cdCanvasGetContext(ref2cnv(canvas));
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasActivate(cdCanvas* canvas);
int
cdActivate(canvas)
                SV* canvas;
        CODE:
                RETVAL = cdCanvasActivate(ref2cnv(canvas));
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasDeactivate(cdCanvas* canvas);
void
cdDeactivate(canvas)
                SV* canvas;
        CODE:
                cdCanvasDeactivate(ref2cnv(canvas));

#### Original C function from <.../cd/include/cd.h>
# int cdUseContextPlus(int use);
int
cdUseContextPlus(use)
                int use;
        CODE:
                RETVAL = cdUseContextPlus(use);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
#xxxTODO void cdInitContextPlus(void); 
#xxxTODO support later, add some ifdefs
#void
#cdInitContextPlus()
#        CODE:
#                cdInitContextPlus();

#### Original C function from <.../cd/include/cd.h>
#xxxTODO int cdContextRegisterCallback(cdContext *context, int cb, cdCallback func);
#xxxTODO cd.ContextRegisterCallback(ctx, cb: number, func: function) -> (status: number) [in Lua]
#xxxTODO cd callbacks? maybe later
#int
#cdContextRegisterCallback(context,cb,func)
#                cdContext* context;
#                int cb;
#                cdCallback func;
#        CODE:
#                RETVAL = cdContextRegisterCallback(context,cb,func);
#        OUTPUT:
#                RETVAL

#### Original C function from <.../cd/include/cd.h>
# unsigned long cdContextCaps(cdContext *context);
unsigned long
cdContextCaps(context)
                IUP::Canvas::InternalContext context;
        CODE:
                RETVAL = cdContextCaps(context);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasSimulate(cdCanvas* canvas, int mode);
int
cdSimulate(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                RETVAL = cdCanvasSimulate(ref2cnv(canvas),mode);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasFlush(cdCanvas* canvas);
void
cdFlush(canvas)
                SV* canvas;
        CODE:
                cdCanvasFlush(ref2cnv(canvas));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasClear(cdCanvas* canvas);
void
cdClear(canvas)
                SV* canvas;
        CODE:
                cdCanvasClear(ref2cnv(canvas));

#### Original C function from <.../cd/include/cd.h>
# cdState* cdCanvasSaveState(cdCanvas* canvas);
IUP::Canvas::InternalState
cdSaveState(canvas)
                SV* canvas;
        INIT:
                //char *CLASS = "IUP::Canvas::InternalState"; /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                RETVAL = cdCanvasSaveState(ref2cnv(canvas));
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasRestoreState(cdCanvas* canvas, cdState* state);
void
cdRestoreState(canvas,state__)
                SV* canvas;
                IUP::Canvas::InternalState state__;
        CODE:
                cdCanvasRestoreState(ref2cnv(canvas),state__);

#### Original C function from <.../cd/include/cd.h>
# void cdReleaseState(cdState* state);
void
cdReleaseState(state)
                IUP::Canvas::InternalState state;
        CODE:
                cdReleaseState(state);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasSetAttribute(cdCanvas* canvas, const char* name, char* data);
void
cdSetAttribute(canvas,name,data)
                SV* canvas;
                const char* name;
                char* data;
        CODE:
                cdCanvasSetAttribute(ref2cnv(canvas),name,data);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasSetfAttribute(cdCanvas* canvas, const char* name, const char* format, ...);
void
cdSetfAttribute(canvas,name,format,...)
                SV* canvas;
                const char* name;
                const char* format;
        CODE:
                cdCanvasSetfAttribute(ref2cnv(canvas),name,format);

#### Original C function from <.../cd/include/cd.h>
# char* cdCanvasGetAttribute(cdCanvas* canvas, const char* name);
char*
cdGetAttribute(canvas,name)
                SV* canvas;
                const char* name;
        CODE:
                RETVAL = cdCanvasGetAttribute(ref2cnv(canvas),name);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasPlay(cdCanvas* canvas, cdContext *context, int xmin, int xmax, int ymin, int ymax, void *data);
#XXX-CHECKLATER: void *data vs. char *data
int
cdPlay(canvas,context,xmin,xmax,ymin,ymax,data)
                SV* canvas;
                IUP::Canvas::InternalContext context;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
                char *data;
        CODE:
                RETVAL = cdCanvasPlay(ref2cnv(canvas),context,xmin,xmax,ymin,ymax,(void*)data);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetSize(cdCanvas* canvas, int *width, int *height, double *width_mm, double *height_mm);
# canvas:GetSize() -> (width, height, mm_width, mm_height: number) [in Lua]
void
cdGetSize(canvas)
                SV* canvas;
        INIT:
                int width;
                int height;
                double width_mm;
                double height_mm;
        PPCODE:
                cdCanvasGetSize(ref2cnv(canvas),&width,&height,&width_mm,&height_mm);
                XPUSHs(sv_2mortal(newSViv(width)));
                XPUSHs(sv_2mortal(newSViv(height)));
                XPUSHs(sv_2mortal(newSVnv(width_mm)));
                XPUSHs(sv_2mortal(newSVnv(height_mm)));

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasUpdateYAxis(cdCanvas* canvas, int* y);
# double cdfCanvasUpdateYAxis(cdCanvas* canvas, double* y);
double
cdUpdateYAxis(canvas,y)
                SV* canvas;
                double y;
        CODE:
                double tmpy = y;
                #XXX-CHECKLATER returns updated value (does not change param value)
                RETVAL = cdfCanvasUpdateYAxis(ref2cnv(canvas),&tmpy);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasYAxisMode(cdCanvas* canvas, int invert);
int
cdYAxisMode(canvas,invert)
                SV* canvas;
                int invert;
        CODE:
                croak("OBSOLETE: cdCanvasYAxisMode");
                RETVAL = 0;
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasInvertYAxis(cdCanvas* canvas, int y);
# double cdfCanvasInvertYAxis(cdCanvas* canvas, double y);
double
cdInvertYAxis(canvas,y)
                SV* canvas;
                double y;
        CODE:
                RETVAL = cdfCanvasInvertYAxis(ref2cnv(canvas),y);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasMM2Pixel(cdCanvas* canvas, double mm_dx, double mm_dy, int *dx, int *dy);
# canvas:MM2Pixel(mm_dx, mm_dy: number) -> (dx, dy: number) [in Lua]
void
cdMM2Pixel(canvas,mm_dx,mm_dy)
                SV* canvas;
                double mm_dx;
                double mm_dy;
        INIT:
                int rv;
                int dx;
                int dy;
        PPCODE:                
                cdCanvasMM2Pixel(ref2cnv(canvas),mm_dx,mm_dy,&dx,&dy);
                XPUSHs(sv_2mortal(newSViv(dx)));
                XPUSHs(sv_2mortal(newSViv(dy)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPixel2MM(cdCanvas* canvas, int dx, int dy, double *mm_dx, double *mm_dy);
# canvas:Pixel2MM(dx, dy: number) -> (mm_dx, mm_dy: number) [in Lua]
void
cdPixel2MM(canvas,dx,dy)
                SV* canvas;
                int dx;
                int dy;
        INIT:
                double mm_dx;
                double mm_dy;
        PPCODE:
                cdCanvasPixel2MM(ref2cnv(canvas),dx,dy,&mm_dx,&mm_dy);
                XPUSHs(sv_2mortal(newSVnv(mm_dx)));
                XPUSHs(sv_2mortal(newSVnv(mm_dy)));


#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasMM2Pixel(cdCanvas* canvas, double mm_dx, double mm_dy, double *dx, double *dy);
# canvas:fMM2Pixel(mm_dx, mm_dy: number) -> (dx, dy: number) [in Lua]
void
cdfMM2Pixel(canvas,mm_dx,mm_dy)
                SV* canvas;
                double mm_dx;
                double mm_dy;
        INIT:
                double dx;
                double dy;
        PPCODE:
                cdfCanvasMM2Pixel(ref2cnv(canvas),mm_dx,mm_dy,&dx,&dy);
                XPUSHs(sv_2mortal(newSVnv(dx)));
                XPUSHs(sv_2mortal(newSVnv(dy)));

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasPixel2MM(cdCanvas* canvas, double dx, double dy, double *mm_dx, double *mm_dy);
# canvas:fPixel2MM(dx, dy: number) -> (mm_dx, mm_dy: number) [in Lua]
void
cdfPixel2MM(canvas,dx,dy,mm_dx,mm_dy)
                SV* canvas;
                double dx;
                double dy;
        INIT:
                double mm_dx;
                double mm_dy;
        PPCODE:
                cdfCanvasPixel2MM(ref2cnv(canvas),dx,dy,&mm_dx,&mm_dy);
                XPUSHs(sv_2mortal(newSVnv(mm_dx)));
                XPUSHs(sv_2mortal(newSVnv(mm_dy)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasOrigin(cdCanvas* canvas, int x, int y);
void
cdOrigin(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        CODE:
                cdCanvasOrigin(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasOrigin(cdCanvas* canvas, double x, double y);
void
cdfOrigin(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                cdfCanvasOrigin(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetOrigin(cdCanvas* canvas, int *x, int *y);
# canvas:GetOrigin() -> (x, y: number) [in Lua]
void
cdGetOrigin(canvas)
                SV* canvas;
        INIT:
                int x;
                int y;
        PPCODE:
                cdCanvasGetOrigin(ref2cnv(canvas),&x,&y);
                XPUSHs(sv_2mortal(newSViv(x)));
                XPUSHs(sv_2mortal(newSViv(y)));

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasGetOrigin(cdCanvas* canvas, double *x, double *y);
# canvas:fGetOrigin() -> (x, y: number) [in Lua]
void
cdfGetOrigin(canvas)
                SV* canvas;
        INIT:
                double x;
                double y;
        PPCODE:
                cdfCanvasGetOrigin(ref2cnv(canvas),&x,&y);
                XPUSHs(sv_2mortal(newSVnv(x)));
                XPUSHs(sv_2mortal(newSVnv(y)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransform(cdCanvas* canvas, const double* matrix);
# canvas:Transform(matrix: table) [in Lua]
void
cdTransform(canvas,matrix)
                SV* canvas;
                SV* matrix;
        INIT:
                double tmpmatrix[6];
        CODE:
                if (AV2transmatrix(matrix,tmpmatrix))
                    cdCanvasTransform(ref2cnv(canvas),tmpmatrix);
                else
                    warn("Warning: cdTransform() invalid 'matrix' parameter");

#### Original C function from <.../cd/include/cd.h>
# double* cdCanvasGetTransform(cdCanvas* canvas);
# canvas:GetTransformation() -> (matrix: table) [in Lua]
SV*
cdGetTransform(canvas)
                SV* canvas;
        INIT:
                double *matrix;
        CODE:
                matrix = cdCanvasGetTransform(ref2cnv(canvas));
                if (!matrix) XSRETURN_UNDEF;
                RETVAL = transmatrix2AV(matrix);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransformMultiply(cdCanvas* canvas, const double* matrix);
# canvas:TransformMultiply(matrix: table) [in Lua]
void
cdTransformMultiply(canvas,matrix)
                SV* canvas;
                SV* matrix;
        INIT:
                double tmpmatrix[6];
        CODE:
                if (AV2transmatrix(matrix,tmpmatrix))
                    cdCanvasTransformMultiply(ref2cnv(canvas),tmpmatrix);
                else
                    warn("Warning: cdTransform() invalid 'matrix' parameter");

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransformRotate(cdCanvas* canvas, double angle);
void
cdTransformRotate(canvas,angle)
                SV* canvas;
                double angle;
        CODE:
                cdCanvasTransformRotate(ref2cnv(canvas),angle);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransformScale(cdCanvas* canvas, double sx, double sy);
void
cdTransformScale(canvas,sx,sy)
                SV* canvas;
                double sx;
                double sy;
        CODE:
                cdCanvasTransformScale(ref2cnv(canvas),sx,sy);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransformTranslate(cdCanvas* canvas, double dx, double dy);
void
cdTransformTranslate(canvas,dx,dy)
                SV* canvas;
                double dx;
                double dy;
        CODE:
                cdCanvasTransformTranslate(ref2cnv(canvas),dx,dy);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasTransformPoint(cdCanvas* canvas, int x, int y, int *tx, int *ty);
# canvas:TransformPoint(x, y: number) -> (tx, ty: number) [in Lua]
void
cdTransformPoint(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        INIT:
                int tx;
                int ty;
        PPCODE:
                cdCanvasTransformPoint(ref2cnv(canvas),x,y,&tx,&ty);
                XPUSHs(sv_2mortal(newSViv(tx)));
                XPUSHs(sv_2mortal(newSViv(ty)));

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasTransformPoint(cdCanvas* canvas, double x, double y, double *tx, double *ty);
# canvas:fTransformPoint(x, y: number) -> (tx, ty: number) [in Lua]
void
cdfTransformPoint(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        INIT:
                double tx;
                double ty;
        PPCODE:
                cdfCanvasTransformPoint(ref2cnv(canvas),x,y,&tx,&ty);
                XPUSHs(sv_2mortal(newSVnv(tx)));
                XPUSHs(sv_2mortal(newSVnv(ty)));

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasClip(cdCanvas* canvas, int mode);
int
cdClip(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                RETVAL = cdCanvasClip(ref2cnv(canvas),mode);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasClipArea(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
void
cdClipArea(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                cdCanvasClipArea(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasGetClipArea(cdCanvas* canvas, int *xmin, int *xmax, int *ymin, int *ymax);
# canvas:GetClipArea() -> (xmin, xmax, ymin, ymax, status: number) [in Lua]
void
cdGetClipArea(canvas)
                SV* canvas;
        INIT:
                int xmin;
                int xmax;
                int ymin;
                int ymax;
                int status;
        PPCODE:
                status = cdCanvasGetClipArea(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSViv(xmin)));
                XPUSHs(sv_2mortal(newSViv(xmax)));
                XPUSHs(sv_2mortal(newSViv(ymin)));
                XPUSHs(sv_2mortal(newSViv(ymax)));
                XPUSHs(sv_2mortal(newSViv(status)));

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasClipArea(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
cdfClipArea(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                cdfCanvasClipArea(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# int cdfCanvasGetClipArea(cdCanvas* canvas, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:GetClipArea() -> (xmin, xmax, ymin, ymax, status: number) [in Lua]
void
cdfGetClipArea(canvas)
                SV* canvas;
        INIT:
                int status;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        PPCODE:
                status = cdfCanvasGetClipArea(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));
                XPUSHs(sv_2mortal(newSVnv(status)));

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasIsPointInRegion(cdCanvas* canvas, int x, int y);
int
cdIsPointInRegion(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        CODE:
                RETVAL = cdCanvasIsPointInRegion(ref2cnv(canvas),x,y);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasOffsetRegion(cdCanvas* canvas, int x, int y);
void
cdOffsetRegion(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        CODE:
                cdCanvasOffsetRegion(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetRegionBox(cdCanvas* canvas, int *xmin, int *xmax, int *ymin, int *ymax);
# canvas:GetRegionBox() -> (xmin, xmax, ymin, ymax, status: number) [in Lua]
void
cdGetRegionBox(canvas)
                SV* canvas;
        INIT:
                int status = 4; /* inspired by Lua */
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        PPCODE:
                cdCanvasGetRegionBox(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSViv(xmin)));
                XPUSHs(sv_2mortal(newSViv(xmax)));
                XPUSHs(sv_2mortal(newSViv(ymin)));
                XPUSHs(sv_2mortal(newSViv(ymax)));
                XPUSHs(sv_2mortal(newSViv(status)));

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasRegionCombineMode(cdCanvas* canvas, int mode);
int
cdRegionCombineMode(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                RETVAL = cdCanvasRegionCombineMode(ref2cnv(canvas),mode);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPixel(cdCanvas* canvas, int x, int y, long color);
void
cdPixel(canvas,x,y,color)
                SV* canvas;
                int x;
                int y;
                long color;
        CODE:
                cdCanvasPixel(ref2cnv(canvas),x,y,color);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasMark(cdCanvas* canvas, int x, int y);
void
cdMark(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        CODE:
                cdCanvasMark(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasBegin(cdCanvas* canvas, int mode);
void
cdBegin(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                cdCanvasBegin(ref2cnv(canvas),mode);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPathSet(cdCanvas* canvas, int action);
void
cdPathSet(canvas,action)
                SV* canvas;
                int action;
        CODE:
                cdCanvasPathSet(ref2cnv(canvas),action);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasEnd(cdCanvas* canvas);
void
cdEnd(canvas)
                SV* canvas;
        CODE:
                cdCanvasEnd(ref2cnv(canvas));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasLine(cdCanvas* canvas, int x1, int y1, int x2, int y2);
void
cdLine(canvas,x1,y1,x2,y2)
                SV* canvas;
                int x1;
                int y1;
                int x2;
                int y2;
        CODE:
                cdCanvasLine(ref2cnv(canvas),x1,y1,x2,y2);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasVertex(cdCanvas* canvas, int x, int y);
void
cdVertex(canvas,x,y)
                SV* canvas;
                int x;
                int y;
        CODE:
                cdCanvasVertex(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasRect(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
void
cdRect(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                cdCanvasRect(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasBox(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
void
cdBox(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                cdCanvasBox(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasArc(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
void
cdArc(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                int xc;
                int yc;
                int w;
                int h;
                double angle1;
                double angle2;
        CODE:
                cdCanvasArc(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasSector(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
void
cdSector(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                int xc;
                int yc;
                int w;
                int h;
                double angle1;
                double angle2;
        CODE:
                cdCanvasSector(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasChord(cdCanvas* canvas, int xc, int yc, int w, int h, double angle1, double angle2);
void
cdChord(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                int xc;
                int yc;
                int w;
                int h;
                double angle1;
                double angle2;
        CODE:
                cdCanvasChord(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasText(cdCanvas* canvas, int x, int y, const char* s);
void
cdText(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        CODE:
                cdCanvasText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasLine(cdCanvas* canvas, double x1, double y1, double x2, double y2);
void
cdfLine(canvas,x1,y1,x2,y2)
                SV* canvas;
                double x1;
                double y1;
                double x2;
                double y2;
        CODE:
                cdfCanvasLine(ref2cnv(canvas),x1,y1,x2,y2);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasVertex(cdCanvas* canvas, double x, double y);
void
cdfVertex(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                cdfCanvasVertex(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasRect(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
cdfRect(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                cdfCanvasRect(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasBox(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
cdfBox(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                cdfCanvasBox(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasArc(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
cdfArc(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                cdfCanvasArc(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasSector(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
cdfSector(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                cdfCanvasSector(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasChord(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
cdfChord(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                cdfCanvasChord(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/cd.h>
# void cdfCanvasText(cdCanvas* canvas, double x, double y, const char* s);
void
cdfText(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        CODE:
                cdfCanvasText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasSetBackground(cdCanvas* canvas, long color);
void
cdSetBackground(canvas,color)
                SV* canvas;
                long color;
        CODE:
                cdCanvasSetBackground(ref2cnv(canvas),color);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasSetForeground(cdCanvas* canvas, long color);
void
cdSetForeground(canvas,color)
                SV* canvas;
                long color;
        CODE:
                cdCanvasSetForeground(ref2cnv(canvas),color);

#### Original C function from <.../cd/include/cd.h>
# long cdCanvasBackground(cdCanvas* canvas, long color);
long
cdBackground(canvas,color)
                SV* canvas;
                long color;
        CODE:
                RETVAL = cdCanvasBackground(ref2cnv(canvas),color);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# long cdCanvasForeground(cdCanvas* canvas, long color);
long
cdForeground(canvas,color)
                SV* canvas;
                long color;
        CODE:
                RETVAL = cdCanvasForeground(ref2cnv(canvas),color);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasBackOpacity(cdCanvas* canvas, int opacity);
int
cdBackOpacity(canvas,opacity)
                SV* canvas;
                int opacity;
        CODE:
                RETVAL = cdCanvasBackOpacity(ref2cnv(canvas),opacity);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasWriteMode(cdCanvas* canvas, int mode);
int
cdWriteMode(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                RETVAL = cdCanvasWriteMode(ref2cnv(canvas),mode);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasLineStyle(cdCanvas* canvas, int style);
int
cdLineStyle(canvas,style)
                SV* canvas;
                int style;
        CODE:
                RETVAL = cdCanvasLineStyle(ref2cnv(canvas),style);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasLineStyleDashes(cdCanvas* canvas, const int* dashes, int count);
# canvas:LineStyleDashes(dashes: table, count: number) -> (old_style: number) [in Lua]
void
cdLineStyleDashes(canvas,dashes)
                SV* canvas;
                SV* dashes;
        INIT:
                int *tmpdashes;
                int count;
        CODE:
                if (AV2int(dashes, &tmpdashes, &count))
                    cdCanvasLineStyleDashes(ref2cnv(canvas),tmpdashes,count);
                else
                    warn("Warning: cdLineStyleDashes() invalid 'dashes' parameter");


#### Original C function from <.../cd/include/cd.h>
# int cdCanvasLineWidth(cdCanvas* canvas, int width);
int
cdLineWidth(canvas,width)
                SV* canvas;
                int width;
        CODE:
                RETVAL = cdCanvasLineWidth(ref2cnv(canvas),width);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasLineJoin(cdCanvas* canvas, int join);
int
cdLineJoin(canvas,join)
                SV* canvas;
                int join;
        CODE:
                RETVAL = cdCanvasLineJoin(ref2cnv(canvas),join);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasLineCap(cdCanvas* canvas, int cap);
int
cdLineCap(canvas,cap)
                SV* canvas;
                int cap;
        CODE:
                RETVAL = cdCanvasLineCap(ref2cnv(canvas),cap);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasInteriorStyle(cdCanvas* canvas, int style);
int
cdInteriorStyle(canvas,style)
                SV* canvas;
                int style;
        CODE:
                RETVAL = cdCanvasInteriorStyle(ref2cnv(canvas),style);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasHatch(cdCanvas* canvas, int style);
int
cdHatch(canvas,style)
                SV* canvas;
                int style;
        CODE:
                RETVAL = cdCanvasHatch(ref2cnv(canvas),style);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasStipple(cdCanvas* canvas, int w, int h, const unsigned char* stipple);
void
cdStipple(canvas,stipple)
                SV* canvas;
                IUP::Canvas::Stipple stipple;
        CODE:
                cdCanvasStipple(ref2cnv(canvas),stipple->w,stipple->h,stipple->fgbg);

#### Original C function from <.../cd/include/cd.h>
# unsigned char* cdCanvasGetStipple(cdCanvas* canvas, int *n, int *m);
# canvas:GetStipple() - > (stipple: cdStipple) [in Lua]
IUP::Canvas::Stipple
cdGetStipple(canvas)
                SV* canvas;
        INIT:
                int w, h;
                unsigned char *data;
                char *CLASS = "IUP::Canvas::Stipple";  /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                data = cdCanvasGetStipple(ref2cnv(canvas),&w,&h);
                if (!data || w<=0 || h<=0) XSRETURN_UNDEF;
                Newz(0, RETVAL, 1, struct __IUPinternal_cdStipple);
                if (!RETVAL) XSRETURN_UNDEF;
                RETVAL->fgbg = malloc(sizeof(unsigned long)*w*h);
                if (!RETVAL->fgbg) {
                  free(RETVAL);
                  XSRETURN_UNDEF;
                }
                RETVAL->w = w;
                RETVAL->h = h;
                memcpy(RETVAL->fgbg, data, w*h*sizeof(unsigned char)); /* XXX-CHECKLATER we are returning a copy of the data */
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPattern(cdCanvas* canvas, int w, int h, long const int *pattern);
# canvas:Pattern(pattern: cdPattern) [in Lua]
void
cdPattern(canvas,pattern)
                SV* canvas;
                IUP::Canvas::Pattern pattern;
        CODE:
                cdCanvasPattern(ref2cnv(canvas),pattern->w,pattern->h,pattern->pattern);

#### Original C function from <.../cd/include/cd.h>
# long* cdCanvasGetPattern(cdCanvas* canvas, int* w, int* h);
# canvas:GetPattern() - > (pattern: cdPattern) [in Lua]
IUP::Canvas::Pattern
cdGetPattern(canvas)
                SV* canvas;                
        INIT:
                int w, h;
                long *data;
                char *CLASS = "IUP::Canvas::Pattern";  /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                data = cdCanvasGetPattern(ref2cnv(canvas),&w,&h);
                if (!data || w<=0 || h<=0) XSRETURN_UNDEF;
                Newz(0, RETVAL, 1, struct __IUPinternal_cdPattern);
                if (!RETVAL) XSRETURN_UNDEF;
                RETVAL->pattern = malloc(sizeof(long)*w*h);
                if (!RETVAL->pattern) {
                  free(RETVAL);
                  XSRETURN_UNDEF;
                }
                RETVAL->w = w;
                RETVAL->h = h;
                memcpy(RETVAL->pattern, data, w*h*sizeof(long)); /* XXX-CHECKLATER we are returning a copy of the data */
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasFillMode(cdCanvas* canvas, int mode);
int
cdFillMode(canvas,mode)
                SV* canvas;
                int mode;
        CODE:
                RETVAL = cdCanvasFillMode(ref2cnv(canvas),mode);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasFont(cdCanvas* canvas, const char* type_face, int style, int size);
int
cdFont(canvas,type_face,style,size)
                SV* canvas;
                const char* type_face;
                int style;
                int size;
        CODE:
                RETVAL = cdCanvasFont(ref2cnv(canvas),type_face,style,size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetFont(cdCanvas* canvas, char *type_face, int *style, int *size);
# canvas:GetFont() -> (typeface: string, style, size: number) [in Lua]
void
cdGetFont(canvas,type_face,style,size)
                SV* canvas;
        INIT:
                char type_face[1024]; /* XXX-CHECKLATER (HARDCODED BUFFER SIZE) 1024 taken from cd_private.h */
                int style;
                int size;
        PPCODE:
                cdCanvasGetFont(ref2cnv(canvas),type_face,&style,&size);
                XPUSHs(sv_2mortal(newSVpv(type_face,0)));
                XPUSHs(sv_2mortal(newSViv(style)));
                XPUSHs(sv_2mortal(newSViv(size)));

#### Original C function from <.../cd/include/cd.h>
# char* cdCanvasNativeFont(cdCanvas* canvas, const char* font);
char*
cdNativeFont(canvas,font)
                SV* canvas;
                const char* font;
        CODE:
                RETVAL = cdCanvasNativeFont(ref2cnv(canvas),font);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasTextAlignment(cdCanvas* canvas, int alignment);
int
cdTextAlignment(canvas,alignment)
                SV* canvas;
                int alignment;
        CODE:
                RETVAL = cdCanvasTextAlignment(ref2cnv(canvas),alignment);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# double cdCanvasTextOrientation(cdCanvas* canvas, double angle);
double
cdTextOrientation(canvas,angle)
                SV* canvas;
                double angle;
        CODE:
                RETVAL = cdCanvasTextOrientation(ref2cnv(canvas),angle);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasMarkType(cdCanvas* canvas, int type);
int
cdMarkType(canvas,type)
                SV* canvas;
                int type;
        CODE:
                RETVAL = cdCanvasMarkType(ref2cnv(canvas),type);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasMarkSize(cdCanvas* canvas, int size);
int
cdMarkSize(canvas,size)
                SV* canvas;
                int size;
        CODE:
                RETVAL = cdCanvasMarkSize(ref2cnv(canvas),size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasVectorText(cdCanvas* canvas, int x, int y, const char* s);
void
cdVectorText(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        CODE:
                cdCanvasVectorText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasMultiLineVectorText(cdCanvas* canvas, int x, int y, const char* s);
void
cdMultiLineVectorText(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        CODE:
                cdCanvasMultiLineVectorText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/cd.h>
# char* cdCanvasVectorFont(cdCanvas* canvas, const char *filename);
char*
cdVectorFont(canvas,filename)
                SV* canvas;
                const char* filename;
        CODE:
                RETVAL = cdCanvasVectorFont(ref2cnv(canvas),filename);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasVectorTextDirection(cdCanvas* canvas, int x1, int y1, int x2, int y2);
void
cdVectorTextDirection(canvas,x1,y1,x2,y2)
                SV* canvas;
                int x1;
                int y1;
                int x2;
                int y2;
        CODE:
                cdCanvasVectorTextDirection(ref2cnv(canvas),x1,y1,x2,y2);

#### Original C function from <.../cd/include/cd.h>
# double* cdCanvasVectorTextTransform(cdCanvas* canvas, const double* matrix);
# canvas:VectorTextTransform(matrix: table) -> (old_matrix: table) [in Lua] 
SV*
cdVectorTextTransform(canvas,matrix)
                SV* canvas;
                SV* matrix;
        INIT:
                double tmpmatrix[6];
                double *oldmatrix;
        CODE:
                if (!AV2transmatrix(matrix,tmpmatrix)) {
                  warn("Warning: cdVectorTextTransform() invalid 'matrix' parameter");
                  XSRETURN_UNDEF;
                }  
                oldmatrix = cdCanvasVectorTextTransform(ref2cnv(canvas),tmpmatrix);
                RETVAL = transmatrix2AV(oldmatrix);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasVectorTextSize(cdCanvas* canvas, int size_x, int size_y, const char* s);
void
cdVectorTextSize(canvas,size_x,size_y,s)
                SV* canvas;
                int size_x;
                int size_y;
                const char* s;
        CODE:
                cdCanvasVectorTextSize(ref2cnv(canvas),size_x,size_y,s);

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasVectorCharSize(cdCanvas* canvas, int size);
int
cdVectorCharSize(canvas,size)
                SV* canvas;
                int size;
        CODE:
                RETVAL = cdCanvasVectorCharSize(ref2cnv(canvas),size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasVectorFontSize(cdCanvas* canvas, double size_x, double size_y);
void
cdVectorFontSize(canvas,size_x,size_y)
                SV* canvas;
                double size_x;
                double size_y;
        CODE:
                cdCanvasVectorFontSize(ref2cnv(canvas),size_x,size_y);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetVectorFontSize(cdCanvas* canvas, double *size_x, double *size_y);
# canvas:GetVectorFontSize() -> (size_x, size_y: number) [in Lua]
void
cdGetVectorFontSize(canvas)
                SV* canvas;
        INIT:
                double size_x;
                double size_y;
        PPCODE:
                cdCanvasGetVectorFontSize(ref2cnv(canvas),&size_x,&size_y);
                XPUSHs(sv_2mortal(newSVnv(size_x)));
                XPUSHs(sv_2mortal(newSVnv(size_y)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetVectorTextSize(cdCanvas* canvas, const char* s, int *x, int *y);
# canvas:GetVectorTextSize(text: string) -> (width, height: number) [in Lua]
void
cdGetVectorTextSize(canvas,s)
                SV* canvas;
                const char* s;
        INIT:
                int x;
                int y;
        PPCODE:
                cdCanvasGetVectorTextSize(ref2cnv(canvas),s,&x,&y);
                XPUSHs(sv_2mortal(newSViv(x)));
                XPUSHs(sv_2mortal(newSViv(y)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetVectorTextBounds(cdCanvas* canvas, const char* s, int x, int y, int *rect);
# canvas:GetVectorTextBounds(text: string, x, y: number) -> (rect: table) [in Lua]
void
cdGetVectorTextBounds(canvas,s,x,y)
                SV* canvas;
                const char* s;
                int x;
                int y;
        INIT:
                int rect[8];
        PPCODE:
                cdCanvasGetVectorTextBounds(ref2cnv(canvas),s,x,y,rect);
                /* XXX-CHECKLATER maybe return an arrayref */
                XPUSHs(sv_2mortal(newSViv(rect[0]))); /* x0 */
                XPUSHs(sv_2mortal(newSViv(rect[1]))); /* y0 */
                XPUSHs(sv_2mortal(newSViv(rect[2]))); /* x1 */
                XPUSHs(sv_2mortal(newSViv(rect[3]))); /* y1 */
                XPUSHs(sv_2mortal(newSViv(rect[4]))); /* x2 */
                XPUSHs(sv_2mortal(newSViv(rect[5]))); /* y2 */
                XPUSHs(sv_2mortal(newSViv(rect[6]))); /* x3 */
                XPUSHs(sv_2mortal(newSViv(rect[7]))); /* y3 */

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetVectorTextBox(cdCanvas* canvas, int x, int y, const char *s, int *xmin, int *xmax, int *ymin, int *ymax);
# canvas:GetVectorTextBox(x, y: number, text: string) -> (xmin, xmax, ymin, ymax: number) [in Lua]
void
cdGetVectorTextBox(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        INIT:
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        PPCODE:
                cdCanvasGetVectorTextBox(ref2cnv(canvas),x,y,s,&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSViv(xmin)));
                XPUSHs(sv_2mortal(newSViv(xmax)));
                XPUSHs(sv_2mortal(newSViv(ymin)));
                XPUSHs(sv_2mortal(newSViv(ymax)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetFontDim(cdCanvas* canvas, int *max_width, int *height, int *ascent, int *descent);
# canvas:GetFontDim() -> (max_width, height, ascent, descent: number) [in Lua]
void
cdGetFontDim(canvas)
                SV* canvas;
        INIT:
                int max_width;
                int height;
                int ascent;
                int descent;
        PPCODE:
                cdCanvasGetFontDim(ref2cnv(canvas),&max_width,&height,&ascent,&descent);
                XPUSHs(sv_2mortal(newSViv(max_width)));
                XPUSHs(sv_2mortal(newSViv(height)));
                XPUSHs(sv_2mortal(newSViv(ascent)));
                XPUSHs(sv_2mortal(newSViv(descent)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetTextSize(cdCanvas* canvas, const char* s, int *width, int *height);
# canvas:GetTextSize(text: string) -> (width, heigth: number) [in Lua]
void
cdGetTextSize(canvas,s)
                SV* canvas;
                const char* s;
        INIT:
                int width;
                int height;
        PPCODE:
                cdCanvasGetTextSize(ref2cnv(canvas),s,&width,&height);
                XPUSHs(sv_2mortal(newSViv(width)));
                XPUSHs(sv_2mortal(newSViv(height)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetTextBox(cdCanvas* canvas, int x, int y, const char* s, int *xmin, int *xmax, int *ymin, int *ymax);
# canvas:GetTextBox(x, y: number, text: string) -> (xmin, xmax, ymin, ymax: number) [in Lua]
void
cdGetTextBox(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        INIT:
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        PPCODE:
                cdCanvasGetTextBox(ref2cnv(canvas),x,y,s,&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSViv(xmin)));
                XPUSHs(sv_2mortal(newSViv(xmax)));
                XPUSHs(sv_2mortal(newSViv(ymin)));
                XPUSHs(sv_2mortal(newSViv(ymax)));

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetTextBounds(cdCanvas* canvas, int x, int y, const char* s, int *rect);
# canvas:GetTextBounds(x, y: number, text: string) -> (rect: table) [in Lua]
void
cdGetTextBounds(canvas,x,y,s)
                SV* canvas;
                int x;
                int y;
                const char* s;
        INIT:
                int rect[8];
        PPCODE:
                cdCanvasGetTextBounds(ref2cnv(canvas),x,y,s,rect);
                /* XXX-CHECKLATER maybe return an arrayref */
                XPUSHs(sv_2mortal(newSViv(rect[0]))); /* x0 */
                XPUSHs(sv_2mortal(newSViv(rect[1]))); /* y0 */
                XPUSHs(sv_2mortal(newSViv(rect[2]))); /* x1 */
                XPUSHs(sv_2mortal(newSViv(rect[3]))); /* y1 */
                XPUSHs(sv_2mortal(newSViv(rect[4]))); /* x2 */
                XPUSHs(sv_2mortal(newSViv(rect[5]))); /* y2 */
                XPUSHs(sv_2mortal(newSViv(rect[6]))); /* x3 */
                XPUSHs(sv_2mortal(newSViv(rect[7]))); /* y3 */

#### Original C function from <.../cd/include/cd.h>
# int cdCanvasGetColorPlanes(cdCanvas* canvas);
int
cdGetColorPlanes(canvas)
                SV* canvas;
        CODE:
                RETVAL = cdCanvasGetColorPlanes(ref2cnv(canvas));
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPalette(cdCanvas* canvas, int n, const long *palette, int mode);
# canvas:Palette(palette: cdPalette; mode: number) [in Lua]
void
cdPalette(canvas,palette,mode)
                SV *canvas;
                IUP::Canvas::Palette palette;
                int mode;
        PREINIT:
                int n;
                long* tmppalette;
        CODE:
                cdCanvasPalette(ref2cnv(canvas),palette->n,palette->palette,mode);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetImage(cdCanvas* canvas, cdImage* image, int x, int y);
IUP::Canvas::InternalServerImage
cdGetImage(canvas,x,y,w,h)
                SV* canvas;                
                int x;
                int y;
                int w;
                int h;
        INIT:
                //char *CLASS = "IUP::Canvas::InternalServerImage";  /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                RETVAL = cdCanvasCreateImage(ref2cnv(canvas),w,h);
                if (!RETVAL) XSRETURN_UNDEF;
                cdCanvasGetImage(ref2cnv(canvas),RETVAL,x,y);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPutImageRect(cdCanvas* canvas, cdImage* image, int x, int y, int xmin, int xmax, int ymin, int ymax);
void
cdPutImageRect(canvas,image,x,y,xmin,xmax,ymin,ymax)
                SV* canvas;
                IUP::Canvas::InternalServerImage image;
                int x;
                int y;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                cdCanvasPutImageRect(ref2cnv(canvas),image,x,y,xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasScrollArea(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax, int dx, int dy);
void
cdScrollArea(canvas,xmin,xmax,ymin,ymax,dx,dy)
                SV* canvas;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
                int dx;
                int dy;
        CODE:
                cdCanvasScrollArea(ref2cnv(canvas),xmin,xmax,ymin,ymax,dx,dy);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasPutBitmap(cdCanvas* canvas, cdBitmap* bitmap, int x, int y, int w, int h);
void
cdPutBitmap(canvas,bitmap,x,y,w,h)
                SV* canvas;
                IUP::Canvas::Bitmap bitmap;
                int x;
                int y;
                int w;
                int h;
        CODE:
                cdCanvasPutBitmap(ref2cnv(canvas),bitmap,x,y,w,h);

#### Original C function from <.../cd/include/cd.h>
# void cdCanvasGetBitmap(cdCanvas* canvas, cdBitmap* bitmap, int x, int y);
IUP::Canvas::Bitmap
cdGetBitmap(canvas,x,y,w,h)
                SV* canvas;
                int x;
                int y;
                int w;
                int h;
        INIT:
                cdBitmap* bmp;
                char *CLASS = "IUP::Canvas::Bitmap"; /* XXX-CHECKLATER ugly hack to handle return value conversion */
        CODE:
                bmp = cdCreateBitmap(w, h, CD_RGB);
                cdCanvasGetBitmap(ref2cnv(canvas),bmp,x,y);
                RETVAL = bmp;
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# long cdEncodeColor(unsigned char red, unsigned char green, unsigned char blue);
long
cdEncodeColor(pkg,red,green,blue)
                SV* pkg;
                unsigned char red;
                unsigned char green;
                unsigned char blue;
        CODE:                
                RETVAL = cdEncodeColor(red,green,blue);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# void cdDecodeColor(long color, unsigned char* red, unsigned char* green, unsigned char* blue);
void
cdDecodeColor(pkg,color,red,green,blue)
                SV* pkg;
                long color;
        INIT:
                unsigned char red;
                unsigned char green;
                unsigned char blue;
        CODE:
                cdDecodeColor(color,&red,&green,&blue);
                XPUSHs(sv_2mortal(newSViv(red)));
                XPUSHs(sv_2mortal(newSViv(green)));
                XPUSHs(sv_2mortal(newSViv(blue)));

#### Original C function from <.../cd/include/cd.h>
# unsigned char cdDecodeAlpha(long color);
unsigned char
cdDecodeAlpha(pkg,color)
                SV* pkg;
                long color;
        CODE:
                RETVAL = cdDecodeAlpha(color);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/cd.h>
# long cdEncodeAlpha(long color, unsigned char alpha);
long
cdEncodeAlpha(pkg,color,alpha)
                SV* pkg;
                long color;
                unsigned char alpha;
        CODE:
                RETVAL = cdEncodeAlpha(color,alpha);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasWindow(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
wdWindow(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasWindow(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetWindow(cdCanvas* canvas, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:wGetWindow() -> (xmin, xmax, ymin, ymax: number) [in Lua]
void
wdGetWindow(canvas)
                SV* canvas;
        INIT:
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        PPCODE:
                wdCanvasGetWindow(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));
                

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasViewport(cdCanvas* canvas, int xmin, int xmax, int ymin, int ymax);
void
wdViewport(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                wdCanvasViewport(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetViewport(cdCanvas* canvas, int *xmin, int *xmax, int *ymin, int *ymax);
# canvas:wGetViewport() -> (xmin, xmax, ymin, ymax: number) [in Lua]
void
wdGetViewport(canvas)
                SV* canvas;
        INIT:
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        PPCODE:
                wdCanvasGetViewport(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSViv(xmin)));
                XPUSHs(sv_2mortal(newSViv(xmax)));
                XPUSHs(sv_2mortal(newSViv(ymin)));
                XPUSHs(sv_2mortal(newSViv(ymax)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasWorld2Canvas(cdCanvas* canvas, double xw, double yw, int *xv, int *yv);
# canvas:wWorld2Canvas(xw, yw: number) -> (xv, yv: number) [in Lua]
void
wdWorld2Canvas(canvas,xw,yw)
                SV* canvas;
                double xw;
                double yw;
        INIT:
                int xv;
                int yv;
        PPCODE:
                wdCanvasWorld2Canvas(ref2cnv(canvas),xw,yw,&xv,&yv);
                XPUSHs(sv_2mortal(newSViv(xv)));
                XPUSHs(sv_2mortal(newSViv(yv)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasWorld2CanvasSize(cdCanvas* canvas, double hw, double vw, int *hv, int *vv);
# Lua ???
void
wdWorld2CanvasSize(canvas,hw,vw)
                SV* canvas;
                double hw;
                double vw;
        INIT:
                int hv;
                int vv;
        PPCODE:
                wdCanvasWorld2CanvasSize(ref2cnv(canvas),hw,vw,&hv,&vv);
                XPUSHs(sv_2mortal(newSViv(hv)));
                XPUSHs(sv_2mortal(newSViv(vv)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasCanvas2World(cdCanvas* canvas, int xv, int yv, double *xw, double *yw);
# canvas:wCanvas2World(xv, yv: number) -> (xw, yw: number) [in Lua]
void
wdCanvas2World(canvas,xv,yv)
                SV* canvas;
                int xv;
                int yv;
        INIT:
                double xw;
                double yw;
        PPCODE:
                wdCanvasCanvas2World(ref2cnv(canvas),xv,yv,&xw,&yw);
                XPUSHs(sv_2mortal(newSVnv(xw)));
                XPUSHs(sv_2mortal(newSVnv(yw)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasSetTransform(cdCanvas* canvas, double sx, double sy, double tx, double ty);
void
wdSetTransform(canvas,sx,sy,tx,ty)
                SV* canvas;
                double sx;
                double sy;
                double tx;
                double ty;
        CODE:
                wdCanvasSetTransform(ref2cnv(canvas),sx,sy,tx,ty);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetTransform(cdCanvas* canvas, double *sx, double *sy, double *tx, double *ty);
# canvas:wGetTransform() -> (sx, sy, tx, ty: number) [in Lua]

void
wdGetTransform(canvas)
                SV* canvas;
        INIT:
                double sx;
                double sy;
                double tx;
                double ty;
        PPCODE:
                wdCanvasGetTransform(ref2cnv(canvas),&sx,&sy,&tx,&ty);
                XPUSHs(sv_2mortal(newSVnv(sx)));
                XPUSHs(sv_2mortal(newSVnv(sy)));
                XPUSHs(sv_2mortal(newSVnv(tx)));
                XPUSHs(sv_2mortal(newSVnv(ty)));                

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasTranslate(cdCanvas* canvas, double dtx, double dty);
void
wdTranslate(canvas,dtx,dty)
                SV* canvas;
                double dtx;
                double dty;
        CODE:
                wdCanvasTranslate(ref2cnv(canvas),dtx,dty);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasScale(cdCanvas* canvas, double dsx, double dsy);
void
wdScale(canvas,dsx,dsy)
                SV* canvas;
                double dsx;
                double dsy;
        CODE:
                wdCanvasScale(ref2cnv(canvas),dsx,dsy);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasClipArea(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
wdClipArea(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasClipArea(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# int wdCanvasGetClipArea(cdCanvas* canvas, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:wGetClipArea() -> (xmin, xmax, ymin, ymax, status: number) (WC) [in Lua]
void
wdGetClipArea(canvas)
                SV* canvas;
        INIT:
                int status;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        PPCODE:
                status = wdCanvasGetClipArea(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));
                XPUSHs(sv_2mortal(newSViv(status)));

#### Original C function from <.../cd/include/wd.h>
# int wdCanvasIsPointInRegion(cdCanvas* canvas, double x, double y);
int
wdIsPointInRegion(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                RETVAL = wdCanvasIsPointInRegion(ref2cnv(canvas),x,y);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasOffsetRegion(cdCanvas* canvas, double x, double y);
void
wdOffsetRegion(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                wdCanvasOffsetRegion(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetRegionBox(cdCanvas* canvas, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:wGetRegionBox() -> (xmin, xmax, ymin, ymax, status: number) (WC) [in Lua]
void
wdGetRegionBox(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
        INIT:
                int status = 4; /* inspired by Lua */
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasGetRegionBox(ref2cnv(canvas),&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));
                XPUSHs(sv_2mortal(newSViv(status)));


#### Original C function from <.../cd/include/wd.h>
#xxxTODO void wdCanvasHardcopy(cdCanvas* canvas, cdContext* ctx, void *data, void(*draw_func)(cdCanvas *canvas_copy));
#xxxTODO canvas:wCanvasHardcopy(ctx: number, data: string or userdata, draw_func: function) [in Lua]
#void
#wdHardcopy(canvas,ctx,data,draw_func)
#                SV* canvas;
#                cdContext* ctx;
#                void* data;
#                void(* draw_func;
#        CODE:
#                wdCanvasHardcopy(ref2cnv(canvas),ctx,data,draw_func);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasPixel(cdCanvas* canvas, double x, double y, long color);
void
wdPixel(canvas,x,y,color)
                SV* canvas;
                double x;
                double y;
                long color;
        CODE:
                wdCanvasPixel(ref2cnv(canvas),x,y,color);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasMark(cdCanvas* canvas, double x, double y);
void
wdMark(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                wdCanvasMark(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasLine(cdCanvas* canvas, double x1, double y1, double x2, double y2);
void
wdLine(canvas,x1,y1,x2,y2)
                SV* canvas;
                double x1;
                double y1;
                double x2;
                double y2;
        CODE:
                wdCanvasLine(ref2cnv(canvas),x1,y1,x2,y2);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasVertex(cdCanvas* canvas, double x, double y);
void
wdVertex(canvas,x,y)
                SV* canvas;
                double x;
                double y;
        CODE:
                wdCanvasVertex(ref2cnv(canvas),x,y);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasRect(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
wdRect(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasRect(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasBox(cdCanvas* canvas, double xmin, double xmax, double ymin, double ymax);
void
wdBox(canvas,xmin,xmax,ymin,ymax)
                SV* canvas;
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasBox(ref2cnv(canvas),xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasArc(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
wdArc(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                wdCanvasArc(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasSector(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
wdSector(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                wdCanvasSector(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasChord(cdCanvas* canvas, double xc, double yc, double w, double h, double angle1, double angle2);
void
wdChord(canvas,xc,yc,w,h,angle1,angle2)
                SV* canvas;
                double xc;
                double yc;
                double w;
                double h;
                double angle1;
                double angle2;
        CODE:
                wdCanvasChord(ref2cnv(canvas),xc,yc,w,h,angle1,angle2);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasText(cdCanvas* canvas, double x, double y, const char* s);
void
wdText(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        CODE:
                wdCanvasText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasPutImageRect(cdCanvas* canvas, cdImage* image, double x, double y, int xmin, int xmax, int ymin, int ymax);
void
wdPutImageRect(canvas,image,x,y,xmin,xmax,ymin,ymax)
                SV* canvas;
                IUP::Canvas::InternalServerImage image;
                double x;
                double y;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                wdCanvasPutImageRect(ref2cnv(canvas),image,x,y,xmin,xmax,ymin,ymax);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasPutBitmap(cdCanvas* canvas, cdBitmap* bitmap, double x, double y, double w, double h);
void
wdPutBitmap(canvas,bitmap,x,y,w,h)
                SV* canvas;
                IUP::Canvas::Bitmap bitmap;
                double x;
                double y;
                double w;
                double h;
        CODE:
                wdCanvasPutBitmap(ref2cnv(canvas),bitmap,x,y,w,h);

#### Original C function from <.../cd/include/wd.h>
# double wdCanvasLineWidth(cdCanvas* canvas, double width);
double
wdLineWidth(canvas,width)
                SV* canvas;
                double width;
        CODE:
                RETVAL = wdCanvasLineWidth(ref2cnv(canvas),width);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# int wdCanvasFont(cdCanvas* canvas, const char* type_face, int style, double size);
int
wdFont(canvas,type_face,style,size)
                SV* canvas;
                const char* type_face;
                int style;
                double size;
        CODE:
                RETVAL = wdCanvasFont(ref2cnv(canvas),type_face,style,size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetFont(cdCanvas* canvas, char *type_face, int *style, double *size);
# canvas:wGetFont() -> (typeface: string, style, size: number) (WC) [in Lua]
void
wdGetFont(canvas,type_face,style,size)
                SV* canvas;
        INIT:
                char type_face[1024]; /* XXX-CHECKLATER (HARDCODED BUFFER SIZE) 1024 taken from cd_private.h */
                int style;
                double size;
        PPCODE:
                wdCanvasGetFont(ref2cnv(canvas),type_face,&style,&size);
                XPUSHs(sv_2mortal(newSVpv(type_face,0)));
                XPUSHs(sv_2mortal(newSViv(style)));
                XPUSHs(sv_2mortal(newSVnv(size)));

#### Original C function from <.../cd/include/wd.h>
# double wdCanvasMarkSize(cdCanvas* canvas, double size);
double
wdMarkSize(canvas,size)
                SV* canvas;
                double size;
        CODE:
                RETVAL = wdCanvasMarkSize(ref2cnv(canvas),size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetFontDim(cdCanvas* canvas, double *max_width, double *height, double *ascent, double *descent);
# canvas:wGetFontDim() -> (max_width, height, ascent, descent: number) (WC) [in Lua]
void
wdGetFontDim(canvas)
                SV* canvas;
        INIT:
                double max_width;
                double height;
                double ascent;
                double descent;
        PPCODE:
                wdCanvasGetFontDim(ref2cnv(canvas),&max_width,&height,&ascent,&descent);
                XPUSHs(sv_2mortal(newSVnv(max_width)));
                XPUSHs(sv_2mortal(newSVnv(height)));
                XPUSHs(sv_2mortal(newSVnv(ascent)));
                XPUSHs(sv_2mortal(newSVnv(descent)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetTextSize(cdCanvas* canvas, const char* s, double *width, double *height);
# canvas:wGetTextSize(text: string) -> (width, heigth: number) (WC) [in Lua]
void
wdGetTextSize(canvas,s)
                SV* canvas;
                const char* s;
        INIT:
                double width;
                double height;
        PPCODE:
                wdCanvasGetTextSize(ref2cnv(canvas),s,&width,&height);
                XPUSHs(sv_2mortal(newSVnv(width)));
                XPUSHs(sv_2mortal(newSVnv(height)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetTextBox(cdCanvas* canvas, double x, double y, const char* s, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:wGetTextBox(x, y: number, text: string) -> (xmin, xmax, ymin, ymax: number) (WC) [in Lua]
void
wdGetTextBox(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        INIT:
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        PPCODE:
                wdCanvasGetTextBox(ref2cnv(canvas),x,y,s,&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetTextBounds(cdCanvas* canvas, double x, double y, const char* s, double *rect);
# canvas:wGetTextBounds(x, y: number, text: string) -> (rect: table) (WC) [in Lua]
void
wdGetTextBounds(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        INIT:
                double rect[8];
        PPCODE:
                wdCanvasGetTextBounds(ref2cnv(canvas),x,y,s,rect);
                /* XXX-CHECKLATER maybe return an arrayref */
                XPUSHs(sv_2mortal(newSVnv(rect[0]))); /* x0 */
                XPUSHs(sv_2mortal(newSVnv(rect[1]))); /* y0 */
                XPUSHs(sv_2mortal(newSVnv(rect[2]))); /* x1 */
                XPUSHs(sv_2mortal(newSVnv(rect[3]))); /* y1 */
                XPUSHs(sv_2mortal(newSVnv(rect[4]))); /* x2 */
                XPUSHs(sv_2mortal(newSVnv(rect[5]))); /* y2 */
                XPUSHs(sv_2mortal(newSVnv(rect[6]))); /* x3 */
                XPUSHs(sv_2mortal(newSVnv(rect[7]))); /* y3 */

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasStipple(cdCanvas* canvas, int w, int h, const unsigned char*fgbg, double w_mm, double h_mm);
void
wdStipple(canvas,stipple,w_mm,h_mm)
                SV* canvas;
                IUP::Canvas::Stipple stipple;
                double w_mm;
                double h_mm;
        CODE:
                wdCanvasStipple(ref2cnv(canvas),stipple->w,stipple->h,stipple->fgbg,w_mm,h_mm);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasPattern(cdCanvas* canvas, int w, int h, const long *color, double w_mm, double h_mm);
# canvas:wPattern(pattern: cdPattern, w_mm, h_mm: number) [in Lua]
void
wdPattern(canvas,pattern,w_mm,h_mm)
                SV* canvas;
                IUP::Canvas::Pattern pattern;
                double w_mm;
                double h_mm;
        CODE:
                wdCanvasPattern(ref2cnv(canvas),pattern->w,pattern->h,pattern->pattern,w_mm,h_mm);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasVectorTextDirection(cdCanvas* canvas, double x1, double y1, double x2, double y2);
void
wdVectorTextDirection(canvas,x1,y1,x2,y2)
                SV* canvas;
                double x1;
                double y1;
                double x2;
                double y2;
        CODE:
                wdCanvasVectorTextDirection(ref2cnv(canvas),x1,y1,x2,y2);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasVectorTextSize(cdCanvas* canvas, double size_x, double size_y, const char* s);
void
wdVectorTextSize(canvas,size_x,size_y,s)
                SV* canvas;
                double size_x;
                double size_y;
                const char* s;
        CODE:
                wdCanvasVectorTextSize(ref2cnv(canvas),size_x,size_y,s);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetVectorTextSize(cdCanvas* canvas, const char* s, double *x, double *y);
# canvas:wGetVectorTextSize(text: string) -> (width, height: number) [in Lua]
void
wdGetVectorTextSize(canvas,s)
                SV* canvas;
                const char* s;
        INIT:
                double x;
                double y;
        PPCODE:
                wdCanvasGetVectorTextSize(ref2cnv(canvas),s,&x,&y);
                XPUSHs(sv_2mortal(newSVnv(x)));
                XPUSHs(sv_2mortal(newSVnv(y)));

#### Original C function from <.../cd/include/wd.h>
# double wdCanvasVectorCharSize(cdCanvas* canvas, double size);
double
wdVectorCharSize(canvas,size)
                SV* canvas;
                double size;
        CODE:
                RETVAL = wdCanvasVectorCharSize(ref2cnv(canvas),size);
        OUTPUT:
                RETVAL

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasVectorText(cdCanvas* canvas, double x, double y, const char* s);
void
wdVectorText(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        CODE:
                wdCanvasVectorText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasMultiLineVectorText(cdCanvas* canvas, double x, double y, const char* s);
void
wdMultiLineVectorText(canvas,x,y,s)
                SV* canvas;
                double x;
                double y;
                const char* s;
        CODE:
                wdCanvasMultiLineVectorText(ref2cnv(canvas),x,y,s);

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetVectorTextBounds(cdCanvas* canvas, const char* s, double x, double y, double *rect);
# canvas:wGetVectorTextBounds(text: string, x, y: number) -> (rect: table) [in Lua] 
void
wdGetVectorTextBounds(canvas,s,x,y)
                SV* canvas;
                const char* s;
                double x;
                double y;
        INIT:
                double rect[8];
        PPCODE:
                wdCanvasGetVectorTextBounds(ref2cnv(canvas),s,x,y,rect);
                /* XXX-CHECKLATER maybe return an arrayref */
                XPUSHs(sv_2mortal(newSVnv(rect[0]))); /* x0 */
                XPUSHs(sv_2mortal(newSVnv(rect[1]))); /* y0 */
                XPUSHs(sv_2mortal(newSVnv(rect[2]))); /* x1 */
                XPUSHs(sv_2mortal(newSVnv(rect[3]))); /* y1 */
                XPUSHs(sv_2mortal(newSVnv(rect[4]))); /* x2 */
                XPUSHs(sv_2mortal(newSVnv(rect[5]))); /* y2 */
                XPUSHs(sv_2mortal(newSVnv(rect[6]))); /* x3 */
                XPUSHs(sv_2mortal(newSVnv(rect[7]))); /* y3 */

#### Original C function from <.../cd/include/wd.h>
# void wdCanvasGetVectorTextBox(cdCanvas* canvas, double x, double y, const char *s, double *xmin, double *xmax, double *ymin, double *ymax);
# canvas:wGetVectorTextBox(x, y: number, text: string) -> (xmin, xmax, ymin, ymax: number) [in Lua]
void
wdGetVectorTextBox(canvas,x,y,s,xmin,xmax,ymin,ymax)
                SV* canvas;
                double x;
                double y;
                const char* s;
        INIT:
                double xmin;
                double xmax;
                double ymin;
                double ymax;
        CODE:
                wdCanvasGetVectorTextBox(ref2cnv(canvas),x,y,s,&xmin,&xmax,&ymin,&ymax);
                XPUSHs(sv_2mortal(newSVnv(xmin)));
                XPUSHs(sv_2mortal(newSVnv(xmax)));
                XPUSHs(sv_2mortal(newSVnv(ymin)));
                XPUSHs(sv_2mortal(newSVnv(ymax)));
