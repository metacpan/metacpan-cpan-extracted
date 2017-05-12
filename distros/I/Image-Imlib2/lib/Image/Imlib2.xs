#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <Imlib2.h>
#include <stdio.h>
#include <string.h>

typedef Imlib_Image Image__Imlib2;
typedef ImlibPolygon Image__Imlib2__Polygon;
typedef Imlib_Color_Range Image__Imlib2__ColorRange;

bool colours_equal(Imlib_Color col1, Imlib_Color col2) {
  return col1.red   == col2.red   &&
         col1.green == col2.green &&
         col1.blue  == col2.blue;
}

static double
TEXT_TO_RIGHT(void)
{
   return IMLIB_TEXT_TO_RIGHT;
}

static double
TEXT_TO_LEFT(void)
{
   return IMLIB_TEXT_TO_LEFT;
}

static double
TEXT_TO_UP(void)
{
   return IMLIB_TEXT_TO_UP;
}

static double
TEXT_TO_DOWN(void)
{
   return IMLIB_TEXT_TO_DOWN;
}

static double
TEXT_TO_ANGLE(void)
{
   return IMLIB_TEXT_TO_ANGLE;
}

MODULE = Image::Imlib2          PACKAGE = Image::Imlib2

double
TEXT_TO_RIGHT()

double
TEXT_TO_LEFT()

double
TEXT_TO_UP()

double
TEXT_TO_DOWN()

double
TEXT_TO_ANGLE()

MODULE = Image::Imlib2		PACKAGE = Image::Imlib2		PREFIX= Imlib2_

Image::Imlib2
Imlib2_new(packname="Image::Imlib2", x=256, y=256)
        char * packname
	int x
	int y

	PROTOTYPE: $;$$

        CODE:
	{
		Imlib_Image image;

		image = imlib_create_image(x, y);

		imlib_context_set_image(image);
		imlib_image_set_has_alpha(1);

		RETVAL = image;
	}
        OUTPUT:
	        RETVAL

Image::Imlib2
Imlib2__new_using_data(packname="Image::Imlib2", x=256, y=256, data)
        char * packname
	int x
	int y
        DATA32 * data
 
	PROTOTYPE: $;$$$
 
        CODE:
	{
		Imlib_Image image;
 
		image = imlib_create_image_using_copied_data(x, y, data);
 
		imlib_context_set_image(image);
		imlib_image_set_has_alpha(1);

		RETVAL = image;
	}
        OUTPUT:
	        RETVAL


char
Imlib2_will_blend(packname="Image::Imlib2", ...)
        char * packname

        PREINIT: 
        char   value;
        
        PROTOTYPE: $;$

        CODE:
	{
		if (items > 1) {
		  value =  SvTRUE(ST(1))?1:0;
		  imlib_context_set_blend(value);
		}

		RETVAL = imlib_context_get_blend();
	}

        OUTPUT:
                RETVAL




void
Imlib2_DESTROY(image)
	Image::Imlib2	image

	PROTOTYPE: $

	CODE:
	{
		imlib_context_set_image(image);

		imlib_free_image();
	}



Image::Imlib2
Imlib2_load(packname="Image::Imlib2", filename)
        char * packname
	char * filename

	PROTOTYPE: $$

        CODE:
	{
		Imlib_Image image;
                Imlib_Load_Error err;

                image = imlib_load_image_with_error_return (filename, &err);
                if (err == IMLIB_LOAD_ERROR_FILE_DOES_NOT_EXIST) {
                  Perl_croak(aTHX_ "Image::Imlib2 load error: File does not exist");
                } 

                if (err == IMLIB_LOAD_ERROR_FILE_IS_DIRECTORY) {
                  Perl_croak(aTHX_ "Image::Imlib2 load error: File is directory");
                } 

                if (err == IMLIB_LOAD_ERROR_PERMISSION_DENIED_TO_READ) {
                  Perl_croak(aTHX_ "Image::Imlib2 load error: Permission denied");
                } 

                if (err == IMLIB_LOAD_ERROR_NO_LOADER_FOR_FILE_FORMAT) {
                  Perl_croak(aTHX_ "Image::Imlib2 load error: No loader for file format");
                }
		RETVAL = image;
	}
        OUTPUT:
	        RETVAL


