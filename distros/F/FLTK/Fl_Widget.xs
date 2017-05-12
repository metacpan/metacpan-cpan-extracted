
MODULE = FLTK   PACKAGE = Fl_Widget

void
Fl_Widget::draw()

void
Fl_Widget::draw_n_clip()

int
Fl_Widget::handle(x)
  int x

void
Fl_Widget::layout()

void
Fl_Widget::style(s=0)
  CASE: items == 2
    INPUT:
      const Fl_Style *s
    CODE:
      THIS->style(s);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const Fl_Style *r;
    CODE:
      r = THIS->style();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Style", (void*)r);
      XSRETURN(1);

int
Fl_Widget::copy_style(s)
  const Fl_Style *s

void
Fl_Widget::parent(...)
  CASE: items == 2
    INIT:
      Fl_Group *g = (Fl_Group *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->parent(g);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Group *g = (Fl_Group *)0;
    CODE:
      g = THIS->parent();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Group", (void*)g);
      XSRETURN(1);

Fl_Window *
Fl_Widget::window()

void
Fl_Widget::type(...)
  CASE: items == 2
    INIT:
      uchar t = (uchar)SvUV(ST(1));
    CODE:
      THIS->type(t);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      uchar t = 0;
    CODE:
      t = THIS->type();
      sv_setuv(ST(0), (UV)t);
      XSRETURN(1);

int
Fl_Widget::is_group()

int
Fl_Widget::is_window()

void
Fl_Widget::x(...)
  CASE: items == 2
    INIT:
      int v = (int)SvIV(ST(1));
    CODE:
      THIS->x(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int rv = 0;
    CODE:
      rv = THIS->x();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)rv);
      XSRETURN(1);

void
Fl_Widget::y(...)
  CASE: items == 2
    INIT:
      int v = (int)SvIV(ST(1));
    CODE:
      THIS->y(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int rv = 0;
    CODE:
      rv = THIS->y();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)rv);
      XSRETURN(1);

void
Fl_Widget::w(...)
  CASE: items == 2
    INIT:
      int v = (int)SvIV(ST(1));
    CODE:
      THIS->w(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int rv = 0;
    CODE:
      rv = THIS->w();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)rv);
      XSRETURN(1);

void
Fl_Widget::h(...)
  CASE: items == 2
    INIT:
      int v = (int)SvIV(ST(1));
    CODE:
      THIS->h(v);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int rv = 0;
    CODE:
      rv = THIS->h();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)rv);
      XSRETURN(1);

int
Fl_Widget::width()

int
Fl_Widget::height()

int
Fl_Widget::resize(x,y,w,h)
  int x
  int y
  int w
  int h

void
Fl_Widget::position(X,Y)
  int X
  int Y

void
Fl_Widget::size(W,H)
  int W
  int H

void
Fl_Widget::label(...)
  CASE: items == 2
    INIT:
      const char *l = (const char *)SvPV(ST(1), PL_na);
    CODE:
      THIS->label(l);
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
Fl_Widget::copy_label(a)
  const char *a;

void
Fl_Widget::image(...)
  CASE: items == 2
    INIT:
      Fl_Image *a = (Fl_Image *)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->image(a);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Image *r = (Fl_Image *)0;
    CODE:
      r = THIS->image();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Image", (void*)r);
      XSRETURN(1);

void
Fl_Widget::tooltip(...)
  CASE: items == 2
    INIT:
      const char *t = (const char *)SvPV(ST(1), PL_na);
    CODE:
      THIS->tooltip(t);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      const char *r = 0;
    CODE:
      r = THIS->tooltip();
      ST(0) = sv_newmortal();
      sv_setpv((SV*)ST(0), (char *)r);
      XSRETURN(1);

void
Fl_Widget::shortcut(...)
  CASE: items == 2
    INIT:
      int s = (int)SvIV(ST(1));
    CODE:
      THIS->shortcut(s);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      int r = 0;
    CODE:
      r = THIS->shortcut();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::callback(...)
  CASE: items >= 2
    CODE:
      if(SvTYPE(SvRV((SV*)ST(1))) != SVt_PVCV) {
        croak("Fl_Widget::callback() requires a function reference.");
      } else {
        //cb = (CV *)SvRV((SV*)ST(1));
        AV *arr = newAV();
        av_extend(arr, items);
        // Push the CV onto the array first, then the widget reference,
        // then the rest.
        av_store(arr, 0, newSVsv((SV*)ST(1)));
        av_store(arr, 1, newSVsv((SV*)ST(0)));
        int c;
        for(c = 2; c < items; c++) {
          av_store(arr, c, newSVsv((SV*)ST(c)));
        }
        //SvREFCNT_inc((SV*)arr);
        THIS->callback(fltkperl_default_cb, (void*)arr);
      }
