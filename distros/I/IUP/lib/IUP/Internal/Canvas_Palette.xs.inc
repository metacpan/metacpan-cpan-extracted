MODULE = IUP::Canvas::Palette        PACKAGE = IUP::Canvas::Palette   PREFIX = __Palette__

IUP::Canvas::Palette
__Palette__new(CLASS,param)
                char *CLASS
                SV *param
        INIT:
                int n, i;
                long *data, c;
        CODE:
                if (items==2 && SvROK(param) && SvROK(param) && SvTYPE(SvRV(param))==SVt_PVAV) {
                  if (!AV2long(param, &data, &n)) XSRETURN_UNDEF;
                }
                else {
                  n = SvIV(param); /* size */
                  c = CD_BLACK; /* color */
                  if (n<=0) XSRETURN_UNDEF;
                  if (n>256) n=256;
                  data = malloc(sizeof(long)*n);
                  if (!data) XSRETURN_UNDEF;
                  for(i=0; i<n; i++) data[i] = c;
                }
                Newz(0, RETVAL, 1, struct __IUPinternal_cdPalette);
                RETVAL->n = n;
                RETVAL->palette = data;
        OUTPUT:
                RETVAL

void
__Palette__DESTROY(self)
                IUP::Canvas::Palette self;
        CODE:
                if (self) {
                  if (self->palette) free(self->palette);
                  free(self);
                }

long
__Palette__Color(self,i,...)
                IUP::Canvas::Palette self;
                int i;
        CODE:
                if ((i >= self->n) || (i < 0)) XSRETURN_UNDEF;
                if (items>2) {
                  self->palette[i] = SvIV(ST(2));
                  XSRETURN_UNDEF;
                }
                RETVAL = self->palette[i];
        OUTPUT:
                RETVAL

int
__Palette__Size(self)
                IUP::Canvas::Palette self
        CODE:
                RETVAL = self->n;
        OUTPUT:
                RETVAL

SV*
__Palette__Data(self)
                IUP::Canvas::Palette self
        CODE:
                RETVAL = long2AV(self->palette, self->n);
        OUTPUT:
                RETVAL