void
Imlib2_save(image, filename)
	Image::Imlib2	image
	char * filename

	PROTOTYPE: $$

        CODE:
	{
                Imlib_Load_Error err;

		imlib_context_set_image(image);
		imlib_save_image_with_error_return(filename, &err);

                if (err != IMLIB_LOAD_ERROR_NONE) {
                  Perl_croak(aTHX_ "Image::Imlib2 save error: Unknown error");
                }
	}




int
Imlib2_get_width(image)
	Image::Imlib2	image

        PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);

		RETVAL = imlib_image_get_width();
	}

        OUTPUT:
                RETVAL


int
Imlib2_width(image)
	Image::Imlib2	image

        PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);

		RETVAL = imlib_image_get_width();
	}

        OUTPUT:
                RETVAL


int
Imlib2_get_height(image)
	Image::Imlib2	image

        PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);

		RETVAL = imlib_image_get_height();
	}

        OUTPUT:
                RETVAL


int
Imlib2_height(image)
	Image::Imlib2	image

        PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);

		RETVAL = imlib_image_get_height();
	}

        OUTPUT:
                RETVAL


void
Imlib2_set_color(image, r, g, b, a)
	Image::Imlib2	image
	int	r
	int 	g
	int 	b
	int 	a

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_context_set_color(r, g, b, a);
	}


void
Imlib2_set_colour(image, r, g, b, a)
	Image::Imlib2	image
	int	r
	int 	g
	int 	b
	int 	a

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_context_set_color(r, g, b, a);
	}


void
Imlib2_draw_point(image, x, y)
	Image::Imlib2	image
	int	x
	int 	y

	PROTOTYPE: $$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_draw_pixel(x, y, 0);
	}


void
Imlib2_draw_line(image, x1, y1, x2, y2)
	Image::Imlib2	image
	int	x1
	int 	y1
	int 	x2
	int 	y2

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_draw_line(x1, y1, x2, y2, 0);
	}

void
Imlib2_query_pixel(image, x, y)
	Image::Imlib2	image
	int 	x
	int 	y

	PROTOTYPE: $$

	PREINIT:
		Imlib_Color color_return;

   PPCODE:
		imlib_context_set_image(image);
		
		imlib_image_query_pixel(x, y, &color_return);
        XPUSHs(sv_2mortal(newSViv(color_return.red)));
        XPUSHs(sv_2mortal(newSViv(color_return.green)));
        XPUSHs(sv_2mortal(newSViv(color_return.blue)));
        XPUSHs(sv_2mortal(newSViv(color_return.alpha)));

