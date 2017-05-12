//-*- mode: c++ -*-

#ifndef __IMGGLYPH__
#define __IMGGLYPH__

#include <vector.h>

#include "Glyph.h"
#include "imgProcess.h"

class imgGlyph {
public:

  imgGlyph();
  ~imgGlyph();

  short addGlyph(Glyph *glyph);
  imgProcess *createImg();
  short blittInImage(imgProcess *image, int x, int y);

  int getWidth();
  int getHeight();
  int getCurX();
  int getCurY();

  // Error handling
  void printError();
  char *getErrorString();
  short getStatus();

private:

  void deleteGlyphPtr();
  void checkTouched();
  void setError(const char *str, short errno);

  int   _width, _height;
  int   _curX, _curY;
  short _touched;

  char *_error;
  char  _errno;

  Glyph **       _glyphPtr;

  vector<Glyph *> _glyphList;
  vector<struct colorMap *> _colorList;
};

#endif
