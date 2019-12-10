#ifndef IMSS_H
#define IMSS_H

extern i_img *
imss_win32(unsigned hwnd, int include_decor, int left, int top, int right, int bottom, int display);

extern i_img *
imss_x11(unsigned long display, int window_id, int left, int top, int right, int bottom, int direct);

extern unsigned long
imss_x11_open(char const *display_name);
extern void
imss_x11_close(unsigned long display);

extern i_img *
imss_darwin(i_img_dim left, i_img_dim top, i_img_dim right, i_img_dim bottom);

#endif
