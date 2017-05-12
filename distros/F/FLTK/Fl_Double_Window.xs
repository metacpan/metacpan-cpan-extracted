
MODULE = FLTK   PACKAGE = Fl_Double_Window

Fl_Double_Window *
Fl_Double_Window::new(...)
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      const char *l = (const char *)SvPV(ST(5),PL_na);
    CODE:
      RETVAL = new Fl_Double_Window(x,y,w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = new Fl_Double_Window(x,y,w,h);
    OUTPUT:
      RETVAL
  CASE: items == 4
    INIT:
      int w = (int)SvIV(ST(1));
      int h = (int)SvIV(ST(2));
      const char *l = (const char *)SvPV(ST(3),PL_na);
    CODE:
      RETVAL = new Fl_Double_Window(w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 3
    PREINIT:
      int w = (int)SvIV(ST(1));
      int h = (int)SvIV(ST(2));
    CODE:
      RETVAL = new Fl_Double_Window(w,h);
    OUTPUT:
      RETVAL

void
Fl_Window::layout()
