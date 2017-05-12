#include "imext.h"
#include <windows.h>
#include <string.h>
#include "imss.h"

/* the SDK headers supplied with cygwin, and with some older strawberry perls */
#ifndef DISPLAY_DEVICE_ACTIVE
#define DISPLAY_DEVICE_ACTIVE 1
#endif

static void
i_push_win32_errorf(DWORD msg_id, char const *fmt, ...) {
  va_list args;
  LPSTR msg;
  char buf[1000];

  va_start(args, fmt);
  vsprintf(buf, fmt, args);
  if (FormatMessage(FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM,
		    NULL,
		    msg_id,
		    0, /* LANGID */
		    (LPSTR)&msg,
		    0,
		    NULL)) {
    strcat(buf, msg);
    LocalFree(msg);
  }
  else {
    sprintf(buf+strlen(buf), "%#010x", msg_id);
  }
  i_push_error(msg_id, buf);
  va_end(args);
}

struct monitor_ctx {
  i_img *out;
  i_img_dim orig_x, orig_y;
  int good;
};

static int
display_to_img(HDC dc, i_img *im, const RECT *src, int dest_x, int dest_y) {
  HBITMAP work_bmp;
  HDC bmdc;
  HBITMAP old_dc_bmp;
  i_img_dim width = src->right - src->left;
  i_img_dim height = src->bottom - src->top;
  int result = 0;
  BITMAPINFO bmi;
  unsigned char *di_bits;

  work_bmp = CreateCompatibleBitmap(dc, width, height);
  bmdc = CreateCompatibleDC(dc);
  old_dc_bmp = SelectObject(bmdc, work_bmp);
  BitBlt(bmdc, 0, 0, width, height, dc, src->left, src->top, SRCCOPY);

  /* make a dib */
  memset(&bmi, 0, sizeof(bmi));
  bmi.bmiHeader.biSize = sizeof(bmi);
  bmi.bmiHeader.biWidth = width;
  bmi.bmiHeader.biHeight = -height;
  bmi.bmiHeader.biPlanes = 1;
  bmi.bmiHeader.biBitCount = 32;
  bmi.bmiHeader.biCompression = BI_RGB;

  di_bits = mymalloc(4 * width * height);
  if (GetDIBits(bmdc, work_bmp, 0, height, di_bits, &bmi, DIB_RGB_COLORS)) {
    i_color *line = mymalloc(sizeof(i_color) * width);
    i_color *cp;
    int x, y;
    unsigned char *ch_pp = di_bits;
    for (y = 0; y < height; ++y) {
      cp = line;
      for (x = 0; x < width; ++x) {
	cp->rgba.b = *ch_pp++;
	cp->rgba.g = *ch_pp++;
	cp->rgba.r = *ch_pp++;
	cp->rgba.a = 255;
	ch_pp++;
	cp++;
      }
      i_plin(im, dest_x, dest_x+width, dest_y + y, line);
    }
    myfree(line);
    result = 1;
  }
  else {
    i_push_win32_errorf(GetLastError(), "GetDIBits() failure: ");
  }

  myfree(di_bits);
  SelectObject(bmdc, old_dc_bmp);
  DeleteDC(bmdc);
  DeleteObject(work_bmp);

  return result;
}

static BOOL CALLBACK
monitor_enum(HMONITOR hmon, HDC dc, LPRECT r, LPARAM lp_ctx) {
  struct monitor_ctx *ctx = (struct monitor_ctx *)lp_ctx;

  if (!display_to_img(dc, ctx->out, r,
		      r->left - ctx->orig_x, r->top - ctx->orig_y)) {
    ctx->good = 0;
  }

  return ctx->good;
}

