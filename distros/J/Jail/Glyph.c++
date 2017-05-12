#include <string.h>
#include <values.h>
#include <stdio.h>
#include "Font.h"
#include "Glyph.h"

Glyph::Glyph()
{
  _bitmap   = NULL;
  _name     = NULL;
  _encoding = 0;
  _offNextX = _offNextY = 0;
  _width = _height = _xOff = _yOff = _stride = 0;
  _fr = _fg = _fb = _ba = 255;
  _br = _bg = _bb = _fa = 0;
}

Glyph::~Glyph()
{
  //  printf("DELETE %s 0x%ld\n",_name,_name);
  if (_bitmap != NULL) delete[] _bitmap;
  //puts("-5-");
  if (_name != NULL) delete[] _name;
  //  puts("-6-");
}

void
Glyph::calcBBX(Glyph **glyphPtr, const int count, int &cur_x, int &cur_y,
	       int &xmax, int &ymax, int &xmin, int &ymin)
{
  // Bounding Box functions
#define MAX(max,value) max = value > max ? value : max;
#define MIN(min,value) min = value < min ? value : min;

  int x,y;

  // Bounding Box setup
  xmin = ymin = MAXINT;
  xmax = ymax = -MAXINT;

  // Calculate BBX
  for (int i=0;i<count;i++) {
    x = cur_x+glyphPtr[i]->getBBXXO();
    y = cur_y+glyphPtr[i]->getBBXYO();

    MAX( xmax, x);
    MAX( ymax, y);
    MIN( xmin, x);
    MIN( ymin, y);
  
    x += glyphPtr[i]->getBBXW();
    y += glyphPtr[i]->getBBXH();
  
    MAX( xmax, x);
    MAX( ymax, y);
    MIN( xmin, x);
    MIN( ymin, y);
  
    cur_x += glyphPtr[i]->getOffsetToNextX();
    cur_y += glyphPtr[i]->getOffsetToNextY();
  }

  //TODO ANPASSEN
  cur_x = -xmin;
  cur_y = -ymin;
}

Glyph *
Glyph::merge(Glyph **glyphPtr, const int count)
{
  int x,y;
  int cur_x, cur_y;
  int xmin, xmax;
  int ymin, ymax;
  int stride = 0;

  if (count <= 0) {
    return NULL;
  }

  x = y = cur_x = cur_y = 0;

  Glyph *glyph = new Glyph();

  Glyph::calcBBX(glyphPtr, count, cur_x, cur_y, xmax, ymax, xmin, ymin);

  // initialize new glyph
  glyph->setBoundingBox(xmax - xmin, // width
			ymax - ymin, // height
			glyphPtr[0]->getBBXXO(), // BBX X Offset
			glyphPtr[0]->getBBXYO());// BBX Y Offset

  int destX, destY;
  for (int i=0;i<count;i++) {

    destX = glyphPtr[i]->getBBXXO() + cur_x;
    destY = glyph->getBBXH() - (glyphPtr[i]->getBBXYO() + cur_y + glyphPtr[i]->getBBXH());

    for (int line=0; line < glyphPtr[i]->getBBXH(); line++) {
      //todo optimize
      for (int bits=0; bits < glyphPtr[i]->getBBXW(); bits++) {
	int destBit, destByte;
	int srcBit, srcByte;

	destByte = (destX + bits) >> 3;
	srcByte  = bits >> 3;

	destBit  = 7 - ((destX + bits) - (destByte * 8));
	srcBit   = 7 - (bits - (srcByte * 8));

	glyph->_bitmap[(destY*glyph->getStride())+(line*glyph->getStride()) + destByte] |=
	  (glyphPtr[i]->_bitmap[ line * glyphPtr[i]->getStride() + srcByte] &
	   (1<<srcBit)) ? 1 << destBit : 0;


      }
    }

    cur_x += glyphPtr[i]->getOffsetToNextX();
    cur_y += glyphPtr[i]->getOffsetToNextY();

  }

  glyph->setOffsetToNext(cur_x, cur_y);

  return glyph;
}

