// -*- mode: c++ -*-
#include <unistd.h>
#include <sys/wait.h>
#include "Font.h"
#include "Glyph.h"
#include "imgGlyph.h"
#include "imgArray.h"
#include "imgProcess.h"
#include "imgDisplay.h"

extern "C" {

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

}

#ifdef PerlIO
typedef PerlIO * OutputStream;
#else
typedef FILE * OutputStream;
#endif

void childCatcher(int i)
{
  wait3(NULL, WNOHANG, NULL);
}

static int not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'E'://ilEdgeMode
      if (strEQ(name, "EDGE_NOPAD"))   return ilNoPad;
      if (strEQ(name, "EDGE_PADSRC"))  return ilPadSrc;
      if (strEQ(name, "EDGE_PADDST"))  return ilPadDst;
      if (strEQ(name, "EDGE_WRAP"))    return ilWrap;
      if (strEQ(name, "EDGE_REFLECT")) return ilReflect;
    case 'R'://ilResampType
      if (strEQ(name, "RT_USERDEF"))  return ilUserDef;
      if (strEQ(name, "RT_NEARNB"))   return ilNearNb;
      if (strEQ(name, "RT_BILINEAR")) return ilBiLinear;
      if (strEQ(name, "RT_BIBUBIC"))  return ilBiCubic;
      if (strEQ(name, "RT_MINIFY"))   return ilMinify;

    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Jail	PACKAGE = Jail		

double
constant(name,arg)
        char *          name
        int             arg

imgProcess *
imgProcess::new(...)
CODE:
  if (items == 1) {
    RETVAL = new imgProcess();
  } else if (items == 3 || items == 4) {
    if (items == 3) {
      RETVAL = new imgProcess((int)SvIV(ST(1)), (int)SvIV(ST(2)));
    } else {
      RETVAL = new imgProcess((int)SvIV(ST(1)), (int)SvIV(ST(2)), (int)SvIV(ST(3)));
    }
  } else {
    croak("Usage: new Jail( [width,height [,channels]] )");
  }
OUTPUT:
  RETVAL

void
imgProcess::DESTROY()

int
imgProcess::getWidth()

int
imgProcess::getHeight()

int
imgProcess::getChannels()

char *
imgProcess::getImageFormatName()
CODE:
   RETVAL = (char *)THIS->getImageFormatName();
OUTPUT:
   RETVAL

short
imgProcess::load(filename)
	char *filename