void
Imlib2_autocrop_dimensions(image)
	Image::Imlib2	image

	PROTOTYPE: $$

	PREINIT:
		Imlib_Color c, bg, tl, tr, bl, br;
                int width, height;
                int cx = 0;
                int cy = 0;
                int cw, ch;
                int x1, y1, x2, y2;
                int i;
                bool abort;

        PPCODE:
		imlib_context_set_image(image);
		width = imlib_image_get_width();
		height = imlib_image_get_height();
                cw = width;
                ch = height;

                /* guess the background colour
                   algorithm from gimp's autocrop.c, originally pinched from
                   pnmcrop: first see if three corners are equal, then if two are equal,
                   otherwise give up */
		imlib_image_query_pixel(0, 0, &tl);
		imlib_image_query_pixel(width - 1, 0, &tr);
		imlib_image_query_pixel(0, height - 1, &bl);
		imlib_image_query_pixel(width -1 , height - 1, &br);

                if (colours_equal(tr, bl) && colours_equal(tr, br)) {
                   bg = tr;
                } else if (colours_equal(tl, bl) && colours_equal(tl, br)) {
                   bg = tl;
                } else if (colours_equal(tl, tr) && colours_equal(tl, br)) {
                   bg = tl;
                } else if (colours_equal(tl, tr) && colours_equal(tl, bl)) {
                   bg = tl;
                } else if (colours_equal(tl, tr) || colours_equal(tl, bl) || colours_equal(tl, br)) {
                   bg = tl;
                } else if (colours_equal(tr, bl) || colours_equal(tr, bl)) {
                   bg = tr;
                } else if (colours_equal(br, bl)) {
                   bg = br;
                } else {
                   /* all different? give up */
                  XPUSHs(sv_2mortal(newSViv(cx)));
                  XPUSHs(sv_2mortal(newSViv(cy)));
                  XPUSHs(sv_2mortal(newSViv(cw)));
                  XPUSHs(sv_2mortal(newSViv(ch)));
                  return;
                }

                /* warn ("Have background colour: %i, %i, %i", bg.red, bg.green, bg.blue); */

                /* check how many of the bottom lines are uniform */
                abort = FALSE;
                for (y2 = height - 1; y2 >= 0 && !abort; y2--) {
                  for (i = 0; i < width && !abort; i++) {
                    imlib_image_query_pixel(i, y2, &c);
                    abort = !colours_equal (c, bg);
                  }
                }

                /* warn("x1 %i, y1 %i, x2 %i, y2 %i", x1, y1, x2, y2); */

                if (y2 == -1) {
                  /* plain colour */
                  XPUSHs(sv_2mortal(newSViv(cx)));
                  XPUSHs(sv_2mortal(newSViv(cy)));
                  XPUSHs(sv_2mortal(newSViv(cw)));
                  XPUSHs(sv_2mortal(newSViv(ch)));
				  return;
                }

				/* since now we don't need to check for the upper boundary 
				of the outer loops as there is at least one pixel of different colour */

                /* check how many of the top lines are uniform */
                abort = FALSE;
                for (y1 = 0; !abort; y1++) {
                  for (i = 0; i < width && !abort; i++) {
                    imlib_image_query_pixel(i, y1, &c);
                    abort = !colours_equal (c, bg);
                    }
                }                                 

                y2 += 1; /* to make y2 - y1 == height */

                /* warn("x1 %i, y1 %i, x2 %i, y2 %i", x1, y1, x2, y2); */

                /* the coordinates are now the first rows which DON'T match
                * the colour - crop instead to one row larger:
                */
                if (y1 > 0) --y1;
                if (y2 < height-1) ++y2;

                /* check how many of the left lines are uniform */
                abort = FALSE;
                for (x1 = 0; !abort; x1++) {
                  for (i = y1; i < y2 && !abort; i++) {
                    imlib_image_query_pixel(x1, i, &c);
                    abort = !colours_equal (c, bg);
                  }
                }

                /* warn("x1 %i, y1 %i, x2 %i, y2 %i", x1, y1, x2, y2); */

                /* check how many of the right lines are uniform */
                abort = FALSE;
                for (x2 = width - 1; !abort; x2--) {
                  for (i = y1; i < y2 && !abort; i++) {
                    imlib_image_query_pixel(x2, i, &c);
                    abort = !colours_equal (c, bg);
                  }
                }

                x2 += 1; /* to make x2 - x1 == width */

                /* the coordinates are now the first columns which DON'T match
                 * the color - crop instead to one column larger:
                 */
                if (x1 > 0) --x1;
                if (x2 < width-1) ++x2;

                /* warn("x1 %i, y1 %i, x2 %i, y2 %i", x1, y1, x2, y2); */
                
                cx = x1;
                cy = y1;
                cw = x2 - x1;
                ch = y2 - y1;
  
                XPUSHs(sv_2mortal(newSViv(cx)));
                XPUSHs(sv_2mortal(newSViv(cy)));
                XPUSHs(sv_2mortal(newSViv(cw)));
                XPUSHs(sv_2mortal(newSViv(ch)));

void
Imlib2_find_colour(image)
	Image::Imlib2	image

	PROTOTYPE: $$

	PREINIT:
		Imlib_Color c;
                int r, g, b, a;
                int width, height;
                int x = 0;
                int y = 0;
                bool abort;

        PPCODE:
		imlib_context_set_image(image);
		width = imlib_image_get_width();
		height = imlib_image_get_height();
                imlib_context_get_color(&r, &g, &b, &a);
