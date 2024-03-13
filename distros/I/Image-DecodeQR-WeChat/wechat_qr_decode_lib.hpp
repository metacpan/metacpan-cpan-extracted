#ifndef _WECHAT_QR_DECODE_LIB_H
#define _WECHAT_QR_DECODE_LIB_H

/*
our $VERSION = '2.1';
*/

int wechat_qr_decode(
	char *infilename,
	char *modelsdir,
	char *outbasename, // optional, can be NULL
	int verbosity,
	int graphicaldisplayresult,
	int dumpqrimagestofile,
	// we return these back to caller if !NULL we allocate and caller needs to free
	char ***_payloads,
	// this assumes that each bbox has 4 items, the num of bboxes is the payloads_sz
	float ***_bboxes,
	// this is the size of both bboxes and payloads
	size_t *payloads_sz
);

int opencv_has_highgui(void);

/* Exactly as above but with C linkage
   so as to avoid name mangling of C++
   Use this when it complains that it can not
   find *decode() symbol
*/
#ifdef __cplusplus
extern "C" {
#endif
int wechat_qr_decode_with_C_linkage(
	char *infilename,
	char *modelsdir,
	char *outbasename, // optional, can be NULL
	int verbosity,
	int graphicaldisplayresult,
	int dumpqrimagestofile,
	// we return these back to caller if !NULL we allocate and caller needs to free
	char ***_payloads,
	// this assumes that each bbox has 4 items, the num of bboxes is the payloads_sz
	float ***_bboxes,
	// this is the size of both bboxes and payloads
	size_t *payloads_sz
);

int opencv_has_highgui_with_C_linkage(void);

#ifdef __cplusplus
} // extern "C" {
#endif

#endif
