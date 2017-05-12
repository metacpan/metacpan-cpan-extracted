MODULE = IUP::Canvas::Bitmap        PACKAGE = IUP::Canvas::Bitmap   PREFIX = __Bitmap__

IUP::Canvas::Bitmap
__Bitmap__new(CLASS,...)
                char *CLASS
        INIT:
                cdBitmap * b;
                int w, h, type, error;
                int wr, hr, wg, hg, wb, hb, wa, ha, wi, hi, wc, hc;
                unsigned char *data_r=NULL, *data_g=NULL, *data_b=NULL, *data_a=NULL;
                unsigned char *index=NULL;
                long *colors=NULL;
                long *colors256=NULL;
                int color_count;
        CODE:
                b = NULL;
                if (items==2) {
                  /* warn("XXX-DEBUG: IUP::Canvas::Bitmap->new($file)"); */
                  b = BitmapFromFile(SvPV_nolen(ST(1)));                  
                }
                else if (items==3 && !SvROK(ST(1))
                                  && SvROK(ST(2)) && SvTYPE(SvRV(ST(2)))==SVt_PVAV) {
                  /* warn("XXX-DEBUG: IUP::Canvas::Bitmap->new($type, $pixels)"); */
                  type = SvIV(ST(1));
                  if (type==CD_RGBA) {
                    if (!AV2bitmap(ST(2),&data_r,&data_g,&data_b,&data_a,&w,&h)) XSRETURN_UNDEF;
                    b = cdInitBitmap(w, h, type, data_r, data_g, data_b, data_a);
                  }
                  else if (type==CD_RGB) {
                    if (!AV2bitmap(ST(2),&data_r,&data_g,&data_b,NULL,&w,&h)) XSRETURN_UNDEF;
                    b = cdInitBitmap(w, h, type, data_r, data_g, data_b);
                  }
                  else {
                    XSRETURN_UNDEF;
                  }
                }
                else if (items==4 && SvROK(ST(2)) && SvTYPE(SvRV(ST(2)))==SVt_PVAV
                                  && SvROK(ST(3)) && SvTYPE(SvRV(ST(3)))==SVt_PVAV) {
                  /* warn("XXX-DEBUG: IUP::Canvas::Bitmap->new($type, $pixels, $palette)"); */
                  type = SvIV(ST(1));                  
                  if (type!=CD_MAP) XSRETURN_UNDEF;
                  error = 0;
                  colors256 = malloc(sizeof(long)*256);
                  if (!colors256) error=1;
                  if (!AV2uchar2D(ST(2),&index,&w,&h)) error=1;
                  if (!AV2long(ST(3),&colors,&color_count)) error=1;
                  if (error) {
                    if (index) free(index);
                    if (colors) free(colors);
                    if (colors256) free(colors256);
                    XSRETURN_UNDEF;
                  }
                  /* palette buffer passed to cdInitBitmap has to be 256 colors long */                  
                  memset(colors256, 0, sizeof(long)*256);
                  if (color_count>256) color_count = 256;
                  memcpy(colors256, colors, sizeof(long)*color_count);
                  free(colors);                  
                  b = cdInitBitmap(w, h, type, index, colors256);
                }
                else if (items==4) {
                  /*warn("XXX-DEBUG: IUP::Canvas::Bitmap->new($type, $width, $height)");*/
                  type = SvIV(ST(1));
                  w = SvIV(ST(2));
                  h = SvIV(ST(3));                  
                  if (w<=0 || h<=0) XSRETURN_UNDEF;
                  /*warn("XXX-DEBUG: w=%d h=%d type=%d b=%p\n",w,h,type,b);*/
                  b = cdCreateBitmap(w, h, type);
                  /*warn("XXX-DEBUG: w=%d h=%d type=%d b=%p\n",w,h,type,b);*/
                }
                else {
                  warn("Error: invalid parameters for IUP::Canvas::Bitmap->new()");
                }
                /* check if we have consistent data */
                RETVAL = NULL;
                if (b) {
                  data_r = cdBitmapGetData(b, CD_IRED);
                  data_g = cdBitmapGetData(b, CD_IGREEN);
                  data_b = cdBitmapGetData(b, CD_IBLUE);
                  data_a = cdBitmapGetData(b, CD_IALPHA);
                  index  = cdBitmapGetData(b, CD_INDEX);
                  colors = (long*)cdBitmapGetData(b, CD_COLORS);
                  if (b->type==CD_RGBA && data_r && data_g && data_b && data_a) RETVAL = b;
                  if (b->type==CD_RGB && data_r && data_g && data_b) RETVAL = b;
                  if (b->type==CD_MAP && index && colors) RETVAL = b;
                  if (!RETVAL) {
                    warn("Error: image data not loaded correctly");
                    cdKillBitmap(b);
                  }
                }
        OUTPUT:
                RETVAL

