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

#include "imext.h"
#include "imperl.h"

void 
sepia(i_img *im, i_color *tone) {
    i_color color, new_color;
    int x,y;
    int r,g,b;
    double tmp_y;

    for(x = 0; x < im->xsize; ++x) {
        for(y = 0; y < im->ysize; ++y) {
            i_gpix(im, x, y, &color);
            tmp_y = 0.299 * color.rgba.r + 0.587 * color.rgba.g + 0.114 * color.rgba.b;

            r = (int)tmp_y * 0.94 + (1 - 0.94) * tone->rgba.r; /* 240/255 */
            g = (int)tmp_y * 0.78 + (1 - 0.78) * tone->rgba.g; /* 200/255 */
            b = (int)tmp_y * 0.57 + (1 - 0.57) * tone->rgba.b; /* 145/255 */

            new_color.rgba.r = r;
            new_color.rgba.g = g;
            new_color.rgba.b = b;
            new_color.rgba.a = color.rgba.a;
            i_ppix(im, x, y, &new_color);
        }
    }
}

DEFINE_IMAGER_CALLBACKS;

MODULE = Imager::Filter::Sepia   PACKAGE = Imager::Filter::Sepia

PROTOTYPES: ENABLE

void
sepia(im, tone)
        Imager::ImgRaw im
        Imager::Color tone

BOOT:
        PERL_INITIALIZE_IMAGER_CALLBACKS;
