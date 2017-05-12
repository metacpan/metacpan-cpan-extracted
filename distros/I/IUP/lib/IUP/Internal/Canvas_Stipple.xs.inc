MODULE = IUP::Canvas::Stipple        PACKAGE = IUP::Canvas::Stipple   PREFIX = __Stipple__

IUP::Canvas::Stipple
__Stipple__new(CLASS,...)
                char *CLASS
        INIT:
                int w, h, i;
                unsigned char *data;
        CODE:
                if (items==2) {
                  if (!AV2uchar2D(ST(1), &data, &w, &h)) XSRETURN_UNDEF;
                  /* XXX-CHECKLATER test for valid values 0 or 1 */
                }
                else {
                  w = SvIV(ST(1));
                  h = SvIV(ST(2));
                  if (w<=0 || h<=0) XSRETURN_UNDEF;
                  data = malloc(sizeof(long)*w*h);                  
                  if (!data) XSRETURN_UNDEF;
                  for(i=0; i<w*h; i++) data[i] = 0;
                }
                Newz(0, RETVAL, 1, struct __IUPinternal_cdStipple);
                RETVAL->w = w;
                RETVAL->h = h;
                RETVAL->fgbg = data;
        OUTPUT:
                RETVAL

unsigned char
__Stipple__Pixel(self,x,y,...)
                IUP::Canvas::Stipple self;
                int x;
                int y;
        CODE:
                if ((x >= self->w) || (x < 0)) XSRETURN_UNDEF;
                if ((y >= self->h) || (y < 0)) XSRETURN_UNDEF;
                if (items>3) {
                  self->fgbg[x+y*self->w] = SvUV(ST(3)); /* XXX-CHECKLATER test for valid values 0 or 1 */
                  XSRETURN_UNDEF;
                }
                RETVAL = self->fgbg[x+y*self->w];
        OUTPUT:
                RETVAL

int
__Stipple__Width(self)
                IUP::Canvas::Stipple self;
        CODE:
                RETVAL = self->w;
        OUTPUT:
                RETVAL

int
__Stipple__Height(self)
                IUP::Canvas::Stipple self
        CODE:
                RETVAL = self->h;
        OUTPUT:
                RETVAL

SV*
__Stipple__Data(self)
                IUP::Canvas::Stipple self
        CODE:
                RETVAL = uchar2D2AV(self->fgbg, self->w, self->h);
        OUTPUT:
                RETVAL
