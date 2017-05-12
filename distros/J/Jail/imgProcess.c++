#include <string.h>

#include <il/ilAddImg.h>
#include <il/ilFileImg.h>
#include <il/ilGBlurImg.h>
#include <il/ilBlendImg.h>
#include <il/ilMemoryImg.h>
#include <il/ilSharpenImg.h>
#include <il/ilCompassImg.h>
#include <il/ilRotZoomImg.h>
#include <il/ilLaplaceImg.h>
#include <il/ilRobertsImg.h>

#include "imgProcess.h"
#include "smpVideo.h"

imgProcess::imgProcess()
{
  _client = 0;
  _image       = NULL;
  _imageFormat = NULL;
  _errno       = ilOKAY;
  _error[0]    = '\0';
}

imgProcess::imgProcess(int width, int height, short channels)
{
  iflSize size(width,height,channels);

  _image = new ilMemoryImg(size,iflUChar);
  _image->setOrientation(iflUpperLeftOrigin);
  switch (channels) {
  case 1:_image->setColorModel(iflRGBPalette);break;
  case 3:_image->setColorModel(iflRGB);break;
  case 4:_image->setColorModel(iflRGBA);break;
  default:delete _image;
    _image = NULL;
    setError((ilStatus)ilABORTED, "Channel count not allowed");    
  }

  _imageFormat = NULL;
  _errno       = ilOKAY;
  _error[0]    = '\0';
}

imgProcess::imgProcess(imgProcess *image)
{
  common_init(image->_image);
}


imgProcess::imgProcess(ilImage *image)
{
  common_init(image);
}

void
imgProcess::common_init(ilImage *image)
{
  _imageFormat = NULL;
  _errno       = ilOKAY;
  _error[0]    = '\0';

  if (image == NULL) {
    _image = NULL;
    setError((ilStatus)ilABORTED, "No imagedata");
    return;
  }

  iflSize size;
  iflOrder order = image->getOrder();
  iflDataType dataType = image->getDataType();
  image->getSize(size);

  ilMemoryImg *img = new ilMemoryImg(size,dataType,order);
  img->setOrientation(iflUpperLeftOrigin);

  img->copy(image);
  _image = img;

}

imgProcess::~imgProcess()
{
  if (_client) return ;//damn il bug, dont delete my shared arena
  if (_image > 0) {
    delete _image;
    _image = NULL;
  }  
  deleteQue();
}

void
imgProcess::deleteQue()
{
  while (_que.begin() != _que.end()) {
    ilImage *image = _que.back();

    delete image;

    _que.pop_back();
  }
}

void 
imgProcess::setError(ilStatus status)
{
  ilStatusToString(status, _error, ERRORSTR_LENGTH);
  _errno = status;
}

void 
imgProcess::setError(iflStatus status)
{
  setError(ilStatusFromIflStatus(status));
}

void 
imgProcess::setError(ilStatus status, const char *str)
{
  _errno = status;
  strncpy(_error, str, ERRORSTR_LENGTH);
}

void 
imgProcess::printError()
{
  printf("%s\n",getErrorString());
}

char *
imgProcess::getErrorString()
{
  static char str[2048];
  sprintf(str,"imgProcess: %.2007s (%d)",_error, _errno);
  return str;
}

ilStatus
imgProcess::getStatus()
{
  return _errno;
}

int 
imgProcess::getWidth()
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for getX");
    return -1;
  }
  return _image->getXsize();
}

int 
imgProcess::getHeight()
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for getY");
    return -1;
  }
  return _image->getYsize();
}

int 
imgProcess::getChannels()
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for getC");
    return -1;
  }
  return _image->getCsize();
}

const char *
imgProcess::getImageFormatName()
{
  return _imageFormat;
}

short 
imgProcess::load(int fd)
{
  return (load( fd, NULL));
}

short 
imgProcess::load(const char *filename)
{
  return (load( -1, filename));
}

short 
imgProcess::load(int fd, const char *filename)
{
  ilFileImg *file = new ilFileImg(fd, filename, O_RDONLY);

  if (file == NULL || file->getStatus() != ilOKAY) {
    setError(file->getStatus());
    delete file;
    return -1;
  }
  
  if (_image > 0) {
    delete _image;
  }
  deleteQue();

  _imageFormat = (char *)file->getImageFormatName();
  _image = file;

  return 1;
}

short 
imgProcess::save(int fd, const char *format)
{
  return (save(fd, NULL, format));
}

