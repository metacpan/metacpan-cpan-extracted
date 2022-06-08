#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <math.h>
#include <tiffperl.h>

MODULE = Graphics::TIFF		PACKAGE = Graphics::TIFF	  PREFIX = tiff_

PROTOTYPES: ENABLE
  
BOOT:
    HV *stash;
    stash = gv_stashpv("Graphics::TIFF", TRUE);

    newCONSTSUB(stash, "TIFFLIB_VERSION", newSViv(TIFFLIB_VERSION));

    newCONSTSUB(stash, "TIFFTAG_SUBFILETYPE", newSViv(TIFFTAG_SUBFILETYPE));
    newCONSTSUB(stash, "FILETYPE_REDUCEDIMAGE", newSViv(FILETYPE_REDUCEDIMAGE));
    newCONSTSUB(stash, "FILETYPE_PAGE", newSViv(FILETYPE_PAGE));
    newCONSTSUB(stash, "FILETYPE_MASK", newSViv(FILETYPE_MASK));

    newCONSTSUB(stash, "TIFFTAG_OSUBFILETYPE", newSViv(TIFFTAG_OSUBFILETYPE));
    newCONSTSUB(stash, "OFILETYPE_IMAGE", newSViv(OFILETYPE_IMAGE));
    newCONSTSUB(stash, "OFILETYPE_REDUCEDIMAGE", newSViv(OFILETYPE_REDUCEDIMAGE));
    newCONSTSUB(stash, "OFILETYPE_PAGE", newSViv(OFILETYPE_PAGE));

    newCONSTSUB(stash, "TIFFTAG_IMAGEWIDTH", newSViv(TIFFTAG_IMAGEWIDTH));
    newCONSTSUB(stash, "TIFFTAG_IMAGELENGTH", newSViv(TIFFTAG_IMAGELENGTH));

    newCONSTSUB(stash, "TIFFTAG_BITSPERSAMPLE", newSViv(TIFFTAG_BITSPERSAMPLE));
    newCONSTSUB(stash, "TIFFTAG_COMPRESSION", newSViv(TIFFTAG_COMPRESSION));
    newCONSTSUB(stash, "COMPRESSION_NONE", newSViv(COMPRESSION_NONE));
    newCONSTSUB(stash, "COMPRESSION_CCITTRLE", newSViv(COMPRESSION_CCITTRLE));
    newCONSTSUB(stash, "COMPRESSION_CCITTFAX3", newSViv(COMPRESSION_CCITTFAX3));
    newCONSTSUB(stash, "COMPRESSION_CCITT_T4", newSViv(COMPRESSION_CCITT_T4));
    newCONSTSUB(stash, "COMPRESSION_CCITTFAX4", newSViv(COMPRESSION_CCITTFAX4));
    newCONSTSUB(stash, "COMPRESSION_CCITT_T6", newSViv(COMPRESSION_CCITT_T6));
    newCONSTSUB(stash, "COMPRESSION_LZW", newSViv(COMPRESSION_LZW));
    newCONSTSUB(stash, "COMPRESSION_OJPEG", newSViv(COMPRESSION_OJPEG));
    newCONSTSUB(stash, "COMPRESSION_JPEG", newSViv(COMPRESSION_JPEG));
    newCONSTSUB(stash, "COMPRESSION_T85", newSViv(COMPRESSION_T85));
    newCONSTSUB(stash, "COMPRESSION_T43", newSViv(COMPRESSION_T43));
    newCONSTSUB(stash, "COMPRESSION_NEXT", newSViv(COMPRESSION_NEXT));
    newCONSTSUB(stash, "COMPRESSION_CCITTRLEW", newSViv(COMPRESSION_CCITTRLEW));
    newCONSTSUB(stash, "COMPRESSION_PACKBITS", newSViv(COMPRESSION_PACKBITS));
    newCONSTSUB(stash, "COMPRESSION_THUNDERSCAN", newSViv(COMPRESSION_THUNDERSCAN));
    newCONSTSUB(stash, "COMPRESSION_IT8CTPAD", newSViv(COMPRESSION_IT8CTPAD));
    newCONSTSUB(stash, "COMPRESSION_IT8LW", newSViv(COMPRESSION_IT8LW));
    newCONSTSUB(stash, "COMPRESSION_IT8MP", newSViv(COMPRESSION_IT8MP));
    newCONSTSUB(stash, "COMPRESSION_IT8BL", newSViv(COMPRESSION_IT8BL));
    newCONSTSUB(stash, "COMPRESSION_PIXARFILM", newSViv(COMPRESSION_PIXARFILM));
    newCONSTSUB(stash, "COMPRESSION_PIXARLOG", newSViv(COMPRESSION_PIXARLOG));
    newCONSTSUB(stash, "COMPRESSION_DEFLATE", newSViv(COMPRESSION_DEFLATE));
    newCONSTSUB(stash, "COMPRESSION_ADOBE_DEFLATE", newSViv(COMPRESSION_ADOBE_DEFLATE));
    newCONSTSUB(stash, "COMPRESSION_DCS", newSViv(COMPRESSION_DCS));
    newCONSTSUB(stash, "COMPRESSION_JBIG", newSViv(COMPRESSION_JBIG));
    newCONSTSUB(stash, "COMPRESSION_SGILOG", newSViv(COMPRESSION_SGILOG));
    newCONSTSUB(stash, "COMPRESSION_SGILOG24", newSViv(COMPRESSION_SGILOG24));
    newCONSTSUB(stash, "COMPRESSION_JP2000", newSViv(COMPRESSION_JP2000));
    newCONSTSUB(stash, "COMPRESSION_LZMA", newSViv(COMPRESSION_LZMA));

    newCONSTSUB(stash, "TIFFTAG_PHOTOMETRIC", newSViv(TIFFTAG_PHOTOMETRIC));
    newCONSTSUB(stash, "PHOTOMETRIC_MINISWHITE", newSViv(PHOTOMETRIC_MINISWHITE));
    newCONSTSUB(stash, "PHOTOMETRIC_MINISBLACK", newSViv(PHOTOMETRIC_MINISBLACK));
    newCONSTSUB(stash, "PHOTOMETRIC_RGB", newSViv(PHOTOMETRIC_RGB));
    newCONSTSUB(stash, "PHOTOMETRIC_PALETTE", newSViv(PHOTOMETRIC_PALETTE));
    newCONSTSUB(stash, "PHOTOMETRIC_MASK", newSViv(PHOTOMETRIC_MASK));
    newCONSTSUB(stash, "PHOTOMETRIC_SEPARATED", newSViv(PHOTOMETRIC_SEPARATED));
    newCONSTSUB(stash, "PHOTOMETRIC_YCBCR", newSViv(PHOTOMETRIC_YCBCR));
    newCONSTSUB(stash, "PHOTOMETRIC_CIELAB", newSViv(PHOTOMETRIC_CIELAB));
    newCONSTSUB(stash, "PHOTOMETRIC_ICCLAB", newSViv(PHOTOMETRIC_ICCLAB));
    newCONSTSUB(stash, "PHOTOMETRIC_ITULAB", newSViv(PHOTOMETRIC_ITULAB));
    newCONSTSUB(stash, "PHOTOMETRIC_LOGL", newSViv(PHOTOMETRIC_LOGL));
    newCONSTSUB(stash, "PHOTOMETRIC_LOGLUV", newSViv(PHOTOMETRIC_LOGLUV));

    newCONSTSUB(stash, "TIFFTAG_FILLORDER", newSViv(TIFFTAG_FILLORDER));
    newCONSTSUB(stash, "FILLORDER_MSB2LSB", newSViv(FILLORDER_MSB2LSB));
    newCONSTSUB(stash, "FILLORDER_LSB2MSB", newSViv(FILLORDER_LSB2MSB));

    newCONSTSUB(stash, "TIFFTAG_DOCUMENTNAME", newSViv(TIFFTAG_DOCUMENTNAME));
    newCONSTSUB(stash, "TIFFTAG_IMAGEDESCRIPTION", newSViv(TIFFTAG_IMAGEDESCRIPTION));
    newCONSTSUB(stash, "TIFFTAG_STRIPOFFSETS", newSViv(TIFFTAG_STRIPOFFSETS));

    newCONSTSUB(stash, "TIFFTAG_ORIENTATION", newSViv(TIFFTAG_ORIENTATION));
    newCONSTSUB(stash, "ORIENTATION_TOPLEFT", newSViv(ORIENTATION_TOPLEFT));
    newCONSTSUB(stash, "ORIENTATION_TOPRIGHT", newSViv(ORIENTATION_TOPRIGHT));
    newCONSTSUB(stash, "ORIENTATION_BOTRIGHT", newSViv(ORIENTATION_BOTRIGHT));
    newCONSTSUB(stash, "ORIENTATION_BOTLEFT", newSViv(ORIENTATION_BOTLEFT));
    newCONSTSUB(stash, "ORIENTATION_LEFTTOP", newSViv(ORIENTATION_LEFTTOP));
    newCONSTSUB(stash, "ORIENTATION_RIGHTTOP", newSViv(ORIENTATION_RIGHTTOP));
    newCONSTSUB(stash, "ORIENTATION_RIGHTBOT", newSViv(ORIENTATION_RIGHTBOT));
    newCONSTSUB(stash, "ORIENTATION_LEFTBOT", newSViv(ORIENTATION_LEFTBOT));

    newCONSTSUB(stash, "TIFFTAG_SAMPLESPERPIXEL", newSViv(TIFFTAG_SAMPLESPERPIXEL));
    newCONSTSUB(stash, "TIFFTAG_ROWSPERSTRIP", newSViv(TIFFTAG_ROWSPERSTRIP));
    newCONSTSUB(stash, "TIFFTAG_STRIPBYTECOUNTS", newSViv(TIFFTAG_STRIPBYTECOUNTS));

    newCONSTSUB(stash, "TIFFTAG_XRESOLUTION", newSViv(TIFFTAG_XRESOLUTION));
    newCONSTSUB(stash, "TIFFTAG_YRESOLUTION", newSViv(TIFFTAG_YRESOLUTION));

    newCONSTSUB(stash, "TIFFTAG_PLANARCONFIG", newSViv(TIFFTAG_PLANARCONFIG));
    newCONSTSUB(stash, "PLANARCONFIG_CONTIG", newSViv(PLANARCONFIG_CONTIG));
    newCONSTSUB(stash, "PLANARCONFIG_SEPARATE", newSViv(PLANARCONFIG_SEPARATE));

    newCONSTSUB(stash, "TIFFTAG_GROUP3OPTIONS", newSViv(TIFFTAG_GROUP3OPTIONS));
    newCONSTSUB(stash, "TIFFTAG_T4OPTIONS", newSViv(TIFFTAG_T4OPTIONS));
    newCONSTSUB(stash, "GROUP3OPT_2DENCODING", newSViv(GROUP3OPT_2DENCODING));
    newCONSTSUB(stash, "GROUP3OPT_UNCOMPRESSED", newSViv(GROUP3OPT_UNCOMPRESSED));
    newCONSTSUB(stash, "GROUP3OPT_FILLBITS", newSViv(GROUP3OPT_FILLBITS));

    newCONSTSUB(stash, "TIFFTAG_GROUP4OPTIONS", newSViv(TIFFTAG_GROUP4OPTIONS));
    newCONSTSUB(stash, "TIFFTAG_T6OPTIONS", newSViv(TIFFTAG_T6OPTIONS));
    newCONSTSUB(stash, "GROUP4OPT_UNCOMPRESSED", newSViv(GROUP4OPT_UNCOMPRESSED));

    newCONSTSUB(stash, "TIFFTAG_RESOLUTIONUNIT", newSViv(TIFFTAG_RESOLUTIONUNIT));
    newCONSTSUB(stash, "RESUNIT_NONE", newSViv(RESUNIT_NONE));
    newCONSTSUB(stash, "RESUNIT_INCH", newSViv(RESUNIT_INCH));
    newCONSTSUB(stash, "RESUNIT_CENTIMETER", newSViv(RESUNIT_CENTIMETER));

    newCONSTSUB(stash, "TIFFTAG_PAGENUMBER", newSViv(TIFFTAG_PAGENUMBER));

    newCONSTSUB(stash, "TIFFTAG_TRANSFERFUNCTION", newSViv(TIFFTAG_TRANSFERFUNCTION));

    newCONSTSUB(stash, "TIFFTAG_SOFTWARE", newSViv(TIFFTAG_SOFTWARE));
    newCONSTSUB(stash, "TIFFTAG_DATETIME", newSViv(TIFFTAG_DATETIME));

    newCONSTSUB(stash, "TIFFTAG_ARTIST", newSViv(TIFFTAG_ARTIST));

    newCONSTSUB(stash, "TIFFTAG_PREDICTOR", newSViv(TIFFTAG_PREDICTOR));
    newCONSTSUB(stash, "PREDICTOR_NONE", newSViv(PREDICTOR_NONE));
    newCONSTSUB(stash, "PREDICTOR_HORIZONTAL", newSViv(PREDICTOR_HORIZONTAL));
    newCONSTSUB(stash, "PREDICTOR_FLOATINGPOINT", newSViv(PREDICTOR_FLOATINGPOINT));

    newCONSTSUB(stash, "TIFFTAG_WHITEPOINT", newSViv(TIFFTAG_WHITEPOINT));
    newCONSTSUB(stash, "TIFFTAG_PRIMARYCHROMATICITIES", newSViv(TIFFTAG_PRIMARYCHROMATICITIES));
    newCONSTSUB(stash, "TIFFTAG_COLORMAP", newSViv(TIFFTAG_COLORMAP));

    newCONSTSUB(stash, "TIFFTAG_TILEWIDTH", newSViv(TIFFTAG_TILEWIDTH));
    newCONSTSUB(stash, "TIFFTAG_TILELENGTH", newSViv(TIFFTAG_TILELENGTH));

    newCONSTSUB(stash, "TIFFTAG_INKSET", newSViv(TIFFTAG_INKSET));
    newCONSTSUB(stash, "INKSET_CMYK", newSViv(INKSET_CMYK));
    newCONSTSUB(stash, "INKSET_MULTIINK", newSViv(INKSET_MULTIINK));

    newCONSTSUB(stash, "TIFFTAG_EXTRASAMPLES", newSViv(TIFFTAG_EXTRASAMPLES));
    newCONSTSUB(stash, "EXTRASAMPLE_UNSPECIFIED", newSViv(EXTRASAMPLE_UNSPECIFIED));
    newCONSTSUB(stash, "EXTRASAMPLE_ASSOCALPHA", newSViv(EXTRASAMPLE_ASSOCALPHA));
    newCONSTSUB(stash, "EXTRASAMPLE_UNASSALPHA", newSViv(EXTRASAMPLE_UNASSALPHA));

    newCONSTSUB(stash, "TIFFTAG_SAMPLEFORMAT", newSViv(TIFFTAG_SAMPLEFORMAT));
    newCONSTSUB(stash, "SAMPLEFORMAT_UINT", newSViv(SAMPLEFORMAT_UINT));
    newCONSTSUB(stash, "SAMPLEFORMAT_INT", newSViv(SAMPLEFORMAT_INT));
    newCONSTSUB(stash, "SAMPLEFORMAT_IEEEFP", newSViv(SAMPLEFORMAT_IEEEFP));
    newCONSTSUB(stash, "SAMPLEFORMAT_VOID", newSViv(SAMPLEFORMAT_VOID));
    newCONSTSUB(stash, "SAMPLEFORMAT_COMPLEXINT", newSViv(SAMPLEFORMAT_COMPLEXINT));
    newCONSTSUB(stash, "SAMPLEFORMAT_COMPLEXIEEEFP", newSViv(SAMPLEFORMAT_COMPLEXIEEEFP));

    newCONSTSUB(stash, "TIFFTAG_INDEXED", newSViv(TIFFTAG_INDEXED));
    newCONSTSUB(stash, "TIFFTAG_JPEGTABLES", newSViv(TIFFTAG_JPEGTABLES));

    newCONSTSUB(stash, "TIFFTAG_JPEGPROC", newSViv(TIFFTAG_JPEGPROC));
    newCONSTSUB(stash, "JPEGPROC_BASELINE", newSViv(JPEGPROC_BASELINE));
    newCONSTSUB(stash, "JPEGPROC_LOSSLESS", newSViv(JPEGPROC_LOSSLESS));

    newCONSTSUB(stash, "TIFFTAG_JPEGIFOFFSET", newSViv(TIFFTAG_JPEGIFOFFSET));
    newCONSTSUB(stash, "TIFFTAG_JPEGIFBYTECOUNT", newSViv(TIFFTAG_JPEGIFBYTECOUNT));

    newCONSTSUB(stash, "TIFFTAG_JPEGLOSSLESSPREDICTORS", newSViv(TIFFTAG_JPEGLOSSLESSPREDICTORS));
    newCONSTSUB(stash, "TIFFTAG_JPEGPOINTTRANSFORM", newSViv(TIFFTAG_JPEGPOINTTRANSFORM));
    newCONSTSUB(stash, "TIFFTAG_JPEGQTABLES", newSViv(TIFFTAG_JPEGQTABLES));
    newCONSTSUB(stash, "TIFFTAG_JPEGDCTABLES", newSViv(TIFFTAG_JPEGDCTABLES));
    newCONSTSUB(stash, "TIFFTAG_JPEGACTABLES", newSViv(TIFFTAG_JPEGACTABLES));

    newCONSTSUB(stash, "TIFFTAG_YCBCRSUBSAMPLING", newSViv(TIFFTAG_YCBCRSUBSAMPLING));

    newCONSTSUB(stash, "TIFFTAG_REFERENCEBLACKWHITE", newSViv(TIFFTAG_REFERENCEBLACKWHITE));

    newCONSTSUB(stash, "TIFFTAG_OPIIMAGEID", newSViv(TIFFTAG_OPIIMAGEID));

    newCONSTSUB(stash, "TIFFTAG_COPYRIGHT", newSViv(TIFFTAG_COPYRIGHT));

    newCONSTSUB(stash, "TIFFTAG_EXIFIFD", newSViv(TIFFTAG_EXIFIFD));

    newCONSTSUB(stash, "TIFFTAG_ICCPROFILE", newSViv(TIFFTAG_ICCPROFILE));

    newCONSTSUB(stash, "TIFFTAG_JPEGQUALITY", newSViv(TIFFTAG_JPEGQUALITY));

    newCONSTSUB(stash, "TIFFTAG_JPEGCOLORMODE", newSViv(TIFFTAG_JPEGCOLORMODE));
    newCONSTSUB(stash, "JPEGCOLORMODE_RAW", newSViv(JPEGCOLORMODE_RAW));
    newCONSTSUB(stash, "JPEGCOLORMODE_RGB", newSViv(JPEGCOLORMODE_RGB));

    newCONSTSUB(stash, "TIFFTAG_JPEGTABLESMODE", newSViv(TIFFTAG_JPEGTABLESMODE));
    newCONSTSUB(stash, "JPEGTABLESMODE_QUANT", newSViv(JPEGTABLESMODE_QUANT));
    newCONSTSUB(stash, "JPEGTABLESMODE_HUFF", newSViv(JPEGTABLESMODE_HUFF));

    newCONSTSUB(stash, "TIFFTAG_ZIPQUALITY", newSViv(TIFFTAG_ZIPQUALITY));

    newCONSTSUB(stash, "TIFFPRINT_STRIPS", newSViv(TIFFPRINT_STRIPS));
    newCONSTSUB(stash, "TIFFPRINT_CURVES", newSViv(TIFFPRINT_CURVES));
    newCONSTSUB(stash, "TIFFPRINT_COLORMAP", newSViv(TIFFPRINT_COLORMAP));
    newCONSTSUB(stash, "TIFFPRINT_JPEGQTABLES", newSViv(TIFFPRINT_JPEGQTABLES));
    newCONSTSUB(stash, "TIFFPRINT_JPEGACTABLES", newSViv(TIFFPRINT_JPEGACTABLES));
    newCONSTSUB(stash, "TIFFPRINT_JPEGDCTABLES", newSViv(TIFFPRINT_JPEGDCTABLES));