//                warn("pr = %i, pg = %i, pb = %i", r, g, b);

                abort = FALSE;
                for (y = 0; y < height && !abort; y++) {
                  for (x = 0; x < width && !abort; x++) {
                    imlib_image_query_pixel(x, y, &c);
                    abort = c.red == r && c.green == g && c.blue == b;
                    }
                }                                 

                if (abort) {
                  XPUSHs(sv_2mortal(newSViv(x)));
                  XPUSHs(sv_2mortal(newSViv(y)));
                } else {
                  XPUSHs(newSV(0));
                  XPUSHs(newSV(0));
                }

void
Imlib2_fill(image, x, y, newimage=NULL)
	Image::Imlib2	image
        Image::Imlib2   newimage
	int	x
	int 	y

	PROTOTYPE: $$$$;$

	PREINIT:
		Imlib_Color c;
                int r, g, b, a;
                int or, og, ob, oa;
                int width, height, px, py, west, east;
                AV* coords;
                SV* sv;
                int length;
                bool abort;

        PPCODE:
		imlib_context_set_image(image);
		width = imlib_image_get_width();
		height = imlib_image_get_height();

                imlib_image_query_pixel(x, y, &c);
                or = c.red; og = c.green; ob = c.blue;

                imlib_context_get_color(&r, &g, &b, &a);
//                warn("pr = %i, pg = %i, pb = %i", r, g, b);

                coords = newAV();
                av_push(coords, newSViv(x));
                av_push(coords, newSViv(y));

                while (av_len(coords) != -1) {

                      length = av_len(coords);
//                      warn("length %i", length);
                
                      sv = av_shift(coords);
                      x = SvIVX(sv);
                      sv_free(sv);
                      sv = av_shift(coords);
                      y = SvIVX(sv);
                      sv_free(sv);
                      imlib_image_query_pixel(x, y, &c);

                      if ((c.red == or && c.green == og && c.blue == ob)) {

                      if (newimage != NULL) {
                         imlib_context_set_image(newimage);
                         imlib_context_set_color(r, g, b, a);
                         imlib_image_draw_pixel(x, y, 0);                         
                         imlib_context_set_image(image);                         
                      }
                      imlib_image_draw_pixel(x, y, 0);

                      west = x;
                      east = x;

                      abort = FALSE;
                      while (!abort) {
                          west -= 1;
                          imlib_image_query_pixel(west, y, &c);
                          abort = (west == 0
                            || !(c.red == or && c.green == og && c.blue == ob)
                          );
                      }
                      
                      abort = FALSE;
                      while (!abort) {
                          east += 1;
                          imlib_image_query_pixel(east, y, &c);
                          abort = (east == width
                            || !(c.red == or && c.green == og && c.blue == ob)
                          );
                      }
//                      warn("  %i-%i, %i", west, east, y);

                      for (px = west; px <= east; px++) {
                          if (newimage != NULL) {
                             imlib_context_set_image(newimage);
                             imlib_image_draw_pixel(px, y, 0);                         
                             imlib_context_set_image(image);                         
                          }
                          imlib_image_draw_pixel(px, y, 0);

                          py = y - 1;
                          imlib_image_query_pixel(px, py, &c);
                          if (py > 0 
                              && (c.red == or && c.green == og && c.blue == ob)
                          ) {
//                                warn("  ^ %i, %i", px, py);
                              av_push(coords, newSViv(px));
                              av_push(coords, newSViv(py));
                          }

                          py = y + 1;
                          imlib_image_query_pixel(px, py, &c);
                          if (py < height
                              && (c.red == or && c.green == og && c.blue == ob)
                          ) {
//                                warn("  v %i, %i", px, py);
                              av_push(coords, newSViv(px));
                              av_push(coords, newSViv(py));
                          }
                      }
                      }
                }
                av_undef(coords);


void
Imlib2_draw_rectangle(image, x, y, w, h)
	Image::Imlib2	image
	int	x
	int 	y
	int 	w
	int 	h

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_draw_rectangle(x, y, w, h);
	}


void
Imlib2_fill_rectangle(image, x, y, w, h)
	Image::Imlib2	image
	int	x
	int 	y
	int 	w
	int 	h

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_fill_rectangle(x, y, w, h);
	}