i_img *
imss_win32(unsigned hwnd_u, int include_decor, int left, int top, 
	   int right, int bottom, int display) {
  HWND hwnd = (HWND)hwnd_u;
  HDC cdc = 0, wdc;
  int orig_x = 0;
  int orig_y = 0;
  int window_width, window_height;
  i_img *result = NULL;
  int width, height;
  int channels = 3;

  i_clear_error();

  if (hwnd) {
    RECT rect;
    if (include_decor) {
      wdc = GetWindowDC(hwnd);
      GetWindowRect(hwnd, &rect);
    }
    else {
      wdc = GetDC(hwnd);
      GetClientRect(hwnd, &rect);
    }
    if (!wdc) {
      i_push_error(0, "Cannot get window DC - invalid hwnd?");
      return NULL;
    }

    window_width = rect.right - rect.left;
    window_height = rect.bottom - rect.top;
  }
  else {
    if (display == -1) {
      cdc = CreateDC("DISPLAY", NULL, NULL, NULL);
      orig_x = GetSystemMetrics(SM_XVIRTUALSCREEN);
      orig_y = GetSystemMetrics(SM_YVIRTUALSCREEN);
      window_width = GetSystemMetrics(SM_CXVIRTUALSCREEN);
      window_height = GetSystemMetrics(SM_CYVIRTUALSCREEN);
      channels = 4;
    }
    else {
      DISPLAY_DEVICE dd;
      int work_display = 0;
      int primary_display = -1;
      int real_display = -1;

      dd.cb = sizeof(dd);
      /* look for the primary display, we need a simulate a gap to put the
	 primary at 0 */
      while (work_display < 100
	     && EnumDisplayDevices(NULL, work_display, &dd, 0)) {
	if (dd.StateFlags & DISPLAY_DEVICE_PRIMARY_DEVICE) {
	  primary_display = work_display;
	  break;
	}
	else if (display && display-1 == work_display) {
	  real_display = work_display;
	  break;
	}
	
	dd.cb = sizeof(dd);
	++work_display;
      }

      if (!work_display && real_display == -1 && primary_display == -1) {
	/* EnumDisplayDevices() failed for the first call */
	i_push_win32_errorf(GetLastError(), "Cannot enumerate device %d(0): ", work_display);
	return NULL;
      }

      if (primary_display != -1 && display == 0) {
	real_display = primary_display;
      }
      
      if (real_display == -1) {
	/* haven't enumerated the display we want yet */
	/* we're after the primary */
	real_display = display;
	dd.cb = sizeof(dd);
	if (!EnumDisplayDevices(NULL, real_display, &dd, 0)) {
	  i_push_win32_errorf(GetLastError(), "Cannot enumerate device %d(%d): ",
			real_display, display);
	  return NULL;
	}
      }

      if (!(dd.StateFlags & DISPLAY_DEVICE_ACTIVE)) {
	i_push_errorf(0, "Display device %d not active", display);
	return NULL;
      }
      cdc = CreateDC(dd.DeviceName, dd.DeviceName, NULL, NULL);
      if (!cdc) {
	i_push_win32_errorf(GetLastError(), "Cannot CreateDC(%s): ", dd.DeviceName);
	return NULL;
      }

      window_width = GetDeviceCaps(cdc, HORZRES);
      window_height = GetDeviceCaps(cdc, VERTRES);
    }

    wdc = cdc;
  }

  /* adjust negative/zero values to window size */
  if (left < 0)
    left += window_width;
  if (top < 0)
    top += window_height;
  if (right <= 0)
    right += window_width;
  if (bottom <= 0)
    bottom += window_height;
  
  /* clamp */
  if (left < 0)
    left = 0;
  if (right > window_width)
    right = window_width;
  if (top < 0)
    top = 0;
  if (bottom > window_height)
    bottom = window_height;

  /* validate */
  if (right <= left || bottom <= top) {
    i_push_error(0, "image would be empty");
    if (cdc)
      DeleteDC(cdc);
    else
      ReleaseDC(hwnd, wdc);
    return NULL;
  }
  width = right - left;
  height = bottom - top;
  
  result = i_img_8_new(width, height, channels);
  
  if (result) {
    RECT r;
    r.left = orig_x + left;
    r.top = orig_y + top;
    r.right = r.left + width;
    r.bottom = r.top + height;
    
    if (display == -1) {
      struct monitor_ctx ctx;
      ctx.out = result;
      ctx.orig_x = orig_x;
      ctx.orig_y = orig_y;
      ctx.good = 1;

      if (!EnumDisplayMonitors(wdc, &r, monitor_enum, (LPARAM)&ctx)
	  || !ctx.good) {
	i_img_destroy(result);
	result = NULL;
      }
    }
    else {
      if (!display_to_img(wdc, result, &r, 0, 0)) {
	i_img_destroy(result);
	result = NULL;
      }
    }
    if (result) {
      i_tags_setn(&result->tags, "ss_window_width", window_width);
      i_tags_setn(&result->tags, "ss_window_height", window_height);
      i_tags_set(&result->tags, "ss_type", "Win32", 5);
      i_tags_setn(&result->tags, "ss_left", left);
      i_tags_setn(&result->tags, "ss_top", top);
    }
  }
  /* clean up */
  if (cdc) {
    DeleteDC(cdc);
  }
  else {
    ReleaseDC(hwnd, wdc);
  }

  return result;
}
