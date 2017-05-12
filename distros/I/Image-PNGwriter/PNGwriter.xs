#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "fallback/const-c.inc"

#ifdef __cplusplus
}
#endif

#include <pngwriter.h>
MODULE = Image::PNGwriter		PACKAGE = Image::PNGwriter		

PROTOTYPES: ENABLE

pngwriter *
pngwriter::new(int width, int height, double backgroundcolour, char * filename);

void
pngwriter::plot(int x, int y, double red, double green, double blue); 
						  
void
pngwriter::plotHSV(int x, int y, double hue, double saturation, double value);

void
pngwriter::plotCMYK(int x, int y, double cyan, double magenta, double yellow, double black);

double
pngwriter::dread(int x, int y, int colour);

double
pngwriter::dreadHSV(int x, int y, int colour);    

double
pngwriter::dreadCMYK(int x, int y, int colour);

void
pngwriter::clear();    

void
pngwriter::close(); 

void
pngwriter::pngwriter_rename(char * newname);

void
pngwriter::line(int xfrom, int yfrom, int xto, int yto, double red, double green,double  blue);

void
pngwriter::triangle(int x1, int y1, int x2, int y2, int x3, int y3, double red, double green, double blue);

void
pngwriter::square(int xfrom, int yfrom, int xto, int yto, double red, double green,double  blue);

void
pngwriter::filledsquare(int xfrom, int yfrom, int xto, int yto, double red, double green,double  blue);

void
pngwriter::circle(int xcentre, int ycentre, int radius, double red, double green, double blue);

void
pngwriter::filledcircle(int xcentre, int ycentre, int radius, double red, double green, double blue);

void
pngwriter::readfromfile(char * name);  

int
pngwriter::getheight();

int
pngwriter::getwidth();

void
pngwriter::setcompressionlevel(int level);

int
pngwriter::getbitdepth();

int
pngwriter::getcolortype();

void
pngwriter::setgamma(double gamma);

double
pngwriter::getgamma();

void
pngwriter::bezier(int startPtX, int startPtY, int startControlX, int startControlY, int endPtX, int endPtY, int endControlX, int endControlY, double red, double green, double blue);

void
pngwriter::settext(char * title, char * author, char * description, char * software);

static double
pngwriter::version();

void
pngwriter::write_png();

void
pngwriter::plot_text(char * face_path, int fontsize, int x_start, int y_start, double angle, char * text, double red, double green, double blue);

void
pngwriter::plot_text_utf8(char * face_path, int fontsize, int x_start, int y_start, double angle, char * text, double red, double green, double blue);

double
pngwriter::bilinear_interpolation_dread(double x, double y, int colour);

void
pngwriter::plot_blend(int x, int y, double opacity, double red, double green, double blue);

void
pngwriter::invert();

void
pngwriter::resize(int width, int height);

void
pngwriter::boundary_fill(int xstart, int ystart, double boundary_red,double boundary_green,double boundary_blue,double fill_red, double fill_green, double fill_blue) ;

void
pngwriter::flood_fill(int xstart, int ystart, double fill_red, double fill_green, double fill_blue) ;

# not supported yet
#void
#pngwriter::polygon(int * points, int number_of_points, double red, double green, double blue);

void
pngwriter::scale_k(double k);

void
pngwriter::scale_kxky(double kx, double ky);

void
pngwriter::scale_wh(int finalwidth, int finalheight);

void
pngwriter::plotHSV_blend(int x, int y, double opacity, double hue, double saturation, double value);

void
pngwriter::line_blend(int xfrom, int yfrom, int xto, int yto, double opacity, double red, double green,double  blue);

void
pngwriter::square_blend(int xfrom, int yfrom, int xto, int yto, double opacity, double red, double green,double  blue);

void
pngwriter::filledsquare_blend(int xfrom, int yfrom, int xto, int yto, double opacity, double red, double green,double  blue);

void
pngwriter::circle_blend(int xcentre, int ycentre, int radius, double opacity, double red, double green, double blue);

void
pngwriter::filledcircle_blend(int xcentre, int ycentre, int radius, double opacity, double red, double green, double blue);

void
pngwriter::bezier_blend(  int startPtX, int startPtY, int startControlX, int startControlY, int endPtX, int endPtY, int endControlX, int endControlY, double opacity, double red, double green, double blue);

void
pngwriter::plot_text_blend(char * face_path, int fontsize, int x_start, int y_start, double angle, char * text, double opacity, double red, double green, double blue);

void
pngwriter::plot_text_utf8_blend(char * face_path, int fontsize, int x_start, int y_start, double angle, char * text, double opacity, double red, double green, double blue);

void
pngwriter::boundary_fill_blend(int xstart, int ystart, double opacity, double boundary_red,double boundary_green,double boundary_blue,double fill_red, double fill_green, double fill_blue) ;

void
pngwriter::flood_fill_blend(int xstart, int ystart, double opacity, double fill_red, double fill_green, double fill_blue) ;

#void
#polygon_blend(int * points, int number_of_points, double opacity, double red, double green, double blue); */

void
pngwriter::plotCMYK_blend(int x, int y, double opacity, double cyan, double magenta, double yellow, double black);

void
pngwriter::laplacian(double k, double offset);

void
pngwriter::filledtriangle(int x1,int y1,int x2,int y2,int x3,int y3, double red, double green, double blue);

void
pngwriter::filledtriangle_blend(int x1,int y1,int x2,int y2,int x3,int y3, double opacity, double red, double green, double blue);

void
pngwriter::arrow( int x1,int y1,int x2,int y2,int size, double head_angle, double red, double green, double blue);

void
pngwriter::filledarrow( int x1,int y1,int x2,int y2,int size, double head_angle, double red, double green, double blue);

void
pngwriter::cross( int x, int y, int xwidth, int yheight, double red, double green, double blue);

void
pngwriter::maltesecross( int x, int y, int xwidth, int yheight, int x_bar_height, int y_bar_width, double red, double green, double blue);

void
pngwriter::filleddiamond( int x, int y, int width, int height, double red, double green, double blue);

void
pngwriter::diamond(int x, int y, int width, int height, double red, double green, double blue);

int
pngwriter::get_text_width(char * face_path, int fontsize,  char * text);

int
pngwriter::get_text_width_utf8(char * face_path, int fontsize, char * text);

void
pngwriter::DESTROY()

INCLUDE: fallback/const-xs.inc