void
Imlib2_draw_ellipse(image, x, y, w, h)
	Image::Imlib2	image
	int	x
	int 	y
	int 	w
	int 	h

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_draw_ellipse(x, y, w, h);
	}


void
Imlib2_fill_ellipse(image, x, y, w, h)
	Image::Imlib2	image
	int	x
	int 	y
	int 	w
	int 	h

	PROTOTYPE: $$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_fill_ellipse(x, y, w, h);
	}




void
Imlib2_add_font_path(image, directory)
	Image::Imlib2	image
	char * directory

	PROTOTYPE: $$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_add_path_to_font_path(directory);
	}


void
Imlib2_load_font(image, fontname)
	Image::Imlib2	image
	char * fontname

	PROTOTYPE: $$

        CODE:
	{
		Imlib_Font font;

		imlib_context_set_image(image);

		font = imlib_load_font(fontname);
		imlib_context_set_font(font);
	}


void
Imlib2_get_text_size(image, text, direction=IMLIB_TEXT_TO_RIGHT, angle=0)
	Image::Imlib2	image
	char * 	text
        int direction
        double  angle

        PROTOTYPE: $$

	PREINIT:
		int text_w;
		int text_h;

        PPCODE:
		imlib_context_set_image(image);
                imlib_context_set_direction(direction);
                imlib_context_set_angle(angle);

		imlib_get_text_size(text, &text_w, &text_h);

		XPUSHs(sv_2mortal(newSViv(text_w)));
		XPUSHs(sv_2mortal(newSViv(text_h)));


void
Imlib2_draw_text(image, x, y, text, direction=IMLIB_TEXT_TO_RIGHT, angle=0)
	Image::Imlib2	image
	int	x
	int 	y
	char * 	text
        int direction
        double  angle

	PROTOTYPE: $$$$;$$

        CODE:
	{
		imlib_context_set_image(image);
                imlib_context_set_direction(direction);
                imlib_context_set_angle(angle);

		imlib_text_draw(x, y, text);
	}


Image::Imlib2
Imlib2_crop(image, x, y, w, h)
	Image::Imlib2	image
	int x
	int y
	int w
	int h

	PROTOTYPE: $$$$$

        CODE:
	{
		Imlib_Image cropped;

		imlib_context_set_image(image);

		cropped = imlib_create_cropped_image(x, y, w, h);
		RETVAL = cropped;
	}
        OUTPUT:
	        RETVAL



void
Imlib2_blend(image, source, alpha, x, y, w, h, d_x, d_y, d_w, d_h)
	Image::Imlib2	image
	Image::Imlib2	source
	int alpha
	int x
	int y
	int w
	int h
	int d_x
	int d_y
	int d_w
	int d_h

	PROTOTYPE: $$$$$$$$$$$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_blend_image_onto_image(source, alpha, x, y, w, h, d_x, d_y, d_w, d_h);
	}


void 
Imlib2_blur(image, radius)
	Image::Imlib2	image
	int	radius

	PROTOTYPE: $$

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_blur(radius);
	}


void 
Imlib2_sharpen(image, radius)
	Image::Imlib2	image
	int	radius

	PROTOTYPE: $$

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_sharpen(radius);
	}


Image::Imlib2 
Imlib2_clone(image)
	Image::Imlib2	image

	PROTOTYPE: $

        CODE:
	{
		Imlib_Image cloned;
		
		imlib_context_set_image(image);
		cloned = imlib_clone_image();
		
		RETVAL = cloned;
	}
        OUTPUT:
	        RETVAL	


void
Imlib2_draw_polygon(image, poly, closed)
        Image::Imlib2  image
        Image::Imlib2::Polygon  poly
        unsigned char closed

        PROTOTYPE: $$$

        CODE:
        {
		imlib_context_set_image(image);

                imlib_image_draw_polygon(poly,closed);
        }

