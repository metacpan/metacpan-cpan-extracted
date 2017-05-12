#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <string.h>
#include <magick/api.h>

MODULE = Graphics::Magick::ColorHistogram  PACKAGE = Graphics::Magick::ColorHistogram

SV*
histogram(file, colors_wanted = 0)
    char* file
    unsigned long colors_wanted
CODE:
    ExceptionInfo exception;
    Image *image;
    ImageInfo *image_info;
    HistogramColorPacket* histo;
    unsigned long i;
    unsigned long colors_found;
    char hex_color[7];
    HV* color_counts;

    InitializeMagick("");
    GetExceptionInfo(&exception);
    image_info = CloneImageInfo(NULL);

    strncpy(image_info->filename, file, MaxTextExtent-1);
    image = ReadImage(image_info, &exception);
    if (!image)
        croak("failed to load %s\n", file);

    if (colors_wanted > 0) {
        QuantizeInfo* quant = CloneQuantizeInfo(NULL);
        quant->number_colors = colors_wanted;
        QuantizeImage(quant, image);
        DestroyQuantizeInfo(quant);
    }

    histo = GetColorHistogram(image, &colors_found, &exception);

    color_counts = (HV*) sv_2mortal((SV*) newHV());

    for (i = 0; i < colors_found; i++) {
        int klen = snprintf(
            hex_color, sizeof(hex_color), "%02x%02x%02x",
            histo[i].pixel.red,
            histo[i].pixel.green,
            histo[i].pixel.blue
        );
        hv_store(color_counts, hex_color, klen, newSVuv(histo[i].count), 0);
    }

    free(histo);
    DestroyImageInfo(image_info);
    DestroyExceptionInfo(&exception);
    DestroyMagick();

    RETVAL = newRV((SV*) color_counts);
OUTPUT:
    RETVAL
