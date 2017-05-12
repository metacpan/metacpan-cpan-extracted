
MODULE = FLTK   PACKAGE = Fl_Browser

Fl_Browser *
Fl_Browser::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Browser::xposition(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->xposition(i);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->xposition();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Browser::yposition(i=0)
  CASE: items == 2
    INPUT:
      int i
    CODE:
      THIS->yposition(i);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->yposition();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0), (IV)r);
      XSRETURN(1);

void
Fl_Browser::indented(i=0)
  CASE: items == 2
    INPUT:
      char i
    CODE:
      THIS->indented(i);
  CASE: items == 1
    INIT:
      char r;
    CODE:
      r = THIS->indented();
      ST(0) = sv_newmortal();
      sv_setpvn(ST(0), (char *)&r, 1);
      XSRETURN(1);

int
Fl_Browser::multi()

int
Fl_Browser::handle(i)
  int i

void
Fl_Browser::layout()

void
Fl_Browser::draw()

Fl_Widget *
Fl_Browser::goto_top()

Fl_Widget *
Fl_Browser::goto_mark(m)
  int m

Fl_Widget *
Fl_Browser::goto_position(y)
  int y

Fl_Widget *
Fl_Browser::goto_number(n)
  int n

Fl_Widget *
Fl_Browser::goto_visible_focus()

Fl_Widget *
Fl_Browser::goto_index(i,l)
  int i
  int l
  CODE:
    RETVAL = THIS->goto_index((const int *)&i,l);
  OUTPUT:
    RETVAL

Fl_Widget *
Fl_Browser::forward()

Fl_Widget *
Fl_Browser::backward()

void
Fl_Browser::set_mark(d,m)
  int d
  int m

int
Fl_Browser::compare_marks(m1,m2)
  int m1
  int m2

int
Fl_Browser::at_mark(m)
  int m

void
Fl_Browser::unset_mark(m)
  int m

int 
Fl_Browser::is_set(m)
  int m

void
Fl_Browser::damage_item(m)
  int m

int
Fl_Browser::set_focus()

void
Fl_Browser::set_top()

int
Fl_Browser::item_select(v=1,d=0)
  int v
  int d

int
Fl_Browser::item_select_only(d=0)
  int d

void
Fl_Browser::deselect(d=0)
  int d

int
Fl_Browser::select(l,v=0)
  int l
  int v

int
Fl_Browser::selected(l)
  int l

void
Fl_Browser::topline(l=0)
  CASE: items == 2
    INPUT:
      int l
    CODE:
      THIS->topline(l);
  CASE: items == 1
    INIT:
      int r;
    CODE:
      r = THIS->topline();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

void
Fl_Browser::format_char(i=0)
  CASE: items == 2
    INPUT:
      char i
    CODE:
      THIS->format_char(i);
  CASE: items == 1
    INIT:
      char r;
    CODE:
      r = THIS->format_char();
      ST(0) = sv_newmortal();
      sv_setpvn(ST(0), (char *)&r, 1);
      XSRETURN(1);

void
Fl_Browser::column_char(i=0)
  CASE: items == 2
    INPUT:
      char i
    CODE:
      THIS->column_char(i);
  CASE: items == 1
    INIT:
      char r;
    CODE:
      r = THIS->column_char();
      ST(0) = sv_newmortal();
      sv_setpvn(ST(0), (char *)&r, 1);
      XSRETURN(1);

void
Fl_Browser::value(v=0)
  CASE: items == 2
    INPUT:
      int v
    CODE:
      THIS->value(v);
  CASE: items == 2
    INIT:
      int r;
    CODE:
      r = THIS->value();
      ST(0) = sv_newmortal();
      sv_setiv(ST(0),(IV)r);
      XSRETURN(1);

