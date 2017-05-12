
MODULE = FLTK   PACKAGE = Fl_Button

Fl_Button *
Fl_Button::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Button::value(...)
  CASE: items == 2
    INIT:
      int i = (int)SvIV(ST(1));
    CODE:
      RETVAL = THIS->value(i);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE:
      RETVAL = THIS->value();
    OUTPUT:
      RETVAL

int
Fl_Button::set()

int
Fl_Button::clear()

void
Fl_Button::setonly()

int
Fl_Button::handle(i)
  int i


MODULE = FLTK   PACKAGE = Fl_Return_Button

Fl_Return_Button *
Fl_Return_Button::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Repeat_Button

Fl_Repeat_Button *
Fl_Repeat_Button::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Repeat_Button::handle(i)
  int i