short 
imgProcess::save(const char *filename, const char *format)
{
  return (save( -1, filename, format));
}

short 
imgProcess::save(int fd, const char *filename, const char *format)
{
  ilStatus error;
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata to save");
    return -1;
  }

  iflFormat* ilformat = iflFormat::findByFormatName(format);
  if (! format) {
    setError((ilStatus)ilABORTED, "iflFormat not found");
    return -1;
  }
  
  // hurra, hurra, there is a il bug, can not save a jpg from a (A)BGR model
  if ((_image->getColorModel() == iflABGR ||
      _image->getColorModel() == iflBGR) &&
      !strcmp(format, "JFIF")) {

    ilImage *img = copyImg(_image, iflRGBA);

    if (img == NULL) {
      setError((ilStatus)ilABORTED, "cant copy img for JFIF bug");
      return -1;
    }
    //damn an other il bug, dont delete my shared arena
    if (!_client) {
      delete _image;
      deleteQue();
    }
    _image = img;
  }

  ilFileImg *file;

  if (_image->getColorModel() != iflRGBA &&
      _image->getColorModel() != iflRGB &&
      !strcmp(format, "TIFF")) {
    // TIFF standard color model should me RGB(A)
    iflColorModel clMdl;
    iflFileConfig *cfg = new iflFileConfig();

    switch (_image->getColorModel()) {
    case iflCMYK:
    case iflABGR:clMdl=iflRGBA;break;
    default:clMdl=iflRGB;
    }
    cfg->setColorModel(clMdl);
    file = new ilFileImg(fd, filename, _image, cfg, ilformat);
    delete cfg;
  } else {
    file = new ilFileImg(fd, filename, _image, NULL, ilformat);
  }

  if (file <= 0 || file->getStatus() != ilOKAY) {
    setError(file->getStatus());
    delete file;
    return -1;
  }

  file->copy(_image);
  //file->copyTileCfg(0,0,0, _image->getXsize(), _image->getYsize(), 1, _image, 0,0,0);

  if (file->getStatus() != ilOKAY) {
    setError(file->getStatus());
    delete file;
    return -1;
  }

  error = file->flush();
  if (error != iflOKAY) {
    setError(error);
    delete file;
    return -1;
  }

  //_imageFormat = (char *)file->getImageFormatName();
  delete file;

  return 1;
}

short 
imgProcess::copyTile(int destX, int destY, int width, int height, imgProcess *srcImage, int srcX, int srcY)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No dst imagedata to copy");
    return -1;
  }
  if (srcImage->_image <= 0) {
    setError((ilStatus)ilABORTED, "No src imagedata to copy");
    return -1;
  }

  ilStatus status =_image->copyTile(destX, destY, width, height, srcImage->_image, srcX, srcY, NULL);

  if (status != ilOKAY) {
    setError(status);
    return -1;
  }

  return 1;
}

short
imgProcess::setPixel(int x, int y, char r, char g, char b, char a)
{
  char map[4];
  int count;

  if (_image->isWritable() != TRUE) {
    ilImage *tmpImage = copyImg(_image, _image->getColorModel());

    if (tmpImage == NULL) {
      setError((ilStatus)ilABORTED, "Cant copy image, have to coz image is not writable");
      return -1;
    }
    delete _image;
    deleteQue();
    _image = tmpImage;
    _errno = ilOKAY;
  }

  if (_image->getColorModel() == iflRGB) {
    map[0] = r;
    map[1] = g;
    map[2] = b;
    count = 3;
  } else if (_image->getColorModel() == iflRGBA) {
    map[0] = r;
    map[1] = g;
    map[2] = b;
    map[3] = a;
    count = 4;
  } else if (_image->getColorModel() == iflBGR) {
    map[0] = b;
    map[1] = g;
    map[2] = r;
    count = 3;
  } else if (_image->getColorModel() == iflABGR) {
    map[0] = a;
    map[1] = b;
    map[2] = g;
    map[3] = r;
    count = 4;
  } else {
    // todo
    map[0] = r;
    map[1] = g;
    map[2] = b;
    //map[3] = a;
    count = 3;
    //puts("ELSE");
  }

  iflPixel pixel(iflChar, count, map);
  ilStatus status = _image->setPixel(x, y, pixel);
  if (status != ilOKAY) {
    setError(status);
    return -1;
  }
  return 1;
}

