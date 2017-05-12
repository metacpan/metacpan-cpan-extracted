
MODULE = FLTK   PACKAGE = Fl_Pack

Fl_Pack *
Fl_Pack::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Pack::draw()

void
Fl_Pack::spacing(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->spacing(i);
  CASE: items == 1
    INIT:
      int r = 0;
    CODE:
      r = THIS->spacing();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

uchar
Fl_Pack::horizontal()
