
MODULE = FLTK   PACKAGE = Fl_Menu_Bar

Fl_Menu_Bar *
Fl_Menu_Bar::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Menu_Bar::handle(i)
  int i


MODULE = FLTK   PACKAGE = Fl_Menu_Button

Fl_Menu_Button *
Fl_Menu_Button::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int 
Fl_Menu_Button::handle(i)
  int i

int
Fl_Menu_Button::popup()


MODULE = FLTK   PACKAGE = Fl_Choice

Fl_Choice *
Fl_Choice::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Choice::handle(i)
  int i

int
Fl_Choice::value(...)
  CASE: items == 3
    INIT:
      int i = (int)SvIV(ST(1));
      int l = (int)SvIV(ST(2));
    CODE:
      RETVAL = THIS->value((const int *)&i,l);
    OUTPUT:
      RETVAL
  CASE: items == 2
    INIT:
      int v = (int)SvIV(ST(1));
    CODE:
      RETVAL = THIS->value(v);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->value();
    OUTPUT:
      RETVAL

