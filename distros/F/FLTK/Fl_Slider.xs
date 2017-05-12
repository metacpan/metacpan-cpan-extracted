
MODULE = FLTK   PACKAGE = Fl_Slider

Fl_Slider *
Fl_Slider::new(...)
  CASE: items == 7
    INIT:
      uchar t = (uchar)SvUV(ST(1));
      int x = (int)SvIV(ST(2));
      int y = (int)SvIV(ST(3));
      int w = (int)SvIV(ST(4));
      int h = (int)SvIV(ST(5));
      const char *l = (const char *)SvPV(ST(6),PL_na);
    CODE:
      RETVAL = new Fl_Slider(t,x,y,w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      const char *l = (const char *)SvPV(ST(5),PL_na);
    CODE:
      RETVAL = new Fl_Slider(x,y,w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = new Fl_Slider(x,y,w,h);
    OUTPUT:
      RETVAL

void
Fl_Slider::draw()

int
Fl_Slider::handle(i)
  int i

void
Fl_Slider::slider_size(...)
  CASE: items == 2
    INIT:
      int i;
      double d;
    CODE:
      if(SvTYPE(ST(1)) == SVt_NV) {
        d = (double)SvNV(ST(1));
        THIS->slider_size(d);
      } else if(SvTYPE(ST(1)) == SVt_IV) {
        i = (int)SvIV(ST(1));
        THIS->slider_size(i);
      } else {
        croak("Fl_Slider::slider_size() argument must be an integer or double");
      }
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->slider_size();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);

void
Fl_Slider::slider(b=0)
  CASE: items == 2
    INPUT:
      Fl_Boxtype b
    CODE:
      THIS->slider(b);
  CASE: items == 1
    INIT:
      Fl_Boxtype r;
    CODE:
      r = THIS->slider();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Boxtype_", (void*)r);
      XSRETURN(1);


