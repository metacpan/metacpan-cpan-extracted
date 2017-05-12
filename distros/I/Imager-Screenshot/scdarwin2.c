/* Darwin support via Quartz Display Services */
#include "imext.h"
#include "imss.h"
#include <ApplicationServices/ApplicationServices.h>

/* Largely based on:

http://stackoverflow.com/questions/448125/how-to-get-pixel-data-from-a-uiimage-cocoa-touch-or-cgimage-core-graphics

*/

i_img *
imss_darwin(i_img_dim left, i_img_dim top, i_img_dim right, i_img_dim bottom) {
  i_clear_error();
  CGDirectDisplayID disp = CGMainDisplayID();
  if (!disp) {
    i_push_error(0, "No main display");
    return NULL;
  }
  
  /* for now, only interested in the first display */
  CGRect rect = CGDisplayBounds(disp);
  i_img_dim screen_width = rect.size.width;
  i_img_dim screen_height = rect.size.height;

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

  i_img_dim width = right - left;
  i_img_dim height = bottom - top;

  CGRect cap_rect;
  cap_rect.origin.x = left;
  cap_rect.origin.y = top; /* flipped relative to I::S API */
  cap_rect.size.width = width;
  cap_rect.size.height = height;

  CGImageRef image = CGDisplayCreateImageForRect(disp, cap_rect);
  if (!image) {
    i_push_error(0, "CGDisplayCreateImageForRect failed");
    return NULL;
  }

  int channels = CGImageGetAlphaInfo(image) == kCGImageAlphaNone ? 3 : 4;
  i_img *result = i_img_8_new(width, height, channels);
  if (!result) {
    CGImageRelease(image);
    return NULL;
  }

  /* bytes per row - round up to the closest 16 byte boundary */
  size_t bytes_per_row = channels * width;
  bytes_per_row = (bytes_per_row + 15) & ~15U;
  
  unsigned char *data = mymalloc(bytes_per_row * height);
  CGColorSpaceRef color_space = CGColorSpaceCreateDeviceRGB();

  CGContextRef context = CGBitmapContextCreate
    (data, width, height, 8, bytes_per_row, color_space,
     kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(color_space);

  CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
  CGContextRelease(context);

  CGImageRelease(image);

  const unsigned char *p = data;
  i_img_dim y;
  for (y = 0; y < height; ++y) {
    i_psamp(result, 0, width, y, p, NULL, channels);

    p += bytes_per_row;
  }

  i_tags_setn(&result->tags, "ss_window_width", width);
  i_tags_setn(&result->tags, "ss_window_height", height);
  i_tags_set(&result->tags, "ss_type", "Darwin", 6);
  i_tags_set(&result->tags, "ss_variant", "11+", 3);
  i_tags_setn(&result->tags, "ss_left", left);
  i_tags_setn(&result->tags, "ss_top", top);

  return result;
}