void Imlib2_fill_color_range_rectangle(image, cr, x, y, width, height, angle)
        Image::Imlib2  image
        Image::Imlib2::ColorRange cr
        int x
        int y
        int width
        int height
        double angle

        PROTOTYPE: $$$$$$

        CODE:
        {
                Imlib_Color_Range oldcr;

		imlib_context_set_image(image);
                oldcr = imlib_context_get_color_range();
                imlib_context_set_color_range(cr);
                imlib_image_fill_color_range_rectangle(x,y,width,height,angle);
                imlib_context_set_color_range(oldcr);
        }


void Imlib2_image_orientate(image, steps)
	Image::Imlib2	image
	int	steps

	PROTOTYPE: $$

        CODE:
	{
		imlib_context_set_image(image);

		imlib_image_orientate(steps);
	}

void Imlib2_image_set_format(image, format)
  Image::Imlib2  image
  char *   format
  PROTOTYPE: $$
        CODE:
  {
     imlib_context_set_image(image);
     imlib_image_set_format(format);
  }

Image::Imlib2 Imlib2_create_scaled_image(image, dw, dh)
        Image::Imlib2	image
	int dw
	int dh

	PROTOTYPE: $$$

        CODE:
	{
		Imlib_Image dstimage;
		int sw, sh;

		imlib_context_set_image(image);
		sw = imlib_image_get_width();
		sh = imlib_image_get_height();

		if ( dw == 0 ) {
			dw = (int) (((double) dh * sw) / sh);
		}
		if ( dh == 0 ) {
			dh = (int) (((double) dw * sh) / sw);
		}

		dstimage = imlib_create_cropped_scaled_image(0, 0, sw, sh, dw, dh);

		RETVAL = dstimage;
	}
        OUTPUT:
	        RETVAL

Image::Imlib2 Imlib2_set_quality(image, qual)
        Image::Imlib2	image
	int qual

	PROTOTYPE: $$

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_attach_data_value("quality",NULL,qual,NULL);
	}

Image::Imlib2 Imlib2_flip_horizontal(image)
        Image::Imlib2	image

	PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_flip_horizontal();
	}

Image::Imlib2 Imlib2_flip_vertical(image)
        Image::Imlib2	image

	PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_flip_vertical();
	}

Image::Imlib2 Imlib2_flip_diagonal(image)
        Image::Imlib2	image

	PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);
		imlib_image_flip_diagonal();
	}


int
Imlib2_has_alpha(image, ...)
	Image::Imlib2	image

        PREINIT: 
        char   value;
        
        PROTOTYPE: $;$

        CODE:
	{
		imlib_context_set_image(image);

		if (items > 1) {
		  value =  SvTRUE(ST(1))?1:0;
		  imlib_image_set_has_alpha(value);
		}

		RETVAL = imlib_image_has_alpha();
	}

        OUTPUT:
                RETVAL

void
Imlib2_set_cache_size(packname="Image::Imlib2", size)
        char * packname
        int size
        
        PROTOTYPE: $$

        CODE:
	{
                imlib_set_cache_size(size);
	}


int
Imlib2_get_cache_size(packname="Image::Imlib2")
        char * packname
        
        PROTOTYPE: $

        CODE:
	{
                RETVAL = imlib_get_cache_size();
	}
	OUTPUT:
	        RETVAL

void
Imlib2_set_changes_on_disk(image)
	Image::Imlib2	image
        
        PROTOTYPE: $

        CODE:
	{
		imlib_context_set_image(image);
                imlib_image_set_changes_on_disk();
	}


Image::Imlib2
Imlib2_create_transparent_image(source, alpha)
        Image::Imlib2 source
        int alpha

        PROTOTYPE: $$

	PREINIT:
		Imlib_Image destination;
		Imlib_Color color_return;
                int x, y, w, h;

        CODE:
        {
		imlib_context_set_image(source);
		w = imlib_image_get_width();
		h = imlib_image_get_height();

                destination = imlib_create_image(w, h);
		imlib_context_set_image(destination);
		imlib_image_set_has_alpha(1);

                for (y = 0; y < h; y++) {
                  for (x = 0; x < w; x++)  {
           	    imlib_context_set_image(source);
                    imlib_image_query_pixel(x, y, &color_return);
                    imlib_context_set_color(color_return.red, color_return.green, color_return.blue, alpha);
		    imlib_context_set_image(destination);                    
		    imlib_image_draw_pixel(x, y, 0);
                  }
                }
		RETVAL = destination;
	}
        OUTPUT:
	        RETVAL


