#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_newRV_noinc
#define NEED_sv_2pv_nolen
#include "ppport.h"
#include "cv.h"
#include "highgui.h"

MODULE = Image::ObjectDetect		PACKAGE = Image::ObjectDetect

PROTOTYPES: ENABLE

SV *
new(class, cascade_name)
        SV *class;
        char *cascade_name;
    PREINIT:
        CvHaarClassifierCascade *cascade;
        SV *self;
    CODE:
        cascade = cvLoad(cascade_name, 0, 0, 0);
        if (!cascade)
            croak("Can't load the cascade file");
        self = newSViv(PTR2IV(cascade));
        self = newRV_noinc(self);
        sv_bless(self, gv_stashpv(SvPV_nolen(class), 1));
        RETVAL = self;
    OUTPUT:
        RETVAL

SV *
xs_detect(self, filename)
        SV *self;
        char *filename;
    PREINIT:
        IplImage *img, *gray;
        int i;
        CvMemStorage *storage;
        CvHaarClassifierCascade *cascade;
        CvSeq *objects;
        CvRect *rect;
        AV *retval;
        HV *hash;
    CODE:
        img = cvLoadImage(filename, 1);
        if (!img)
            croak("Can't load the image file");

        gray = cvCreateImage(cvSize(img->width, img->height), 8, 1);
        cvCvtColor(img, gray, CV_BGR2GRAY);
        cvEqualizeHist(gray, gray);

        storage = cvCreateMemStorage(0);
        cascade = INT2PTR(CvHaarClassifierCascade *, SvIV(SvRV(self)));
        objects = cvHaarDetectObjects(gray, cascade, storage,
#if (CV_MAJOR_VERSION < 2 || (CV_MAJOR_VERSION == 2 && CV_MINOR_VERSION < 1))
                1.1, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(0, 0));
#else
                1.1, 2, CV_HAAR_DO_CANNY_PRUNING, cvSize(0, 0), cvSize(0, 0));
#endif

        retval = newAV();
        for (i = 0; i < (objects ? objects->total : 0); i++) {
            rect = (CvRect *) cvGetSeqElem(objects, i);
            hash = newHV();
            hv_store(hash, "x", 1, newSViv(rect->x), 0);
            hv_store(hash, "y", 1, newSViv(rect->y), 0);
            hv_store(hash, "width", 5, newSViv(rect->width), 0);
            hv_store(hash, "height", 6, newSViv(rect->height), 0);
            av_push(retval, newRV_noinc((SV *) hash));
        }

        cvReleaseMemStorage(&storage);
        cvReleaseImage(&img);
        cvReleaseImage(&gray);

        RETVAL = newRV_noinc((SV *) retval);
    OUTPUT:
        RETVAL

void
DESTROY(self)
        SV *self;
    PREINIT:
        CvHaarClassifierCascade *cascade;
    CODE:
        cascade = INT2PTR(CvHaarClassifierCascade *, SvIV(SvRV(self)));
        cvReleaseHaarClassifierCascade(&cascade);

