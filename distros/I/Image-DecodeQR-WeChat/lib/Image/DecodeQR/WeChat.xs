// Function name mangling!!!!!!!!!!!
// use this so that function names in object files are as
// specified in the proto

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <stdlib.h>

#include "wechat_qr_decode_lib.hpp"

/* helper func to check if SV contains undef */
int _SV_contains_undef(SV *ansv){ SvGETMAGIC(ansv); return(!SvOK(ansv)); }

MODULE = Image::DecodeQR::WeChat		PACKAGE = Image::DecodeQR::WeChat

PROTOTYPES: ENABLE

AV *
decode_xs(infilename_SV, modelsdir_SV, outbase_SV, verbosity, graphicaldisplayresult, dumpqrimagestofile)
	SV *infilename_SV;
	SV *modelsdir_SV;
	SV *outbase_SV;
	int verbosity;
	int graphicaldisplayresult;
	int dumpqrimagestofile;
    PREINIT:
	char **payloads;
	char *infilename;
	char *outbase;
	char *modelsdir;
	char *dummy;
	STRLEN infilename_len;
	STRLEN outbase_len = 0;
	STRLEN modelsdir_len;
	STRLEN dummy_len;
	size_t payloads_sz = 0;
	size_t I;
	size_t apayload_sz;
	SV *apayload, **apayloadPP;
    CODE:
	/* this is a bit of a hocus-pocus ... */
	if( _SV_contains_undef(infilename_SV) ){ fprintf(stderr, "decode_xs() : error, input filename can not be undefined.\n"); XSRETURN_UNDEF; }
	infilename = SvUTF8(infilename_SV)
		? SvPVutf8(infilename_SV, infilename_len) : SvPVbyte(infilename_SV, infilename_len)
	;
	if( _SV_contains_undef(modelsdir_SV) ){ fprintf(stderr, "decode_xs() : error, modelsdir can not be undefined.\n"); XSRETURN_UNDEF; }
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
		fprintf(stdout, "decode_xs() : got these input parameters:"
"\n  infilename(length %zu)='%s'"
"\n  modelsdir(length: %zu)='%s'"
"\n  outbase(length: %zu)='%s'"
"\n  verbosity=%d"
"\n  graphicaldisplayresult=%d"
"\n  dumpqrimagestofile=%d"
"\ndecode_xs() : end of input parameters.\n",
			infilename_len, infilename,
			modelsdir_len, modelsdir,
			outbase_len, outbase==NULL ? "undef":outbase,
			verbosity, graphicaldisplayresult, dumpqrimagestofile
		);
	}
	payloads = wechat_qr_decode_with_C_linkage(
		infilename,
		modelsdir,
		outbase,
		verbosity,
		graphicaldisplayresult,
		dumpqrimagestofile,
		&payloads_sz
	);
	if( payloads == NULL ){
		fprintf(stderr, "decode_xs() : call to wechat_qr_decode_with_C_linkage() has failed.\n");
		// return undef on error
		//RETVAL = (AV *)(&PL_sv_undef);
		XSRETURN_UNDEF;
	} else {
		RETVAL = (AV*)sv_2mortal((SV*)newAV());
		for(I=0;I<payloads_sz;I++){
			apayload_sz = strlen(payloads[I]);
			if( verbosity > 9 ){ fprintf(stdout, "decode_xs() : payload %d/%d received (length: %zu): %s\n", I+1, payloads_sz, apayload_sz, payloads[I]); }
			// this will create an SV with C-char-* to a utf8-perl-string
			// Thanks Håkon Hægland, ikegami, Timothy Legge:
			//    https://stackoverflow.com/questions/71402095/perl-xs-create-and-return-array-of-strings-char-taken-from-calling-a-c-funct
			// this is equivalent to the one below:
			//    apayload = newSVpvn_utf8(payloads[I], strlen(payloads[I]), 1);
			apayload = newSVpvn_flags(payloads[I], strlen(payloads[I]), SVf_UTF8);
			// disregard any utf8 strings
			//apayload = newSVpv(payloads[I], 0);
			av_push(RETVAL, apayload);
		}
		// free received data which was allocated by C function
		for(I=0;I<payloads_sz;I++) free(payloads[I]); free(payloads);
		if( verbosity > 9 ){
			fprintf(stdout, "decode_xs() : returning these %zu payload(s):\n", payloads_sz);
			for(I=0;I<payloads_sz;I++){
				apayloadPP = av_fetch((AV *)RETVAL, I, 0);
				dummy = SvPVutf8(*apayloadPP, dummy_len);
				fprintf(stdout, "  %d/%d (length is %zu): %s\n", I+1, payloads_sz, dummy_len, dummy);
			}
			fprintf(stdout, "decode_xs() : end of payload(s) to return.\n");
		}
	}
	// end of program

	OUTPUT:
		RETVAL
