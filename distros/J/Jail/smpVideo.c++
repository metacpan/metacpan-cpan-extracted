#include "smpVideo.h"

smpVideo::smpVideo()
{
  _transferRunning = 0;
  _frameAmount = 0;
  _frameCounter = 0;
  _framePointer = NULL;
  _server = NULL;
  _source = NULL;
  _drain = NULL;
  _path = NULL;
  _buffer = NULL;
}

smpVideo::~smpVideo()
{
  cleanup();
}

void smpVideo::cleanup()
{
  deleteBuffer();
  videoCleanup();
}

void smpVideo::videoCleanup()
{
  closePath();
  closeVideo();
}

void smpVideo::setError()
{
  _errno = vlGetErrno();
  _error = (char *)vlStrError(_errno);
}

void smpVideo::setError(int errno, const char *errstr)
{
  _errno = errno;
  _error = (char *)errstr;
}

char *smpVideo::getErrorStr()
{
  return _error;
}

void smpVideo::printError()
{
  printf("video: %s (%d)\n", _error, _errno);
}

int smpVideo::getErrorNo()
{
  return _errno;
}

void smpVideo::getErrorStrFmt(char *string)
{
  sprintf(string,"video: %s (%d)", _error, _errno);
}

short smpVideo::openVideo()
{
  if (_server != NULL) {
    setError(VLBadRequest, "Video is already open");

    return -1;
  }

  if (!(_server = vlOpenVideo(""))) {
    setError();

    _server = NULL;
    return -1;
  }

  return 1;
}

short smpVideo::closeVideo()
{
  if (_server <= 0) {
    setError(VLBadRequest, "Video is not open");

    return -1;
  }

  if ((vlCloseVideo(_server)) < 0) {
    setError();
      
    return -1;
  }
  _server = 0;

  return 1;
}

short smpVideo::setVideoInPath(int packing)
{
  VLControlValue controlValue;

  if (_server <= 0) {
    setError(VLBadRequest, "Video is not open");

    return -1;
  }

  if (_path != NULL) {
    setError(VLBadRequest, "There is already a video path");

    return -1;
  }

  /* Set up a drain node in memory */
  if ((_drain = vlGetNode(_server, VL_DRN, VL_MEM, VL_ANY)) < 0) {
    setError();

    cleanup();
    return -1;
  }
  
  /* Set up a source node on any video source  */
  if ((_source = vlGetNode(_server, VL_SRC, VL_VIDEO, VL_ANY)) < 0) {
    setError();

    cleanup();
    return -1;
  }
  
  /* Create a path using the first device that will support it */
  if ((_path = vlCreatePath(_server, VL_ANY, _source, _drain)) < 0) {
    setError();

    cleanup();
    return -1;
  }

  /* Set up the hardware for and define the usage of the path */
  if ((vlSetupPaths(_server, (VLPathList)&_path, 1, VL_SHARE, VL_SHARE)) < 0) {
    setError();

    cleanup();
    return -1;
  }

  /* Set the packing */
  controlValue.intVal = packing;
  if ((vlSetControl(_server, _path, _drain, VL_PACKING, &controlValue)) < 0) {
    setError();

    cleanup();
    return -1;
  }

  return 1;
}

short smpVideo::closePath()
{
  if (_path == NULL) {
    setError(VLBadRequest, "There is no video path");

    return -1;
  }

  if (_transferRunning > 0) {
    if ((vlEndTransfer(_server, _path)) < 0) {
      setError();

      return -1;
    }
    _transferRunning = 0;
  }
  if (_path > 0) {

    if (_source > 0) {
      vlRemoveNode(_server, _path, _source);
      _source = NULL;
    }
    if (_drain > 0) {
      vlRemoveNode(_server, _path, _drain);
      _drain = NULL;
    }

    if ((vlDestroyPath(_server, _path)) < 0) {
      setError();

      return -1;
    }
    _path = NULL;
  }

  return 1;
}

