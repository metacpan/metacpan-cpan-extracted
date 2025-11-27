/* Copyright 2018-## YEAR ## Richard Kelsch, All Rights Reserved
   See the Perl documentation for Graphics::Framebuffer for licensing information.

   Version:  ## VERSION ##

   You may wonder why the stack is so heavily used when the global structures
   have the needed values.  Well, the module can emulate another graphics mode
   that may not be the one being displayed.  This means using the two structures
   would break functionality.  Therefore, the data from Perl is passed along.

   8 bit and 1 bit modes are not yet supported and their case values just
   placeholders.

   I am NOT a C programmer and this code likely proves that, but this code works
   and that's good enough for me.
*/

#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <linux/fb.h>
#include <linux/kd.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <math.h>
#include <string.h> /* for memcpy */
#include <stdint.h> /* added for fixed width integer types */

#define NORMAL_MODE   0
#define XOR_MODE      1
#define OR_MODE       2
#define AND_MODE      3
#define MASK_MODE     4
#define UNMASK_MODE   5
#define ALPHA_MODE    6
#define ADD_MODE      7
#define SUBTRACT_MODE 8
#define MULTIPLY_MODE 9
#define DIVIDE_MODE   10

#define RGB           0
#define RBG           1
#define BGR           2
#define BRG           3
#define GBR           4
#define GRB           5

#define integer_(X)  ((int)(X))
#define round_(X)    ((int)(((double)(X))+0.5))
#define decimal_(X)  (((double)(X))-(double)integer_(X))
#define rdecimal_(X) (1.0-decimal_(X))
#define swap_(a, b)  do { __typeof__(a) tmp;  tmp = a; a = b; b = tmp; } while(0)

/* Global Structures */
struct fb_var_screeninfo vinfo;
struct fb_fix_screeninfo finfo;

// This gets the framebuffer info and populates the above structures, then sends them to Perl
void c_get_screen_info(char *fb_file) {
    int fbfd = open(fb_file,O_RDWR);
        ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo); // Get the physical information
        ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo); // Get the virtual console information
        close(fbfd);

        // This monstrosity pushes the needed values on Perl's stack, like "return" does.

        Inline_Stack_Vars;
        Inline_Stack_Reset;

        Inline_Stack_Push(sv_2mortal(newSVpvn(finfo.id,16)));
        Inline_Stack_Push(sv_2mortal(newSVnv(finfo.smem_start)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.smem_len)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.type)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.type_aux)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.visual)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.xpanstep)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.ypanstep)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.ywrapstep)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.line_length)));
        Inline_Stack_Push(sv_2mortal(newSVnv(finfo.mmio_start)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.mmio_len)));
        Inline_Stack_Push(sv_2mortal(newSVuv(finfo.accel)));

        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.xres)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.yres)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.xres_virtual)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.yres_virtual)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.xoffset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.yoffset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.bits_per_pixel)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.grayscale)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.red.offset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.red.length)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.red.msb_right)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.green.offset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.green.length)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.green.msb_right)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.blue.offset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.blue.length)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.blue.msb_right)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.transp.offset)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.transp.length)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.transp.msb_right)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.nonstd)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.activate)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.height)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.accel_flags)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.pixclock)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.left_margin)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.right_margin)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.upper_margin)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.lower_margin)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.hsync_len)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.vsync_len)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.sync)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.vmode)));
        Inline_Stack_Push(sv_2mortal(newSVnv(vinfo.rotate)));

        Inline_Stack_Done;
        // Phew!
}

// Sets the framebuffer to text mode, which enables the cursor
void c_text_mode(char *tty_file) 
{
   int tty_fd = open(tty_file,O_RDWR);
   ioctl(tty_fd,KDSETMODE,KD_TEXT);
   close(tty_fd);
}

// Sets the framebuffer to graphics mode, which disables the cursor
void c_graphics_mode(char *tty_file) 
{
   int tty_fd = open(tty_file,O_RDWR);
   ioctl(tty_fd,KDSETMODE,KD_GRAPHICS);
   close(tty_fd);
}

