
MODULE = FLTK   PACKAGE = Fl_Image

void
Fl_Image::measure(w,h)
  int w
  int h
  CODE:
    THIS->measure(w, h);
  OUTPUT:
    w
    h

void
Fl_Image::draw(...)
  CASE: items == 7
    INIT:
      int x = (int)SvIV(ST(1));
      int y = (int)SvIV(ST(2));
      int w = (int)SvIV(ST(3));
      int h = (int)SvIV(ST(4));
      int cx = (int)SvIV(ST(5));
      int cy = (int)SvIV(ST(6));
    CODE:
      THIS->draw(x,y,w,h,cx,cy);
  CASE: items == 3
    INIT:
      int X = (int)SvIV(ST(1));
      int Y = (int)SvIV(ST(2));
    CODE:
      THIS->draw(X,Y);

void
Fl_Image::draw_tiled(X,Y,W,H,cx=0,cy=0)
  int X
  int Y
  int W
  int H
  int cx
  int cy

void
Fl_Image::label(o)
  Fl_Widget *o