short smpVideo::createBuffer(int frameAmount)
{
  if (_server <= 0 || _path <= 0) {
    setError(VLBadRequest, "Video is not set uped correctly");

    return -1;
  }

  _frameAmount = frameAmount;

  _framePointer = new void*[frameAmount];

  if ((_buffer = vlCreateBuffer(_server, _path, _drain, _frameAmount)) == NULL) {
    setError();

    deleteBuffer();
    return -1;
  }

  if ((vlRegisterBuffer(_server, _path, _drain, _buffer)) < 0) {
    setError();

    deleteBuffer();
    return -1;
  }

  return 1;
}

short smpVideo::deleteBuffer()
{
  if (_framePointer > 0) {
    vlPutFree(_server, _buffer);
    delete[] _framePointer;
    _framePointer = NULL;
  }

  if (_transferRunning > 0) {
    vlEndTransfer(_server, _path);
    _transferRunning = 0;
  }

  if (_buffer > 0) {
    vlDeregisterBuffer(_server, _path, _drain, _buffer);
    if ((vlDestroyBuffer(_server, _buffer)) < 0) {
      setError();

      _buffer = NULL;
      return -1;
    }
    _buffer = NULL;    
  }

  return 1;
}

short smpVideo::beginTransfer()
{

  if (_buffer <= 0 || _path <= 0) {
    setError(VLBadRequest, "Video is not set uped correctly");

    return -1;
  }

  if (_transferRunning > 0) {
    setError(VLBadRequest, "Transfer is already running");

    return -1;
  }

  if ((vlBeginTransfer(_server, _path, 0, NULL)) < 0) {
    setError();

    return -1;
  }
  _transferRunning = 1;

  return 1;
}

short smpVideo::restartTransfer()
{
  if (_buffer <= 0 || _path <= 0) {
    setError(VLBadRequest, "Video is not set uped correctly");

    return -1;
  }

  if (_transferRunning > 0) {

    _transferRunning = 0;

    if ((vlEndTransfer(_server, _path)) < 0) {
      setError();
      return -1;
    }
  }

  _frameCounter = 0;

  if ((vlPutFree(_server, _buffer)) < 0) {
    setError();
    return -1;
  }

  return beginTransfer();
}

short smpVideo::getVideoSize(int *x, int *y)
{
  if (_server <= 0 || _path <= 0) {
    setError(VLBadRequest, "Video is not set uped correctly");

    return -1;
  }

  VLControlValue controlValue;
  if ((vlGetControl(_server, _path, _drain, VL_SIZE, &controlValue)) < 0) {
    setError();

    return -1;
  }
  *x = controlValue.xyVal.x;
  *y = controlValue.xyVal.y;

  return 1;
}

int smpVideo::checkTransferDone()
{
  int returnValue = vlBufferDone(_buffer);

  if (returnValue < 0) {
    setError();
  }

  return returnValue;
}

int smpVideo::waitTransferDone()
{
  VLInfoPtr infoPtr;


  if (_buffer <= 0 || _path <= 0) {
    setError(VLBadRequest, "Video is not set uped correctly");

    return -1;
  }

  while (_frameCounter < _frameAmount) {
    do {
      infoPtr = vlGetNextValid(_server, _buffer);
    } while (!infoPtr);

    if (infoPtr < 0) {
      setError();

      return -1;
    }

    if ((_framePointer[_frameCounter] = 
	 vlGetActiveRegion(_server, _buffer, infoPtr)) <= 0) {

      setError();

      return -1;
    }

    //printf("got %d ptr: 0x%lx\n",_frameCounter,_framePointer[_frameCounter]);

    _frameCounter++;
  }

  return _frameCounter;
}

int smpVideo::getFrameCounter()
{
  return _frameCounter;
}

void *smpVideo::getFramePointer(int number)
{
  //  printf("frameCounter: %d, request: %d, ptr: 0x%lx\n",_frameCounter,number,_framePointer[number-1]);

  if (number > 0 && number <= _frameCounter) {
    return _framePointer[number-1];
  }

  setError(VLBadRequest, "Bad frame index");
  return (void *)0;
}