/* The other routines call this.  It handles all draw modes
 * 
 * Normally I would add code to properly place the RGB values according to
 * color order, but in reality, that can be done solely when the color value
 * itself is defined, so the colors are in the correct order before even
 * arriving at this routine.
*/
void c_plot(
    char *framebuffer,
    short x, short y,
    short x_clip, short y_clip, short xx_clip, short yy_clip,
    unsigned int color,
    unsigned int bcolor,
    unsigned char alpha,
    unsigned char draw_mode,
    unsigned char bytes_per_pixel,
    unsigned char bits_per_pixel,
    unsigned int bytes_per_line,
    short xoffset, short yoffset)
{
    if (!(x >= x_clip && x <= xx_clip && y >= y_clip && y <= yy_clip)) {
        return; // outside clip
    }

    x = x + xoffset;
    y = y + yoffset;

    unsigned int index = ((unsigned int)x * (unsigned int)bytes_per_pixel) + ((unsigned int)y * bytes_per_line);
    unsigned char *p = (unsigned char*)(framebuffer + index);

    switch (bits_per_pixel) {
        case 32: {
            uint32_t fb = *((uint32_t*)p);
            uint32_t col = (uint32_t)color;
            uint32_t bcol = (uint32_t)bcolor;
            uint32_t res = fb;
            switch (draw_mode) {
                case NORMAL_MODE:  res = col; break;
                case XOR_MODE:     res = fb ^ col; break;
                case OR_MODE:      res = fb | col; break;
                case AND_MODE:     res = fb & col; break;
                case MASK_MODE:    if ((fb & 0xFFFFFF00) != (bcol & 0xFFFFFF00)) res = col; break;
                case UNMASK_MODE:  if ((fb & 0xFFFFFF00) == (bcol & 0xFFFFFF00)) res = col; break;
                case ALPHA_MODE: {
                    unsigned char fb_r = fb & 0xFF;
                    unsigned char fb_g = (fb >> 8) & 0xFF;
                    unsigned char fb_b = (fb >> 16) & 0xFF;
                    unsigned char R = col & 0xFF;
                    unsigned char G = (col >> 8) & 0xFF;
                    unsigned char B = (col >> 16) & 0xFF;
                    unsigned char A = (col >> 24) & 0xFF;
                    unsigned char invA = 255 - A;
                    fb_r = ((R * A) + (fb_r * invA)) >> 8;
                    fb_g = ((G * A) + (fb_g * invA)) >> 8;
                    fb_b = ((B * A) + (fb_b * invA)) >> 8;
                    res = fb_r | (fb_g << 8) | (fb_b << 16) | (A << 24);
                } break;
                case ADD_MODE:      res = fb + col; break;
                case SUBTRACT_MODE: res = fb - col; break;
                case MULTIPLY_MODE: res = fb * col; break;
                case DIVIDE_MODE:   if (col != 0) res = fb / col; break;
                default: break;
            }
            *((uint32_t*)p) = res;
            break;
        }
        case 24: {
            /* pack 3 bytes into a 32-bit local (low 24 bits used) */
            uint32_t fb = (uint32_t)p[0] | ((uint32_t)p[1] << 8) | ((uint32_t)p[2] << 16);
            uint32_t col = color & 0x00FFFFFF;
            uint32_t bcol = bcolor & 0x00FFFFFF;
            uint32_t res = fb;
            switch (draw_mode) {
                case NORMAL_MODE:  res = col; break;
                case XOR_MODE:     res = fb ^ col; break;
                case OR_MODE:      res = fb | col; break;
                case AND_MODE:     res = fb & col; break;
                case MASK_MODE:    if ((fb & 0xFFFFFF00) != (bcol & 0xFFFFFF00)) res = col; break;
                case UNMASK_MODE:  if ((fb & 0xFFFFFF00) == (bcol & 0xFFFFFF00)) res = col; break;
                case ALPHA_MODE: {
                    unsigned char fb_r = fb & 0xFF;
                    unsigned char fb_g = (fb >> 8) & 0xFF;
                    unsigned char fb_b = (fb >> 16) & 0xFF;
                    unsigned char R = col & 0xFF;
                    unsigned char G = (col >> 8) & 0xFF;
                    unsigned char B = (col >> 16) & 0xFF;
                    unsigned char invA = 255 - alpha;
                    fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                    fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                    fb_b = ((B * alpha) + (fb_b * invA)) >> 8;
                    res = (uint32_t)fb_r | ((uint32_t)fb_g << 8) | ((uint32_t)fb_b << 16);
                } break;
                case ADD_MODE:      res = fb + col; break;
                case SUBTRACT_MODE: res = fb - col; break;
                case MULTIPLY_MODE: res = fb * col; break;
                case DIVIDE_MODE:   {
                    uint32_t c0 = col & 0xFF, c1 = (col >> 8) & 0xFF, c2 = (col >> 16) & 0xFF;
                    uint32_t r0 = (c0 != 0) ? ((fb & 0xFF) / c0) : (fb & 0xFF);
                    uint32_t r1 = (c1 != 0) ? (((fb >> 8) & 0xFF) / c1) : ((fb >> 8) & 0xFF);
                    uint32_t r2 = (c2 != 0) ? (((fb >> 16) & 0xFF) / c2) : ((fb >> 16) & 0xFF);
                    res = r0 | (r1 << 8) | (r2 << 16);
                } break;
                default: break;
            }
            p[0] = res & 0xFF;
            p[1] = (res >> 8) & 0xFF;
            p[2] = (res >> 16) & 0xFF;
            break;
        }
        case 16: {
            uint16_t fb = *((uint16_t*)p);
            uint16_t col16 = (uint16_t)color;
            uint16_t res16 = fb;
            switch (draw_mode) {
                case NORMAL_MODE:  res16 = col16; break;
                case XOR_MODE:     res16 = fb ^ col16; break;
                case OR_MODE:      res16 = fb | col16; break;
                case AND_MODE:     res16 = fb & col16; break;
                case MASK_MODE:    if (fb != (bcolor & 0xFFFF)) res16 = col16; break;
                case UNMASK_MODE:  if (fb == (bcolor & 0xFFFF)) res16 = col16; break;
                case ALPHA_MODE: {
                    unsigned short rgb565 = fb;
                    unsigned short fb_r = rgb565 & 31;
                    unsigned short fb_g = (rgb565 >> 5) & 63;
                    unsigned short fb_b = (rgb565 >> 11) & 31;
                    unsigned short R = col16 & 31;
                    unsigned short G = (col16 >> 5) & 63;
                    unsigned short B = (col16 >> 11) & 31;
                    unsigned char invA = 255 - alpha;
                    fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                    fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                    fb_b = ((B * alpha) + (fb_b * invA)) >> 8;
                    res16 = (fb_b << 11) | (fb_g << 5) | fb_r;
                } break;
                case ADD_MODE:      res16 = fb + col16; break;
                case SUBTRACT_MODE: res16 = fb - col16; break;
                case MULTIPLY_MODE: res16 = fb * col16; break;
                case DIVIDE_MODE:   if (col16 != 0) res16 = fb / col16; break;
                default: break;
            }
            *((uint16_t*)p) = res16;
            break;
        }
        case 8: {
            uint8_t fb = *p;
            uint8_t col8 = (uint8_t)color;
            uint8_t res8 = fb;
            switch (draw_mode) {
                case NORMAL_MODE:  res8 = col8; break;
                case XOR_MODE:     res8 = fb ^ col8; break;
                case OR_MODE:      res8 = fb | col8; break;
                case AND_MODE:     res8 = fb & col8; break;
                case MASK_MODE:    if (fb != (bcolor & 0xFF)) res8 = col8; break;
                case UNMASK_MODE:  if (fb == (bcolor & 0xFF)) res8 = col8; break;
                case ALPHA_MODE: {
                    uint8_t invA = 255 - alpha;
                    res8 = (uint8_t)((((uint32_t)col8 * alpha) + ((uint32_t)fb * invA)) >> 8);
                } break;
                case ADD_MODE:      res8 = fb + col8; break;
                case SUBTRACT_MODE: res8 = fb - col8; break;
                case MULTIPLY_MODE: res8 = fb * col8; break;
                case DIVIDE_MODE:   if (col8 != 0) res8 = fb / col8; break;
                default: break;
            }
            *p = res8;
            break;
        }
        case 1: {
            /* Not supported yet; no-op */
            break;
        }
        default:
            break;
    }
}

