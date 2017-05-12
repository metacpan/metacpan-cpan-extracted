/*
** Fehlerbehandlung
**
*/
#include <il/ilMemoryImg.h>
#include "imgProcess.h"
#include "smpVideo.h"
#include "imgArray.h"

imgArray::imgArray()
{
  _error = 0;
  _errno = 0;
}

imgArray::~imgArray()
{
  deleteArray();
  if (_error > 0) {
    delete _error;
  }
}

void
imgArray::deleteArray()
{
  while (_array.begin() != _array.end()) {
    imgProcess *image = _array.back();
    delete image;

    _array.pop_back();
  }
}

void
imgArray::setError(const char *str)
{
  setError(str,1);
}

void
imgArray::setError(const char *str, short errno)
{
  if (_error > 0) {
    printf("WARNING: imgArray::setError() called twice (%s,%s)\n",_error,str);
    delete _error;
  }
  _error = new char[strlen(str)+1];
  strcpy(_error,str);
  _errno = errno;
}

void
imgArray::printError()
{
  printf("%s\n",getErrorString());
}

char *
imgArray::getErrorString()
{
  static char str[2048];
  sprintf(str,"imgArray: %.2007s (%d)",_error, _errno);
  return str;
}

short
imgArray::getStatus()
{
  return _errno;
}

int
imgArray::size()
{
  return _array.size();
}

void
imgArray::push(imgProcess *image)
{
  _array.push_back(image);
}

void
imgArray::unshift(imgProcess *image)
{
  _array.insert(_array.begin(), image);
}

imgProcess *
imgArray::pop()
{
  imgProcess *image = _array.back();
  _array.pop_back();

  return image;
}

imgProcess *
imgArray::shift()
{
  imgProcess *image = _array.front();
  _array.erase(_array.begin());

  return image;
}

short
imgArray::loadIndexed(const char *prefix, int startSuffix, const char *suffix, 
			    int amount)
{

  imgProcess **tmpArray = new imgProcess*[amount];
  char *string = new char[ strlen(prefix) + strlen(suffix) + 100 ];
  
  for (int i=0; i < amount;i++) {
    sprintf(string, "%s%d%s",prefix, startSuffix + i, suffix);
    if ((tmpArray[i]->load(string)) <= 0) {

      delete string;
      delete[] tmpArray;

      string = new char[ strlen(prefix) + strlen(suffix) + 200 ];
      sprintf(string, "imgArray: Can't load '%s%d%s'",prefix, startSuffix + i, suffix);
      setError(string);
      delete string;
      return -1;
    }
  }

  deleteArray();
  for ( i=0; i < amount;i++) {
    _array.push_back(tmpArray[i]);
  }

  delete string;
  delete[] tmpArray;

  return 1;
}

short
imgArray::saveIndexed(const char *prefix, int startSuffix, const char *suffix, const char *format)
{
  char *string = new char[ strlen(prefix) + strlen(suffix) + 100 ];

  for (int i=0; i < _array.size();i++) {
    sprintf(string, "%s%d%s",prefix, startSuffix + i, suffix);
    if ((_array[i]->save(string,format)) <= 0) {

      delete string;
      string = new char[ strlen(prefix) + strlen(suffix) + 200 ];
      sprintf(string, "imgArray: Can't save '%s%d%s'",prefix, startSuffix + i, suffix);
      setError(string);
      return -1;
    }
  }

  delete string;

  return 1;
}

short
imgArray::getVideoStream(int frameAmount)
{

  int xsize, ysize;
  char errorString[ERRORSTR_LENGTH];

  smpVideo *vid = new smpVideo;

  if ((vid->openVideo()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  if ((vid->setVideoInPath()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  if ((vid->createBuffer(frameAmount)) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  if ((vid->beginTransfer()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  if ((vid->waitTransferDone()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  if ((vid->getVideoSize(&xsize, &ysize)) < 0) {
    vid->getErrorStrFmt(errorString);
    setError(errorString);
    delete vid;
    return -1;
  }

  iflSize imgSize(xsize, ysize, 1, 4);
  char **dataPtr = new char*[frameAmount];
  ilMemoryImg **tmpImages = new ilMemoryImg*[frameAmount];

  int x;

  for (int i=0; i< frameAmount; i++) {
    if ((dataPtr[i] = (char *)vid->getFramePointer(i+1)) <= 0) {
      vid->getErrorStrFmt(errorString);
      setError(errorString);

      for (x=0;x<i;x++) {
	delete tmpImages[x];
      }
      delete[] tmpImages;
      delete[] dataPtr;
      delete vid;
      

      return -1;
    }

    tmpImages[i] = new ilMemoryImg(NULL, imgSize, iflUChar);

    tmpImages[i]->setColorModel(iflABGR);
    tmpImages[i]->setOrientation(iflUpperLeftOrigin);
    tmpImages[i]->setTile(0,0,xsize,ysize,dataPtr[i]);

    if (tmpImages[i]->getStatus() != ilOKAY) {
      //      setError(tmpImage->getStatus());
      for (x=0;x < i+1;x++) {
	delete tmpImages[x];
      }
      delete[] tmpImages;
      delete[] dataPtr;
      delete vid;

      sprintf(errorString,"imgArray: Error while creating of tmpImage[%d] or while copying raw data",i);
      setError(errorString);
      return -1;
    }
  }

  deleteArray();

  for ( i=0; i< frameAmount; i++) {

    _array.push_back( new imgProcess(tmpImages[i]));
  }

  delete[] tmpImages;
  delete[] dataPtr;
  delete vid;

  return 1;
}
