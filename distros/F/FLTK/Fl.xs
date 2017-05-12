
MODULE = FLTK   PACKAGE = Fl

void
display(c)
  const char *c
  CODE:
    Fl::display(c);

int
visual(i)
  int i
  CODE:
    RETVAL = Fl::visual(i);
  OUTPUT:
    RETVAL

void
own_colormap()
  CODE:
    Fl::own_colormap();

int
wait(d=0)
  CASE: items == 1
    INPUT:
      double d
    CODE:
      RETVAL = Fl::wait(d);
    OUTPUT:
      RETVAL
  CASE:
    CODE:
      RETVAL = Fl::wait();
    OUTPUT:
      RETVAL

int
ready()
  CODE:
    RETVAL = Fl::ready();
  OUTPUT:
    RETVAL

int
run()
  CODE:
    RETVAL = Fl::run();
  OUTPUT:
    RETVAL

Fl_Widget *
readqueue()
  CODE:
    RETVAL = Fl::readqueue();
  OUTPUT:
    RETVAL

int
damage()
  CODE:
    RETVAL = Fl::damage();
  OUTPUT:
    RETVAL

void
redraw()
  CODE:
    Fl::redraw();

void
flush()
  CODE:
    Fl::flush();

void
first_window(w=0)
  CASE: items == 1
    INPUT:
      Fl_Window *w
    CODE:
      Fl::first_window(w);
  CASE:
    INIT:
      Fl_Window *r;
    CODE:
      r = Fl::first_window();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Window", (void*)r);
      XSRETURN(1);

Fl_Window *
next_window(w)
  const Fl_Window *w
  CODE:
    RETVAL = Fl::next_window(w);
  OUTPUT:
    RETVAL

Fl_Window *
modal()
  CODE:
    RETVAL = Fl::modal();
  OUTPUT:
    RETVAL

void
grab(w)
  Fl_Widget *w
  CODE:
    Fl::grab(w);

void
release()
  CODE:
    Fl::release();

int
event_x()
  CODE:
    RETVAL = Fl::event_x();
  OUTPUT:
    RETVAL

int
event_y()
  CODE:
    RETVAL = Fl::event_y();
  OUTPUT:
    RETVAL

int
event_dx()
  CODE:
    RETVAL = Fl::event_dx();
  OUTPUT:
    RETVAL

int
event_dy()
  CODE:
    RETVAL = Fl::event_dy();
  OUTPUT:
    RETVAL

int
event_x_root()
  CODE:
    RETVAL = Fl::event_x_root();
  OUTPUT:
    RETVAL

int
event_y_root()
  CODE:
    RETVAL = Fl::event_y_root();
  OUTPUT:
    RETVAL

void
get_mouse(x,y)
  int x
  int y
  CODE:
    Fl::get_mouse(x,y);
  OUTPUT:
    x
    y

void
event_clicks(i=0)
  CASE: items == 1
    INPUT:
      int i
    CODE:
      Fl::event_clicks(i);
  CASE:
    INIT:
      int r;
    CODE:
      r = Fl::event_clicks();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
event_is_click(i=0)
  CASE: items == 1
    INPUT:
      int i
    CODE:
      Fl::event_is_click(i);
  CASE:
    INIT:
      int r;
    CODE:
      r = Fl::event_is_click();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

int
event_button()
  CODE:
    Fl::event_button();
  OUTPUT:
    RETVAL

void
event_state(i=0)
  CASE: items == 1
    INPUT:
      int i
    CODE:
      Fl::event_state(i);
  CASE:
    INIT:
      int r;
    CODE:
      r = Fl::event_state();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

int
event_pushed()
  CODE:
    RETVAL = Fl::event_pushed();
  OUTPUT:
    RETVAL

void
event_key(i=0)
  CASE: items == 1
    INPUT:
      int i
    CODE:
      Fl::event_key(i);
  CASE:
    INIT:
      int r;
    CODE:
      r = Fl::event_key();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