void
tiff_GetVersion (class)
        PPCODE:
                XPUSHs(sv_2mortal(newSVpv((char *) TIFFGetVersion(), 0)));

void
tiff_IsCODECConfigured (class, compression)
                uint16_t compression
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFIsCODECConfigured(compression))));

void
tiff__Open (class, path, flags)
		const char*	path
		const char*	flags
	INIT:
                TIFF		*tif;
        PPCODE:
                tif = TIFFOpen(path, flags);
                XPUSHs(sv_2mortal(newSViv(PTR2IV(tif))));

void
tiff_Close (tif)
                TIFF		*tif;
        PPCODE:
                TIFFClose(tif);

void
tiff_FileName (tif)
                TIFF		*tif;
        PPCODE:
                XPUSHs(sv_2mortal(newSVpv((char *) TIFFFileName(tif), 0)));

void
tiff_ReadDirectory (tif)
                TIFF		*tif;
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFReadDirectory(tif))));

void
tiff_WriteDirectory (tif)
                TIFF		*tif;
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFWriteDirectory(tif))));

void
tiff_ReadEXIFDirectory (tif, diroff)
                TIFF		*tif
                toff_t          diroff;
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFReadEXIFDirectory(tif, diroff))));

void
tiff_NumberOfDirectories (tif)
                TIFF		*tif
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFNumberOfDirectories(tif))));

