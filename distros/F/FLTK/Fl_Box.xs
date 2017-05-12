
MODULE = FLTK   PACKAGE = Fl_Box

Fl_Box *
Fl_Box::new(...)
  CASE: items == 7
    INIT:
      Fl_Boxtype b = (Fl_Boxtype)SvIV((SV*)SvRV(ST(1)));
      int x = (int)SvIV(ST(2));
      int y = (int)SvIV(ST(3));
      int w = (int)SvIV(ST(4));
      int h = (int)SvIV(ST(5));
      const char *l = (const char *)SvPV(ST(6),PL_na);
    CODE:
      RETVAL = new Fl_Box(b,x,y,w,h, l);
      RETVAL->copy_label(l);
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
      RETVAL = new Fl_Box(x,y,w,h);
      RETVAL->copy_label(l);
    OUTPUT:
      RETVAL
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = new Fl_Box(x,y,w,h);
    OUTPUT:
      RETVAL

