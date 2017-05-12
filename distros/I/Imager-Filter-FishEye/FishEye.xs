#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include <math.h>
#include "imext.h"
#include "imperl.h"

#define min(x,y) ((x)<(y) ? (x) : (y))

void 
__fisheye(i_img *im, double r, double d) {
    i_color color;
    i_img *canvas;

    int x,y;
    int xx, yy;

    if (r == -1) {
        r = min(im->xsize, im->ysize)/2;
    }
    int w = im->xsize;
    int h = im->ysize;

    canvas = i_img_8_new(im->xsize, im->ysize, im->channels);

    for(x = 0; x < im->xsize; ++x) {
        for(y = 0; y < im->ysize; ++y) {
            double rp = sqrt(d*d + (x-w/2)*(x-w/2) + (y-h/2)*(y-h/2));
            xx = rp*(x-w/2)/r + w/2;
            yy = rp*(y-h/2)/r + h/2;
            if (xx>=0 && xx<w && yy>=0 && yy<h) {
                i_gpix(im, xx, yy, &color);
                i_ppix(canvas, x, y, &color);
            }
        }
    }
    i_copyto(im, canvas, 0, 0, (int)im->xsize, (int)im->ysize, 0, 0);
    i_img_destroy(canvas);
}

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::Filter::FishEye   PACKAGE = Imager::Filter::FishEye

PROTOTYPES: ENABLE

void
__fisheye(im, r, d)
    Imager::ImgRaw im
    int r
    int d

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;

