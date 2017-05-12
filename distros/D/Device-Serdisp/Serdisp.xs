#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <serdisplib/serdisp.h>

#include <gd.h>
#include <gdfontt.h>
#include <gdfonts.h>
#include <gdfontmb.h>
#include <gdfontl.h>
#include <gdfontg.h>

#include "ppport.h"

typedef struct {

   serdisp_CONN_t	*	sdcd;
	serdisp_t		*	dd;
	int					invers;
	char				*	connection;
	char				*	display;
	char				*	options;

} Serdisp;

Serdisp*
new_serdisp(char *connection, char *display, char *options)
{
    Serdisp *serdisp		= malloc(sizeof(Serdisp));
    serdisp->connection		= savepv(connection);
    serdisp->display		= savepv(display);
    serdisp->options		= savepv(options);
    serdisp->invers		= 0;
    return serdisp;
}

int
init(Serdisp *serdisp)
{
	serdisp->sdcd = SDCONN_open(serdisp->connection);

	if (serdisp->sdcd == (serdisp_CONN_t*)0)
	{
		Perl_croak(aTHX_ "Error opening %s, additional info: %s", serdisp->connection, sd_geterrormsg());
	}

	/* opening and initialising the display */
	serdisp->dd = serdisp_init(serdisp->sdcd, serdisp->display, serdisp->options);

	if (!serdisp->dd)
	{
		SDCONN_close(serdisp->sdcd);
		Perl_croak(aTHX_ "Error opening display %s, additional info: %s", serdisp->display, sd_geterrormsg());
	}

	/* turning on backlight */
	serdisp_setoption(serdisp->dd, "BACKLIGHT", SD_OPTION_YES);

	/* clearing the display */
	serdisp_clear(serdisp->dd);

	return 1;
}

int
width(Serdisp *serdisp)
{
	return serdisp_getwidth(serdisp->dd);
}

int
height(Serdisp *serdisp)
{
	return serdisp_getheight(serdisp->dd);
}

#define min(a,b) ((a)<(b))?(a):(b)
#define GET_COLOR_VALUE(d)        ((d)->invers ? SD_COL_WHITE : SD_COL_BLACK)
#define GET_COLOR_VALUE_INVERS(d) ((d)->invers ? SD_COL_BLACK : SD_COL_WHITE)

int
copyGD(Serdisp *serdisp, gdImagePtr image)
{
	int max_x = min(gdImageSX(image), serdisp_getwidth(serdisp->dd));
	int max_y = min(gdImageSY(image), serdisp_getheight(serdisp->dd));

	int x,y;

	for (y = 0; y < max_y; y++)
	{
		for (x = 0; x < max_x; x++)
		{
			int color = gdImageGetPixel(image, x, y);

			//	set the pixel in the display if the color is non black
			int set_pixel_in_display =
					gdImageRed	(image, color)
				||	gdImageGreen(image, color)
				||	gdImageBlue	(image, color);

	      serdisp_setcolour(
	       	serdisp->dd,
	       	x, y,
	       	set_pixel_in_display
	       		?	GET_COLOR_VALUE(serdisp)
	 	      	:	GET_COLOR_VALUE_INVERS(serdisp)
	       );
		}
	}
	serdisp_update(serdisp->dd);
	
	return 1;
}

void
clear(Serdisp *serdisp)
{
	serdisp_clear(serdisp->dd);
}

int
update(Serdisp *serdisp)
{
	serdisp_update(serdisp->dd);
	
	return 1;
}

void
delete_display(Serdisp *serdisp) {

	/* shutdown display and release device*/
	serdisp_quit(serdisp->dd);
	free(serdisp);
}

void
set_option(Serdisp *serdisp, char *option, long value) {

	/* change option */
	serdisp_setoption(serdisp->dd,savepv(option),value);
}

long
get_option(Serdisp *serdisp, char *option) {

	/* get option */
	int temp = 0;
	return serdisp_getoption(serdisp->dd,savepv(option),&temp);
}

MODULE = Device::Serdisp		PACKAGE = Device::Serdisp

Serdisp *
new (CLASS, connection, display, options="")
		char *CLASS
		char *connection
		char *display
		char *options
	CODE:
		RETVAL = new_serdisp(connection, display, options);
	OUTPUT:
		RETVAL

int
init (serdisp)
    Serdisp*   serdisp

int
width (serdisp)
    Serdisp*   serdisp

int
height (serdisp)
    Serdisp*   serdisp

int
copyGD(serdisp, image)
	Serdisp*		serdisp
	gdImagePtr		image

int
update(serdisp)
    Serdisp*   serdisp

void
clear(serdisp)
    Serdisp*   serdisp

void
DESTROY(serdisp)
    Serdisp *serdisp
  CODE:
    delete_display(serdisp); /* deallocate that object */

void
set_option(serdisp,option,value)
    Serdisp*   serdisp
    char*      option
    long      value

long
get_option(serdisp,option)
    Serdisp*   serdisp
    char*      option
