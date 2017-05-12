
MODULE = FLTK   PACKAGE = Fl_Scroll

Fl_Scroll *
Fl_Scroll::new(x,y,w,h,l=0)
  int x
  int y
  int w
  int h
  const char *l

void
Fl_Scroll::bbox(x,y,w,h)
  int x
  int y
  int w
  int h
  OUTPUT:
    x
    y
    w
    h

int
Fl_Scroll::handle(i)
  int i

int
Fl_Scroll::xposition()

int 
Fl_Scroll::yposition()

void
Fl_Scroll::position(x,y)
  int x
  int y
