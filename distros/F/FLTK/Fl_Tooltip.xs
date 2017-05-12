
MODULE = FLTK   PACKAGE = Fl_Tooltip

void
delay(f=0)
  CASE: items == 1
    INPUT:
      float f
    CODE:
      Fl_Tooltip::delay(f);
  CASE:
    INIT:
      float r;
    CODE:
      r = Fl_Tooltip::delay();
      ST(0) = sv_newmortal();
      sv_setnv(ST(0),(double)r);
      XSRETURN(1);

int
enabled()
  CODE:
    Fl_Tooltip::enabled();
  OUTPUT:
    RETVAL

void
enable(b=1)
  int b
  CODE:
    Fl_Tooltip::enable(b);

void
disable()
  CODE:
    Fl_Tooltip::enable(0);

void
enter(wd,x=0,y=0,w=0,h=0,t=0)
  CASE: items == 6
    INPUT:
      Fl_Widget *wd
      int x
      int y
      int w
      int h
      const char *t
    CODE:
      Fl_Tooltip::enter(wd,x,y,w,h,t);
  CASE: items == 1
    INPUT:
      Fl_Widget *wd
    CODE:
      Fl_Tooltip::enter(wd);

void
exit(w)
  Fl_Widget *w
  CODE:
    Fl_Tooltip::exit(w);

Fl_Style *
style()
  CODE:
    Fl_Tooltip::style();
  OUTPUT:
    RETVAL

void
size(s=0)
  CASE: items == 1
    INPUT:
      unsigned s
    CODE:
      Fl_Tooltip::size(s);
  CASE:
    INIT:
      unsigned r;
    CODE:
      r = Fl_Tooltip::size();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
color(c=0)
  CASE: items == 1
    INPUT:
      Fl_Color c
    CODE:
      Fl_Tooltip::color(c);
  CASE:
    INIT:
      Fl_Color r;
    CODE:
      r = Fl_Tooltip::color();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
textcolor(c=0)
  CASE: items == 1
    INPUT:
      Fl_Color c
    CODE:
      Fl_Tooltip::textcolor(c);
  CASE:
    INIT:
      Fl_Color r;
    CODE:
      r = Fl_Tooltip::textcolor();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0),(UV)r);
      XSRETURN(1);

void
boxtype(b=0)
  CASE: items == 1
    INPUT:
      Fl_Boxtype b
    CODE:
      Fl_Tooltip::boxtype(b);
  CASE:
    INIT:
      Fl_Boxtype r;
    CODE:
      r = Fl_Tooltip::boxtype();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Boxtype_", (void*)r);
      XSRETURN(1);