void
Glyph::setName(const char *name)
{
  if (name == NULL) {
    printf("WARNING: Glyph::setName(name) given name is NULL\n");
    return;
  }
  int len = strlen(name);

  if (len == 0) {
    printf("WARNING: Glyph::setName(name) given name is empty\n");
    return;
  }
  len++;

  if (_name != NULL) {
    printf("WARNING: Glyph::setName(%s,%s) called twice",_name,name);
    delete[] _name;
  }

  _name = new char[len];
  strcpy(_name, name);
}

void
Glyph::setEncoding(int encoding)
{
  _encoding = encoding;
}

void
Glyph::setOffsetToNext(int x, int y)
{
  _offNextX = x;
  _offNextY = y;
}

void
Glyph::setBoundingBox(int width, int height, int xOff, int yOff)
{
  if (width <= 0 || height <= 0) return;
  _width = width;
  _height = height;
  _xOff = xOff;
  _yOff = yOff;

  // byte align
  _stride = ((width -1)>>3) +1;

  //printf("*--BBX: %d %d %d %d %d 0x%d\n",_width, _height, _xOff, _yOff, _stride, _bitmap);

  _bitmap = new char[_stride * _height];
  memset(_bitmap, 0, _stride * _height);
}

void
Glyph::setBitmap8(int byteCount, int line, char bitmap)
{
  if (byteCount < 0 || line < 0 || byteCount >= _stride || line >= _height) {
    printf("WARNING: Glyph::setBitmap8(%d,%d,...) failed\n", byteCount, line);
    return;
  }

  _bitmap[byteCount + line*_stride] = bitmap;
}

int
Glyph::getEncoding()
{
  return _encoding;
}

int
Glyph::getBBXW()
{
  return _width;
}

int
Glyph::getBBXH()
{
  return _height;
}

int
Glyph::getBBXXO()
{
  return _xOff;
}

int
Glyph::getBBXYO()
{
  return _yOff;
}

int
Glyph::getStride()
{
  return _stride;
}

int
Glyph::getOffsetToNextX()
{
  return _offNextX;
}

int
Glyph::getOffsetToNextY()
{
  return _offNextY;
}

const char *
Glyph::getName()
{
  return _name;
}

const char *
Glyph::getBitmap()
{
  return _bitmap;
}

char
Glyph::getForegroundR()
{
  return _fr;
}

char
Glyph::getForegroundG()
{
  return _fg;
}

char
Glyph::getForegroundB()
{
  return _fb;
}

char
Glyph::getForegroundA()
{
  return _fa;
}

char
Glyph::getBackgroundR()
{
  return _br;
}

char
Glyph::getBackgroundG()
{
  return _bg;
}

char
Glyph::getBackgroundB()
{
  return _bb;
}

char
Glyph::getBackgroundA()
{
  return _ba;
}

void
Glyph::setForeground(char r, char g, char b, char a)
{
  _fr = r;
  _fg = g;
  _fb = b;
  _fa = a;
}

void
Glyph::setBackground(char r, char g, char b, char a)
{
  _br = r;
  _bg = g;
  _bb = b;
  _ba = a;
}

void
Glyph::print()
{
  printf("\n%s W:%d H:%d XO:%d YO:%d SW:%d SH:%d\n", _name, _width, _height, _xOff, _yOff, _offNextX, _offNextY);

  printf("  ");
  for (int w=0; w< _stride*8; w++) {
    int wp = w;
    while (wp >= 10) {wp-=10;}
    printf("%d",wp);
  }
  printf("\n");
  for (int h=0; h< _height; h++) {
    printf("%2d",h);
    for ( w=0; w< _stride; w++) {
      for (int i=7; i >= 0; i--) {
	if (_bitmap[h * _stride + w] & (1<<i)) {
	  printf("#");
	} else {
	  printf("-");
	}
      }
    }
    printf("\n");
  }
  printf("  ");
  for (w=0; w< _stride*8; w++) {
    int wp = w;
    while (wp >= 10) {wp-=10;}
    printf("%d",wp);
  }
  printf("\n");
}