void
__Bitmap__SetRect(self,xmin,xmax,ymin,ymax)
                IUP::Canvas::Bitmap self;
                int xmin;
                int xmax;
                int ymin;
                int ymax;
        CODE:
                cdBitmapSetRect(self,xmin,xmax,ymin,ymax);

IUP::Canvas::Bitmap
__Bitmap__RGB2Map(self)
                IUP::Canvas::Bitmap self;
        PREINIT:
                /* char *CLASS = "IUP::Canvas::Bitmap"; / * XXX-CHECKLATER ugly hack to handle return value conversion */
                unsigned char* index;
                long* colors;
        CODE:
                index = malloc(sizeof(unsigned char)*self->w*self->h);
                colors = malloc(sizeof(long)*256);
                if (!index || !colors) {
                  if (index) free(index);
                  if (colors) free(colors);
                  XSRETURN_UNDEF;
                }
                RETVAL = cdInitBitmap(self->w, self->h, CD_MAP, index, colors);
                if (!RETVAL) XSRETURN_UNDEF;
                cdBitmapRGB2Map(self,RETVAL);
        OUTPUT:
                RETVAL

int
__Bitmap__Width(self)
                IUP::Canvas::Bitmap self;
        CODE:
                RETVAL = self->w;
        OUTPUT:
                RETVAL

int
__Bitmap__Height(self)
                IUP::Canvas::Bitmap self;
        CODE:
                RETVAL = self->h;
        OUTPUT:
                RETVAL

int
__Bitmap__Type(self)
                IUP::Canvas::Bitmap self;
        CODE:
                RETVAL = self->type;
        OUTPUT:
                RETVAL

SV*
__Bitmap__Data(self)
                IUP::Canvas::Bitmap self;
        PREINIT:
                unsigned char *r, *g, *b, *a, *m;
        CODE:
                /* warn("XXX-DEBUG: Bitmap->Data type=%d, w=%d h=%d\n",self->type,self->w,self->h); */
                if (self->type == CD_RGBA) {
                  /* warn("XXX-DEBUG: Bitmap->Data RGBA 1\n"); */
                  r = cdBitmapGetData(self, CD_IRED);
                                  g = cdBitmapGetData(self, CD_IGREEN);
                  b = cdBitmapGetData(self, CD_IBLUE);
                  a = cdBitmapGetData(self, CD_IALPHA);
                  /* warn("XXX-DEBUG: Bitmap->Data RGBA 2 r=%p g=%p b=%p a=%p\n",r,g,b,a); */
                  if (!r || !g || !b || !a) XSRETURN_UNDEF;
                  /* warn("XXX-DEBUG: Bitmap->Data RGBA 3\n"); */
                  RETVAL = Bitmap2AV(r,g,b,a,NULL,self->w,self->h);
                }
                else if (self->type == CD_RGB) {
                  r = cdBitmapGetData(self, CD_IRED);
                  g = cdBitmapGetData(self, CD_IGREEN);
                  b = cdBitmapGetData(self, CD_IBLUE);
                  if (!r || !g || !b) XSRETURN_UNDEF;
                  RETVAL = Bitmap2AV(r,g,b,NULL,NULL,self->w,self->h);
                }
                else if (self->type == CD_MAP) {
                  m = cdBitmapGetData(self, CD_INDEX);
                  if (!m) XSRETURN_UNDEF;
                  RETVAL = Bitmap2AV(NULL,NULL,NULL,NULL,m,self->w,self->h);
                }
                else XSRETURN_UNDEF;
        OUTPUT:
                RETVAL

