
MODULE = FLTK   PACKAGE = Fl_Scrollbar

Fl_Scrollbar *
Fl_Scrollbar::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

int
Fl_Scrollbar::value(p=0,s=0,t=0,to=0)
  CASE: items == 5
    INPUT:
      int p
      int s
      int t
      int to
    CODE:
      RETVAL = THIS->value(p,s,t,to);
    OUTPUT:
      RETVAL
  CASE: items == 1
    CODE: 
      RETVAL = THIS->value();
    OUTPUT:
      RETVAL

int
Fl_Scrollbar::handle(i)
  int i

MODULE = FLTK   PACKAGE = Fl_Fill_Slider

Fl_Fill_Slider *
Fl_Fill_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Value_Slider

Fl_Value_Slider *
Fl_Value_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Hor_Slider

Fl_Hor_Slider *
Fl_Hor_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Hor_Fill_Slider

Fl_Hor_Fill_Slider *
Fl_Hor_Fill_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Hor_Value_Slider

Fl_Hor_Value_Slider *
Fl_Hor_Value_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Nice_Slider

Fl_Nice_Slider *
Fl_Nice_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

MODULE = FLTK   PACKAGE = Fl_Hor_Nice_Slider

Fl_Hor_Nice_Slider *
Fl_Hor_Nice_Slider::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

