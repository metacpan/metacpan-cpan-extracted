
MODULE = FLTK   PACKAGE = Fl_Input

Fl_Input *
Fl_Input::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Input::draw(x=0,y=0,w=0,h=0)
  CASE: items == 5
    INPUT:
      int x
      int y
      int w
      int h
    CODE:
      THIS->draw(x,y,w,h);
  CASE: items == 1
    CODE:
      THIS->draw();

int
Fl_Input::handle(e,x=0,y=0,w=0,h=0)
  CASE: items == 6
    INPUT:
      int e
      int x
      int y
      int w
      int h
    CODE:
      RETVAL = THIS->handle(e,x,y,w,h);
    OUTPUT:
      RETVAL

void
Fl_Input::value(c=0,i=0)
  CASE: items == 3
    INPUT:
      const char *c
      int i
    INIT:
      int RETVAL;
    CODE:
      RETVAL = THIS->value(c,i);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)RETVAL);
      XSRETURN(1);
  CASE: items == 2
    INPUT:
      const char *c
    INIT:
      int RETVAL;
    CODE:
      RETVAL = THIS->value(c);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)RETVAL);
      XSRETURN(1);
  CASE: items == 1
    INIT:
      const char *RETVAL;
    CODE:
      RETVAL = THIS->value();
      ST(0) = sv_newmortal();
      sv_setpv(ST(0), (char *)RETVAL);
      XSRETURN(1);

int
Fl_Input::static_value(c,i=0)
  CASE: items == 3
    INPUT:
      const char *c
      int i
    CODE:
      RETVAL = THIS->static_value(c,i);
    OUTPUT:
      RETVAL
  CASE: items == 2
    INPUT:
      const char *c
    CODE:
      RETVAL = THIS->static_value(c);
    OUTPUT:
      RETVAL

char
Fl_Input::index(i)
  int i

int
Fl_Input::size()

void
Fl_Input::maximum_size(m=0)
  CASE: items == 2
    INPUT:
      int m
    CODE:
      THIS->maximum_size(m);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->maximum_size();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Input::show_cursor(i=0)
  CASE: items == 2
    INPUT:
      char i;
    CODE:
      THIS->show_cursor(i);
  CASE: items == 1
    INIT:
      char r;
    CODE:
      r = THIS->show_cursor();
      ST(0) = sv_newmortal();
      sv_setpvn(ST(0), (char *)&r, 1);
      XSRETURN(1);

int
Fl_Input::position(p=0,m=0)
  CASE: items == 3
    INPUT:
      int p
      int m
    CODE:
      RETVAL = THIS->position(p,m);
    OUTPUT:
      RETVAL
  CASE: items == 2
    INPUT:
      int p
    CODE:
      RETVAL = THIS->position(0);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->position();
    OUTPUT:
      RETVAL

int
Fl_Input::mark(m=0)
  CASE: items == 2
    INPUT:
      int m
    CODE:
      RETVAL = THIS->mark(m);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->mark();
    OUTPUT:
      RETVAL 

int
Fl_Input::replace(...)
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      const char *t = (const char *)SvPV(ST(3),PL_na);
      int z = (int)SvIV(ST(4));
    CODE:
      RETVAL = THIS->replace(x,y,t,z);
    OUTPUT:
      RETVAL
  CASE: items == 3
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      char c = (char)*SvPV(ST(3),PL_na);
    CODE:
      RETVAL = THIS->replace(x,y,c);
    OUTPUT:
      RETVAL

int
Fl_Input::cut(a=0,b=0)
  CASE: items == 3
    INPUT:
      int a
      int b
    CODE:
      RETVAL = THIS->cut(a,b);
    OUTPUT:
      RETVAL
  CASE: items == 2
    INPUT:
      int a
    CODE:
      RETVAL = THIS->cut(a);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->cut();
    OUTPUT:
      RETVAL

int
Fl_Input::insert(t,l=0)
  const char *t
  int l

int
Fl_Input::copy()

int
Fl_Input::undo()

int
Fl_Input::word_start(i)
  int i

int
Fl_Input::word_end(i)
  int i

int
Fl_Input::line_start(i)
  int i

int
Fl_Input::line_end(i)
  int i

int
Fl_Input::mouse_position(x,y,w,h)
  int x
  int y
  int w
  int h

int
Fl_Input::up_down_position(p,e)
  int p
  int e

void
Fl_Input::maybe_do_callback()

int
Fl_Input::xscroll()

int
Fl_Input::yscroll()

