/* -*- mode: c++ -*- */

#ifndef __imgPROCESS__
#define __imgPROCESS__

#include <stdlib.h>
#include <il/ilImage.h>
#include <il/ilError.h>
#include <ifl/iflError.h>
#include <vector.h>
#include "imgDisplay.h"

#define ERRORSTR_LENGTH 512

class imgProcess {
  friend class imgDisplay;

 public:

  // Constructor
  imgProcess();
  imgProcess(int width, int height, short channels=3);
  imgProcess(imgProcess *image);
  imgProcess(ilImage *image);
  // Destructor
  ~imgProcess();

  // Statistik
  int    getWidth();
  int    getHeight();
  int    getChannels();
  const char *getImageFormatName();

  // File i/o
  short  load(int fd);
  short  load(const char *filename);
  short  load(int fd, const char *filename);
  short  save(int fd, const char *format);
  short  save(const char *filename, const char *format);
  short  save(int fd, const char *filename, const char *format);

  // manipulator
  short copyTile(int destX, int destY, int width, int height, imgProcess *srcImage, int srcX, int srcY);
  short add(imgProcess *addImg, double bias=.0);
  short setPixel(int x, int y, char r, char g, char b, char a=0);

  // Video
  short  getVideoSnapshot();

  // Filter
  short  rotateZoom(float angle, float zoomX=1.0, float zoomY=1.0, unsigned short resampleType=ilNearNb);
  short  blur(float blur=1.0, int width=5, int height=5,double biasValue=0., unsigned short edgeMode=ilPadSrc);
  short  sharp(float sharpness=.5, float radius=1.5, unsigned short edgeMode=ilPadSrc);
  short  compass(float radius, double biasVal=0., int kernSize=3, unsigned short edgeMode=ilPadSrc);
  short  laplace(double biasVal=0., unsigned short edgeMode=ilPadSrc, int kernSize=1);
  short  edgeDetection(double biasVal=0., unsigned short edgeMode=ilPadSrc);
  short  blendImg(imgProcess *image, float alpha);
  short  blendImg(imgProcess *image, imgProcess *alphaimg, ilCompose compose=ilAplusB);

  // Error handling
  void printError();
  char *getErrorString();
  ilStatus getStatus();

  void setClient(short st);
 private:
  void common_init(ilImage *image);
  void setError(ilStatus status);
  void setError(iflStatus status);
  void setError(ilStatus status, const char *str);
  void deleteQue();
  static ilImage* copyImg(ilImage *src, iflColorModel model=iflRGBA);

  ilImage          *_image;
  vector<ilImage *> _que;
  char             *_imageFormat;
  char              _error[ERRORSTR_LENGTH];
  ilStatus          _errno;

  // il bug ..
  short             _client;
};

#endif
