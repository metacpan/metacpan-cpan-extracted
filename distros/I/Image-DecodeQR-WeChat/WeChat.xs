// Function name mangling!!!!!!!!!!!
// use this so that function names in object files are as
// specified in the proto

/* don't forget that we are using a C++ compiler and so these
  need to be protected else ... function-name mangling ooouuouuuuoouu :
*/

/*
our $VERSION = '2.1';
*/

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

/* helper func to check if SV contains undef */
int _SV_contains_undef(SV *ansv){ SvGETMAGIC(ansv); return(!SvOK(ansv)); }

#ifdef __cplusplus
} // extern "C" {
#endif

#include "wechat_qr_decode_lib.hpp"

/* NOTE on
	PROTOTYPE: @
   without it, and with PROTOTYPES: ENABLE above it, the default
   prototype set by xsubpp is $$$$$$ (6 scalars).
   Which has problems when calling
   detect_and_decode_qr_xs(@x) where @x is an array of 6 scalars.
   With explicitly setting
	PROTOTYPE: @
   it allow function to be called from Perl with
   both an array and 6 scalars.
   And catches the case where array has not exactly 6 items.
   See test case t/06-decode-xs-prototype.t
   #perl advice (Botje, LeoNerd): 
     - Don't set PROTOTYPE
     - you should probably just abandon the use of prototypes.
     - a lack of a prototype is the same as '@'
   BOTTOMLINE: I will leave prototypes on for the time being with 
   explicitly setting '@' rather than relying on Perl's defaults.
*/

MODULE = Image::DecodeQR::WeChat		PACKAGE = Image::DecodeQR::WeChat

PROTOTYPES: ENABLE