void
tiff_SetDirectory (tif, dirnum)
                TIFF		*tif
                uint16_t        dirnum;
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFSetDirectory(tif, dirnum))));

void
tiff_SetSubDirectory(tif, diroff)
                TIFF		*tif
                uint64_t        diroff;
        PPCODE:
	        XPUSHs(sv_2mortal(newSViv(TIFFSetSubDirectory(tif, diroff))));

void
tiff_GetField (tif, tag)
                TIFF            *tif
                uint32_t        tag
	INIT:
                uint16_t        ui16, ui16_2, *aui16, *aui16_2, *aui16_3;
                uint32_t        ui32;
                uint64_t        *aui;
                float           f;
                float           *af;
                int             vector_length, nvals;
        PPCODE:
/* See http://www.libtiff.org/man/TIFFGetField.3t.html */
                switch (tag) {
                    /* byte single uint8 */
                    /* short single uint16 */
		    case TIFFTAG_BITSPERSAMPLE:
		    case TIFFTAG_COMPRESSION:
		    case TIFFTAG_FILLORDER:
		    case TIFFTAG_MATTEING:
		    case TIFFTAG_MAXSAMPLEVALUE:
		    case TIFFTAG_MINSAMPLEVALUE:
		    case TIFFTAG_ORIENTATION:
		    case TIFFTAG_PHOTOMETRIC:
		    case TIFFTAG_PLANARCONFIG:
                    case TIFFTAG_PREDICTOR:
		    case TIFFTAG_RESOLUTIONUNIT:
		    case TIFFTAG_SAMPLESPERPIXEL:
		    case TIFFTAG_THRESHHOLDING:
                        if (TIFFGetField (tif, tag, &ui16)) {
                            XPUSHs(sv_2mortal(newSViv(ui16)));
                        }
                        break;

                    /* single 64-bit unsigned fraction float */
		    case TIFFTAG_XRESOLUTION:
		    case TIFFTAG_YRESOLUTION:
		    case TIFFTAG_XPOSITION:
		    case TIFFTAG_YPOSITION:
                        if (TIFFGetField (tif, tag, &f)) {
                            XPUSHs(sv_2mortal(newSVnv(f)));
                        }
                        break;

                    /* two short uint16 */
		    case TIFFTAG_PAGENUMBER:
		    case TIFFTAG_HALFTONEHINTS:
                        if (TIFFGetField (tif, tag, &ui16, &ui16_2)) {
                            XPUSHs(sv_2mortal(newSViv(ui16)));
                            XPUSHs(sv_2mortal(newSViv(ui16_2)));
                        }
                        break;

                    /* count + array of short uint16 */
		    case TIFFTAG_EXTRASAMPLES:
                        if (TIFFGetField (tif, tag, &ui16, &aui16)) {
                            int i;
			    for (i = 0; i < ui16; ++i)
                                XPUSHs(sv_2mortal(newSViv(aui16[i])));
                        }
                        break;

                    /* three array of short uint16 */
		    case TIFFTAG_COLORMAP:
                        if (TIFFGetField (tif, tag, &aui16, &aui16_2, &aui16_3)) {
                          if ((aui16 != (uint16_t *) NULL)
                              && (aui16_2 != (uint16_t *) NULL)
                              && (aui16_3 != (uint16_t *) NULL)) {
                            AV* rav = newAV();
                            AV* gav = newAV();
                            AV* bav = newAV();
                            mXPUSHs(newRV_noinc((SV*)rav));
                            mXPUSHs(newRV_noinc((SV*)gav));
                            mXPUSHs(newRV_noinc((SV*)bav));
                            TIFFGetField (tif, TIFFTAG_BITSPERSAMPLE, &ui16);
                            int i;
                            for (i=0; i < (ssize_t) pow(2.0, (double) ui16); i++) {
                              av_push(rav, newSViv(aui16[i]));
                              av_push(gav, newSViv(aui16_2[i]));
                              av_push(bav, newSViv(aui16_3[i]));
                            }
                          }
                        }
                        break;

                    /* array of uint64 */
                    case TIFFTAG_TILEOFFSETS:
                    case TIFFTAG_TILEBYTECOUNTS:
                    case TIFFTAG_STRIPOFFSETS:
                    case TIFFTAG_STRIPBYTECOUNTS:
                         if (TIFFGetField (tif, tag, &aui)) {
                            nvals = TIFFNumberOfStrips(tif);
                            int i;
			    for (i = 0; i < nvals; ++i)
                                XPUSHs(sv_2mortal(newSViv(aui[i])));
                        }
                        break;

                    /* array of float */
                    case TIFFTAG_WHITEPOINT:
                    case TIFFTAG_PRIMARYCHROMATICITIES:
                        switch (tag) {
                            case TIFFTAG_PRIMARYCHROMATICITIES:
                                nvals = 6;
                                break;
                            /* TIFFTAG_WHITEPOINT */
                            default:
                                nvals = 2;
                        }
                        if (TIFFGetField (tif, tag, &af)) {
                            int i;
			    for (i = 0; i < nvals; ++i)
                                XPUSHs(sv_2mortal(newSVnv(af[i])));
                        }
                        break;

                    /* single uint32 */
                    default:
                        if (TIFFGetField (tif, tag, &ui32)) {
                            XPUSHs(sv_2mortal(newSViv(ui32)));
                        }
                        break;
                }

