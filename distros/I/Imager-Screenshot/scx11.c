#include "imext.h"
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include "imss.h"

static
int
my_handler(Display *display, XErrorEvent *error) {
  char buffer[500];

  XGetErrorText(display, error->error_code, buffer, sizeof(buffer));
  i_push_error(error->error_code, buffer);

  return 0;
}

i_img *
imss_x11(unsigned long display_ul, int window_id,
	 int left, int top, int right, int bottom, int direct) {
  Display *display = (Display *)display_ul;
  int own_display = 0; /* non-zero if we connect */
  XImage *image = NULL;
  XWindowAttributes attr;
  i_img *result;
  i_color *line, *cp;
  int x, y;
  XColor *colors;
  XErrorHandler old_handler;
  int width, height;
  int root_id;
  int screen;

  i_clear_error();

  /* we don't want the default noisy error handling */
  old_handler = XSetErrorHandler(my_handler);

  if (!display) {
    display = XOpenDisplay(NULL);
    ++own_display;
    if (!display) {
      i_push_error(0, "No display supplied and cannot connect");
      goto fail;
    }
  }

  screen = DefaultScreen(display);
  root_id = RootWindow(display, screen);
  if (!window_id) {
    window_id = root_id;
  }

  if (!XGetWindowAttributes(display, window_id, &attr)) {
    i_push_error(0, "Cannot XGetWindowAttributes");
    goto fail;
  }

  /* adjust negative/zero values to window size */
  if (left < 0)
    left += attr.width;
  if (top < 0)
    top += attr.height;
  if (right <= 0)
    right += attr.width;
  if (bottom <= 0)
    bottom += attr.height;

  mm_log((3, "window @(%d,%d) %dx%d\n", attr.x, attr.y, attr.width, attr.height));
  
  /* clamp */
  if (left < 0)
    left = 0;
  if (right > attr.width)
    right = attr.width;
  if (top < 0)
    top = 0;
  if (bottom > attr.height)
    bottom = attr.height;

  /* validate */
  if (right <= left || bottom <= top) {
    i_push_error(0, "image would be empty");
    goto fail;
  }
  width = right - left;
  height = bottom - top;
  if (direct) {
    /* try to get the pixels directly, this returns black images in
       some ill-determined cases, I suspect compositing.
    */
    image = XGetImage(display, window_id, left, top, width, height,
		      -1, ZPixmap);
  }
  else {
    int rootx = left, rooty = top;
    Window child_id; /* ignored */

    if (root_id != window_id) {
      XWindowAttributes root_attr;

      if (!XTranslateCoordinates(display, window_id, root_id, left, top,
				 &rootx, &rooty, &child_id)) {
	i_push_error(0, "could not translate co-ordinates");
	goto fail;
      }

      if (!XGetWindowAttributes(display, root_id, &root_attr)) {
	i_push_error(0, "Cannot XGetWindowAttributes for root");
	goto fail;
      }

      /* clip the window to the root, in case it's partly off the edge
	 of the root window
      */
      if (rootx < 0) {
	width += rootx;
	rootx = 0;
      }
      if (rootx + width > root_attr.width) {
	width = root_attr.width - rootx;
      }
      if (rooty < 0) {
	height += rooty;
	rooty = 0;
      }
      if (rooty + height > root_attr.height) {
	height = root_attr.height - rooty;
      }

      if (width == 0 || height == 0) {
	i_push_error(0, "window is completely clipped by the root window");
	goto fail;
      }
    }
    image = XGetImage(display, root_id, rootx, rooty,
		      width, height, -1, ZPixmap);
  }
  if (!image) {
    i_push_error(0, "Cannot XGetImage");
    goto fail;
  }

  result = i_img_8_new(width, height, 3);
  line = mymalloc(sizeof(i_color) * width);
  colors = mymalloc(sizeof(XColor) * width);
  for (y = 0; y < height; ++y) {
    cp = line;
    /* XQueryColors seems to be a round-trip, so do one big request
       instead of one per pixel */
    for (x = 0; x < width; ++x) {
      colors[x].pixel = XGetPixel(image, x, y);
    }
    XQueryColors(display, attr.colormap, colors, width);
    for (x = 0; x < width; ++x) {
      cp->rgb.r = colors[x].red >> 8;
      cp->rgb.g = colors[x].green >> 8;
      cp->rgb.b = colors[x].blue >> 8;
      ++cp;
    }
    i_plin(result, 0, width, y, line);
  }
  myfree(line);
  myfree(colors);
  XDestroyImage(image);

  XSetErrorHandler(old_handler);
  if (own_display)
    XCloseDisplay(display);

  i_tags_setn(&result->tags, "ss_window_width", attr.width);
  i_tags_setn(&result->tags, "ss_window_height", attr.height);
  i_tags_set(&result->tags, "ss_type", "X11", 3);
  i_tags_setn(&result->tags, "ss_left", left);
  i_tags_setn(&result->tags, "ss_top", top);

  return result;

 fail:
  if (image)
    XDestroyImage(image);

  XSetErrorHandler(old_handler);
  if (own_display)
    XCloseDisplay(display);
  return NULL;
}

unsigned long
imss_x11_open(char const *display_name) {
  XErrorHandler old_handler;
  Display *display;

  i_clear_error();
  old_handler = XSetErrorHandler(my_handler);
  display = XOpenDisplay(display_name);
  if (!display)
    i_push_errorf(0, "Cannot connect to X server %s", XDisplayName(display_name));
  
  XSetErrorHandler(old_handler);

  return (unsigned long)display;
}

void
imss_x11_close(unsigned long display) {
  XCloseDisplay((Display *)display);
}
