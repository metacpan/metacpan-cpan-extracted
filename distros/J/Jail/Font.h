// -*- mode: c++ -*-
#include <map.h>
#include <stdio.h>
#include "Glyph.h"

#ifndef _FONTINCLUDE_
#define _FONTINCLUDE_

class BitFont {
public:
  static BitFont *openBDF(const char *path);

  ~BitFont();

  class Glyph **getText(const char *text, int &count);
  void releaseText(class Glyph **glyphList);

  int   getBBXW();
  int   getBBXH();
  int   getBBXXO();
  int   getBBXYO();
  int   getCharsetEncoding();
  const char *getName();

  const char *getErrorString();
  short getStatus();

  static void printBin(char c);

 private:
  BitFont();

  short addBDFglyph(const char *name, FILE *file, char *buffer, int bsize, int &line);

  void  addGlyph(class Glyph *glyph);
  void  setName(const char *name);
  void  setBoundingBox(int width, int height, int xOff, int yOff);
  void  setNumberOfGlyphs(int number);
  void  setCharsetEncoding(int encoding);
  void  setError(short id, const char *str, int line);

  char *_name;
  int   _width, _height, _xOff, _yOff;
  int   _glyphCount;
  int   _charsetEncoding;
  char *_errorString;
  short _errorID;

  map<const int, Glyph *> _glyphList;
  map<const char *, Glyph *> _glyphNameList;
};

#endif
