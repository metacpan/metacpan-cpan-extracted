/*
** Font Class
**
*/

#include <ctype.h>
#include <string.h>
#include <map.h>

#include "Font.h"

#define BUFFERSIZE         4096
#define SEPERATORS         " \r\n"
#define SEPERATORS_WOSPACE "\r\n"

BitFont::BitFont()
{
  _name = NULL;
  _glyphCount = 0;
  _width = _height = _xOff = _yOff = 0;
  _charsetEncoding = 0;
  _errorID = 0;
  _errorString = NULL;
}

BitFont::~BitFont()
{

  if (_name != NULL) delete[] _name;
  if (_errorString != NULL) delete[] _errorString;
  while (_glyphList.begin() != _glyphList.end()) {
    int encoding = (*(_glyphList.begin())).first;
    //Glyph *glyph = _glyphList[encoding];
    //delete glyph;

    _glyphList.erase(encoding);
  }
  while (_glyphNameList.begin() != _glyphNameList.end()) {
    const char *name = (*(_glyphNameList.begin())).first;
    Glyph *glyph = _glyphNameList[name];
    delete glyph;

    _glyphNameList.erase(name);
  }
}

BitFont *
BitFont::openBDF(const char *path)
{
  FILE    *file   = fopen(path, "r");
  char    *token;
  int      line = 0;
  short    jobDone = 0;

  BitFont *newFont = new BitFont();

  if (!file) {
    newFont->setError(1,"Can not open file",0);
    return newFont;
  }

  char    *buffer = new char[BUFFERSIZE];

  while (fgets(buffer, BUFFERSIZE, file)) {
    line++;
    token = strtok(buffer, SEPERATORS);

    if (!token) {
      newFont->setError(1,"Can not get token in line %d",line);
      break;
    }

    if (!strcmp(token, "STARTCHAR")) {
      if (!newFont->addBDFglyph(strtok(NULL, SEPERATORS), file, buffer, BUFFERSIZE,line)) 
	break;

    } else if (!strcmp(token, "FONT")) {
      newFont->setName(strtok(NULL, SEPERATORS));

    } else if (!strcmp(token, "SIZE")) {
      
    } else if (!strcmp(token, "FONTBOUNDINGBOX")) {
      token = strtok(NULL, SEPERATORS_WOSPACE);

      if (!token) {
	newFont->setError(1,"FONTBOUNDINGBOX values expected in line %d",line);
	break;
      } else {
	int height, xOff, yOff, width=0;
	sscanf(token, "%d %d %d %d", &width, &height, &xOff, &yOff);
	if (width == 0) {
	  newFont->setError(1,"Width for FONTBOUNDINGBOX shoul not be 0 in line %d",line);
	  break;
	} else {
	  newFont->setBoundingBox(width, height, xOff, yOff);
	}
      }
    } else if (!strcmp(token, "CHARSET_ENCODING")) {
      token = strtok(NULL, SEPERATORS_WOSPACE);
      if (!token) {
	newFont->setError(1,"CHARSET_ENCODING value expected in line %d",line);
	break;
      } else {
	int encoding=0;
	if (token[0] == '"') {
	  sscanf(token, "\"%d\"",&encoding);
	} else {
	  sscanf(token, "%d",&encoding);
	}
	if (encoding == 0) {
	  newFont->setError(1,"CHARSET_ENCODING should not be 0 in line %d",line);
	  break;
	} else {
	  newFont->setCharsetEncoding(encoding);
	}
      }
    } else if (!strcmp(token, "CHARS")) {
      token = strtok(NULL, SEPERATORS_WOSPACE);
      if (!token) {
	newFont->setError(1,"CHARS value expected in line %d",line);
	break;
      } else {
	int number=0;
	sscanf(token, "%d",&number);
	if (number == 0) {
	  newFont->setError(1,"CHARS should not be 0 in line %d",line);
	  break;
	} else {
	  newFont->setNumberOfGlyphs(number);
	}
      }
    } else if (!strcmp(token, "ENDCHAR")) {
      newFont->setError(1, "Unexpected ENDCHAR in line %d",line);
      break;
    } else if (!strcmp(token, "ENDFONT")) {
      jobDone = 1;
      // _glyphCount != count
      break;
    } /*else if (!strcmp(token, "")) {
    }*/
  }
	  
  fclose(file);
  delete[] buffer;

  if (!jobDone && newFont->getStatus() == 0) {
    newFont->setError(1, "Unexpected EOF in line %d , nothing done",line);
  }
  return newFont;
}