int
get_key(i)
  int i
  CODE:
    RETVAL = Fl::get_key(i);
  OUTPUT:
    RETVAL

const char *
key_name(k)
  int k
  CODE:
    RETVAL = Fl::key_name(k);
  OUTPUT:
    RETVAL

int
test_shortcut(i)
  int i
  CODE:
    RETVAL = Fl::test_shortcut(i);
  OUTPUT:
    RETVAL

const char *
event_text()
  CODE:
    RETVAL = Fl::event_text();
  OUTPUT:
    RETVAL

int
event_length()
  CODE:
    RETVAL = Fl::event_length();
  OUTPUT:
    RETVAL

int
compose(d)
  int d
  CODE:
    RETVAL = Fl::compose(d);
  OUTPUT:
    d
    RETVAL

void
compose_reset()
  CODE:
    Fl::compose_reset();

int
event_inside(...)
  CASE: items == 4
    INIT:
      int x = (int)SvIV(ST(0));
      int y = (int)SvIV(ST(1));
      int w = (int)SvIV(ST(2));
      int h = (int)SvIV(ST(3));
    CODE:
      RETVAL = Fl::event_inside(x,y,w,h);
    OUTPUT:
      RETVAL
  CASE: items == 1
    INIT:
      Fl_Widget *w = (Fl_Widget *)SvIV((SV*)SvRV(ST(0)));
    CODE:
      RETVAL = Fl::event_inside(w);
    OUTPUT:
      RETVAL

int
handle(i,w)
  int i
  Fl_Window *w
  CODE:
    RETVAL = Fl::handle(i,w);
  OUTPUT:
    RETVAL

void
belowmouse(w=0)
  CASE: items == 1
    INPUT:
      Fl_Widget *w
    CODE:
      Fl::belowmouse(w);
  CASE:
    INIT:
      Fl_Widget *w;
    CODE:
      w = Fl::belowmouse();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void*)w);
      XSRETURN(1);

void
pushed(w=0)
  CASE: items == 1
    INPUT:
      Fl_Widget *w
    CODE:
      Fl::pushed(w);
  CASE:
    INIT:
      Fl_Widget *w;
    CODE:
      w = Fl::pushed();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void*)w);
      XSRETURN(1);

void
focus(w=0)
  CASE: items == 1
    INPUT:
      Fl_Widget *w
    CODE:
      Fl::focus(w);
  CASE:
    INIT:
      Fl_Widget *w;
    CODE:
      w = Fl::focus();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Widget", (void*)w);
      XSRETURN(1);

void
copy(s,l)
  const char *s
  int l
  CODE:
    Fl::copy(s,l);

void
paste(r)
  Fl_Widget *r
  CODE:
    Fl::paste(*r);

int
dnd()
  CODE:
    RETVAL = Fl::dnd();
  OUTPUT:
    RETVAL

int
x()
  CODE:
    RETVAL = Fl::x();
  OUTPUT:
    RETVAL

int
y()
  CODE:
    RETVAL = Fl::y();
  OUTPUT:
    RETVAL

int
w()
  CODE:
    RETVAL = Fl::w();
  OUTPUT:
    RETVAL

int
h()
  CODE:
    RETVAL = Fl::h();
  OUTPUT:
    RETVAL

int
theme(c)
  const char *c
  CODE:
    RETVAL = Fl::theme(c);
  OUTPUT:
    RETVAL

void
scheme(c=0)
  CASE: items == 1
    INPUT:
      const char *c
    INIT:
      int r;
    CODE:
      r = Fl::scheme(c);
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);
  CASE:
    INIT:
      const char *ret;
    CODE:
      ret = Fl::scheme();
      ST(0) = sv_newmortal();
      sv_setpv(ST(0),(char *)ret);
      XSRETURN(1);

void
reload_scheme()
  CODE:
    Fl::reload_scheme();