short 
imgProcess::getVideoSnapshot()
{

  char *dataPtr;
  int xsize, ysize;
  char errorString[ERRORSTR_LENGTH];
  smpVideo *vid = new smpVideo;

  if ((vid->openVideo()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((vid->setVideoInPath()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((vid->createBuffer(1)) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((vid->beginTransfer()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((vid->waitTransferDone()) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((vid->getVideoSize(&xsize, &ysize)) < 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  if ((dataPtr = (char *)vid->getFramePointer(1)) <= 0) {
    vid->getErrorStrFmt(errorString);
    setError((ilStatus)ilABORTED, errorString);
    delete vid;
    return -1;
  }

  iflSize imgSize(xsize, ysize, 1, 4);

  ilMemoryImg *tmpImage = new ilMemoryImg(NULL, imgSize, iflUChar);
  tmpImage->setColorModel(iflABGR);
  tmpImage->setOrientation(iflUpperLeftOrigin);

  if (tmpImage->getStatus() != ilOKAY) {
    setError(tmpImage->getStatus());
    delete tmpImage;
    delete vid;
    return -1;
  }

  tmpImage->setTile(0,0,xsize,ysize,dataPtr);

  if (_image > 0) {
    delete _image;
  }
  deleteQue();

  _image = tmpImage;
  _imageFormat = "RGB";

  delete vid;

  return 1;
}

short 
imgProcess::rotateZoom(float angle, float zoomX, float zoomY, unsigned short resampleType)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata to rotate/zoom");
    return -1;
  }

  ilRotZoomImg *rotateZoom = new ilRotZoomImg(_image, angle, zoomX, zoomY, (ilResampType)resampleType);

  if (rotateZoom->getStatus() != ilOKAY) {
    setError(rotateZoom->getStatus());
    delete rotateZoom;

    return -1;
  }

  _que.push_back(_image);
  _image = rotateZoom;

  return 1;
}

short 
imgProcess::blur(float blur, int width, int height, double biasValue, unsigned short edgeMode)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for blur");
    return -1;
  }

  ilGBlurImg *blurImg = new ilGBlurImg(_image, blur, width, height, 
				       biasValue, (ilEdgeMode)edgeMode);
  if (blurImg->getStatus() != ilOKAY) {
    setError(blurImg->getStatus());
    delete blurImg;

    return -1;
  }
  _que.push_back(_image);
  _image = blurImg;

  return 1;
}

short 
imgProcess::sharp(float sharpness, float radius, unsigned short edgeMode)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata to draw sharp");
    return -1;
  }

  ilSharpenImg *sharpImg = new ilSharpenImg(_image, sharpness, radius, 
					    (ilEdgeMode)edgeMode);
  if (sharpImg->getStatus() != ilOKAY) {
    setError(sharpImg->getStatus());
    delete sharpImg;

    return -1;
  }

  _que.push_back(_image);
  _image = sharpImg;

  return 1;
}

short 
imgProcess::compass(float radius, double biasVal, int kernSize, unsigned short edgeMode)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for compass");
    return -1;
  }

  ilCompassImg *compassImg = new ilCompassImg(_image, radius, 
					      biasVal, kernSize, (ilEdgeMode)edgeMode);
  if (compassImg->getStatus() != ilOKAY) {
    setError(compassImg->getStatus());
    delete compassImg;

    return -1;
  }

  _que.push_back(_image);
  _image = compassImg;

  return 1;
}

short 
imgProcess::laplace(double biasVal, unsigned short edgeMode, int kernSize)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for laplace");
    return -1;
  }

  ilLaplaceImg *laplaceImg = new ilLaplaceImg(_image,
					      biasVal, (ilEdgeMode)edgeMode, kernSize);
  if (laplaceImg->getStatus() != ilOKAY) {
    setError(laplaceImg->getStatus());
    delete laplaceImg;

    return -1;
  }

  _que.push_back(_image);
  _image = laplaceImg;

  return 1;
}

short 
imgProcess::edgeDetection(double biasVal, unsigned short edgeMode)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No imagedata for edge detection");
    return -1;
  }

  ilRobertsImg *edgeDetectionImg = new ilRobertsImg(_image,
					      biasVal, (ilEdgeMode)edgeMode);
  if (edgeDetectionImg->getStatus() != ilOKAY) {
    setError(edgeDetectionImg->getStatus());
    delete edgeDetectionImg;

    return -1;
  }

  _que.push_back(_image);
  _image = edgeDetectionImg;

  return 1;
}