Glyph **
BitFont::getText(const char *text, int &count)
{
  if (strlen(text) == 0) {
    return NULL;
  }

  Glyph **glyphPtr = new Glyph*[strlen(text)];
  count = 0;
  
  for (int i=0;i<strlen(text);i++) {
    map<const int, Glyph *>::iterator glyph = _glyphList.find(text[i]);

    if (glyph != _glyphList.end()) {
      glyphPtr[i] = _glyphList[(*glyph).first];
      count++;
    } else {
      // glyph not in font
      glyph = _glyphList.find(32); // find space
      if (glyph != _glyphList.end()) {
	glyphPtr[i] = _glyphList[(*glyph).first];
	count++;
      } else {
	//
      }
    }
  }
  if (count > 0) return glyphPtr;

  delete[] glyphPtr;
  return NULL;
}

void
BitFont::releaseText(Glyph  **memory)
{
  if (memory == NULL) {
    return;
  }

  delete[] memory;
}

int
BitFont::getBBXW()
{
  return _width;
}

int
BitFont::getBBXH()
{
  return _height;
}

int
BitFont::getBBXXO()
{
  return _xOff;
}

int
BitFont::getBBXYO()
{
  return _yOff;
}

int
BitFont::getCharsetEncoding()
{
  return _charsetEncoding;
}

const char *
BitFont::getName()
{
  return _name;
}

const char *
BitFont::getErrorString()
{
  return _errorString;
}

short
BitFont::getStatus()
{
  return _errorID;
}

