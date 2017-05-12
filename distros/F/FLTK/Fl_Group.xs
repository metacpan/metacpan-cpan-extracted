
MODULE = FLTK   PACKAGE = Fl_Group

Fl_Group *
Fl_Group::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Group::list(...)
  CASE: items == 2
    INIT: 
      Fl_List *l = (Fl_List *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->list(l);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_List *r = (Fl_List *)0;
    CODE:
      r = THIS->list();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_List", (void*)r);
      XSRETURN(1);

int
Fl_Group::children(...)
  CASE: items == 3
    INIT:
      int tmpi = (int)SvIV(ST(1));
      const int *i;
      i = (const int *)&tmpi;
      int l = (int)SvIV(ST(2));
    CODE:
      RETVAL = THIS->children(i,l);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->children();
    OUTPUT:
      RETVAL

Fl_Widget *
Fl_Group::child(...)
  CASE: items == 3
    INIT:
      int tmpi = (int)SvIV(ST(1));
      const int *i;
      i = (const int *)&tmpi;
      int l = (int)SvIV(ST(2));
    CODE:
      RETVAL = THIS->child(i,l);
    OUTPUT:
      RETVAL
  CASE: items == 1
    INIT:
      int in = (int)SvIV(ST(1));
    CODE:
      RETVAL = THIS->child(in);
    OUTPUT:
      RETVAL

void
Fl_Group::draw()

void
Fl_Group::layout()

int
Fl_Group::handle(i)
  int i

void
Fl_Group::begin()

void
Fl_Group::end()

void
Fl_Group::add(o)
  Fl_Widget *o

void
Fl_Group::insert(...)
  CASE: items == 3
    INIT:
      Fl_Widget *w = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
      Fl_Widget *b = (Fl_Widget *)0;
      int i = 0;
    CODE:
      if(SvROK(ST(2))) {
        b = (Fl_Widget *)SvIV((SV*)SvRV(ST(2)));
        THIS->insert(*w, b);
      } else {
        i = (int)SvIV(ST(2));
        THIS->insert(*w, i);
      }

void
Fl_Group::remove(...)
  CASE: items == 2
    INIT:
      Fl_Widget *w = (Fl_Widget *)0;
      int i = 0;
    CODE:
      if(SvROK(ST(1))) {
        w = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
        THIS->remove(w);
      } else {
        i = (int)SvIV(ST(1));
        THIS->remove(i);
      }

void
Fl_Group::clear()

void
Fl_Group::replace(...)
  CASE: items == 3
    INIT:
      Fl_Widget *w = (Fl_Widget *)0;
      int i = 0;
      Fl_Widget *o = (Fl_Widget *)SvIV((SV*)SvRV(ST(2)));
    CODE:
      if(SvROK(ST(1))) {
        w = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
        THIS->replace(*w, *o);
      } else {
        i = (int)SvIV(ST(1));
        THIS->replace(i, *o);
      }

void
Fl_Group::resizable(...)
  CASE: items == 2
    INIT:
      Fl_Widget *o = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->resizable(o);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Widget *r = (Fl_Widget *)0;
    CODE:
      r = THIS->resizable();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void*)r);
      XSRETURN(1);

void
Fl_Group::add_resizable(w)
  Fl_Widget *w
  CODE:
    THIS->resizable(w);
    THIS->add(w);

void
Fl_Group::init_sizes()

void
Fl_Group::focus(...)
  CASE: items == 2
    CODE:
      if(SvROK(ST(1))) {
        Fl_Widget *w = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
        THIS->focus(w);
      } else {
        int i = (int)SvIV(ST(1));
        THIS->focus(i);
      }
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int r = 0;
    CODE:
      r = THIS->focus();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

int
Fl_Group::navigation_key()
  CODE:
    RETVAL = (int)THIS->navigation_key();
  OUTPUT:
    RETVAL