SV*
__Bitmap__Palette(self)
                IUP::Canvas::Bitmap self;
        PREINIT:
                long *c;
                unsigned char *m;
                int max_index=0, i;
        CODE:
                if (self->type != CD_MAP) XSRETURN_UNDEF;
                c = (long*)cdBitmapGetData(self, CD_COLORS);
                m = (unsigned char*)cdBitmapGetData(self, CD_INDEX);
                if (!c || !m) XSRETURN_UNDEF;
                for(i=0; i<self->w*self->h; i++) if(m[i]>max_index) max_index=m[i];                
                if (max_index>255) max_index=255;
                RETVAL = long2AV(c, max_index+1);
        OUTPUT:
                RETVAL

long
__Bitmap__Color(self,n,...)
                IUP::Canvas::Bitmap self;
                int n;
        PREINIT:
                long *c;
        CODE:
                if (self->type!=CD_MAP) XSRETURN_UNDEF;
                if (n<0 || n>=256) XSRETURN_UNDEF;
                c = (long*)cdBitmapGetData(self, CD_COLORS);
                if (!c) XSRETURN_UNDEF;
                if (items>2) {
                  c[n] = SvIV(ST(2));
                  XSRETURN_UNDEF;
                }
                RETVAL = c[n];
        OUTPUT:
                RETVAL

void
__Bitmap__Pixel(self,x,y,...)
                IUP::Canvas::Bitmap self;
                int x;
                int y;
        PREINIT:
                unsigned char *data_buffer=NULL, *r=NULL, *g=NULL, *b=NULL, *a=NULL, *m=NULL;
                int color_space, plane_size=0, plane_count=0, color_count=0;
                int width = self->w;
                int height = self->h;
        PPCODE:
                /* warn("XXX-DEBUG: bitmap.pixel x=%d y=%d items=%d w=%d h=%d\n",x,y,items,width,height); */
                /* warn("XXX-DEBUG: rgb=%d rgba=%d\n", (self->type==CD_RGB), (self->type==CD_RGBA)); */
                if (x<0 || x>=width || y<0 || y>=height ) {
                  warn("Error: x or y out of range");
                }
                else if (self->type==CD_RGBA) {
                  plane_count = 4;
                  r = cdBitmapGetData(self, CD_IRED);
                  g = cdBitmapGetData(self, CD_IGREEN);
                  b = cdBitmapGetData(self, CD_IBLUE);
                  a = cdBitmapGetData(self, CD_IALPHA);
                  if (r && g && b && a) {
                    if (items==3) {
                      XPUSHs(sv_2mortal(newSVuv(r[width*y+x])));
                      XPUSHs(sv_2mortal(newSVuv(g[width*y+x])));
                      XPUSHs(sv_2mortal(newSVuv(b[width*y+x])));
                      XPUSHs(sv_2mortal(newSVuv(a[width*y+x])));
                    }
                                        else if (items>3 && items<7) {
                                          warn("Error: not enough parameters, expected: Pixel(x,y,r,g,b,a)");
                                        }
                    else {
                      r[width*y+x] = SvUV(ST(3));
                      g[width*y+x] = SvUV(ST(4)); 
                      b[width*y+x] = SvUV(ST(5));
                      a[width*y+x] = SvUV(ST(6));
                    }
                  }
                }
                else if (self->type==CD_RGB) {
                  plane_count = 3;
                  r = cdBitmapGetData(self, CD_IRED);
                  g = cdBitmapGetData(self, CD_IGREEN);
                  b = cdBitmapGetData(self, CD_IBLUE);
                  if (r && g && b) {
                    if (items==3) {
                      XPUSHs(sv_2mortal(newSVuv(r[width*y+x])));
                      XPUSHs(sv_2mortal(newSVuv(g[width*y+x])));
                      XPUSHs(sv_2mortal(newSVuv(b[width*y+x])));
                    }
                                        else if (items>3 && items<6) {
                                          warn("Error: not enough parameters, expected: Pixel(x,y,r,g,b)");
                                        }
                    else {
                      r[width*y+x] = SvUV(ST(3));
                      g[width*y+x] = SvUV(ST(4)); 
                      b[width*y+x] = SvUV(ST(5));
                    }
                  }
                }
                else if (self->type==CD_MAP) {
                  plane_count = 1;
                  m = cdBitmapGetData(self, CD_INDEX);
                  if (m) {
                    if (items==3) {
                      XPUSHs(sv_2mortal(newSVuv(m[width*y+x])));
                    }
                    else if (items==4) {
                      m[width*y+x] = SvUV(ST(3));
                    }
                  }
                }