void
tiff_GetFieldDefaulted (tif, tag)
                TIFF            *tif
                uint32_t        tag
	INIT:
                uint16_t        ui16, ui16_2, *aui16, *aui16_2, *aui16_3;
                uint32_t        ui32;
                uint64_t        *aui;
                float           f;
                int             vector_length;
        PPCODE:
                switch (tag) {
                    /* byte single uint8 */
                    /* short single uint16 */
		    case TIFFTAG_BITSPERSAMPLE:
		    case TIFFTAG_COMPRESSION:
		    case TIFFTAG_FILLORDER:
		    case TIFFTAG_MATTEING:
		    case TIFFTAG_MAXSAMPLEVALUE:
		    case TIFFTAG_MINSAMPLEVALUE:
		    case TIFFTAG_ORIENTATION:
		    case TIFFTAG_PHOTOMETRIC:
		    case TIFFTAG_PLANARCONFIG:
                    case TIFFTAG_PREDICTOR:
		    case TIFFTAG_RESOLUTIONUNIT:
		    case TIFFTAG_SAMPLESPERPIXEL:
		    case TIFFTAG_THRESHHOLDING:
                        if (TIFFGetFieldDefaulted (tif, tag, &ui16)) {
                            XPUSHs(sv_2mortal(newSViv(ui16)));
                        }
                        break;

                    /* single 64-bit unsigned fraction float */
		    case TIFFTAG_XRESOLUTION:
		    case TIFFTAG_YRESOLUTION:
		    case TIFFTAG_XPOSITION:
		    case TIFFTAG_YPOSITION:
                        if (TIFFGetFieldDefaulted (tif, tag, &f)) {
                            XPUSHs(sv_2mortal(newSVnv(f)));
                        }
                        break;

                    /* two short uint16 */
		    case TIFFTAG_PAGENUMBER:
		    case TIFFTAG_HALFTONEHINTS:
                        if (TIFFGetFieldDefaulted (tif, tag, &ui16, &ui16_2)) {
                            XPUSHs(sv_2mortal(newSViv(ui16)));
                            XPUSHs(sv_2mortal(newSViv(ui16_2)));
                        }
                        break;

                    /* count + array of short uint16 */
		    case TIFFTAG_EXTRASAMPLES:
                        if (TIFFGetFieldDefaulted (tif, tag, &ui16, &aui16)) {
                            int i;
			    for (i = 0; i < ui16; ++i)
                                XPUSHs(sv_2mortal(newSViv(aui16[i])));
                        }
                        break;

                    /* three array of short uint16 */
		    case TIFFTAG_COLORMAP:
                        if (TIFFGetFieldDefaulted (tif, tag, &aui16, &aui16_2, &aui16_3)) {
                          if ((aui16 != (uint16_t *) NULL)
                              && (aui16_2 != (uint16_t *) NULL)
                              && (aui16_3 != (uint16_t *) NULL)) {
                            AV* rav = newAV();
                            AV* gav = newAV();
                            AV* bav = newAV();
                            mXPUSHs(newRV_noinc((SV*)rav));
                            mXPUSHs(newRV_noinc((SV*)gav));
                            mXPUSHs(newRV_noinc((SV*)bav));
                            TIFFGetFieldDefaulted (tif, TIFFTAG_BITSPERSAMPLE, &ui16);
                            int i;
                            for (i=0; i < (ssize_t) pow(2.0, (double) ui16); i++) {
                              av_push(rav, newSViv(aui16[i]));
                              av_push(gav, newSViv(aui16_2[i]));
                              av_push(bav, newSViv(aui16_3[i]));
                            }
                          }
                        }
                        break;

                    /* array of uint64 */
                    case TIFFTAG_TILEOFFSETS:
                    case TIFFTAG_TILEBYTECOUNTS:
                    case TIFFTAG_STRIPOFFSETS:
                    case TIFFTAG_STRIPBYTECOUNTS:
                        if (TIFFGetFieldDefaulted (tif, tag, &aui)) {
                            int nstrips = TIFFNumberOfStrips(tif);
                            int i;
			    for (i = 0; i < nstrips; ++i)
                                XPUSHs(sv_2mortal(newSViv(aui[i])));
                        }
                        break;

                    /* single uint32 */
                    default:
                        if (TIFFGetFieldDefaulted (tif, tag, &ui32)) {
                            XPUSHs(sv_2mortal(newSViv(ui32)));
                        }
                        break;
                }