/*    switch(SvTYPE(SvRV((SV*)ST(1)))) {
      case SVt_IV:
        croak("Argument is an integer.");
        break;
      case SVt_PV:
        croak("Argument is a string.");
        break;
      case SVt_PVAV:
        croak("Argument is an array.");
        break;
      case SVt_PVCV:
        croak("Argument is a CV.");
        break;
      case SVt_PVMG:
        croak("Argument is blessed or magic.");
        break;
      case SVt_NV:
        croak("Argument is a double.");
        break;
      case SVt_RV:
        croak("Argument is a reference.");
        break;
      case SVt_PVHV:
        croak("Argument is a hash.");
        break;
      case SVt_PVGV:
        croak("Argument is a glob.");
        break;
    } */
    //THIS->callback(fltkperl_default_cb, (void *)cb);

void
Fl_Widget::when(...)
  CASE: items == 2
    INIT:
      uchar i = (uchar)SvUV(ST(1));
    CODE:
      THIS->when(i);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      uchar r = 0;
    CODE:
      r = (uchar)THIS->when();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0), (UV)r);
      XSRETURN(1);

void
Fl_Widget::default_callback(w,d)
  Fl_Widget *w
  void *d

void
Fl_Widget::do_callback()

int
Fl_Widget::test_shortcut()

int 
Fl_Widget::contains(w)
  const Fl_Widget *w

int
Fl_Widget::inside(o)
  const Fl_Widget *o

int
Fl_Widget::pushed()

int
Fl_Widget::focused()

int
Fl_Widget::belowmouse()

Fl_Flags
Fl_Widget::flags()

void
Fl_Widget::set_flag(c)
  int c

void
Fl_Widget::clear_flag(c)
  int c

void
Fl_Widget::invert_flag(c)
  int c

void
Fl_Widget::align(a)
  unsigned a

int
Fl_Widget::visible()

int
Fl_Widget::visible_r()

void
Fl_Widget::show()

void
Fl_Widget::hide()

void
Fl_Widget::set_visible()

void
Fl_Widget::clear_visible()

int
Fl_Widget::active()

int 
Fl_Widget::active_r()

void
Fl_Widget::activate(...)
  CASE: items == 2
    INIT:
      int b = (int)SvIV(ST(1));
    CODE:
      THIS->activate(b);
  CASE: items == 1
    CODE:
      THIS->activate();

void
Fl_Widget::deactivate()

int
Fl_Widget::output()

void
Fl_Widget::set_output()

void
Fl_Widget::clear_output()

int
Fl_Widget::takesevents()

int
Fl_Widget::changed()

void
Fl_Widget::set_changed()

void
Fl_Widget::clear_changed()

int
Fl_Widget::value()

void
Fl_Widget::set_value()

void
Fl_Widget::clear_value()

int
Fl_Widget::take_focus()

void
Fl_Widget::throw_focus()

void
Fl_Widget::redraw()

void 
Fl_Widget::relayout()

void
Fl_Widget::damage(...)
  CASE: items == 6
    INIT:
      uchar c = (uchar)SvUV(ST(1));
      int x = (int)SvIV(ST(2));
      int y = (int)SvIV(ST(3));
      int w = (int)SvIV(ST(4));
      int h = (int)SvIV(ST(5));
    CODE:
      THIS->damage(c,x,y,w,h);
  CASE: items == 2
    INIT:
      uchar ch = (uchar)SvUV(ST(1));
    CODE:
      THIS->damage(ch);
  CASE: items == 1
    CODE:
      THIS->damage();

void
Fl_Widget::set_damage(c)
  uchar c

void
Fl_Widget::clear_damage()

void
Fl_Widget::damage_label()

void
Fl_Widget::draw_box(...)
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      Fl_Flags f = (Fl_Flags)SvIV(ST(5));
    CODE:
      THIS->draw_box(x,y,w,h,f);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Flags r = 0;
    CODE:
      r = THIS->draw_box();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

Fl_Flags
Fl_Widget::draw_button(...)
  CASE: items == 2
    INIT:
      Fl_Flags f = (Fl_Flags)SvIV(ST(1));
    CODE:
      RETVAL = THIS->draw_button(f);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->draw_button();
    OUTPUT:
      RETVAL

