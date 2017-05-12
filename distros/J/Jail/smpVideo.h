
#ifndef __smpVIDEO__
#define __smpVIDEO__

#include <stdlib.h>
#include <dmedia/vl.h> 

class smpVideo {
 public:
  smpVideo();
  ~smpVideo();

  int   getErrorNo();
  char *getErrorStr();
  void  getErrorStrFmt(char *string);
  void  printError();

  short openVideo();
  short closeVideo();
  short setVideoInPath(int packing = VL_PACKING_RGBA_8);
  short closePath();
  short createBuffer(int frameAmount = 1);
  short deleteBuffer();
  short beginTransfer();
  short restartTransfer();
  short getVideoSize(int *x, int *y);
  int   checkTransferDone();
  int   waitTransferDone();
  int   getFrameCounter();
  void *getFramePointer(int number);
  
 private:
  void setError();
  void setError(int errno, const char *errstr);
  void cleanup();
  void videoCleanup();

  short    _transferRunning;
  int      _frameAmount;
  int      _frameCounter;
  void   **_framePointer;
  VLServer _server;
  VLPath   _path;
  VLNode   _source, _drain;

  VLBuffer _buffer;
  VLInfoPtr      info;

  char *_error;
  int   _errno;
};

#endif
