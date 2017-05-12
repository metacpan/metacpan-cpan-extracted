/* Darwin support via OpenGL */
#include "imext.h"
#include "imss.h"
#include <ApplicationServices/ApplicationServices.h>
#include "OpenGL/OpenGL.h"
#include "OpenGL/gl.h"
#include "OpenGL/glu.h"
#include "OpenGL/glext.h"

i_img *
imss_darwin(i_img_dim left, i_img_dim top, i_img_dim right, i_img_dim bottom) {
  CGDisplayCount count;
  CGDisplayErr err;
  CGRect rect;
  CGLPixelFormatObj pix;
  GLint npix;
  CGLContextObj ctx;
  i_img *im;
  CGDirectDisplayID disp;
  i_img_dim screen_width, screen_height;
  i_img_dim width, height;

  CGLPixelFormatAttribute pix_attrs[] =
    {
      kCGLPFADisplayMask, 0, /* filled in later */
      kCGLPFAColorSize, 24,
      kCGLPFAAlphaSize, 0,
      kCGLPFAFullScreen,
      0
    };

  i_clear_error();

  disp = CGMainDisplayID();
  if (!disp) {
    i_push_error(0, "No main display");
    return NULL;
  }
  
  /* for now, only interested in the first display */
  rect = CGDisplayBounds(disp);
  screen_width = rect.size.width;
  screen_height = rect.size.height;

  /* adjust negative/zero values to window size */
  if (left < 0)
    left += screen_width;
  if (top < 0)
    top += screen_height;
  if (right <= 0)
    right += screen_width;
  if (bottom <= 0)
    bottom += screen_height;
  
  /* clamp */
  if (left < 0)
    left = 0;
  if (right > screen_width)
    right = screen_width;
  if (top < 0)
    top = 0;
  if (bottom > screen_height)
    bottom = screen_height;

  /* validate */
  if (right <= left || bottom <= top) {
    i_push_error(0, "image would be empty");
    return NULL;
  }

  width = right - left;
  height = bottom - top;

  /* select a pixel format */
  pix_attrs[1] = CGDisplayIDToOpenGLDisplayMask(disp);
  err = CGLChoosePixelFormat(pix_attrs, &pix, &npix);
  if (err) {
    i_push_errorf(err, "CGLChoosePixelFormat: %d", (int)err);
    return NULL;
  }
  if (!npix) {
    i_push_error(0, "No pixel format found - hidden display?");
    return NULL;
  }

  /* make ourselves a context */
  err = CGLCreateContext(pix, NULL, &ctx);
  CGLDestroyPixelFormat(pix);
  if (err) {
    i_push_errorf(err, "CGLCreateContext: %d", (int)err);
    return NULL;
  }

  err = CGLSetCurrentContext(ctx);
  if (err) {
    i_push_errorf(err, "CGLSetCurrentContext: %d", (int)err);
    return NULL;
  }

  err = CGLSetFullScreen(ctx);
  if (err) {
    i_push_errorf(err, "CGLSetFullScreen: %d", (int)err);
    return NULL;
  }

  /* capture */
  im = i_img_8_new(width, height, 3);
  if (im) {
    size_t line_size = width * 4; 
    size_t buf_size = line_size * height;
    unsigned char *buf = malloc(buf_size);
    i_img_dim y = height - 1;
    i_color *bufp = (i_color *)buf; /* hackish */

    /* GL has the vertical axis going from bottom to top, so translate it */

    glReadBuffer(GL_FRONT);
    glReadPixels(left, screen_height - top - height, width, height,
		 GL_RGBA, GL_UNSIGNED_BYTE, buf);

    /* transfer */
    while (y >= 0) {
      i_plin(im, 0, width, y, bufp);
      bufp += width;
      --y;
    }
    
    free(buf);

    i_tags_setn(&im->tags, "ss_window_width", width);
    i_tags_setn(&im->tags, "ss_window_height", height);
    i_tags_set(&im->tags, "ss_type", "Darwin", 6);
    i_tags_set(&im->tags, "ss_variant", "<11", 3);
    i_tags_setn(&im->tags, "ss_left", left);
    i_tags_setn(&im->tags, "ss_top", top);
  }

  /* clean up */
  CGLSetCurrentContext(NULL);
  CGLDestroyContext(ctx);

  return im;
}