int
__Bitmap__SaveAs(self,filename,format,...)
                IUP::Canvas::Bitmap self;
                char *filename;
                char *format;
        PREINIT:
                unsigned char *data_buffer=NULL, *r=NULL, *g=NULL, *b=NULL, *a=NULL, *m=NULL;
                                unsigned char *data;
                long *c=NULL;
                imImage *image;
                int color_space, plane_size=0, plane_count=0, color_count=0;                                
        CODE:                
                plane_size = sizeof(unsigned char)*self->w*self->h;
                if (self->type==CD_RGBA) {
                  plane_count = 4;
                  color_space = (IM_RGB | IM_ALPHA);
                                  data = cdBitmapGetData(self, CD_IRED); /* full image buffer */
                }
                else if (self->type==CD_RGB) {
                  plane_count = 3;
                  color_space = IM_RGB;
                                  data = cdBitmapGetData(self, CD_IRED); /* full image buffer */
                }
                else if (self->type==CD_MAP) {
                  plane_count = 1;
                  color_space = IM_MAP;
                                  data = cdBitmapGetData(self, CD_INDEX);
                  c = (long*)cdBitmapGetData(self, CD_COLORS);
                  color_count = 256; /* XXX-CHECKLATER */
                }
                RETVAL = 999; /* means "error somewhere in perl XS code" */
                if (plane_count>0)  {
                  if (data) {                                        
                                        image = imImageInit(self->w, self->h, color_space, IM_BYTE, data, c, color_count);                    
                    if (image) {
                      if (items>=4) {
                        float res = (float)SvNV(ST(3));
                        /* warn("XXX-DEBUG: setting resolution to '%f' DPI\n", res); */
                        imImageSetAttribute(image, "XResolution", IM_FLOAT, 1, &res);
                        imImageSetAttribute(image, "YResolution", IM_FLOAT, 1, &res);
                        imImageSetAttribute(image, "ResolutionUnit", IM_BYTE, -1, "DPI"); /* "DPI" or "DPC" */
                      }
                      RETVAL = imFileImageSave(filename, format, image);  /* valid formats: TIFF JPEG PNG GIF BMP RAS ICO PNM KRN LED SGI PCX TGA */
                                          image->data[0] = NULL; /* to avoid duplicate memory release */
                      imImageDestroy(image);
                      /* warn("XXX-DEBUG: imFileImageSave RETVAL=%d\n",RETVAL); */
                    }
                  }
                }             
        OUTPUT:
                RETVAL

void
__Bitmap__DESTROY(self)
                IUP::Canvas::Bitmap self;
        CODE:
                cdKillBitmap(self);
