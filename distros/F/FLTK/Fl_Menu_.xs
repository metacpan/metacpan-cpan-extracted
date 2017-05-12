
MODULE = FLTK   PACKAGE = Fl_Menu_

Fl_Menu_ *
Fl_Menu_::new(...)
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      const char *l = (const char *)SvPV(ST(5),PL_na);
    CODE:
      RETVAL = new Fl_Menu_(x,y,w,h);
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
      RETVAL = new Fl_Menu_(x,y,w,h);
    OUTPUT:
      RETVAL 
  CASE: items == 2
    INIT:
      const char *l = (const char *)SvPV(ST(1),PL_na);
    CODE:
      RETVAL = new Fl_Menu_();
      RETVAL->copy_label(l);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = new Fl_Menu_();
    OUTPUT:
      RETVAL

void
Fl_Menu_::layout()

void
Fl_Menu_::draw()

void
Fl_Menu_::value(...)
  CASE: items == 3
    INIT:
      int i = (int)SvIV(ST(1));
      int l = (int)SvIV(ST(2));
    CODE:
      THIS->value((const int *)&i, l);
  CASE: items == 2
    INIT:
      int i = (int)SvIV(ST(1));
    CODE:
      THIS->value(i);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->value();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Menu_::item(...)
  CASE: items == 2
    INIT:
      Fl_Widget *w = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->item(w);
  CASE: items == 1
    INIT:
      Fl_Widget *r;
    CODE:
      r = THIS->item();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void*)r);
      XSRETURN(1);

int
Fl_Menu_::popup(x,y,t=0)
  int x
  int y
  const char *t

int
Fl_Menu_::pulldown(x,y,w,h,t=0,m=0)
  int x
  int y
  int w
  int h
  Fl_Widget *t
  int m

int
Fl_Menu_::handle_shortcut()

void
Fl_Menu_::global()

void
Fl_Menu_::execute(w)
  Fl_Widget *w

