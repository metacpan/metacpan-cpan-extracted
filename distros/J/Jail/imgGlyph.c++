#include "imgGlyph.h"

imgGlyph::imgGlyph()
{
  _touched = 0;
  _glyphPtr = NULL;
  _width = _height = 0;
  _curX = _curY = 0;

  _error = 0;
  _errno = 0;
}

imgGlyph::~imgGlyph()
{
  deleteGlyphPtr();
  if (_error > 0) {
    delete _error;
  }
}

void
imgGlyph::setError(const char *str, short errno)
{
  if (_error > 0) {
    printf("WARNING: imgGlyph::setError() called twice (%s,%s)\n",_error,str);
    delete _error;
  }
  _error = new char[strlen(str)+1];
  strcpy(_error,str);
  _errno = errno;
}

void
imgGlyph::printError()
{
  printf("%s\n",getErrorString());
}

char *
imgGlyph::getErrorString()
{
  static char str[2048];
  sprintf(str,"imgArray: %.2007s (%d)",_error, _errno);
  return str;
}

short
imgGlyph::getStatus()
{
  return _errno;
}

int
imgGlyph::getWidth()
{
  checkTouched();
  return _width;
}

int
imgGlyph::getHeight()
{
  checkTouched();
  return _height;
}

int
imgGlyph::getCurX()
{
  checkTouched();
  return _curX;
}

int
imgGlyph::getCurY()
{
  checkTouched();
  return _curY;
}

short
imgGlyph::addGlyph(Glyph *glyph)
{
  if (glyph == NULL) {
    setError("No glyh to add (NULL)",2);
    return -1;
  }

  _glyphList.push_back(glyph);

  _touched = 1;

  return 1;
}

imgProcess *
imgGlyph::createImg()
{
  checkTouched();// update BBX

  int count = _glyphList.size();

  if (count == 0) {
    setError("No glyph to create image",3);
    return NULL;
  }
  if (_width <= 0 || _height <= 0) {
    setError("Width or Height equal zero",4);
    return NULL;
  }

  imgProcess *tmpImage = new imgProcess(_width, _height, 4);
  
  if (tmpImage->getStatus() != ilOKAY) {
    setError(tmpImage->getErrorString(),5);
    delete tmpImage;
    return NULL;
  }

  int destX, destY;
  int cur_x = _curX;
  int cur_y = _curY;
  int lastX=0;

  for (int i =0; i < count; i++) {
    int offX = 0;

    destX = _glyphPtr[i]->getBBXXO() + cur_x;
    destY = _height - (_glyphPtr[i]->getBBXYO() + cur_y + _glyphPtr[i]->getBBXH());

    if (lastX < destX) offX = destX - lastX;

    for (int line=0; line < _height; line++) {

      int Y = destY + line;

      for (int bits= -offX; bits < _glyphPtr[i]->getBBXW(); bits++) {

	int X = destX + bits;

	if (line >= _glyphPtr[i]->getBBXH() ||
	    bits < 0) {
	  //get rid of memory thrash
	  tmpImage->setPixel(X, Y, 
			     _glyphPtr[i]->getBackgroundR(),
			     _glyphPtr[i]->getBackgroundG(),
			     _glyphPtr[i]->getBackgroundB(),
			     _glyphPtr[i]->getBackgroundA());
	} else {
	  int srcBit, srcByte;
	  srcByte  = bits >> 3;
	  srcBit   = 7 - (bits - (srcByte * 8));
	  
	  const char *bitmap = _glyphPtr[i]->getBitmap();
	  if (bitmap[line* _glyphPtr[i]->getStride() + srcByte] &(1<<srcBit)) {
	    tmpImage->setPixel(X, Y, 
			       _glyphPtr[i]->getForegroundR(),
			       _glyphPtr[i]->getForegroundG(),
			       _glyphPtr[i]->getForegroundB(),
			       _glyphPtr[i]->getForegroundA());
	  } else {
	    tmpImage->setPixel(X, Y, 
			       _glyphPtr[i]->getBackgroundR(),
			       _glyphPtr[i]->getBackgroundG(),
			       _glyphPtr[i]->getBackgroundB(),
			       _glyphPtr[i]->getBackgroundA());
	  }
	  
	}
      }
      
    }

    cur_x += _glyphPtr[i]->getOffsetToNextX();
    cur_y += _glyphPtr[i]->getOffsetToNextY();
    lastX = destX + _glyphPtr[i]->getBBXW();
  }
  if (tmpImage->getStatus() != ilOKAY) {
    setError(tmpImage->getErrorString(),6);
    delete tmpImage;
    return NULL;
  }
  return tmpImage;
}

