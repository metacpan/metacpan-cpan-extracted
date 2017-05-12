// -*- mode: c++ -*-

#ifndef __imgDISPLAY__
#define __imgDISPLAY__

#include <X11/Xlib.h>
#include <il/ilViewer.h>

class imgDisplay {

public:
  imgDisplay(class imgProcess *image);
  ~imgDisplay();

private:
  //void setError(ilStatus status, const char *str);

  Display  *_display;

};

#endif