void
tiff_SetField (tif, tag, ...)
                TIFF            *tif
                uint32_t        tag
	INIT:
                uint16_t        ui16, ui16_2;
                uint32_t        ui32;
                float           f;
        PPCODE:
                switch (tag) {

                    /* single float */
		    case TIFFTAG_XRESOLUTION:
		    case TIFFTAG_YRESOLUTION:
                        f = SvNV(ST(2));
                        XPUSHs(sv_2mortal(newSViv(TIFFSetField (tif, tag, f))));
                        break;

                    /* two uint16 */
		    case TIFFTAG_PAGENUMBER:
                        ui16 = SvIV(ST(2));
                        ui16_2 = SvIV(ST(3));
                        XPUSHs(sv_2mortal(newSViv(TIFFSetField (tif, tag, ui16, ui16_2))));
                        break;

                    /* single uint32 */
                    default:
                        ui32 = SvIV(ST(2));
                        XPUSHs(sv_2mortal(newSViv(TIFFSetField (tif, tag, ui32))));
                        break;
                }

void
tiff_IsTiled (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFIsTiled(tif))));

void
tiff_ScanlineSize (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFScanlineSize(tif))));

void
tiff_StripSize (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFStripSize(tif))));

void
tiff_NumberOfStrips (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFNumberOfStrips(tif))));