Image::Imlib2
Imlib2_create_blended_image(source1, source2, pc)
        Image::Imlib2 source1
        Image::Imlib2 source2
        int pc

        PROTOTYPE: $$

	PREINIT:
		Imlib_Image destination;
		Imlib_Color color1, color2;
                int x, y, w, h;
                int npc;

        CODE:
        {
                npc = 100 - pc;
		imlib_context_set_image(source1);
		w = imlib_image_get_width();
		h = imlib_image_get_height();

                destination = imlib_create_image(w, h);
		imlib_context_set_image(destination);

                for (y = 0; y < h; y++) {
                  for (x = 0; x < w; x++)  {
           	    imlib_context_set_image(source1);
                    imlib_image_query_pixel(x, y, &color1);
           	    imlib_context_set_image(source2);
                    imlib_image_query_pixel(x, y, &color2);
		    imlib_context_set_image(destination);                    
                    imlib_context_set_color((color1.red * pc + color2.red * npc)/100, (color1.green * pc + color2.green * npc)/100, (color1.blue * pc + color2.blue * npc)/100, 255);
		    imlib_image_draw_line(x, y, x, y, 0);
                  }
                }
		RETVAL = destination;
	}
        OUTPUT:
	        RETVAL

Image::Imlib2
Imlib2_create_rotated_image(source, angle)
	Image::Imlib2 source
	double angle
	CODE:
		imlib_context_set_image(source);
		RETVAL = imlib_create_rotated_image(angle);
	OUTPUT:
		RETVAL

MODULE = Image::Imlib2	PACKAGE = Image::Imlib2::Polygon	PREFIX= Imlib2_Polygon_

Image::Imlib2::Polygon
Imlib2_Polygon_new(packname="Image::Imlib2::Polygon")
        char * packname

	PROTOTYPE: $

        CODE:
	{
		ImlibPolygon poly;

		poly = imlib_polygon_new();
		RETVAL = poly;
	}
        OUTPUT:
	        RETVAL


void
Imlib2_Polygon_DESTROY(poly)
        Image::Imlib2::Polygon  poly

        PROTOTYPE: $

        CODE:
        {
                imlib_polygon_free(poly);
        }


void
Imlib2_Polygon_add_point(poly, x, y)
	Image::Imlib2::Polygon	poly
	int x
	int y

	PROTOTYPE: $$$

        CODE:
	{
                imlib_polygon_add_point(poly,x,y);
	}


void
Imlib2_Polygon_fill(poly)
        Image::Imlib2::Polygon  poly

        PROTOTYPE: $

        CODE:
        {
                imlib_image_fill_polygon(poly);
        }


MODULE = Image::Imlib2	PACKAGE = Image::Imlib2::ColorRange	PREFIX= Imlib2_ColorRange_

Image::Imlib2::ColorRange
Imlib2_ColorRange_new(packname="Image::Imlib2::ColorRange")
        char * packname

        PROTOTYPE: $

        CODE:
        {
                Imlib_Color_Range cr;

                cr = imlib_create_color_range();
                RETVAL = cr;
        }
        OUTPUT:
                RETVAL

void Imlib2_ColorRange_DESTROY(cr)
        Image::Imlib2::ColorRange cr

        PROTOTYPE: $

        CODE:
        {
                Imlib_Color_Range oldcr;
                oldcr = imlib_context_get_color_range();
                imlib_context_set_color_range(cr);
                imlib_free_color_range();
                imlib_context_set_color_range(oldcr);
        }

void Imlib2_ColorRange_add_color(cr, d, r, g, b, a)
        Image::Imlib2::ColorRange cr
        int d
        int r
        int g
        int b
        int a

        PROTOTYPE: $$

        CODE:
        {
                Imlib_Color_Range oldcr;
                oldcr = imlib_context_get_color_range();
                imlib_context_set_color_range(cr);
                imlib_context_set_color(r,b,g,a);
                imlib_add_color_to_color_range(d);
                imlib_context_set_color_range(oldcr);
        }