Fl_Flags
Fl_Widget::draw_text_frame(...)
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = THIS->draw_text_frame(x,y,w,h);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->draw_text_frame();
    OUTPUT:
      RETVAL

Fl_Flags
Fl_Widget::draw_text_box(...)
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      RETVAL = THIS->draw_text_box(x,y,w,h);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->draw_text_box();
    OUTPUT:
      RETVAL

void
Fl_Widget::draw_glyph(t,x,y,w,h,f)
  int t
  int x
  int y
  int w
  int h
  Fl_Flags f

void
Fl_Widget::draw_label(x,y,w,h,f)
  int x
  int y
  int w
  int h
  Fl_Flags f

void
Fl_Widget::draw_inside_label(...)
  CASE: items == 6
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      Fl_Flags f = (Fl_Flags)SvIV(ST(5));
    CODE:
      THIS->draw_inside_label(x,y,w,h,f);
  CASE: items == 5
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
    CODE:
      THIS->draw_inside_label(x,y,w,h);
  CASE: items == 1
    CODE:
      THIS->draw_inside_label();

void
Fl_Widget::measure_label(x,y)
  int x
  int y
  OUTPUT:
    x
    y

Fl_Color
Fl_Widget::glyph_color(f)
  Fl_Flags f

Fl_Color
Fl_Widget::box_color(f)
  Fl_Flags f

void
Fl_Widget::box(...)
  CASE: items == 2
    INIT:
      int b = (int)SvIV(ST(1));
    CODE:
      THIS->box(lookup_box(b));
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Boxtype r;
    CODE:
      r = THIS->box();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::text_box(...)
  CASE: items == 2
    INIT:
      int b = (int)SvIV(ST(1));
    CODE:
      THIS->text_box(lookup_box(b));
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Boxtype r;
    CODE:
      r = THIS->text_box();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::glyph(...)
  CASE: items == 2
    INIT:
      Fl_Glyph b = (Fl_Glyph)SvIV(ST(1));
    CODE:
      THIS->glyph(b);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Glyph r;
    CODE:
      r = THIS->glyph();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::label_font(...)
  CASE: items == 2
    INIT:
      Fl_Font b = (Fl_Font)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->label_font(b);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Font r;
    CODE:
      r = THIS->label_font();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0),"Fl_Font_", (void*)r);
      XSRETURN(1);

void
Fl_Widget::text_font(...)
  CASE: items == 2
    INIT:
      Fl_Font b = (Fl_Font)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->text_font(b);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Font r;
    CODE:
      r = THIS->text_font();
      ST(0) = sv_newmortal();
      sv_setref_pv(ST(0), "Fl_Font_",(void*)r);
      XSRETURN(1);

void
Fl_Widget::label_type(...)
  CASE: items == 2
    INIT:
      Fl_Labeltype b = (Fl_Labeltype)SvIV((SV*)SvRV(ST(1)));
    CODE:
      THIS->label_type(b);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Labeltype r;
    CODE:
      r = THIS->label_type();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::label_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->label_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->label_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::selection_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->selection_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->selection_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::selection_text_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->selection_text_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->selection_text_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::text_background(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->text_background(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->text_background();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::highlight_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->highlight_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->highlight_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::highlight_label_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->highlight_label_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->highlight_label_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::text_color(...)
  CASE: items == 2
    INIT:
      Fl_Color c = (Fl_Color)SvIV(ST(1));
    CODE:
      THIS->text_color(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      Fl_Color r;
    CODE:
      r = THIS->text_color();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Widget::label_size(...)
  CASE: items == 2
    INIT:
      unsigned c = (unsigned)SvUV(ST(1));
    CODE:
      THIS->label_size(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      unsigned r = 0;
    CODE:
      r = THIS->label_size();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0), (UV)r);
      XSRETURN(1);

void
Fl_Widget::text_size(...)
  CASE: items == 2
    INIT:
      unsigned c = (unsigned)SvUV(ST(1));
    CODE:
      THIS->text_size(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      unsigned r = 0;
    CODE:
      r = THIS->text_size();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0), (UV)r);
      XSRETURN(1);

void
Fl_Widget::leading(...)
  CASE: items == 2
    INIT:
      unsigned c = (unsigned)SvUV(ST(1));
    CODE:
      THIS->leading(c);
      XSRETURN_EMPTY;
  CASE: items == 1
    INIT:
      unsigned r = 0;
    CODE:
      r = THIS->leading();
      ST(0) = sv_newmortal();
      sv_setuv(ST(0), (UV)r);
      XSRETURN(1);
