#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "libgen.h"

#include "cv.h"
#include "highgui.h"


void *get_ptr(SV *self, char *param)
{
	void *ptr = NULL;
	
	if ( hv_exists((HV*)SvRV(self) , param , strlen(param)) )
		ptr = SvIV(*hv_fetch( (HV*)SvRV(self) , param , strlen(param), 0));
	
	return ptr;
}

void set_ptr(SV *self, char *param, void *ptr)
{
	if (ptr) hv_store((HV*)SvRV(self), param, strlen(param), newSViv(PTR2IV(ptr)), 0);
}

char* get_file_extension(char *filename)
{
	char *ext;
	ext = strrchr(basename(filename), '.');

	return ext ? ext+1 : NULL;
}

MODULE = Image::Resize::OpenCV		PACKAGE = Image::Resize::OpenCV		

IV _init(self, filename = NULL)
	SV *self;
	char *filename;
	PREINIT:
		IplImage *img, *gray;
		AV *retval;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		if (filename)
		{
			img = cvLoadImage(filename, CV_LOAD_IMAGE_UNCHANGED);
			if (!img) croak("Can't load the image file `%s'", filename);
		
			set_ptr(self, "_img", img);
		}
		
		RETVAL = 1;
	OUTPUT:
		RETVAL

IV load(self, filename)
	SV *self;
	char *filename;
	PREINIT:
		IplImage *img, *gray;
		AV *retval;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		img = (IplImage *) get_ptr(self, "_img");
		if (img)
		{
			cvReleaseImage(&img);
			img = NULL;
		}

		img = cvLoadImage(filename, CV_LOAD_IMAGE_UNCHANGED);
		if (!img) croak("Can't load the image file `%s'", filename);

		set_ptr(self, "_img", img);
		
		RETVAL = 1;
	OUTPUT:
		RETVAL
		

void resize(self, width, height, ...)
	SV *self;
	int width;
	int height;
	PREINIT:
		IplImage *img, *small_img;
		int inter = 1;
		int keep_aspect = 0;
	PPCODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}

		if (items % 2 == 0)
		{
			croak("ERROR: resize - called with odd number of option parameters - should be of the form option => value");
		}

		int i;
		for (i = 1; i < items; i+=2)
		{

			char *key = SvPV_nolen(ST(i));
			IV value = SvIV(ST(i + 1));
			if (strcasecmp(key, "inter") == 0)
			{
				inter = value;
			}
			else if (strcasecmp(key, "keep_aspect") == 0)
			{
				keep_aspect = value;
			}
		}

		img = (IplImage *) get_ptr(self, "_img");
		if (!img) croak("image not loaded!");
		
		if (keep_aspect == 1)
		{
			double img_scale = 1;
			if (abs(img->width - width) > abs(img->height - height))
				img_scale = (double) img->width / (double) width;
			else
				img_scale = (double) img->height / (double) height;
			
			small_img = cvCreateImage(cvSize(cvRound ((double) img->width / img_scale),
			                          cvRound ((double) img->height / img_scale)), img->depth, img->nChannels );
		}
		else
		{
			small_img = cvCreateImage(cvSize(width, height), img->depth, img->nChannels );
		
		}

		cvResize(img, small_img, inter);
		cvReleaseImage(&img);
		
		set_ptr(self, "_img", small_img);
		
		img = small_img;

		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(img -> width)));
		PUSHs(sv_2mortal(newSViv(img -> height)));
		

IV width(self)
	SV *self;
	PREINIT:
		IplImage *img;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		img = (IplImage *) get_ptr(self, "_img");
		if (!img) croak("image not loaded!");

		RETVAL = img->width;
	OUTPUT:
		RETVAL

IV height(self)
	SV *self;
	PREINIT:
		IplImage *img;
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		img = (IplImage *) get_ptr(self, "_img");
		if (!img) croak("image not loaded!");

		RETVAL = img->height;
	OUTPUT:
		RETVAL

IV save(self, filename, compression = 25)
	SV *self;
	char *filename;
	int compression;
	PREINIT:
		IplImage *img;
		int p[3];
	CODE:
		if (!SvROK(self)) {XSRETURN_UNDEF;}
		
		img = (IplImage *) get_ptr(self, "_img");
		if (!img) croak("image not loaded!");

		char *ext = get_file_extension(filename);
		if (!ext) croak("File extension not defined");
		
		if (strcasecmp(ext, "jpg") == 0 || strcasecmp(ext, "jpeg") == 0)
		{
			p[0] = CV_IMWRITE_JPEG_QUALITY;
			p[1] = 100 - (compression);
			p[2] = 0;
		}
		else if (strcasecmp(ext, "png") == 0)
		{
			p[0] = CV_IMWRITE_PNG_COMPRESSION;
			p[1] = (int) compression/10;
			p[2] = 0;
		}

		cvSaveImage(filename, img, p);

		RETVAL = 1;
	OUTPUT:
		RETVAL
	

void DESTROY(self)
		SV *self;
	PREINIT:
		IplImage *img;
	CODE:
		img = (IplImage *) get_ptr(self, "_img");
		if (img) cvReleaseImage(&img);