// Draws a line
void c_line(
    char *framebuffer,
    short x1, short y1, short x2, short y2,
    short x_clip, short y_clip, short xx_clip, short yy_clip,
    unsigned int color,
    unsigned int bcolor,
    unsigned char alpha,
    unsigned char draw_mode,
    unsigned char bytes_per_pixel,
    unsigned char bits_per_pixel,
    unsigned int bytes_per_line,
    short xoffset, short yoffset)
{
    short shortLen = y2 - y1;
    short longLen  = x2 - x1;
    int yLonger    = false;

    if (abs(shortLen) > abs(longLen)) {
        short swap = shortLen;
        shortLen   = longLen;
        longLen    = swap;
        yLonger    = true;
    }
    int decInc;
    if (longLen == 0) {
        decInc = 0;
    } else {
        decInc = (shortLen << 16) / longLen;
    }
    int count;
    if (yLonger) {
        if (longLen > 0) {
            longLen += y1;
            for (count = 0x8000 + (x1 << 16); y1 <= longLen; ++y1) {
                c_plot(framebuffer, count >> 16, y1, x_clip, y_clip, xx_clip, yy_clip, color, bcolor, alpha, draw_mode, bytes_per_pixel, bits_per_pixel, bytes_per_line, xoffset, yoffset);
                count += decInc;
            }
            return;
        }
        longLen += y1;
        for (count = 0x8000 + (x1 << 16); y1 >= longLen; --y1) {
            c_plot(framebuffer, count >> 16, y1, x_clip, y_clip, xx_clip, yy_clip, color, bcolor, alpha, draw_mode, bytes_per_pixel, bits_per_pixel, bytes_per_line, xoffset, yoffset);
            count -= decInc;
        }
        return;
    }
    if (longLen > 0) {
        longLen += x1;
        for (count = 0x8000 + (y1 << 16); x1 <= longLen; ++x1) {
            c_plot(framebuffer, x1, count >> 16, x_clip, y_clip, xx_clip, yy_clip, color, bcolor, alpha, draw_mode, bytes_per_pixel, bits_per_pixel, bytes_per_line, xoffset, yoffset);
            count += decInc;
        }
        return;
    }
    longLen += x1;
    for (count = 0x8000 + (y1 << 16); x1 >= longLen; --x1) {
        c_plot(framebuffer, x1, count >> 16, x_clip, y_clip, xx_clip, yy_clip, color, bcolor, alpha, draw_mode, bytes_per_pixel, bits_per_pixel, bytes_per_line, xoffset, yoffset);
        count -= decInc;
    }
}

// Reads in rectangular screen data as a string to a previously allocated buffer
void c_blit_read(
    char *framebuffer,
    short screen_width, short screen_height,
    unsigned int bytes_per_line,
    short xoffset, short yoffset,
    char *blit_data,
    short x, short y, short w, short h,
    unsigned char bytes_per_pixel,
    unsigned char draw_mode,
    unsigned char alpha,
    unsigned int bcolor,
    short x_clip, short y_clip, short xx_clip, short yy_clip)
{
    short fb_x = xoffset + x;
    short fb_y = yoffset + y;
    short xx   = x + w;
    short yy   = y + h;
    short horizontal;
    short vertical;
    unsigned int bline = w * bytes_per_pixel;

    for (vertical = 0; vertical < h; vertical++) {
        unsigned int vbl  = vertical * bline;
        unsigned short yv = fb_y + vertical;
        unsigned int yvbl = yv * bytes_per_line;
        if (yv >= (yoffset + y_clip) && yv <= (yoffset + yy_clip)) {
            for (horizontal = 0; horizontal < w; horizontal++) {
                unsigned short xh = fb_x + horizontal;
                unsigned int xhbp = xh * bytes_per_pixel;
                if (xh >= (xoffset + x_clip) && xh <= (xoffset + xx_clip)) {
                    unsigned int hzpixel   = horizontal * bytes_per_pixel;
                    unsigned int vhz       = vbl + hzpixel;
                    unsigned int yvhz      = yvbl + hzpixel;
                    unsigned int xhbp_yvbl = xhbp + yvbl;
                    if (bytes_per_pixel == 4) {
                        *((unsigned int*)(blit_data + vhz)) = *((unsigned int*)(framebuffer + xhbp_yvbl));
                    } else if (bytes_per_pixel == 3) {
                        *(blit_data + vhz ) = *(framebuffer + xhbp_yvbl );
                        *(blit_data + vhz  + 1) = *(framebuffer + xhbp_yvbl  + 1);
                        *(blit_data + vhz  + 2) = *(framebuffer + xhbp_yvbl  + 2);
                    } else {
                        *((unsigned short*)(blit_data + vhz )) = *((unsigned short*)(framebuffer + xhbp_yvbl ));
                    }
                }
            }
        }
    }
}