short 
imgProcess::blendImg(imgProcess *dstimg, float alpha)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No src imagedata for blending images");
    return -1;
  }

  if (dstimg->_image <= 0) {
    setError((ilStatus)ilABORTED, "No dst imagedata for blending images");
    return -1;
  }
  ilBlendImg *blendImg = new ilBlendImg(_image, dstimg->_image, alpha);

  if (blendImg->getStatus() != ilOKAY) {
    setError(blendImg->getStatus());
    delete blendImg;

    return -1;
  }

  _que.push_back(_image);
  _image = blendImg;
  
  return 1;
}

short 
imgProcess::blendImg(imgProcess *image, imgProcess *alphaimg, ilCompose compose)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No src imagedata for blending images");
    return -1;
  }

  if (image->_image <= 0) {
    setError((ilStatus)ilABORTED, "No dst imagedata for blending images");
    return -1;
  }

  if (alphaimg->_image <= 0) {
    setError((ilStatus)ilABORTED, "No dst imagedata for blending images");
    return -1;
  }

  ilImage *useAlpha = alphaimg->_image;

  // convert an image with only one channel to a 4 channel image
  if (alphaimg->_image->getCsize() == 1) {

    ilImage *tmpImage = copyImg(alphaimg->_image);
    if (tmpImage == NULL) {
      return -1;
    }
    // remember the img
    useAlpha = tmpImage;
    _que.push_back(tmpImage);
  }

  ilBlendImg *blendImg = new ilBlendImg(_image, image->_image, useAlpha, NULL, compose);

  if (blendImg->getStatus() != ilOKAY) {
    setError(blendImg->getStatus());
    delete blendImg;
    delete _que.back();
    _que.pop_back();
    return -1;
  }

  _que.push_back(_image);
  _image = blendImg;
  
  return 1;
}

short 
imgProcess::add(imgProcess *addImg, double bias)
{
  if (_image <= 0) {
    setError((ilStatus)ilABORTED, "No src imagedata for adding images");
    return -1;
  }

  if (addImg->_image <= 0) {
    setError((ilStatus)ilABORTED, "No addImg imagedata for adding images");
    return -1;
  }

  ilImage *addImgCopy = copyImg(addImg->_image, addImg->_image->getColorModel());
  if (addImgCopy == NULL) {
    return -1;
  }

  ilAddImg *addi = new ilAddImg(_image, addImgCopy, bias);
				
  if (addi->getStatus() != ilOKAY) {
    setError(addi->getStatus());
    delete addi;
    delete addImgCopy;

    return -1;
  }

  _que.push_back(_image);
  _que.push_back(addImgCopy);
  _image = addi;

  return 1;  
}

ilImage *
imgProcess::copyImg(ilImage *src, iflColorModel colorModel)
{
  int channels;
  switch (colorModel) {
  case iflCMYK:
  case iflRGBA:
  case iflABGR:channels=4;break;
  case iflRGBPalette:
    // damn an other bug, cant copy a RGBPalette pic
    //channels=1;
    channels=3;
    colorModel=iflRGB;
    break;
  case iflRGB:
  case iflBGR:channels=3;break;
  default:channels=3;puts("WARNING: unsupported color model\n");
  }

  iflSize imgSize(src->getXsize(), src->getYsize(), 1, channels);

  ilMemoryImg *tmpImage = new ilMemoryImg(imgSize, src->getDataType(),
					  src->getOrder());
  tmpImage->setOrientation(iflUpperLeftOrigin);
  if (tmpImage->setColorModel(colorModel) != iflOKAY) {
    puts("aaaaaargh cant set color model");
    delete tmpImage;
    return NULL;
  }
  if (tmpImage->getStatus() != ilOKAY) {
    //setError(tmpImage->getStatus());
    delete tmpImage;
    return NULL;
  }
  if (src->getColorModel() == iflRGBPalette &&
      colorModel == iflRGBPalette)
    tmpImage->setColormap(*(src->getColormap()));

  if (tmpImage->getStatus() != ilOKAY) {
    //setError(tmpImage->getStatus());
    delete tmpImage;
    return NULL;
  }

  tmpImage->copy(src);
  if (tmpImage->getStatus() != ilOKAY) {
    //setError(tmpImage->getStatus());
    delete tmpImage;
    return NULL;
  }

  return tmpImage;
}

void imgProcess::setClient(short st)
{
  _client = st;
}