short
imgGlyph::blittInImage(imgProcess *image, int x, int y)
{
  checkTouched(); // update BBX
  int count = _glyphList.size();

  if (count == 0) {
    setError("No glyph to blitt",8);
    return -1;
  }
  
  if (x >= image->getWidth() ||
      y >= image->getHeight() ||
      x+ _width < 0 ||
      y+ _height < 0) {
    
    setError("Blitting position is not in image",9);
    return -1;
  }

  int destX, destY;
  int drawFore, drawBack;

  int cur_x = _curX;
  int cur_y = _curY;

  for (int i =0; i < count; i++) {

    if (_glyphPtr[i]->getForegroundA() == 255) {
      drawFore = 0;
    } else {
      drawFore = 1;      
    }
    if (_glyphPtr[i]->getBackgroundA() == 255) {
      drawBack = 0;
    } else {
      drawBack = 1;      
    }
    
    destX = _glyphPtr[i]->getBBXXO() + cur_x + x;
    destY = _height - (_glyphPtr[i]->getBBXYO() + cur_y + _glyphPtr[i]->getBBXH()) + y;
    
    for (int line=0; line < _glyphPtr[i]->getBBXH(); line++) {

      int Y = destY + line;
      if (Y < 0 || Y >= image->getHeight()) continue;

      for (int bits=0; bits < _glyphPtr[i]->getBBXW(); bits++) {

	int X = destX + bits;
	if (X < 0 || X >= image->getWidth()) continue;

	int srcBit, srcByte;
	srcByte  = bits >> 3;
	srcBit   = 7 - (bits - (srcByte * 8));
       
	const char *bitmap = _glyphPtr[i]->getBitmap();
	if (bitmap[ line * _glyphPtr[i]->getStride() + srcByte] &(1<<srcBit)) {
	  if (drawFore)
	    if (image->setPixel(X, Y, 
				_glyphPtr[i]->getForegroundR(),
				_glyphPtr[i]->getForegroundG(),
				_glyphPtr[i]->getForegroundB(),
				_glyphPtr[i]->getForegroundA()) == -1) {
	      setError("set pixel foreground failed",10);
	      return -1;
	    }
	} else {
	   if (drawBack)
	    if (image->setPixel(X, Y, 
				_glyphPtr[i]->getBackgroundR(),
				_glyphPtr[i]->getBackgroundG(),
				_glyphPtr[i]->getBackgroundB(),
				_glyphPtr[i]->getBackgroundA()) == -1) {
	      setError("set pixel background failed",11);
	      return -1;
	    }
	}
	
      }
      
    }

    cur_x += _glyphPtr[i]->getOffsetToNextX();
    cur_y += _glyphPtr[i]->getOffsetToNextY();
  }

  return 1;
}

void
imgGlyph::checkTouched()
{
  int count = _glyphList.size();
  if (!_touched || !count) return;

  int xmin, xmax;
  int ymin, ymax;

  _curX = _curY = 0;

  deleteGlyphPtr();

  _glyphPtr = new Glyph*[count];

  for (int i=0; i < count; i++) {
    _glyphPtr[i] = _glyphList[i];
  }

  Glyph::calcBBX(_glyphPtr, count, _curX, _curY, xmax, ymax, xmin, ymin);

  // initialize new glyph
  _width = xmax - xmin;
  _height = ymax - ymin;

  _touched = 0;
}

void
imgGlyph::deleteGlyphPtr()
{
  if (_glyphPtr == NULL) return;

  delete[] _glyphPtr;

  _glyphPtr = NULL;
}