CODE:
  if ((THIS->load(filename)) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

short
imgProcess::save(filename, format)
    char *filename
    char *format
CODE:
  if ((THIS->save((const char*)filename,(const char *)format)) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

short
imgProcess::saveFile(handle,format)
    OutputStream     handle
    char *format
CODE:
  if (handle) {
    int fd[2], gif=0;
    if (!strcmp("GIF",format)) gif=1;
    if (pipe(fd) == -1) {
      croak("pipe() failed");
    }
    signal(SIGCHLD,childCatcher);
    if (fork()) {
      close(fd[1]);
      ssize_t ret;
      char *buffer = new char[1024];  
      do {
	ret = read(fd[0], buffer, 1024);
	if (ret > 0) {
	  // mega hack, it seems that the ifl is trying to seek on
	  // the fifo... can only correct it for gifs
	  if (gif && ret == 782) {
	    ret--;
	    gif = 0;
	  }
#ifdef PerlIO
	  PerlIO_write(handle, buffer, ret);
	  PerlIO_flush(handle);
#else
	  fwrite(buffer, sizeof(char), ret, handle);
	  fflush(handle);
#endif
	}
      } while (ret > 0);
      close(fd[0]);
      delete[] buffer;
    } else {
      // child
      close(fd[0]);
      /// damn il bug, iam a client dont delete my shared arena
      THIS->setClient(1);
      if ((THIS->save(fd[1],(const char*)NULL,(const char *)format)) == -1) {
	char *err  = THIS->getErrorString();
	printf("ERROR WHILE WRITING TO FD: %s\n",err);
      }
      close(fd[1]);
      exit(0);
      puts("-ERROR:EXIT--------------------------------");
    }
  }
  RETVAL = 1;
OUTPUT:
  RETVAL

short
imgProcess::copyTile(destX, destY, width, height, srcImage, srcX, srcY)
   int destX
   int destY
   int width
   int height
   imgProcess *srcImage
   int srcX
   int srcY
CODE:
   if (!(sv_isobject(ST(5)) && (SvTYPE(SvRV(ST(5))) == SVt_PVMG)
	 && !strcmp(HvNAME(SvSTASH(SvRV(ST(5)))), "Jail" ) )) {
     croak("Need a blessed 'Jail' object as srcImg");
   } else {
     if (THIS->copyTile(destX,destY,width,height,srcImage,srcX,srcY) == -1) {
       RETVAL = 0;
     } else {
       RETVAL = 1;
     }
   }
OUTPUT:
   RETVAL

short
imgProcess::add(addImg, bias=.0)
     imgProcess *addImg
     double bias
CODE:
   if (!(sv_isobject(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVMG)
	 && !strcmp(HvNAME(SvSTASH(SvRV(ST(1)))), "Jail" )
	 )) {
     croak("Need a blessed 'Jail' object as addImg");
   } else {
     if (THIS->add(addImg,bias) == -1) {
       RETVAL = 0;
     } else {
       RETVAL = 1;
     }
   }
OUTPUT:
   RETVAL

short
imgProcess::setPixel(x, y, r, g, b, a=0)
   int x
   int y
   int r
   int g
   int b
   int a
CODE:
   if (THIS->setPixel(x,y,r,g,b,a) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

imgProcess *
imgProcess::duplicate()
CODE:
   char *CLASS = "Jail";
   if (!(sv_isobject(ST(0)) && (SvTYPE(SvRV(ST(0))) == SVt_PVMG)
	 && !strcmp(HvNAME(SvSTASH(SvRV(ST(0)))), "Jail" ) )) {
     croak("Need a blessed 'Jail' object as srcImg");
   } else {
     RETVAL = new imgProcess(THIS);
   }
OUTPUT:
   RETVAL

short
imgProcess::getVideoSnapshot()
CODE:
   if ((THIS->getVideoSnapshot()) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::rotateZoom(angle,zoomX=1.0,zoomY=1.0,rs=ilNearNb)
     float angle
     float zoomX
     float zoomY
     unsigned short rs
CODE:
   if ((THIS->rotateZoom(angle,zoomX,zoomY,rs)) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::blur(blur=1.0,width=5,height=5,biasValue=0.,edgeMode=ilPadSrc)
     float blur
     int width
     int height
     double biasValue
     unsigned short edgeMode
CODE:
   if ((THIS->blur(blur,width,height,biasValue,edgeMode)) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::sharp(sharp=.5,radius=1.5,edgeMode=ilPadSrc)
     float sharp
     float radius
     unsigned short edgeMode
CODE:
   if ((THIS->sharp(sharp,radius,edgeMode)) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL
	 
short
imgProcess::compass(radius,biasVal=0., kernSize=3, edgeMode=ilPadSrc)
     float radius
     double biasVal
     int kernSize
     unsigned short edgeMode
CODE:
   if ((THIS->compass(radius,biasVal,kernSize,edgeMode)) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::laplace(biasVal=0., edgeMode=ilPadSrc, kernSize=1)
     double biasVal
     unsigned short edgeMode
     int kernSize
CODE:
   if ((THIS->laplace(biasVal,edgeMode,kernSize)) == -1) {
     RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::edgeDetection(biasVal=0., edgeMode=ilPadSrc)
     double biasVal
     unsigned short edgeMode
CODE:
   if ((THIS->edgeDetection()) == -1) {
	   RETVAL = 0;
   } else {
     RETVAL = 1;
   }
OUTPUT:
   RETVAL

short
imgProcess::blendImg(srcImg, ...)
     imgProcess *srcImg
CODE:
   if (!(sv_isobject(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVMG)
	 && !strcmp(HvNAME(SvSTASH(SvRV(ST(1)))), "Jail" )
	 )) {
     croak("Need a blessed 'Jail' object as srcImg");
   }
   if (items == 3 && SvNOKp(ST(2))) {
     float alpha = (float)SvNV(ST(2));
     if ((THIS->blendImg(srcImg,alpha)) == -1) {
       RETVAL = 0;
     } else {
       RETVAL = 1;
     }
   } else if ((items == 3 || items == 4) && sv_isobject(ST(2))) {
     if (!((SvTYPE(SvRV(ST(2))) == SVt_PVMG)
	   && !strcmp(HvNAME(SvSTASH(SvRV(ST(2)))), "Jail" )
	   )) {
       croak("Need a blessed 'Jail' object as alphaImg");
     }
     unsigned short comp;
     if (items == 2) {
       comp = (unsigned short)SvIV(ST(3));
     } else {
       comp = ilAplusB;
     }
     imgProcess *alphaImg=(imgProcess *)SvIV((SV*)SvRV(ST(2)));
     if (THIS->blendImg(srcImg,alphaImg,(ilCompose)comp) == -1) {
       RETVAL = 0;
     } else {
       RETVAL = 1;
     }
   } else {
     croak("Usage: blendImg(srcImg,alpha) | blendImg(srcImg, alphaImg, [compos]");
   }
OUTPUT:
   RETVAL

void
imgProcess::printError()

char*
imgProcess::getErrorString()

short
imgProcess::getStatus()

void
imgProcess::display()
CODE:
   imgDisplay *display = new imgDisplay(THIS);
   delete display;

MODULE = Jail	PACKAGE = JailArray

double
constant(name,arg)
        char *          name
        int             arg

imgArray *
imgArray::new()

imgArray *
imgArray::DESTROY()

int
imgArray::size()

void
imgArray::push(image)
	imgProcess *image

void
imgArray::unshift(image)
	imgProcess *image

imgProcess *
imgArray::pop()
INIT:
   char *CLASS = "Jail";

imgProcess *
imgArray::shift()
INIT:
   char *CLASS = "Jail";

short
imgArray::loadIndexed(prefix,startSuffix,suffix,amount)
  char *prefix
  int startSuffix
  char *suffix
  int amount
CODE:
  if ((THIS->loadIndexed(prefix,startSuffix,suffix,amount)) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

short
imgArray::saveIndexed(prefix,startSuffix,suffix,format)
    char *prefix
    int startSuffix
    char *suffix
    char *format
CODE:
  if ((THIS->saveIndexed(prefix,startSuffix,suffix,format)) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

short
imgArray::getVideoStream( frameAmount)
    int frameAmount
CODE:
  if ((THIS->getVideoStream(frameAmount)) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

void
imgArray::printError()

char *
imgArray::getErrorString()

short
imgArray::getStatus()

MODULE = Jail	PACKAGE = Font

void
BitFont::DESTROY()

static BitFont *
BitFont::openBDF(path)
    char *path

Glyph **
BitFont::getText(text, count)
	 char *text
	 int count
INIT:
  char *CLASS = "GlyphArray";
OUTPUT:
  RETVAL
  count

int
BitFont::getBBXW()

int
BitFont::getBBXH()

int
BitFont::getBBXXO()

int
BitFont::getBBXYO()

int
BitFont::getCharsetEncoding()

char *
BitFont::getName()
CODE:
  RETVAL = (char *)THIS->getName();
OUTPUT:
  RETVAL

short
BitFont::getStatus()

char *
BitFont::getErrorString()
CODE:
  RETVAL = (char *)THIS->getErrorString();
OUTPUT:
  RETVAL

MODULE = Jail	PACKAGE = Glyph

#Glyph *
#Glyph::new()

void
Glyph::DESTROY()

static Glyph *
Glyph::merge(glyphList, count)
	 Glyph **glyphList
	 int count
CODE:
  RETVAL = Glyph::merge(glyphList,count);
  if (RETVAL == NULL) {
    RETVAL = 0;
  } else {
    ST(0) = sv_newmortal();
    sv_setref_pv( ST(0), CLASS, (void*)RETVAL );
  }

void
Glyph::setName(name)
    char *name

int
Glyph::getEncoding()

int
Glyph::getBBXW()

int
Glyph::getBBXH()

int
Glyph::getBBXXO()

int
Glyph::getBBXYO()

char *
Glyph::getName()
CODE:
  RETVAL = (char *)THIS->getName();

void
Glyph::setForeground(r,g,b,a=0)
  int r
  int g
  int b
  int a

void
Glyph::setBackground(r,g,b,a=0)
  int r
  int g
  int b
  int a

char
Glyph::getForegroundR()

char
Glyph::getForegroundG()

char
Glyph::getForegroundB()

char
Glyph::getForegroundA()

char
Glyph::getBackgroundR()

char
Glyph::getBackgroundG()

char
Glyph::getBackgroundB()

char
Glyph::getBackgroundA()

void
Glyph::print()

MODULE = Jail	PACKAGE = GlyphArray

void
Glyph::DESTROY()
CODE:
  Glyph **toDestroy = (Glyph **)THIS;
  delete[] toDestroy;

MODULE = Jail   PACKAGE = JailGlyph

imgGlyph *
imgGlyph::new()

void
imgGlyph::DESTROY()
CODE:
  if (THIS) delete THIS;

short
imgGlyph::addGlyph(glyph)
  Glyph *glyph
CODE:
  if (!(sv_isobject(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVMG)
	&& !strcmp(HvNAME(SvSTASH(SvRV(ST(1)))), "Glyph" )
	)) {
    croak("Need a blessed 'Glyph' object for addGlyph");
  }
  if (THIS->addGlyph(glyph) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

imgProcess*
imgGlyph::createImg()
INIT:
  char *CLASS = "Jail";

short
imgGlyph::blittInImage(image, x, y)
  imgProcess *image
  int x
  int y
CODE:
  if (!(sv_isobject(ST(1)) && (SvTYPE(SvRV(ST(1))) == SVt_PVMG)
	&& !strcmp(HvNAME(SvSTASH(SvRV(ST(1)))), "Jail" )
	)) {
    croak("Need a blessed 'Jail' object for blittInImage");
  }
  if (THIS->blittInImage(image, x, y) == -1) {
    RETVAL = 0;
  } else {
    RETVAL = 1;
  }
OUTPUT:
  RETVAL

int
imgGlyph::getWidth()

int
imgGlyph::getHeight()

int
imgGlyph::getCurX()

int
imgGlyph::getCurY()

void
imgGlyph::printError()

char *
imgGlyph::getErrorString()

short
imgGlyph::getStatus()
