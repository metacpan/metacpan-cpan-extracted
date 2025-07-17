/* Copyright 2018-## YEAR ## Richard Kelsch, All Rights Reserved
   See the Perl documentation for Graphics::Framebuffer for licensing information.

   Version:  ## VERSION ##

   You may wonder why the stack is so heavily used when the global structures
   have the needed values.  Well, the module can emulate another graphics mode
   that may not be the one being displayed.  This means using the two structures
   would break functionality.  Therefore, the data from Perl is passed along.

   8 bit and 1 bit modes are not yet supported and their case values are just
   placeholders.
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
    ioctl(fbfd, FBIOGET_FSCREENINFO, &finfo);
    ioctl(fbfd, FBIOGET_VSCREENINFO, &vinfo);
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
    if (x >= x_clip && x <= xx_clip && y >= y_clip && y <= yy_clip) { // Make sure the pixel is within the clipped area
        x += xoffset;
        y += yoffset;
        unsigned int index = (x * bytes_per_pixel) + (y * bytes_per_line);
        switch(draw_mode) {
            case NORMAL_MODE :
                switch(bits_per_pixel) {
                    case 32 : 
                        {
                           *((unsigned int*)(framebuffer + index)) = color; // 32 bit drawing can send a long word in one operation.  Which is why it is the fastest.
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     = color         & 255; // 24 Bit requites one byte at a time.  Not as efficient as 32 bit.
                            *(framebuffer + index + 1) = (color >> 8)  & 255;
                            *(framebuffer + index + 2) = (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) = (short) color; // 16 bit can send a word at a time, the second most efficient method.
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case XOR_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) ^= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     ^= color         & 255;
                            *(framebuffer + index + 1) ^= (color >> 8)  & 255;
                            *(framebuffer + index + 2) ^= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) ^= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case OR_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) |= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     |= color         & 255;
                            *(framebuffer + index + 1) |= (color >> 8)  & 255;
                            *(framebuffer + index + 2) |= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                           *((unsigned short*)(framebuffer + index)) |= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case AND_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) &= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     &= color         & 255;
                            *(framebuffer + index + 1) &= (color >> 8)  & 255;
                            *(framebuffer + index + 2) &= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) &= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case MASK_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            if ((*((unsigned int*)(framebuffer + index )) & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                *((unsigned int*)(framebuffer + index )) = color;
                            }
                        }
                        break;
                    case 24 :
                        {
                            if ((*((unsigned int*)(framebuffer + index )) & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                *(framebuffer + index )     = color         & 255;
                                *(framebuffer + index  + 1) = (color >> 8)  & 255;
                                *(framebuffer + index  + 2) = (color >> 16) & 255;
                            }
                        }
                        break;
                    case 16 :
                        {
                            if (*((unsigned short*)(framebuffer + index)) != (bcolor & 0xFFFF)) {
                                *((unsigned short*)(framebuffer + index )) = color;
                            }
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case UNMASK_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            if ((*((unsigned int*)(framebuffer + index )) & 0xFFFFFF00) == (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                *((unsigned int*)(framebuffer + index )) = color;
                            }
                        }
                        break;
                     case 24 :
                         {
                             if ((*((unsigned int*)(framebuffer + index )) & 0xFFFFFF00) == (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                 *(framebuffer + index )     = color         & 255;
                                 *(framebuffer + index  + 1) = (color >> 8)  & 255;
                                 *(framebuffer + index  + 2) = (color >> 16) & 255;
                             }
                         }
                         break;
                     case 16 :
                         {
                             if (*((unsigned short*)(framebuffer + index)) == (bcolor & 0xFFFF)) {
                                 *((unsigned short*)(framebuffer + index )) = color;
                             }
                         }
                         break;
                     case 8 : // Obviously not yet supported 
                         break;
                     case 1 : // Obviously not yet supported 
                         break;
                }
            break;
            case ALPHA_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            unsigned int fb_rgb = *((unsigned int*)(framebuffer + index));
                            unsigned char fb_r  = fb_rgb & 255;
                            unsigned char fb_g  = (fb_rgb >> 8) & 255;
                            unsigned char fb_b  = (fb_rgb >> 16) & 255;
                            unsigned char R     = color         & 255;
                            unsigned char G     = (color >> 8)  & 255;
                            unsigned char B     = (color >> 16) & 255;
                            unsigned char A     = (color >> 24) & 255;
                            unsigned char invA  = (255 - A);

                            fb_r = ((R * A) + (fb_r * invA)) >> 8;
                            fb_g = ((G * A) + (fb_g * invA)) >> 8;
                            fb_b = ((B * A) + (fb_b * invA)) >> 8;

                            *((unsigned int*)(framebuffer + index)) = fb_r | (fb_g << 8) | (fb_b << 16) | (A << 24);
                        }
                        break;
                    case 24 :
                        {
                            unsigned char fb_r  = *(framebuffer + index);
                            unsigned char fb_g  = *(framebuffer + index + 1);
                            unsigned char fb_b  = *(framebuffer + index + 2);
                            unsigned char invA  = (255 - alpha);
                            unsigned char R     = color         & 255;
                            unsigned char G     = (color >> 8)  & 255;
                            unsigned char B     = (color >> 16) & 255;

                            fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                            fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                            fb_b = ((B * alpha) + (fb_b * invA)) >> 8;

                            *(framebuffer + index)     = fb_r;
                            *(framebuffer + index + 1) = fb_g;
                            *(framebuffer + index + 2) = fb_b;
                        }
                        break;
                    case 16 :
                        {
                            unsigned short rgb565 = *((unsigned short*)(framebuffer + index));
                            unsigned short fb_r   = rgb565 & 31;
                            unsigned short fb_g   = (rgb565 >> 5) & 63;
                            unsigned short fb_b   = (rgb565 >> 11) & 31;
                            unsigned short R = color & 31;
                            unsigned short G = (color >> 5) & 63;
                            unsigned short B = (color >> 11) & 31;
                            unsigned char invA = (255 - alpha);
                            fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                            fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                            fb_b = ((B * alpha) + (fb_b * invA)) >> 8;
                            rgb565 = (fb_b << 11) | (fb_g << 5) | fb_r;
                            *((unsigned short*)(framebuffer + index)) = rgb565;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case ADD_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) += color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     += color         & 255;
                            *(framebuffer + index + 1) += (color >> 8)  & 255;
                            *(framebuffer + index + 2) += (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) += (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case SUBTRACT_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) -= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     -= color         & 255;
                            *(framebuffer + index + 1) -= (color >> 8)  & 255;
                            *(framebuffer + index + 2) -= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) -= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case MULTIPLY_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) *= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     *= color         & 255;
                            *(framebuffer + index + 1) *= (color >> 8)  & 255;
                            *(framebuffer + index + 2) *= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) *= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
            case DIVIDE_MODE :
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(framebuffer + index)) /= color;
                        }
                        break;
                    case 24 :
                        {
                            *(framebuffer + index)     /= color         & 255;
                            *(framebuffer + index + 1) /= (color >> 8)  & 255;
                            *(framebuffer + index + 2) /= (color >> 16) & 255;
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(framebuffer + index)) /= (short) color;
                        }
                        break;
                    case 8 : // Obviously not yet supported 
                        break;
                    case 1 : // Obviously not yet supported 
                        break;
                }
            break;
        }
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
    short horizontal;
    short vertical;
    unsigned int bline = w * bytes_per_pixel;

    // Fastest is unclipped normal mode
    if (draw_mode == NORMAL_MODE && x >= x_clip && xx <= xx_clip && y >= y_clip && yy <= yy_clip) {
        unsigned char *source = blit_data;
        unsigned char *dest   = &framebuffer[(fb_y * bytes_per_line) + (fb_x * bytes_per_pixel)];
        for (vertical = 0; vertical < h; vertical++) {
            memcpy(dest, source, bline);
            source += bline;
            dest += bytes_per_line;
        }
    } else {
        switch(draw_mode) {
            case NORMAL_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) = *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     = *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) = *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) = *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) = *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case XOR_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) ^= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     ^= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) ^= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) ^= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) ^= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case OR_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) |= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     |= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) |= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) |= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) |= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case AND_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) &= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     &= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) &= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) &= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) &= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case MASK_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        unsigned int rgb       = *((unsigned int*)(blit_data + vhz ));
                                        if (( rgb & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                            *((unsigned int*)(framebuffer + xhbp_yvbl )) = rgb;
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        if ((*((unsigned int*)(blit_data + vhz )) & 0xFFFFFF00) != (bcolor & 0xFFFFFF00)) { // Ignore alpha channel
                                            *(framebuffer + xhbp_yvbl )     = *(blit_data + vhz );
                                            *(framebuffer + xhbp_yvbl  + 1) = *(blit_data + vhz  + 1);
                                            *(framebuffer + xhbp_yvbl  + 2) = *(blit_data + vhz  + 2);
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        unsigned int rgb       = *((unsigned short*)(blit_data + vhz ));
                                        if (rgb != (bcolor & 0xFFFF)) {
                                            *((unsigned short*)(framebuffer + xhbp_yvbl )) = rgb;
                                        }
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case UNMASK_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        if ((*((unsigned int*)(framebuffer + xhbp_yvbl )) & 0xFFFFFF00) == (bcolor & 0xFFFFFF00)) { // Ignore alpha channel for color testing
                                            *((unsigned int*)(framebuffer + xhbp_yvbl )) = *((unsigned int*)(blit_data + vhz ));
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        if (*((unsigned int*)(framebuffer + xhbp + yvhz )) == (bcolor & 0xFFFFFF00)) {
                                            *(framebuffer + xhbp_yvbl )     = *(blit_data + vhz );
                                            *(framebuffer + xhbp_yvbl  + 1) = *(blit_data + vhz  + 1);
                                            *(framebuffer + xhbp_yvbl  + 2) = *(blit_data + vhz  + 2);
                                        }
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        if (*((unsigned short*)(framebuffer + xhbp + yvhz )) == (bcolor & 0xFFFF)) {
                                            *((unsigned short*)(framebuffer + xhbp_yvbl )) = *((unsigned short*)(blit_data + vhz ));
                                        }
                                    }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case ALPHA_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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

                                        unsigned int fb_rgb = *((unsigned int*)(framebuffer + xhbp_yvbl));
                                        unsigned char fb_r  = fb_rgb & 255;
                                        unsigned char fb_g  = (fb_rgb >> 8) & 255;
                                        unsigned char fb_b  = (fb_rgb >> 16) & 255;

                                        unsigned int blit_rgb = *((unsigned int*)(blit_data + vhz));
                                        unsigned char R       = blit_rgb & 255;
                                        unsigned char G       = (blit_rgb >> 8) & 255;
                                        unsigned char B       = (blit_rgb >> 16) & 255;
                                        unsigned char A       = (blit_rgb >> 24) & 255;
                                        unsigned char invA    = (255 - A);

                                        fb_r = ((R * A) + (fb_r * invA)) >> 8;
                                        fb_g = ((G * A) + (fb_g * invA)) >> 8;
                                        fb_b = ((B * A) + (fb_b * invA)) >> 8;

                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) = fb_r | (fb_g << 8) | (fb_b << 16) | (A << 24);
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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

                                        unsigned char fb_r = *(framebuffer + xhbp_yvbl );
                                        unsigned char fb_g = *(framebuffer + xhbp_yvbl  + 1);
                                        unsigned char fb_b = *(framebuffer + xhbp_yvbl  + 2);
                                        unsigned char R    = *(blit_data + vhz );
                                        unsigned char G    = *(blit_data + vhz + 1);
                                        unsigned char B    = *(blit_data + vhz + 2);
                                        unsigned char invA = (255 - alpha);

                                        fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                                        fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                                        fb_b = ((B * alpha) + (fb_b * invA)) >> 8;

                                        *(framebuffer + xhbp_yvbl )     = fb_r;
                                        *(framebuffer + xhbp_yvbl  + 1) = fb_g;
                                        *(framebuffer + xhbp_yvbl  + 2) = fb_b;
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        unsigned short rgb565  = *((unsigned short*)(framebuffer + xhbp_yvbl ));

                                        unsigned short fb_r = rgb565 & 31;
                                        unsigned short fb_g = (rgb565 >> 5) & 63;
                                        unsigned short fb_b = (rgb565 >> 11) & 31;
                                        rgb565 = *((unsigned short*)(blit_data + vhz ));
                                        unsigned short R   = rgb565 & 31;
                                        unsigned short G   = (rgb565 >> 5) & 63;
                                        unsigned short B   = (rgb565 >> 11) & 31;
                                        unsigned char invA = (255 - alpha);
                                        fb_r = ((R * alpha) + (fb_r * invA)) >> 8;
                                        fb_g = ((G * alpha) + (fb_g * invA)) >> 8;
                                        fb_b = ((B * alpha) + (fb_b * invA)) >> 8;

                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) = (fb_b << 11) | (fb_g << 5) | fb_r;

                                    }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case ADD_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) += *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     += *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) += *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) += *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) += *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case SUBTRACT_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) -= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     -= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) -= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) -= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) -= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case MULTIPLY_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) *= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     *= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) *= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) *= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) *= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
            case DIVIDE_MODE :
                switch(bits_per_pixel) {
                    case 32 :
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
                                        *((unsigned int*)(framebuffer + xhbp_yvbl)) /= *((unsigned int*)(blit_data + vhz));
                                    }
                                }
                            }
                        }
                        break;
                    case 24 :
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
                                        *(framebuffer + xhbp_yvbl )     /= *(blit_data + vhz );
                                        *(framebuffer + xhbp_yvbl  + 1) /= *(blit_data + vhz  + 1);
                                        *(framebuffer + xhbp_yvbl  + 2) /= *(blit_data + vhz  + 2);
                                    }
                                }
                            }
                        }
                        break;
                    case 16 :
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
                                        *((unsigned short*)(framebuffer + xhbp_yvbl )) /= *((unsigned short*)(blit_data + vhz ));
                                   }
                                }
                            }
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
                break;
        }       
    }
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
    short x;
    short y;

    for (x = 0; x < wh; x++) {
        short xt = x - hwh;
        for (y = 0; y < wh; y++) {
            short yt = y - hwh;
            short xs = ((cosma * xt - sinma * yt) + hwidth);
            short ys = ((sinma * xt + cosma * yt) + hheight);
            if (xs >= 0 && xs < width && ys >= 0 && ys < height) {
                switch(bits_per_pixel) {
                    case 32 :
                        {
                            *((unsigned int*)(new_img + (x * bytes_per_pixel) + (y * bbline))) = *((unsigned int*)(image + (xs * bytes_per_pixel) + (ys * bline)));
                        }
                        break;
                    case 24 :
                        {
                            *(new_img + (x * bytes_per_pixel) + (y * bbline))     = *(image + (xs * bytes_per_pixel) + (ys * bline));
                            *(new_img + (x * bytes_per_pixel) + (y * bbline) + 1) = *(image + (xs * bytes_per_pixel) + (ys * bline) + 1);
                            *(new_img + (x * bytes_per_pixel) + (y * bbline) + 2) = *(image + (xs * bytes_per_pixel) + (ys * bline) + 2);
                        }
                        break;
                    case 16 :
                        {
                            *((unsigned short*)(new_img + (x * bytes_per_pixel) + (y * bbline))) = *((unsigned short*)(image + (xs * bytes_per_pixel) + (ys * bline)));
                        }
                        break;
				    case 8 :
				        break;
				    case 1 :
				        break;
                }
            }
        }
    }
}

// Horizontally mirror blit graphics data
void c_flip_horizontal(char* pixels, short width, short height, unsigned char bytes_per_pixel) {
    short y;
    short x;
    unsigned short offset;
    unsigned char left;
    unsigned int bpl = width * bytes_per_pixel;
    unsigned short hwidth = width / 2;
    for ( y = 0; y < height; y++ ) {
        unsigned int ydx = y * bpl;
        for (x = 0; x < hwidth ; x++) { // Stop when you reach the middle
            for (offset = 0; offset < bytes_per_pixel; offset++) {
                left    = *(pixels + (x * bytes_per_pixel) + ydx + offset);
                *(pixels + (x * bytes_per_pixel) + ydx + offset)           = *(pixels + ((width - x) * bytes_per_pixel) + ydx + offset);
                *(pixels + ((width - x) * bytes_per_pixel) + ydx + offset) = left;
            }
        }
    }
}

// Vertically flip blit graphics data
void c_flip_vertical(char *pixels, short width, short height, unsigned char bytes_per_pixel) {
    unsigned int bufsize = width * bytes_per_pixel;        // Bytes per line
    unsigned char *row  = malloc(bufsize);                 // Allocate a temporary buffer
    unsigned char *low  = pixels;                         // Pointer to the beginning of the image
    unsigned char *high = &pixels[(height - 1) * bufsize]; // Pointer to the last line in the image

    for (; low < high; low += bufsize, high -= bufsize) { // Stop when you reach the middle
          memcpy(row,low,bufsize);    // Make a copy of the lower line
          memcpy(low,high,bufsize);   // Copy the upper line to the lower
          memcpy(high, row, bufsize); // Copy the saved copy to the upper line
    }
    free(row); // Release the temporary buffer
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
    unsigned int loc16 = 0;
    unsigned int loc24 = 0;
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
        unsigned char r5 = ( r8 * 249 + 1014 ) >> 11;
        unsigned char g6 = ( g8 * 253 + 505  ) >> 10;
        unsigned char b5 = ( b8 * 249 + 1014 ) >> 11;
        if (color_order == RGB) {
            rgb565 = (b5 << 11) | (g6 << 5) | r5;
        } else {
            rgb565 = (r5 << 11) | (g6 << 5) | b5;
        }
        *((unsigned short*)(buf16 + loc16)) = rgb565;
        loc16 += 2;
    }
}

// Convert a RGB8888 bitmap to a RGB888 bitmap
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

// Convert a RGB888 bitmap to a RGB8888 bitmap
void c_convert_24_32(char* buf24, unsigned int size24, char* buf32, unsigned char color_order) {
    unsigned int loc32 = 0;
    unsigned int loc24 = 0;
    while(loc24 < size24) {
        unsigned char r = *(buf24 + loc24++);
        unsigned char g = *(buf24 + loc24++);
        unsigned char b = *(buf24 + loc24++);
        *((unsigned int*)(buf32 + loc32++)) = r | (g << 8) | (b << 16);
        loc32 += 3;
        if (r == 0 && g == 0 && b == 0) {
            *(buf32 + loc32++) = 0; // The background is transparent
        } else {
            *(buf32 + loc32++) = 255; // The foreground is opague
        }
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

    for (idx = 0; idx < size; idx += bytes_per_pixel) {
        switch (bits_per_pixel) {
		    case 32 :
                switch(color_order) {
                    case RBG :  // RBG
                        r = *(pixels + idx);
				        b = *(pixels + idx + 1);
                        g = *(pixels + idx + 2);
                        break;
                    case BGR :  // BGR
                        b = *(pixels + idx);
                        g = *(pixels + idx + 1);
                        r = *(pixels + idx + 2);
                        break;
                    case BRG :  // BRG
                        b = *(pixels + idx);
                        r = *(pixels + idx + 1);
                        g = *(pixels + idx + 2);
                        break;
                    case GBR :  // GBR
                        g = *(pixels + idx);
                        b = *(pixels + idx + 1);
                        r = *(pixels + idx + 2);
                        break;
                    case GRB :  // GRB
                        g = *(pixels + idx);
                        r = *(pixels + idx + 1);
                        b = *(pixels + idx + 2);
                        break;
                    default : // RGB
                        r = *(pixels + idx);
                        g = *(pixels + idx + 1);
                        b = *(pixels + idx + 2);
				        break;
                }
		        break;
		    case 24 :
                switch(color_order) {
                    case RBG :  // RBG
                        r = *(pixels + idx);
				        b = *(pixels + idx + 1);
                        g = *(pixels + idx + 2);
                        break;
                    case BGR :  // BGR
                        b = *(pixels + idx);
                        g = *(pixels + idx + 1);
                        r = *(pixels + idx + 2);
                        break;
                    case BRG :  // BRG
                        b = *(pixels + idx);
                        r = *(pixels + idx + 1);
                        g = *(pixels + idx + 2);
                        break;
                    case GBR :  // GBR
                        g = *(pixels + idx);
                        b = *(pixels + idx + 1);
                        r = *(pixels + idx + 2);
                        break;
                    case GRB :  // GRB
                        g = *(pixels + idx);
                        r = *(pixels + idx + 1);
                        b = *(pixels + idx + 2);
                        break;
                    default : // RGB
                        r = *(pixels + idx);
                        g = *(pixels + idx + 1);
                        b = *(pixels + idx + 2);
				        break;
                }
		        break;
		    case 16 :
                rgb565 = *((unsigned short*)(pixels + idx));
                g      = (rgb565 >> 6) & 31;
                if (color_order == 0) { // RGB
                    r = rgb565 & 31;
                    b = (rgb565 >> 11) & 31;
                } else {                // BGR
                    b = rgb565 & 31;
                    r = (rgb565 >> 11) & 31;
                }
		        break;
		    case 8 :
		        break;
		    case 1 :
		        break;
		}
	   
        m = (unsigned char) round(0.2126 * r + 0.7152 * g + 0.0722 * b);

        switch(bits_per_pixel) {
            case 32 :
                if (m == 0)  {
                    *((unsigned int*)(pixels + idx)) = m | (m << 8) | (m << 16);
                } else {
                    *((unsigned int*)(pixels + idx)) = m | (m << 8) | (m << 16) | 0xFF000000;
                }
                break;
            case 24 :
                *(pixels + idx)     = m;
                *(pixels + idx + 1) = m;
                *(pixels + idx + 2) = m;
                break;
            case 16 :
                rgb565                             = 0;
                rgb565                             = (m << 11) | (m << 6) | m;
                *((unsigned short*)(pixels + idx)) = rgb565;
                break;
		    case 8 :
		        break;
		    case 1 :
		        break;
        }
    }
}