void
tiff_TileSize (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFTileSize(tif))));

void
tiff_TileRowSize (tif)
                TIFF            *tif
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFTileRowSize(tif))));

void
tiff_ComputeStrip (tif, row, sample)
                TIFF            *tif
                uint32_t        row
                uint16_t        sample
        PPCODE:
                XPUSHs(sv_2mortal(newSViv(TIFFComputeStrip(tif, row, sample))));

void
tiff_ReadEncodedStrip (tif, strip, size)
                TIFF            *tif
                uint32_t        strip
                tmsize_t        size
	INIT:
                void            *buf;
                tmsize_t        stripsize, bufsize;
        PPCODE:
                stripsize = TIFFStripSize(tif);
                buf = _TIFFmalloc(stripsize);
                bufsize = TIFFReadEncodedStrip(tif, strip, buf, size);
                if (bufsize > 0) {
                    XPUSHs(sv_2mortal(newSVpvn(buf, bufsize)));
                }
		_TIFFfree(buf);

void
tiff_WriteEncodedStrip (tif, strip, data, size)
                TIFF            *tif
                uint32_t        strip
                void*           data
                tmsize_t        size
	INIT:
                tmsize_t        stripsize;
        PPCODE:
                stripsize = TIFFWriteEncodedStrip(tif, strip, data, size);
                XPUSHs(sv_2mortal(newSViv(stripsize)));