short
BitFont::addBDFglyph(const char*name, FILE *file, char *buffer, int bsize, int &line)
{
  if (!name) {
    setError(1,"No name for glyph specified in line %d",line);
    return 0;
  }

  char *token;
  Glyph *newGlyph = new Glyph();

  newGlyph->setName(name);
  //printf("*--Glyphname: %s\n",name);
  while (fgets(buffer, bsize, file)) {
    token = strtok(buffer, SEPERATORS);

    //printf("*--Token: %s\n",token);

    if (!token) {
      setError(1,"Glyph specification exptected in line %d",line);
      break;
    }

    if (!strcmp(token, "ENCODING")) {

      token = strtok(NULL, SEPERATORS);
      if (!token) {
	setError(1,"Value for ENCODING expected in line %d",line);
	break;
      } else {
	int encoding=0;
	sscanf(token, "%d",&encoding);
	
	if (encoding == -1) {
	  /*if (!(token = strtok(NULL, SEPERATORS))) {
	    setError(1,"Non-standard encoding value expexted in line %d",line);
	    break;

	  } else {
	    sscanf(token, "%d",&encoding);
	  }*/
	}
	if (encoding > 0) {
	  newGlyph->setEncoding(encoding);
	} else {
	  //setError(1,"Encoding value error in line %d",line);
	  //break;
	}
      }
    } else if (!strcmp(token, "SWIDTH")) {
    } else if (!strcmp(token, "DWIDTH")) {
      token = strtok(NULL, SEPERATORS_WOSPACE);

      if (!token) {
	setError(1,"DWIDTH values expected in line %d",line);
	break;

      } else {
	int y, x=0;
	sscanf(token, "%d %d", &x, &y);
	if (x == 0) {
	  setError(1,"Width for DWIDTH should not be 0 in line %d",line);
	  break;

	} else {
	  newGlyph->setOffsetToNext(x,y);
	}
      }
    } else if (!strcmp(token, "BBX")) {
      token = strtok(NULL, SEPERATORS_WOSPACE);

      if (!token) {
	setError(1,"BBX values expected in line %d",line);
	break;

      } else {
	int height, xOff, yOff, width=0;
	sscanf(token, "%d %d %d %d", &width, &height, &xOff, &yOff);

	if (width == 0) {
	  //setError(1,"Width for BBX should not be 0 in line %d",line);
	  //break;

	} else {
	  newGlyph->setBoundingBox(width, height, xOff, yOff);
	}
      }
    } else if (!strcmp(token, "BITMAP")) {
      int lineBitmap = 0;

      /*if (newGlyph->getBBXW() == 0) {
	//setError(1,"No BBX specification before BITMAP, line %d",line);
	//break;

      } else {*/

	while (fgets(buffer, bsize, file)) {
	  line++;
	  int xcount = 0;

	  if (!strncmp(buffer, "ENDCHAR", 7)) {
	    if (lineBitmap == newGlyph->getBBXH()) {
              //if (!strcmp(newGlyph->getName(),"a")) 
	      //newGlyph->print();
	      addGlyph(newGlyph);
	      return 1;
	    } else {
	      setError(1,"Unexpected ENDCHAR in line %d while adding glyph",line);
	      break;
	    }
	  } else if (isxdigit(*buffer)) {

	    char *ptr = buffer;
	    int bitmap = 0;

	    while (isxdigit(*ptr)) {
	      sscanf(ptr,"%2X",&bitmap);

	      newGlyph->setBitmap8(xcount, lineBitmap, bitmap);
	      xcount++;

	      ptr += 2;
	    }
	  } else {
	    setError(1,"Unexpected Token in line %d",line);
	  }

	  lineBitmap++;
	} /* while fgets */

	if (_errorID == 0) setError(1,"Unexpected EOF in line %d", line);
	break;

	/*}  else newGlyph->getBBXW() == 0*/

    } else if (!strcmp(token, "ENDCHAR")) {
      setError(1,"Unexpected ENDCHAR in line %d, no prior BITMAP", line);
      break;
    } else if (!strcmp(token, "ENDFONT")) {
      setError(1,"ENDFONT unexpexted in line %d",line);
      break;
    }
  } /* while fgets */
  delete newGlyph;

  if (getStatus() == 0)
    setError(1,"Unexpected EOF in line %d ,did not add glyph",line);
  return 0;
}

void
BitFont::addGlyph(Glyph *glyph)
{
  /*if (_glyphList.find(glyph->getEncoding()) != _glyphList.end()) {
    return;
  }*/

  if (glyph->getEncoding() != 0)
    _glyphList[glyph->getEncoding()] = glyph;
  _glyphNameList[glyph->getName()] = glyph;
}

void
BitFont::setName(const char*name)
{
  if (name == NULL) return;
  int len = strlen(name);
  if (len == 0) return;
  len++;
  _name = new char[len];
  strcpy(_name, name);
}

void
BitFont::setBoundingBox(int width, int height, int xOff, int yOff)
{
  _width  = width;
  _height = height;
  _xOff   = xOff;
  _yOff   = yOff;
}

void
BitFont::setNumberOfGlyphs(int number)
{
  _glyphCount = number;
}

void
BitFont::setCharsetEncoding(int encoding)
{
  _charsetEncoding = encoding;
}

void
BitFont::setError(short id, const char*str, int line)
{
  if (_errorString) {
    printf("WARNING: setError called twice '%s' '%s'\n",_errorString, str);
    delete[] _errorString;
  }
  _errorString = new char[strlen(str)+512];// +512 just for security reasons
                                           // dont know how big %d is
  sprintf(_errorString,str,line);
  _errorID = id;
}

void BitFont::printBin(char c)
{
  for (int i=7;i >= 0; i--) {
    if (c & (1<<i)) {
      printf("#");
    } else {
      printf("-");
    }
  }
  puts("");
}
