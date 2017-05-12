
MODULE = FLTK   PACKAGE = Fl_Tabs

Fl_Tabs *
Fl_Tabs::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Tabs::handle(i)
  int i

void
Fl_Tabs::value(w=0)
  CASE: items == 2
    INPUT:
      Fl_Widget *w
    INIT:
      int r;
    CODE:
      r = THIS->value(w);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);
  CASE: items == 1
    INIT:
      Fl_Widget *ret = (Fl_Widget *)0;
    CODE:
      ret = THIS->value();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void *)ret);
      XSRETURN(1);

void
Fl_Tabs::push(w=0)
  CASE: items == 2
    INPUT:
      Fl_Widget *w
    INIT:
      int r;
    CODE:
      r = THIS->push(w);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);
  CASE: items == 1
    INIT:
      Fl_Widget *ret = (Fl_Widget *)0;
    CODE:
      ret = THIS->push();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void *)ret);
      XSRETURN(1);

Fl_Widget *
Fl_Tabs::which(x,y)
  int x
  int y