SV *
detect_and_decode_qr_xs(infilename_SV, modelsdir_SV, outbase_SV, verbosity, graphicaldisplayresult, dumpqrimagestofile)
	SV *infilename_SV;
	SV *modelsdir_SV;
	SV *outbase_SV;
	int verbosity;
	int graphicaldisplayresult;
	int dumpqrimagestofile;

    PROTOTYPE: @

    PREINIT:
	int ret;
	char **payloads = NULL;
	float **bboxes = NULL;
	char *infilename;
	char *outbase;
	char *modelsdir;
	char *dummy;
	STRLEN infilename_len;
	STRLEN outbase_len = 0;
	STRLEN modelsdir_len;
	STRLEN dummy_len;
	size_t payloads_sz = 0;
	size_t I, J;
	size_t apayload_sz;
	SV *apayload, **apayloadPP;
	AV *bbox_AV, *bbox_AV2;
	AV *payloads_AV;
	AV *bboxes_AV;
    INIT:
	AV *retarr_AV;
	// TODO: try using croak
	if( _SV_contains_undef(infilename_SV) ){ fprintf(stderr, "detect_and_decode_qr_xs() : error, input filename can not be undefined.\n"); XSRETURN_UNDEF; }
	if( _SV_contains_undef(modelsdir_SV) ){ fprintf(stderr, "detect_and_decode_qr_xs() : error, modelsdir can not be undefined.\n"); XSRETURN_UNDEF; }

	// prepare an array for return
	retarr_AV = (AV *)sv_2mortal((SV *)newAV());
    CODE:
	/* this is a bit of a hocus-pocus ... */
	infilename = SvUTF8(infilename_SV)
		? SvPVutf8(infilename_SV, infilename_len) : SvPVbyte(infilename_SV, infilename_len)
	;
	modelsdir = SvUTF8(modelsdir_SV)
		? SvPVutf8(modelsdir_SV, modelsdir_len) : SvPVbyte(modelsdir_SV, modelsdir_len)
	;

	/* this is optional */
	if( _SV_contains_undef(outbase_SV) ){ 
		outbase = NULL;
	} else {
		outbase = SvUTF8(outbase_SV)
			? SvPVutf8(outbase_SV, outbase_len) : SvPVbyte(outbase_SV, outbase_len)
		;
	}

	if( verbosity > 9 ){
		fprintf(stdout, "detect_and_decode_qr_xs() : got these input parameters:"
"\n  infilename(length %zu)='%s'"
"\n  modelsdir(length: %zu)='%s'"
"\n  outbase(length: %zu)='%s'"
"\n  verbosity=%d"
"\n  graphicaldisplayresult=%d"
"\n  dumpqrimagestofile=%d"
"\ndetect_and_decode_qr_xs() : end of input parameters.\n",
			infilename_len, infilename,
			modelsdir_len, modelsdir,
			outbase_len, outbase==NULL ? "undef":outbase,
			verbosity, graphicaldisplayresult, dumpqrimagestofile
		);
	}
	ret = wechat_qr_decode_with_C_linkage(
		infilename,
		modelsdir,
		outbase,
		verbosity,
		graphicaldisplayresult,
		dumpqrimagestofile,
		&payloads,
		&bboxes,
		&payloads_sz
	);
	if( ret != 0 ){
		fprintf(stderr, "detect_and_decode_qr_xs() : call to wechat_qr_decode_with_C_linkage() has failed.\n");
		// return undef on error
		//RETVAL = (AV *)(&PL_sv_undef);
		XSRETURN_UNDEF; // or croak?
	}

	// our return is an arrayref of 2 arrays, one for payloads and one for bboxes
	// if no payloads, these 2 arrays will have zero elements but they will be there
	payloads_AV = (AV *)sv_2mortal((SV *)newAV());
	bboxes_AV = (AV *)sv_2mortal((SV *)newAV());
	RETVAL = newRV((SV *)retarr_AV);
	// add payloads and bboxes to returned array in this order:
	av_push(retarr_AV, newRV( (SV *)payloads_AV ));
	av_push(retarr_AV, newRV( (SV *)bboxes_AV ));

	if( payloads_sz == 0 ){
		fprintf(stderr, "detect_and_decode_qr_xs() : no QR-codes detected.\n");
		goto END;
	}

	for(I=0;I<payloads_sz;I++){
		apayload_sz = strlen(payloads[I]);
		if( verbosity > 9 ){ fprintf(stdout, "detect_and_decode_qr_xs() : payload %d/%d received (length: %zu): %s\n", I+1, payloads_sz, apayload_sz, payloads[I]); }

		// this will create an SV with C-char-* to a utf8-perl-string
		// Thanks Håkon Hægland, ikegami, Timothy Legge:
		//    https://stackoverflow.com/questions/71402095/perl-xs-create-and-return-array-of-strings-char-taken-from-calling-a-c-funct
		// this is equivalent to the one below:
		//    apayload = newSVpvn_utf8(payloads[I], strlen(payloads[I]), 1);
		apayload = newSVpvn_flags(payloads[I], strlen(payloads[I]), SVf_UTF8);
		// disregard any utf8 strings
		//apayload = newSVpv(payloads[I], 0);
		av_push(payloads_AV, apayload);

		// and now the bboxes, assume there are 4 2D points = 8 floats in each bbox
		bbox_AV = (AV *)sv_2mortal((SV *)newAV());
		for(J=0;J<8;J++){
			av_push(bbox_AV, newSVnv(bboxes[I][J]));
		}
		av_push(bboxes_AV, newRV( (SV *)bbox_AV ));
		// free received data which was allocated by C function
		free(payloads[I]); free(bboxes[I]);
	}
	// free received data which was allocated by C function
	free(payloads); free(bboxes);

	if( verbosity > 9 ){
		// print the results if verbose
		fprintf(stdout, "detect_and_decode_qr_xs() : returning these %zu payload(s):\n", payloads_sz);
		for(I=0;I<payloads_sz;I++){
			apayloadPP = av_fetch(payloads_AV, I, 0);
			dummy = SvPVutf8(*apayloadPP, dummy_len);
			fprintf(stdout, "  %d/%d (length is %zu): %s [", I+1, payloads_sz, dummy_len, dummy);

			/* FIXME: this does not seem to work, it can't get bbox_AV2!
			bbox_AV2 = (AV *)*av_fetch(bboxes_AV, I, 0);
			for(J=0;J<8;J++){
				fprintf(stdout, "%f, ", SvNV(*av_fetch(bbox_AV2, J, 0)));
			}
			fprintf(stdout, "]\n");
			*/
		}
		fprintf(stdout, "detect_and_decode_qr_xs() : end of payload(s) to return.\n");
	}
	// this is lame but it's there because I don't know how to tell it to just
	// return back in the middle of the codez above!, so just goto...
	END:
	// end of program

	OUTPUT:
		RETVAL

int
opencv_has_highgui_xs()
    CODE:
	RETVAL = opencv_has_highgui_with_C_linkage();

	OUTPUT:
		RETVAL
