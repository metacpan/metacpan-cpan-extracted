MODULE = IUP::Canvas::Pattern        PACKAGE = IUP::Canvas::Pattern   PREFIX = __Pattern__

IUP::Canvas::Pattern
__Pattern__new(CLASS,...)
                char *CLASS
        INIT:
                int w, h, i;
                long *data;
        CODE:
                if (items==2) {
                  if (!AV2long2D(ST(1), &data, &w, &h)) XSRETURN_UNDEF;
                }
                else {
                  w = SvIV(ST(1));
                  h = SvIV(ST(2));
                  if (w<=0 || h<=0) XSRETURN_UNDEF;
                  data = malloc(sizeof(long)*w*h);
                  if (!data) XSRETURN_UNDEF;
                  for(i=0; i<w*h; i++) data[i] = 0;
                }
                Newz(0, RETVAL, 1, struct __IUPinternal_cdPattern);
                RETVAL->w = w;
                RETVAL->h = h;
                RETVAL->pattern = data;
        OUTPUT:
                RETVAL

long
__Pattern__Pixel(self,x,y,...)
                IUP::Canvas::Pattern self;
                int x;
                int y;
        CODE:
                if ((x >= self->w) || (x < 0)) XSRETURN_UNDEF;
                if ((y >= self->h) || (y < 0)) XSRETURN_UNDEF;
                if (items>3) {
                  self->pattern[x+y*self->w] = SvIV(ST(3));
                  XSRETURN_UNDEF;
                }
                RETVAL = self->pattern[x+y*self->w];
        OUTPUT:
                RETVAL

int
__Pattern__Width(self)
                IUP::Canvas::Pattern self
        CODE:
                RETVAL = self->w;
        OUTPUT:
                RETVAL

int
__Pattern__Height(self)
                IUP::Canvas::Pattern self
        CODE:
                RETVAL = self->h;
        OUTPUT:
                RETVAL

SV*
__Pattern__Data(self)
                IUP::Canvas::Pattern self
        CODE:
                RETVAL = long2D2AV(self->pattern, self->w, self->h);
        OUTPUT:
                RETVAL
