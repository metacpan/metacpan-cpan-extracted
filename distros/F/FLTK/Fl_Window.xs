
MODULE = FLTK		PACKAGE = Fl_Window		

Fl_Window *
Fl_Window::new(...)
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      const char *l = (const char *)SvPV(ST(5),PL_na);
    CODE:
      RETVAL = new Fl_Window(x,y,w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = new Fl_Window(x,y,w,h);
    OUTPUT:
      RETVAL
  CASE: items == 4
    INIT:
      int w = (int)SvIV(ST(1));
      int h = (int)SvIV(ST(2));
      const char *l = (const char *)SvPV(ST(3),PL_na);
    CODE:
      RETVAL = new Fl_Window(w,h,l);
    OUTPUT:
      RETVAL
  CASE: items == 3
    PREINIT:
      int w = (int)SvIV(ST(1));
      int h = (int)SvIV(ST(2));
    CODE:
      RETVAL = new Fl_Window(w,h);
    OUTPUT:
      RETVAL

int 
Fl_Window::handle(x)
    int x

void
Fl_Window::clear_border()

int
Fl_Window::border()

void
Fl_Window::set_modal()

int
Fl_Window::modal()

void
Fl_Window::set_non_modal()

void
Fl_Window::move(x,y)
  int x
  int y

void
Fl_Window::hotspot(...)
  CASE: items == 4
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int offscreen = (int)SvIV(ST(3));
    CODE:
      THIS->hotspot(x,y,offscreen);
  CASE: items == 3
    INIT:
      int x = 0;
      int y = 0;
      int offscreen = 0;
      Fl_Widget *p = (Fl_Widget *)0;
    CODE:
      if(SvROK(ST(1))) {
        p = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
        offscreen = (int)SvIV(ST(2));
        THIS->hotspot((const Fl_Widget *)p, offscreen);
      } else {
        int x = (int)SvIV(ST(1));
        int y = (int)SvIV(ST(2));
        THIS->hotspot(x,y);
      }
  CASE: items == 2
    INIT:
      Fl_Widget *p = (Fl_Widget *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->hotspot((const Fl_Widget *)p);

void
Fl_Window::size_range(a,b,c=0,d=0,e=0,f=0)
    int a
    int b
    int c
    int d
    int e
    int f

void
Fl_Window::label(...)
  CASE: items == 3
    INIT:
      const char *l = (const char *)SvPV(ST(1),PL_na);
      const char *i = (const char *)SvPV(ST(2),PL_na);
    CODE:
      THIS->label(l,i);
      XSRETURN_EMPTY;
  CASE: items == 2
    INIT:
      const char *lab = (const char *)SvPV(ST(1),PL_na);
    CODE:
      THIS->label(lab);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const char *r = 0;
    CODE:
      r = THIS->label();
      ST(0) = sv_newmortal();
      sv_setpv((SV*)ST(0), (char *)r);
      XSRETURN(1);

void
Fl_Window::iconlabel(...)
  CASE: items == 2
    INIT:
      const char *lab = (const char *)SvPV(ST(1),PL_na);
    CODE:
      THIS->iconlabel(lab);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const char *r = 0;
    CODE:
      r = THIS->iconlabel();
      ST(0) = sv_newmortal();
      sv_setpv((SV*)ST(0), (char *)r);
      XSRETURN(1);

void
Fl_Window::icon(ic)
  const void *ic

void
Fl_Window::xclass(...)
  CASE: items == 2
    INIT:
      const char *v = (const char *)SvPV(ST(1),PL_na);
    CODE:
      THIS->xclass(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const char *r = 0;
    CODE:
      r = (const char *)THIS->xclass();
      ST(0) = sv_newmortal();
      sv_setpv((SV*)ST(0), (char *)r);
      XSRETURN(1);

int
Fl_Window::shown()

void
Fl_Window::show(Argc=0,Argv=0)
  CASE: items == 3
    INIT:
      int Argc = (int)SvIV(ST(1));
      char **Argv;
    CODE:
      if(!SvROK(ST(2))) {
        croak("Fl_Window::show(argc,argv): argv must be an array ref");
      }
      if(SvTYPE(SvRV(ST(2))) != SVt_PVAV) {
        croak("Fl_Window::show(argc,argv): argv must be an array ref");
      }
      AV *tmpav = (AV*)SvRV(ST(2));
      I32 alen = av_len(tmpav);
      Argv = (char **)malloc((alen+2)*sizeof(char *));
      int ti;
      SV **tmpsv;
      for(ti = 0; ti <= alen; ti++) {
        tmpsv = av_fetch(tmpav, ti, 0);
        Argv[ti] = (char *)SvPV(*tmpsv,PL_na);
      }
      Argv[ti] = 0;
      THIS->show(Argc,Argv);
  CASE: items == 2
    INIT:
      const Fl_Window *p = (const Fl_Window *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->show(p);
  CASE: items == 1
    CODE:
      THIS->show();

int
Fl_Window::exec(parent=0)
    const Fl_Window *parent

void
Fl_Window::show_inside(p)
  const Fl_Window *p

void
Fl_Window::iconize()

int
Fl_Window::iconic()

void
Fl_Window::destroy()

void
Fl_Window::fullscreen()

void
Fl_Window::fullscreen_off(x,y,w,h)
  int x
  int y
  int w
  int h

int
Fl_Window::x_root()

int
Fl_Window::y_root()

Fl_Window *
Fl_Window::current()
  CODE:
    RETVAL = (Fl_Window *)THIS->current();
  OUTPUT:
    RETVAL

void
Fl_Window::make_current()

void
Fl_Window::cursor(cur,ca=FL_BLACK,cb=FL_WHITE)
  Fl_Cursor cur
  Fl_Color ca
  Fl_Color cb

void
Fl_Window::default_callback(w,v)
  Fl_Window *w
  void *v

void
Fl_Window::modal_for(w=0)
  CASE: items == 2
    INPUT:
      const Fl_Window *w
    CODE:
      THIS->modal_for(w);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const Fl_Window *r = (const Fl_Window *)0;
    CODE:
      r = THIS->modal_for();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Window", (void*)r);
      XSRETURN(1);

void
Fl_Window::layout()

void
Fl_Window::flush()

void
Fl_Window::draw()

void
Fl_Window::draw_n_clip()

void
Fl_Window::end()

