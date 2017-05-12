#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define TRANSFORMS_SUPPORTED   1
#define SAVE_MARKERS_SUPPORTED 1
#define ENTROPY_OPT_SUPPORTED  1

#include "jinclude.h"
#include <jpeglib.h>
#include "transupp.h"

#define DES_DECO_SRC 0x0001
#define DES_COMP_DST 0x0002

#define my_croak(...) \
	STMT_START { \
		if (fp != NULL) { fclose(fp); } \
		if (what_destroy & DES_COMP_DST) {\
			/*jpeg_finish_compress(&dstinfo);*/ \
			jpeg_destroy_compress(&dstinfo); \
		} \
		if (what_destroy & DES_DECO_SRC) { \
			/*(void) jpeg_finish_decompress(&srcinfo);*/\
			jpeg_destroy_decompress(&srcinfo);\
		}\
		croak(__VA_ARGS__);\
	} STMT_END

MODULE = Image::JpegTran		PACKAGE = Image::JpegTran

void
_jpegtran(src,dst,conf)
		char *src;
		char *dst;
		HV   *conf;
	PROTOTYPE: $$$
	CODE:
		SV **key;
		
		static JCOPY_OPTION             copyoption;      /* -copy switch */
		static jpeg_transform_info      transformoption; /* image transformation options */
		struct jpeg_decompress_struct   srcinfo;
		struct jpeg_compress_struct     dstinfo;
		
		struct jpeg_error_mgr jsrcerr, jdsterr;
		
		jvirt_barray_ptr * src_coef_arrays;
		jvirt_barray_ptr * dst_coef_arrays;
		int what_destroy = 0;
		/* We assume all-in-memory processing and can therefore use only a
		 * single file pointer for sequential input and output operation.
		 */
		FILE * fp = NULL;
		srcinfo.err = jpeg_std_error(&jsrcerr);
		jpeg_create_decompress(&srcinfo);
		what_destroy |= DES_DECO_SRC;
		/* Initialize the JPEG compression object with default error handling. */
		dstinfo.err = jpeg_std_error(&jdsterr);
		jpeg_create_compress(&dstinfo);
		what_destroy |= DES_COMP_DST;
		/*
			transformoption.transform = JXFORM_NONE;
			transformoption.perfect = FALSE;
			transformoption.trim = FALSE;
			transformoption.force_grayscale = FALSE;
			transformoption.crop = FALSE;
			
			scaleoption = NULL;
			copyoption = JCOPYOPT_DEFAULT;
			copyoption = JCOPYOPT_NONE;
			copyoption = JCOPYOPT_COMMENTS;
			copyoption = JCOPYOPT_ALL;
			
			select_transform(JXFORM_NONE);
			select_transform(JXFORM_FLIP_H);
			select_transform(JXFORM_FLIP_V);
			select_transform(JXFORM_ROT_90);
			select_transform(JXFORM_ROT_180);
			select_transform(JXFORM_ROT_270);
			select_transform(JXFORM_TRANSPOSE);
			select_transform(JXFORM_TRANSVERSE);
			transformoption.trim = TRUE;
			
			if (! jtransform_parse_crop_spec(&transformoption, argv[argn]));
		*/
		
		transformoption.transform = JXFORM_NONE;
		
		if ((key = hv_fetch(conf, "perfect", 7, 0)) && SvTRUE(*key)) {
			transformoption.perfect = TRUE;
		} else {
			transformoption.perfect = FALSE;
		}

		if ((key = hv_fetch(conf, "trim", 4, 0)) && SvTRUE(*key)) {
			transformoption.trim    = TRUE;
		} else {
			transformoption.trim    = FALSE;
		}


		if ((key = hv_fetch(conf, "grayscale", 9, 0)) && SvTRUE(*key)) {
			transformoption.force_grayscale = TRUE;
		} else {
			transformoption.force_grayscale = FALSE;
		}

		if (key = hv_fetch(conf, "rotate", 6, 0)) {
			if( transformoption.transform != JXFORM_NONE){ my_croak("Can't apply several transforms at once"); }
			if (SvIOK( *key )) {
				transformoption.transform = 
					SvIV(*key) ==  90 ? JXFORM_ROT_90 :
					SvIV(*key) == 180 ? JXFORM_ROT_180 :
					SvIV(*key) == 270 ? JXFORM_ROT_270 :
					JXFORM_NONE;
				if( transformoption.transform == JXFORM_NONE ) {
					my_croak("Bad value for rotate");
				}
			} else {
				my_croak("Bad value for rotate");
			}
		}
		if ((key = hv_fetch(conf, "transpose", 9, 0)) && SvTRUE(*key)) {
			if( transformoption.transform != JXFORM_NONE){ my_croak("Can't apply several transforms at once"); }
			transformoption.transform = JXFORM_TRANSPOSE;
		}
		if ((key = hv_fetch(conf, "transverse", 10, 0)) && SvTRUE(*key)) {
			if( transformoption.transform != JXFORM_NONE){ my_croak("Can't apply several transforms at once"); }
			transformoption.transform = JXFORM_TRANSVERSE;
		}
		if (key = hv_fetch(conf, "flip", 4, 0)) {
			if( transformoption.transform != JXFORM_NONE){ my_croak("Can't apply several transforms at once"); }
			if (SvPOK( *key )) {
				if (strEQ(SvPV_nolen(*key),"horizontal") || strEQ(SvPV_nolen(*key),"horisontal")) {
					transformoption.transform = JXFORM_FLIP_H;
				} else
				if (strEQ(SvPV_nolen(*key),"vertical")) {
					transformoption.transform = JXFORM_FLIP_V;
				} else
				{
					my_croak("Bad value for flip: %s",SvPV_nolen(*key));
				}
			} else {
				my_croak("Bad value for flip %s",SvPV_nolen(*key));
			}
		}
		
		if (key = hv_fetch(conf, "copy", 4, 0)) {
			if (SvPOK(*key)) {
				char *copyopt = SvPV_nolen(*key);
				// none comments exif all
				if (!strcmp(copyopt,"none")) {
					copyoption = JCOPYOPT_NONE;
				} else
				if (!strcmp(copyopt,"comments")) {
					copyoption = JCOPYOPT_COMMENTS;
				} else 
				if (!strcmp(copyopt,"exif")) {
					copyoption = JCOPYOPT_ALL;
				} else 
				if (!strcmp(copyopt,"all")) {
					copyoption = JCOPYOPT_ALL;
				} else
				{
					my_croak("Bad value for copy `%s'. Available are: none, exif, comments, all", copyopt);
				}
			} else {
				my_croak("Bad value for copy");
			}
		} else {
			copyoption = JCOPYOPT_ALL;
		}
		
		if ((key = hv_fetch(conf, "optimize", 8, 0)) && SvTRUE(*key)) {
			/* Enable entropy parm optimization. */
			dstinfo.optimize_coding = TRUE;
		}
		
		if ((key = hv_fetch(conf, "arithmetic", 10, 0)) && SvTRUE(*key)) {
			//#ifdef C_ARITH_CODING_SUPPORTED
				dstinfo.arith_code = TRUE;
			//#else
			//	warn("sorry, arithmetic coding not supported");
			//	dstinfo.arith_code = FALSE;
			//#endif
		} else {
			dstinfo.arith_code = FALSE;
		}
		
		if ((key = hv_fetch(conf, "maxmemory", 9, 0))) {
			if (SvIOK(*key)) {
				dstinfo.mem->max_memory_to_use = SvIV(*key);
			} else {
				my_croak("Bad value for maxmemory: %s",SvPV_nolen(*key));
			}
		}
		
		//transformoption.crop            = TRUE; // Not implemented
		
		if ((fp = fopen(src, READ_BINARY)) == NULL) {
			my_croak("can't open `%s' for reading",src);
		}

		jpeg_stdio_src(&srcinfo, fp);
		
		/* Enable saving of extra markers that we want to copy */
		jcopy_markers_setup(&srcinfo, copyoption);
		
		/* Read file header */
		(void) jpeg_read_header(&srcinfo, TRUE);
		if (!jtransform_request_workspace(&srcinfo, &transformoption)) {
			my_croak("transformation is not perfect");
		}
		
		/* Read source file as DCT coefficients */
		src_coef_arrays = jpeg_read_coefficients(&srcinfo);
		
		/* Initialize destination compression parameters from source values */
		jpeg_copy_critical_parameters(&srcinfo, &dstinfo);
		
		/* Adjust destination parameters if required by transform options;
		 * also find out which set of coefficient arrays will hold the output.
		 */
		dst_coef_arrays = jtransform_adjust_parameters(&srcinfo, &dstinfo, src_coef_arrays, &transformoption);

		/* Close input file, if we opened it.
		 * Note: we assume that jpeg_read_coefficients consumed all input
		 * until JPEG_REACHED_EOI, and that jpeg_finish_decompress will
		 * only consume more while (! cinfo->inputctl->eoi_reached).
		 * We cannot call jpeg_finish_decompress here since we still need the
		 * virtual arrays allocated from the source object for processing.
		 */
		fclose(fp);

		/* Open the output file. */
		if ((fp = fopen(dst, WRITE_BINARY)) == NULL) {
			my_croak("can't open `%s' for writing",dst);
		}

		/* Adjust default compression parameters by re-parsing the options */
		//file_index = parse_switches(&dstinfo, argc, argv, 0, TRUE);
		//TODO
		if ((key = hv_fetch(conf, "progressive", 11, 0)) && SvTRUE(*key)) {
			jpeg_simple_progression(&dstinfo);
		}

		//#ifdef C_MULTISCAN_FILES_SUPPORTED
		//if ((key = hv_fetch(conf, "scans", 5, 0))) {
		//	if (SvPOK(*key)) {
		//		char *scansarg = SvPV_nolen(*key);
		//		if (! read_scan_script(&dstinfo, scansarg)) {
		//			my_croak("Can't read scans script `%s'",scansarg);
		//		}
		//	}
		//}
		//#endif

		/* Specify data destination for compression */
		jpeg_stdio_dest(&dstinfo, fp);

		/* Start compressor (note no image data is actually written here) */
		jpeg_write_coefficients(&dstinfo, dst_coef_arrays);

		/* Copy to the output file any extra markers that we want to preserve */
		jcopy_markers_execute(&srcinfo, &dstinfo, copyoption);

		jtransform_execute_transformation(&srcinfo, &dstinfo, src_coef_arrays, &transformoption);

		/* Finish compression and release memory */
		jpeg_finish_compress(&dstinfo);
		jpeg_destroy_compress(&dstinfo);
		(void) jpeg_finish_decompress(&srcinfo);
		jpeg_destroy_decompress(&srcinfo);

		fclose(fp);
		if( jsrcerr.num_warnings + jdsterr.num_warnings ) {
			warn("Compression/decompression have warings");
		}
