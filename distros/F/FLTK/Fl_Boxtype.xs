
MODULE = FLTK     PACKAGE = Fl_Boxtype_

void
Fl_Boxtype_::draw(wd,x,y,w,h,f=0)
  const Fl_Widget *wd
  int x
  int y
  int w
  int h
  Fl_Flags f

int
Fl_Boxtype_::fills_rectangle()

int
Fl_Boxtype_::dx()

int
Fl_Boxtype_::dy()

int
Fl_Boxtype_::dw()

int 
Fl_Boxtype_::dh()

void
Fl_Boxtype_::inset(X,Y,W,H)
  int X
  int Y
  int W
  int H
  CODE:
    THIS->inset(X, Y, W, H);
  OUTPUT:
    X
    Y
    W
    H

const Fl_Boxtype_ *
Fl_Boxtype_::find(n)
  const char *n
