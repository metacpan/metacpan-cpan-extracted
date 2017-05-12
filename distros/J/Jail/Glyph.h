

#ifndef _GLYPHINCLUDE_
#define _GLYPHINCLUDE_

class Glyph {
 public:
  Glyph();
  ~Glyph();

  static Glyph *merge(Glyph **glyphList, const int count);
  static void calcBBX(Glyph **glyphPtr, const int count, int &cur_x, 
		      int &cur_y, int &xmax, int &ymax, int &xmin, int &ymin);

  void setName(const char *name);
  void setEncoding(int encoding);
  void setOffsetToNext(int x, int y);
  void setBoundingBox(int width, int height, int xOff, int yOff);  
  void setBitmap8(int byteCount, int line, char bitmap);

  // Char encoding value
  int getEncoding();

  // Boundingbox
  int getBBXW(); // Width
  int getBBXH(); // Height
  int getBBXXO(); // X Offset
  int getBBXYO(); // Y Offset
  int getStride(); // Bytes per Line

  int getOffsetToNextX();
  int getOffsetToNextY();
  const char *getName();
  const char *getBitmap();

  char getForegroundR();
  char getForegroundG();
  char getForegroundB();
  char getForegroundA();
  char getBackgroundR();
  char getBackgroundG();
  char getBackgroundB();
  char getBackgroundA();

  void setForeground(char r, char g, char b, char a=0);
  void setBackground(char r, char g, char b, char a=0);  

  void print();

private:
  char  *_bitmap;
  char  *_name;
  char    _fr, _fg, _fb, _fa;
  char    _br, _bg, _bb, _ba;
  int    _encoding;
  int    _offNextX, _offNextY;
  int    _width, _height, _xOff, _yOff, _stride;
};
#endif