// Blits a rectangle of graphics to the screen using the specified draw mode
void c_blit_write(
    char *framebuffer,
    short screen_width, short screen_height,
    unsigned int bytes_per_line,
    short xoffset, short yoffset,
    char *blit_data,
    short x, short y, short w, short h,
    unsigned char bytes_per_pixel,
	unsigned char bits_per_pixel,
    unsigned char draw_mode,
    unsigned char alpha,
    unsigned int bcolor,
    short x_clip, short y_clip, short xx_clip, short yy_clip)
{
    short fb_x = xoffset + x;
    short fb_y = yoffset + y;
    short xx   = x + w;
    short yy   = y + h;
    unsigned int bline = (unsigned int)w * (unsigned int)bytes_per_pixel;

    /* Fastest is unclipped normal mode (keep original memcpy path) */
    if (draw_mode == NORMAL_MODE && x >= x_clip && xx <= xx_clip && y >= y_clip && yy <= yy_clip) {
        unsigned char *source = (unsigned char*)blit_data;
        unsigned char *dest   = (unsigned char*)framebuffer + (fb_y * bytes_per_line) + (fb_x * bytes_per_pixel);
        unsigned int row_bytes = bline;
        unsigned short v;
        for (v = 0; v < h; v++) {
            memcpy(dest, source, row_bytes);
            source += row_bytes;
            dest   += bytes_per_line;
        }
        return;
    }

    /* General clipped / non-normal modes: compute per-row bases and minimize per-pixel math */
    unsigned short vertical, horizontal;
    for (vertical = 0; vertical < h; vertical++) {
        unsigned short yv = fb_y + vertical;
        if (yv < (yoffset + y_clip) || yv > (yoffset + yy_clip)) continue;

        unsigned char *dest_row = (unsigned char*)framebuffer + ((unsigned int)yv * bytes_per_line);
        unsigned char *src_row  = (unsigned char*)blit_data + ((unsigned int)vertical * bline);

        for (horizontal = 0; horizontal < w; horizontal++) {
            unsigned short xh = fb_x + horizontal;
            if (xh < (xoffset + x_clip) || xh > (xoffset + xx_clip)) continue;

            unsigned char *dst = dest_row + ((unsigned int)xh * bytes_per_pixel);
            unsigned char *src = src_row  + ((unsigned int)horizontal * bytes_per_pixel);

            switch (bits_per_pixel) {
                case 32: {
                    uint32_t s = *((uint32_t*)src);
                    switch (draw_mode) {
                        case NORMAL_MODE:      *((uint32_t*)dst) = s; break;
                        case XOR_MODE:         *((uint32_t*)dst) ^= s; break;
                        case OR_MODE:          *((uint32_t*)dst) |= s; break;
                        case AND_MODE:         *((uint32_t*)dst) &= s; break;
                        case MASK_MODE: {
                            uint32_t fbv = *((uint32_t*)dst);
                            if ((s & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) *((uint32_t*)dst) = s;
                        } break;
                        case UNMASK_MODE: {
                            uint32_t fbv = *((uint32_t*)dst);
                            if ((fbv & 0xFFFFFF00) == (bcolor & 0xFFFFFF00)) *((uint32_t*)dst) = s;
                        } break;
                        case ALPHA_MODE: {
                            uint32_t fbv = *((uint32_t*)dst);
                            unsigned char fb_r = fbv & 0xFF;
                            unsigned char fb_g = (fbv >> 8) & 0xFF;
                            unsigned char fb_b = (fbv >> 16) & 0xFF;
                            unsigned char R = s & 0xFF;
                            unsigned char G = (s >> 8) & 0xFF;
                            unsigned char B = (s >> 16) & 0xFF;
                            unsigned char A = (s >> 24) & 0xFF;
                            unsigned char invA = 255 - A;
                            fb_r = ((R * A) + (fb_r * invA)) >> 8;
                            fb_g = ((G * A) + (fb_g * invA)) >> 8;
                            fb_b = ((B * A) + (fb_b * invA)) >> 8;
                            *((uint32_t*)dst) = fb_r | (fb_g << 8) | (fb_b << 16) | (A << 24);
                        } break;
                        case ADD_MODE:          *((uint32_t*)dst) += s; break;
                        case SUBTRACT_MODE:     *((uint32_t*)dst) -= s; break;
                        case MULTIPLY_MODE:     *((uint32_t*)dst) *= s; break;
                        case DIVIDE_MODE:       if (s != 0) *((uint32_t*)dst) /= s; break;
                    }
                } break;

                case 24: {
                    /* pack 3 bytes into 24-bit value */
                    uint32_t s = (uint32_t)src[0] | ((uint32_t)src[1] << 8) | ((uint32_t)src[2] << 16);
                    uint32_t fbv = (uint32_t)dst[0] | ((uint32_t)dst[1] << 8) | ((uint32_t)dst[2] << 16);
                    uint32_t res = fbv;
                    switch (draw_mode) {
                        case NORMAL_MODE:  res = s; break;
                        case XOR_MODE:     res = fbv ^ s; break;
                        case OR_MODE:      res = fbv | s; break;
                        case AND_MODE:     res = fbv & s; break;
                        case MASK_MODE:    if ((s & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) res = s; break;
                        case UNMASK_MODE:  if ((fbv & 0xFFFFFF00) == (bcolor & 0xFFFFFF00)) res = s; break;
                        case ALPHA_MODE: {
                            unsigned char fb_r = fbv & 0xFF;
                            unsigned char fb_g = (fbv >> 8) & 0xFF;
                            unsigned char fb_b = (fbv >> 16) & 0xFF;
                            unsigned char R = s & 0xFF;
                            unsigned char G = (s >> 8) & 0xFF;
                            unsigned char B = (s >> 16) & 0xFF;
                            unsigned char invA = 255 - alpha;
                            fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                            fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                            fb_b = ((B * alpha) + (fb_b * invA)) >> 8;
                            res = (uint32_t)fb_r | ((uint32_t)fb_g << 8) | ((uint32_t)fb_b << 16);
                        } break;
                        case ADD_MODE:      res = fbv + s; break;
                        case SUBTRACT_MODE: res = fbv - s; break;
                        case MULTIPLY_MODE: res = fbv * s; break;
                        case DIVIDE_MODE: {
                            /* per-channel safe divide (skip division when denominator is zero) */
                            unsigned char sc0 = s & 0xFF, sc1 = (s >> 8) & 0xFF, sc2 = (s >> 16) & 0xFF;
                            unsigned char dc0 = fbv & 0xFF, dc1 = (fbv >> 8) & 0xFF, dc2 = (fbv >> 16) & 0xFF;
                            unsigned char r0 = (sc0 != 0) ? (dc0 / sc0) : dc0;
                            unsigned char r1 = (sc1 != 0) ? (dc1 / sc1) : dc1;
                            unsigned char r2 = (sc2 != 0) ? (dc2 / sc2) : dc2;
                            res = (uint32_t)r0 | ((uint32_t)r1 << 8) | ((uint32_t)r2 << 16);
                        } break;
                    }
                    dst[0] = res & 0xFF;
                    dst[1] = (res >> 8) & 0xFF;
                    dst[2] = (res >> 16) & 0xFF;
                } break;

                case 16: {
                    uint16_t s = *((uint16_t*)src);
                    uint16_t fbv = *((uint16_t*)dst);
                    uint16_t res = fbv;
                    switch (draw_mode) {
                        case NORMAL_MODE:  res = s; break;
                        case XOR_MODE:     res = fbv ^ s; break;
                        case OR_MODE:      res = fbv | s; break;
                        case AND_MODE:     res = fbv & s; break;
                        case MASK_MODE:    if (s != (bcolor & 0xFFFF)) res = s; break;
                        case UNMASK_MODE:  if (fbv == (bcolor & 0xFFFF)) res = s; break;
                        case ALPHA_MODE: {
                            unsigned short rgb565 = fbv;
                            unsigned short fb_r = rgb565 & 31;
                            unsigned short fb_g = (rgb565 >> 5) & 63;
                            unsigned short fb_b = (rgb565 >> 11) & 31;
                            unsigned short R = s & 31;
                            unsigned short G = (s >> 5) & 63;
                            unsigned short B = (s >> 11) & 31;
                            unsigned char invA = 255 - alpha;
                            fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                            fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                            fb_b = ((B * alpha) + (fb_b * invA)) >> 8;
                            res = (fb_b << 11) | (fb_g << 5) | fb_r;
                        } break;
                        case ADD_MODE:      res = fbv + s; break;
                        case SUBTRACT_MODE: res = fbv - s; break;
                        case MULTIPLY_MODE: res = fbv * s; break;
                        case DIVIDE_MODE:   if (s != 0) res = fbv / s; break;
                    }
                    *((uint16_t*)dst) = res;
                } break;

                case 8: {
                    uint8_t s = *src;
                    uint8_t fbv = *dst;
                    uint8_t res = fbv;
                    switch (draw_mode) {
                        case NORMAL_MODE:  res = s; break;
                        case XOR_MODE:     res = fbv ^ s; break;
                        case OR_MODE:      res = fbv | s; break;
                        case AND_MODE:     res = fbv & s; break;
                        case MASK_MODE:    if (s != (bcolor & 0xFF)) res = s; break;
                        case UNMASK_MODE:  if (fbv == (bcolor & 0xFF)) res = s; break;
                        case ALPHA_MODE: {
                            uint8_t invA = 255 - alpha;
                            res = (uint8_t)((((uint32_t)s * alpha) + ((uint32_t)fbv * invA)) >> 8);
                        } break;
                        case ADD_MODE:      res = fbv + s; break;
                        case SUBTRACT_MODE: res = fbv - s; break;
                        case MULTIPLY_MODE: res = fbv * s; break;
                        case DIVIDE_MODE:   if (s != 0) res = fbv / s; break;
                    }
                    *dst = res;
                } break;

                case 1: {
                    /* not supported */
                } break;
            } /* end bits_per_pixel switch */
        } /* end horizontal loop */
    } /* end vertical loop */
}

// Fast rotate blit graphics data
void c_rotate(
    char *image,
    char *new_img,
    short width, short height,
    unsigned short wh,
    double degrees,
    unsigned char bytes_per_pixel,
    unsigned char bits_per_pixel)
{
    unsigned int hwh        = floor(wh / 2 + 0.5);
    unsigned int bbline     = wh * bytes_per_pixel;
    unsigned int bline      = width * bytes_per_pixel;
    unsigned short hwidth   = floor(width / 2 + 0.5);
    unsigned short hheight  = floor(height / 2 + 0.5);
    double sinma            = sin((degrees * M_PI) / 180);
    double cosma            = cos((degrees * M_PI) / 180);
    short x, y;

    /* iterate rows (y) outer, columns (x) inner for better dest-row locality */
    for (y = 0; y < wh; y++) {
        double yt = (double)y - (double)hwh;
        /* xs and ys for x == 0 */
        double xs = cosma * (0 - (double)hwh) - sinma * yt + (double)hwidth;
        double ys = sinma * (0 - (double)hwh) + cosma * yt + (double)hheight;

        unsigned char *dest_row = (unsigned char*)new_img + (unsigned int)y * bbline;

        for (x = 0; x < wh; x++) {
            int xi = (int)xs;
            int yi = (int)ys;

            if (xi >= 0 && xi < width && yi >= 0 && yi < height) {
                unsigned char *src = (unsigned char*)image + (unsigned int)xi * bytes_per_pixel + (unsigned int)yi * bline;
                unsigned char *dst = dest_row + (unsigned int)x * bytes_per_pixel;

                switch (bits_per_pixel) {
                    case 32:
                        *((unsigned int*)dst) = *((unsigned int*)src);
                        break;
                    case 24:
                        dst[0] = src[0];
                        dst[1] = src[1];
                        dst[2] = src[2];
                        break;
                    case 16:
                        *((unsigned short*)dst) = *((unsigned short*)src);
                        break;
                    case 8:
                        *dst = *src;
                        break;
                    case 1:
                        /* not supported */
                        break;
                    default:
                        break;
                }
            }

            /* incrementally update xs, ys for next x (adds are cheaper than multiplications) */
            xs += cosma;
            ys += sinma;
        }
    }
}

// Horizontally mirror blit graphics data
void c_flip_horizontal(char* pixels, short width, short height, unsigned char bytes_per_pixel) {
    if (bytes_per_pixel == 0 || width <= 1 || height <= 0) return;

    unsigned int bpl = (unsigned int)width * (unsigned int)bytes_per_pixel;
    short hwidth = width / 2;

    /* allocate a single temporary buffer once (VLA) */
    unsigned char tmp[bytes_per_pixel];

    for (short y = 0; y < height; y++) {
        unsigned char *row = (unsigned char*)pixels + (unsigned int)y * bpl;
        for (short x = 0; x < hwidth; x++) {
            unsigned char *left  = row + ((unsigned int)x * bytes_per_pixel);
            unsigned char *right = row + ((unsigned int)(width - 1 - x) * bytes_per_pixel);

            /* swap whole pixel at once */
            memcpy(tmp, left, bytes_per_pixel);
            memcpy(left, right, bytes_per_pixel);
            memcpy(right, tmp, bytes_per_pixel);
        }
    }
}

// Vertically flip blit graphics data
void c_flip_vertical(char *pixels, short width, short height, unsigned char bytes_per_pixel) {
    if (bytes_per_pixel == 0 || width <= 0 || height <= 1 || pixels == NULL) return;

    size_t bufsize = (size_t)width * (size_t)bytes_per_pixel;        // Bytes per line
    size_t half = (size_t)height / 2;

    unsigned char *tmp = malloc(bufsize);                           // Allocate a temporary buffer once
    if (!tmp) return; /* allocation failed, nothing we can do */

    for (size_t i = 0; i < half; ++i) {
        unsigned char *low  = (unsigned char*)pixels + i * bufsize;
        unsigned char *high = (unsigned char*)pixels + ((size_t)(height - 1 - i)) * bufsize;

        memcpy(tmp, low,  bufsize);    // Make a copy of the lower line
        memcpy(low, high, bufsize);    // Copy the upper line to the lower
        memcpy(high, tmp, bufsize);    // Copy the saved copy to the upper line
    }

    free(tmp); // Release the temporary buffer
}

// Horizontally and vertically flip blit graphics data
void c_flip_both(char* pixels, short width, short height, unsigned char bytes_per_pixel) {
    c_flip_vertical(
        pixels,
        width,height,
        bytes_per_pixel
    );
    c_flip_horizontal(
        pixels,
        width,height,
        bytes_per_pixel
    );
}

/* bitmap conversions */

// Convert an RGB565 bitmap to an RGB888 bitmap
void c_convert_16_24( char* buf16, unsigned int size16, char* buf24, unsigned char color_order ) {
    unsigned int loc16 = 0;
    unsigned int loc24 = 0;
    unsigned char r5;
    unsigned char g6;
    unsigned char b5;

    while(loc16 < size16) {
        unsigned short rgb565 = *((unsigned short*)(buf16 + loc16));
        loc16 += 2;
        if (color_order == RGB) {
            b5 = (rgb565 & 0xf800) >> 11;
            r5 = (rgb565 & 0x001f);
        } else {
            r5 = (rgb565 & 0xf800) >> 11;
            b5 = (rgb565 & 0x001f);
        }
        g6 = (rgb565 & 0x07e0) >> 5;
        unsigned char r8 = (r5 * 527 + 23) >> 6;
        unsigned char g8 = (g6 * 259 + 33) >> 6;
        unsigned char b8 = (b5 * 527 + 23) >> 6;
        *((unsigned char*)(buf24 + loc24++)) = r8;
        *((unsigned char*)(buf24 + loc24++)) = g8;
        *((unsigned char*)(buf24 + loc24++)) = b8;
    }
}

// Convert an RGB565 bitmap to a RGB8888 bitmap
void c_convert_16_32( char* buf16, unsigned int size16, char* buf32, unsigned char color_order ) {
    unsigned int loc16 = 0;
    unsigned int loc32 = 0;
    unsigned char r5;
    unsigned char g6;
    unsigned char b5;

    while(loc16 < size16) {
        unsigned short rgb565 = *((unsigned short*)(buf16 + loc16));
        loc16 += 2;
        if (color_order == 0) {
            b5 = (rgb565 & 0xf800) >> 11;
            r5 = (rgb565 & 0x001f);
        } else {
            r5 = (rgb565 & 0xf800) >> 11;
            b5 = (rgb565 & 0x001f);
        }
        g6 = (rgb565 & 0x07e0) >> 5;
        unsigned char r8 = (r5 * 527 + 23) >> 6;
        unsigned char g8 = (g6 * 259 + 33) >> 6;
        unsigned char b8 = (b5 * 527 + 23) >> 6;
        *((unsigned int*)(buf32 + loc32)) = r8 | (g8 << 8) | (b8 << 16);
        loc32 += 3;
        if (r8 == 0 && g8 == 0 && b8 ==0) { // Black is always treated as a clear mask
            *((unsigned char*)(buf32 + loc32++)) = 0;
        } else { // Anything but black is opague
            *((unsigned char*)(buf32 + loc32++)) = 255;
        }
    }
}

// Convert a RGB888 bitmap to a RGB565 bitmap
void c_convert_24_16(char* buf24, unsigned int size24, char* buf16, unsigned char color_order) {
    unsigned int loc16    = 0;
    unsigned int loc24    = 0;
    unsigned short rgb565 = 0;
    while(loc24 < size24) {
        unsigned char r8 = *(buf24 + loc24++);
        unsigned char g8 = *(buf24 + loc24++);
        unsigned char b8 = *(buf24 + loc24++);
        unsigned char r5 = ( r8 * 249 + 1014 ) >> 11;
        unsigned char g6 = ( g8 * 253 + 505  ) >> 10;
        unsigned char b5 = ( b8 * 249 + 1014 ) >> 11;
        if (color_order == RGB) {
            rgb565 = (b5 << 11) | (g6 << 5) | r5;
        } else {
            rgb565 = (r5 << 11) | (g6 << 5) | b5;
        }
        /* write 16-bit value at loc16 and advance by 2 bytes */
        *((unsigned short*)(buf16 + loc16)) = rgb565;
        loc16 += 2;
    }
}

// Convert a RGB8888 bitmap to a RGB565 bitmap
void c_convert_32_16(char* buf32, unsigned int size32, char* buf16, unsigned char color_order) {
    unsigned int loc16    = 0;
    unsigned int loc32    = 0;
    unsigned short rgb565 = 0;
    while(loc32 < size32) {
        unsigned int crgb = *((unsigned int*)(buf32 + loc32));
        unsigned char r8 = crgb & 255;
        unsigned char g8 = (crgb >> 8) & 255;
        unsigned char b8 = (crgb >> 16) & 255;
	    loc32 += 4;
        unsigned char r5 = ( r8 * 249 + 1014 ) >> 11;
        unsigned char g6 = ( g8 * 253 + 505  ) >> 10;
        unsigned char b5 = ( b8 * 249 + 1014 ) >> 11;
        if (color_order == RGB) {
            rgb565 = (b5 << 11) | (g6 << 5) | r5;
        } else {
            rgb565 = (r5 << 11) | (g6 << 5) | b5;
        }
        /* write 16-bit value and advance */
        *((unsigned short*)(buf16 + loc16)) = rgb565;
        loc16 += 2;
    }
}

// Convert a RGB888 bitmap to a RGB8888 bitmap
void c_convert_32_24(char* buf32, unsigned int size32, char* buf24, unsigned char color_order) {
    unsigned int loc24 = 0;
    unsigned int loc32 = 0;
    while(loc32 < size32) {
        *(buf24 + loc24++) = *(buf32 + loc32++);
        *(buf24 + loc24++) = *(buf32 + loc32++);
        *(buf24 + loc24++) = *(buf32 + loc32++);
        loc32++; // Toss the alpha
    }
}

// Convert a RGB8888 bitmap to a RGB888 bitmap
void c_convert_24_32(char* buf24, unsigned int size24, char* buf32, unsigned char color_order) {
    unsigned int loc32 = 0;
    unsigned int loc24 = 0;
    while(loc24 < size24) {
        unsigned char r = *(buf24 + loc24++);
        unsigned char g = *(buf24 + loc24++);
        unsigned char b = *(buf24 + loc24++);
        *((unsigned int*)(buf32 + loc32)) = r | (g << 8) | (b << 16);
        loc32 += 3;
        if (r == 0 && g == 0 && b == 0) {
            *(buf32 + loc32++) = 0; // The background is transparent
        } else {
            *(buf32 + loc32++) = 255; // The foreground is opague
        }
    }
}

// These are not yet implemented, but they will likely incorporate conversion to/from monochrome
void c_convert_32_8(char* buf32, unsigned int size32, char* buf8, unsigned char color_order) {
    unsigned int loc32 = 0;
    unsigned int loc8  = 0;
    unsigned char m    = 0;
    while(loc32 < size32) {
        unsigned int crgb = *((unsigned int*)(buf32 + loc32));
	    loc32 += 4;
        unsigned char r = crgb & 255;
        unsigned char g = (crgb >> 8) & 255;
        unsigned char b = (crgb >> 16) & 255;
	    m = (unsigned char) round(0.2126 * r + 0.7152 * g + 0.0722 * b);
        *((unsigned char*)(buf8 + loc8++)) = m;
    }
}
void c_convert_24_8(char* buf24, unsigned int size24, char* buf8, unsigned char color_order) {
    unsigned int loc8  = 0;
    unsigned int loc24 = 0;
    unsigned char m    = 0;
    while(loc24 < size24) {
        unsigned int crgb = *((unsigned int*)(buf24 + loc24));
	    loc24 += 3;
        unsigned char r = crgb & 255;
        unsigned char g = (crgb >> 8) & 255;
        unsigned char b = (crgb >> 16) & 255;
	    m = (unsigned char) round(0.2126 * r + 0.7152 * g + 0.0722 * b);
        *((unsigned char*)(buf8 + loc8++)) = m;
    }
}
void c_convert_16_8(char* buf16, unsigned int size16, char* buf8, unsigned char color_order) {
    unsigned int loc8  = 0;
    unsigned int loc16 = 0;
    unsigned char r5;
    unsigned char g6;
    unsigned char b5;

    while(loc16 < size16) {
        unsigned short rgb565 = *((unsigned short*)(buf16 + loc16));
        loc16 += 2;
        if (color_order == 0) {
            b5 = (rgb565 & 0xf800) >> 11;
            r5 = (rgb565 & 0x001f);
        } else {
            r5 = (rgb565 & 0xf800) >> 11;
            b5 = (rgb565 & 0x001f);
        }
        g6 = (rgb565 & 0x07e0) >> 5;
        unsigned char r8 = (r5 * 527 + 23) >> 6;
        unsigned char g8 = (g6 * 259 + 33) >> 6;
        unsigned char b8 = (b5 * 527 + 23) >> 6;
        *((unsigned char*)(buf8 + loc8++)) = (unsigned char) round(0.2126 * r8 + 0.7152 * g8 + 0.0722 * b8);
    }
}
void c_convert_8_32(char* buf8, unsigned int size8, char* buf32, unsigned char color_order) {
    unsigned int loc8  = 0;
    unsigned int loc32 = 0;

    while(loc8 < size8) {
        unsigned char m = *((unsigned char*)(buf8 + loc8++));
        *((unsigned int*)(buf32 + loc32)) = m | (m << 8) | (m << 16);
        loc32 += 3;
        if (m == 0) { // Black is always treated as a clear mask
            *((unsigned char*)(buf32 + loc32++)) = 0;
        } else { // Anything but black is opague
            *((unsigned char*)(buf32 + loc32++)) = 255;
        }
    }
}
void c_convert_8_24(char* buf8, unsigned int size8, char* buf24, unsigned char color_order) {
    unsigned int loc8  = 0;
    unsigned int loc24 = 0;

    while(loc8 < size8) {
        unsigned char m = *((unsigned char*)(buf8 + loc8++));
        /* write 3 bytes explicitly to avoid accidental 4-byte writes */
        *(buf24 + loc24++) = m;
        *(buf24 + loc24++) = m;
        *(buf24 + loc24++) = m;
    }
}
void c_convert_8_16(char* buf8, unsigned int size8, char* buf16, unsigned char color_order) {
    unsigned int loc8     = 0;
    unsigned int loc16    = 0;
    unsigned short rgb565 = 0;
    while(loc8 < size8) {
        unsigned char m = *(buf8 + loc8++);
        unsigned char r5 = ( m * 249 + 1014 ) >> 11;
        unsigned char g6 = ( m * 253 + 505  ) >> 10;
        unsigned char b5 = ( m * 249 + 1014 ) >> 11;
        if (color_order == RGB) {
            rgb565 = (b5 << 11) | (g6 << 5) | r5;
        } else {
            rgb565 = (r5 << 11) | (g6 << 5) | b5;
        }
        *((unsigned short*)(buf16 + loc16)) = rgb565;
        loc16 += 2;
    }
}

// Convert any type RGB bitmap to a monochrome bitmap of the same type
void c_monochrome(char *pixels, unsigned int size, unsigned char color_order, unsigned char bytes_per_pixel, unsigned char bits_per_pixel) {
    unsigned int idx;
    unsigned char r;
    unsigned char g;
    unsigned char b;
    unsigned char m;
    unsigned short rgb565;
    unsigned char rgb8;

    for (idx = 0; idx < size; idx += bytes_per_pixel) {
        switch (bits_per_pixel) {
		    case 32 :
                switch(color_order) {
                    case RBG :  // RBG
						{
                        	r = *(pixels + idx);
				        	b = *(pixels + idx + 1);
                        	g = *(pixels + idx + 2);
						}
                        break;
                    case BGR :  // BGR
						{
                        	b = *(pixels + idx);
                        	g = *(pixels + idx + 1);
                        	r = *(pixels + idx + 2);
						}
                        break;
                    case BRG :  // BRG
						{
                        	b = *(pixels + idx);
                        	r = *(pixels + idx + 1);
                        	g = *(pixels + idx + 2);
						}
                        break;
                    case GBR :  // GBR
						{
                        	g = *(pixels + idx);
                        	b = *(pixels + idx + 1);
                        	r = *(pixels + idx + 2);
						}
                        break;
                    case GRB :  // GRB
						{
                        	g = *(pixels + idx);
                        	r = *(pixels + idx + 1);
                        	b = *(pixels + idx + 2);
						}
                        break;
                    default : // RGB
						{
                        	r = *(pixels + idx);
                        	g = *(pixels + idx + 1);
                        	b = *(pixels + idx + 2);
						}
				        break;
                }
                m = (unsigned char) round(0.2126 * r + 0.7152 * g + 0.0722 * b);
		        break;
		    case 24 :
                switch(color_order) {
                    case RBG :  // RBG
						{
                        	r = *(pixels + idx);
				        	b = *(pixels + idx + 1);
                        	g = *(pixels + idx + 2);
						}
                        break;
                    case BGR :  // BGR
						{
                        	b = *(pixels + idx);
                        	g = *(pixels + idx + 1);
                        	r = *(pixels + idx + 2);
						}
                        break;
                    case BRG :  // BRG
						{
                        	b = *(pixels + idx);
                        	r = *(pixels + idx + 1);
                        	g = *(pixels + idx + 2);
						}
                        break;
                    case GBR :  // GBR
						{
                        	g = *(pixels + idx);
                        	b = *(pixels + idx + 1);
                        	r = *(pixels + idx + 2);
						}
                        break;
                    case GRB :  // GRB
						{
                        	g = *(pixels + idx);
                        	r = *(pixels + idx + 1);
                        	b = *(pixels + idx + 2);
						}
                        break;
                    default : // RGB
						{
                        	r = *(pixels + idx);
                        	g = *(pixels + idx + 1);
                        	b = *(pixels + idx + 2);
						}
				        break;
                }
                m = (unsigned char) round(0.2126 * r + 0.7152 * g + 0.0722 * b);
		        break;
		    case 16 :
				{
                	rgb565 = *((unsigned short*)(pixels + idx));
                	/* extract components consistent with other conversion routines */
                	unsigned char r5;
                	unsigned char g6;
                	unsigned char b5;
                	if (color_order == RGB) {
                	    b5 = (rgb565 & 0xf800) >> 11;
                	    r5 = (rgb565 & 0x001f);
                	} else {
                	    r5 = (rgb565 & 0xf800) >> 11;
                	    b5 = (rgb565 & 0x001f);
                	}
                	g6 = (rgb565 & 0x07e0) >> 5;
                    /* expand to 8-bit */
                    unsigned char r8 = (r5 * 527 + 23) >> 6;
                    unsigned char g8 = (g6 * 259 + 33) >> 6;
                    unsigned char b8 = (b5 * 527 + 23) >> 6;
                    unsigned char m8 = (unsigned char) round(0.2126 * r8 + 0.7152 * g8 + 0.0722 * b8);
                    /* convert back to RGB565 components */
                    unsigned char nr5 = ( m8 * 249 + 1014 ) >> 11;
                    unsigned char ng6 = ( m8 * 253 + 505  ) >> 10;
                    unsigned char nb5 = ( m8 * 249 + 1014 ) >> 11;
                    if (color_order == RGB) {
                        rgb565 = (nb5 << 11) | (ng6 << 5) | nr5;
                    } else {
                        rgb565 = (nr5 << 11) | (ng6 << 5) | nb5;
                    }
                	m = 0; /* will be set below when writing */
				}
		        break;
		    case 8 :
				{ // No actual conversion since already monochrome
					rgb8 = *((unsigned char*)(pixels + idx));
					m    = rgb8;
				}
		        break;
		    case 1 :
				{
				}
		        break;
		}

        switch(bits_per_pixel) {
            case 32 :
                if (m == 0)  {
                    *((unsigned int*)(pixels + idx)) = m | (m << 8) | (m << 16);
                } else {
                    *((unsigned int*)(pixels + idx)) = m | (m << 8) | (m << 16) | 0xFF000000;
                }
                break;
            case 24 :
				{
                	*(pixels + idx)     = m;
                	*(pixels + idx + 1) = m;
                 	*(pixels + idx + 2) = m;
				}
                break;
            case 16 :
				{
					/* for 16-bit we've prepared rgb565 above */
                	*((unsigned short*)(pixels + idx)) = rgb565;
				}
                break;
		    case 8 :
				{
                	*(pixels + idx)     = rgb8;
				}
		        break;
		    case 1 :
				{
				}
		        break;
        }
    }
}