void
tiff_ReadRawStrip (tif, strip, size)
                TIFF            *tif
                uint32_t        strip
                tmsize_t        size
	INIT:
                void            *buf;
                tmsize_t        stripsize, bufsize;
        PPCODE:
                stripsize = TIFFStripSize(tif);
                buf = _TIFFmalloc(stripsize);
                bufsize = TIFFReadRawStrip(tif, strip, buf, size);
                if (bufsize > 0) {
                    XPUSHs(sv_2mortal(newSVpvn(buf, bufsize)));
                }
		_TIFFfree(buf);

void
tiff_ReadTile (tif, x, y, z, s)
                TIFF            *tif
                uint32_t        x
                uint32_t        y
                uint32_t        z
                uint16_t        s
	INIT:
                void            *buf;
                tmsize_t        tilesize, bufsize;
        PPCODE:
                tilesize = TIFFTileSize(tif);
                buf = _TIFFmalloc(tilesize);
                bufsize = TIFFReadTile(tif, buf, x, y, z, s);
                if (bufsize > 0) {
                    XPUSHs(sv_2mortal(newSVpvn(buf, bufsize)));
                }
		_TIFFfree(buf);

uint16_t
tiff_CurrentDirectory (tif)
                TIFF            *tif
        CODE:
                RETVAL = TIFFCurrentDirectory(tif);
        OUTPUT:
                RETVAL

void
tiff_PrintDirectory (tif, file, flags)
                TIFF            *tif
                FILE            *file
                long            flags
        CODE:
                TIFFPrintDirectory(tif, file, flags);

void
tiff_ReverseBits (data, size)
                void*           data
                tmsize_t        size
        CODE:
                TIFFReverseBits((uint8_t*) data, size);
