#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "headers.h"

#include <stdio.h>

static const size_t BUF_SIZE = 102400;

typedef enum { 
	UNKNOWN, 
	IMAGE_BMP, 
	IMAGE_GIF, 
	IMAGE_PNG, 
	IMAGE_PSD, 
	IMAGE_JPEG, 
	IMAGE_TIFF,
	IMAGE_ICO
} ImageType;

static const unsigned char  bmp_sig[2]    = {'B', 'M'};

static const unsigned char  gif_sig[3]    = {'G', 'I', 'F'};
static const unsigned char  jpg_sig[3]    = { 0xFF, 0xD8, 0xFF };

static const unsigned char  psd_sig[4]    = {'8', 'B', 'P', 'S'};
static const unsigned char  iitiff_sig[4] = {'I', 'I', 0x2A, 0x00};
static const unsigned char  mmtiff_sig[4] = {'M', 'M', 0x00, 0x2A};
static const unsigned char  ico_sig[8]    = { 0x00, 0x00, 0x01, 0x00};

static const unsigned char  png_sig[8]    = { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };


static const char *bmp_compression[7] = {"None",
                                         "RLE8",
                                         "RLE4",
                                         "BITFIELDS",
                                         "JPEG",
                                         "PNG"
                                        };

static const char *psd_color[10] = {"Mono",
                                    "Grayscale",
                                    "Indexed",
                                    "RGB",
                                    "CMYK",
                                    NULL,
                                    NULL,
                                    "Multichannel"
                                    "Duotone",
                                    "LAB"
                                   };
                                   
static const char *png_color[10] = {"Gray",
                                    NULL,
                                    "RGB",
                                    "Indexed",
                                    "GrayA",
                                    NULL,
                                    "RGBA"
                                   };

static const char *png_filter[5] = {"None",
                                    "Sub",
                                    "Up",
                                    "Average",
                                    "Paeth"
                                   };

static const char *tiff_color[11] = {"WhiteIsZero",
                                     "BlackIsZero",
                                     "RGB",
                                     "Indexed",
                                     "Transparency Mask",
                                     "CMYK",
                                     "YCbCr",
                                     "CIE L*a*b*",
                                     "ICC L*a*b*",
                                     "ITU L*a*b*"
                                    };
                                     



static uint16_t get_uint16(const unsigned char * data, const unsigned short rev_order)
{
	if (rev_order) 
		return (data[0] << 8) | data[1];
	else
		return (data[1] << 8) | data[0];

}

static uint32_t get_uint32(const unsigned char * data, const unsigned short rev_order)
{
	if (rev_order)
		return (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
	else
		return (data[3] << 24) | (data[2] << 16) | (data[1] << 8) | data[0];
}


ImageType get_image_type(const unsigned char *data, const size_t size)
{
	// 2 bytes
	if (size >= 2)
	{
		if (memcmp(data, bmp_sig, 2) == 0) return IMAGE_BMP; 
	}

	if (size >= 3)
	{
		if (memcmp(data, gif_sig, 3) == 0) return IMAGE_GIF;

		if (memcmp(data, jpg_sig, 3) == 0) return IMAGE_JPEG; 
	}

	if (size >= 4)
	{
		if (memcmp(data, psd_sig, 4) == 0) return IMAGE_PSD;

		if (memcmp(data, iitiff_sig, 4) == 0) return IMAGE_TIFF;

		if (memcmp(data, mmtiff_sig, 4) == 0) return IMAGE_TIFF;

		if (memcmp(data, ico_sig, 4) == 0) return IMAGE_ICO;
	}

	if (size >= 8)
	{
		if (memcmp(data, png_sig, 8) == 0) { return IMAGE_PNG; }
	}

}


IV get_png_info(const unsigned char *data, const size_t size, HV *hash)
{
	if (size < sizeof(ImageInfoPNG) + 16) return 0;

	ImageInfoPNG *png = (ImageInfoPNG*) (data + 16);
	
	uint32_t width  = get_uint32(png->width, 1);
	uint32_t height = get_uint32(png->height, 1);

	hv_store(hash, "file_media_type", 15, newSVpv("image/png", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("png", 0), 0);
	
	
	hv_store(hash, "width", 5, newSViv(width), 0);
	hv_store(hash, "height", 6, newSViv(height), 0);
	hv_store(hash, "bits", 4, newSViv(png->depth), 0);
	
	if (png->compression == 0)
		hv_store(hash, "compression", 11, newSVpv("Deflate", 0), 0);
	else
		hv_store(hash, "compression", 11, newSViv(png->compression), 0);
	
	hv_store(hash, "interlace", 9, newSVpv(png->interlace == 1 ? "Adam7" : "None", 0), 0);
	
	if (png->filter < sizeof(png_filter) / sizeof(png_filter[0]))
		hv_store(hash, "filter", 6, newSVpv(png_filter[png->filter], 0), 0);

	if (png->color_type < sizeof(png_color) / sizeof(png_color[0]))
		hv_store(hash, "color_type", 10, newSVpv(png_color[png->color_type], 0), 0);

	return 1;
}

IV get_jpeg_info(const unsigned char *data, const size_t size, HV *hash) 
{
	unsigned long pos = 4;

	uint16_t block_length = get_uint16(data + pos, 1);

	hv_store(hash, "file_media_type", 15, newSVpv("image/jpeg", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("jpg", 0), 0);
	
	
	short unsigned int jpeg_type = 0;
	
	while(pos < size)
	{
		pos += block_length;

		if (pos >= size) return 0; 
		if (data[pos] != 0xFF) return 0;
		
		jpeg_type = data[pos + 1];
		
		switch(jpeg_type)
		{
			case JPEG_TYPE_BASELINE:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Baseline", 0), 0); break;
			case JPEG_TYPE_EXTENDED_SEQUENTIAL:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Extended sequential", 0), 0); break;
			case JPEG_TYPE_PROGRESSIVE:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Progressive", 0), 0); break;
			case JPEG_TYPE_LOSSLESS:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Lossless", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_SEQUENTIAL:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential sequential", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_PROGRESSIVE:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential progressive", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_LOSSLESS:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential lossless", 0), 0); break;
			case JPEG_TYPE_EXTENDED_SEQUENTIAL_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Extended sequential, arithmetic coding", 0), 0); break;
			case JPEG_TYPE_PROGRESSIVE_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Progressive, arithmetic coding", 0), 0); break;
			case JPEG_TYPE_LOSSLESS_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Lossless, arithmetic coding", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_SEQUENTIAL_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential sequential, arithmetic coding", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_PROGRESSIVE_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential progressive, arithmetic coding", 0), 0); break;
			case JPEG_TYPE_DIFFERENTIAL_LOSSLESS_AC:  
				hv_store(hash, "jpeg_type", 9, newSVpv("Differential lossless, arithmetic coding", 0), 0); break;
			default:
				jpeg_type = 0;
		}

		if (jpeg_type > 0)
		{
			// 0xFFC? block: [0xFFC?][ushort length][uchar precision][ushort x][ushort y]
			uint8_t  bits     = data[pos + 4];
			uint16_t height   = get_uint16(data + pos + 5, 1); 
			uint16_t width    = get_uint16(data + pos + 7, 1); 
			uint8_t  num_comp = data[pos + 9];
			
			hv_store(hash, "width", 5, newSViv(width), 0);
			hv_store(hash, "height", 6, newSViv(height), 0);
			hv_store(hash, "bits", 4, newSViv(bits), 0);
			hv_store(hash, "samples_per_pixel", 17, newSViv(num_comp), 0);
			
			
			switch(num_comp)
			{
				case 1:
					hv_store(hash, "color_type", 10, newSVpv("Gray", 0), 0); break;
				case 3:
					hv_store(hash, "color_type", 10, newSVpv("YCbCr", 0), 0); break; //or RGB ?
				case 4:
					hv_store(hash, "color_type", 10, newSVpv("CMYK", 0), 0); break; //or YCCK ?
			}
			
			return 1;
		}
		else
		{
			pos += 2;
			// Next block
			block_length = get_uint16(data + pos, 1);
		}
	}

	return 1;
}

IV get_bmp_info(const unsigned char *data, const size_t size, HV *hash) 
{
	if (size < (14 + sizeof(ImageInfoBMP))) return 0;
	
	ImageInfoBMP *bmp = (ImageInfoBMP*) (data + 14);
	
	hv_store(hash, "file_media_type", 15, newSVpv("image/bmp", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("bmp", 0), 0);
	
	hv_store(hash, "width", 5, newSViv(bmp->biWidth), 0);
	hv_store(hash, "height", 6, newSViv(bmp->biHeight), 0);
	hv_store(hash, "bits", 4, newSViv(bmp->biBitCount), 0);
	hv_store(hash, "x_pixels_per_meter", 18, newSViv(bmp->biXPelsPerMeter), 0);
	hv_store(hash, "y_pixels_per_meter", 18, newSViv(bmp->biYPelsPerMeter), 0);
	hv_store(hash, "colors_used", 11, newSViv(bmp->biClrUsed), 0);
	hv_store(hash, "colors_important", 16, newSViv(bmp->biClrUsed), 0);
	
	if (bmp->biCompression <= sizeof(bmp_compression)/sizeof(bmp_compression[0]))
		hv_store(hash, "compression", 11, newSVpv(bmp_compression[bmp->biCompression], 0), 0);

	if (bmp->biBitCount < 24) 
		hv_store(hash, "color_type", 10, newSVpv("Indexed", 0), 0);
	else
		hv_store(hash, "color_type", 10, newSVpv("RGB", 0), 0);

	return 1;
}

IV get_gif_info(const unsigned char *data, const size_t size, HV *hash) 
{

	if (size < sizeof(ImageInfoGIF)) return 0;

	ImageInfoGIF *gif = (ImageInfoGIF*) (data);
	
	hv_store(hash, "file_media_type", 15, newSVpv("image/gif", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("gif", 0), 0);
	
	hv_store(hash, "width", 5, newSViv(gif->ScreenWidth), 0);
	hv_store(hash, "height", 6, newSViv(gif->ScreenHeight), 0);
	hv_store(hash, "color_type", 10, newSVpv("Indexed", 0), 0);
	
	hv_store(hash, "sorted_colors", 13, newSViv((gif->Packed & 0x08) ? 1 : 0), 0);
	
	hv_store(hash, "bits", 4, newSViv(((gif->Packed & 0x70) >> 4) + 1), 0);
	
	unsigned short color_table_size = 1 << ((gif->Packed & 0x07) + 1);
	hv_store(hash, "color_table_size", 16, newSViv(color_table_size), 0);
	
	hv_store(hash, "background_color", 16, newSViv(gif->BackgroundColor), 0);
	hv_store(hash, "version", 7, newSVpv(gif->Version, 3), 0);
	
	
	if (gif->AspectRatio != 0)
	{
		double aspect_ratio = ((double)(gif->AspectRatio + 15) / 64); 
		hv_store(hash, "aspect_ratio", 12, newSVnv(aspect_ratio), 0);
	}
	
	int pos = sizeof(ImageInfoGIF) + (color_table_size * 3);
	if (size > pos)
	{
		if (memcmp("89a", gif->Version, 3) == 0 && data[pos] == 0xF9)
			hv_store(hash, "animated", 8, newSViv(1), 0);
		else 
			hv_store(hash, "animated", 8, newSViv(0), 0);
	}
	else return 0;
	
	return 1;
}

IV get_psd_info(const unsigned char *data, const size_t size, HV *hash) 
{
	if (size < sizeof(ImageInfoPSD) + 4) return 0;

	ImageInfoPSD *psd = (ImageInfoPSD*) (data + 4);
	
	uint32_t width  = get_uint32(psd->width, 1);
	uint32_t height = get_uint32(psd->height, 1);
	uint16_t depth  = get_uint16(psd->depth, 1);
	uint16_t color_type = get_uint16(psd->mode, 1);
	
	hv_store(hash, "file_media_type", 15, newSVpv(" image/photoshop", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("psd", 0), 0);
	
	hv_store(hash, "width", 5, newSViv(width), 0);
	hv_store(hash, "height", 6, newSViv(height), 0);
	hv_store(hash, "bits", 4, newSViv(depth), 0);
	
	if (color_type < 10)
		hv_store(hash, "color_type", 10, newSVpv(psd_color[color_type], 0), 0);

	return 1;
}

IV get_tiff_info(const unsigned char *data, const size_t size, HV *hash) 
{
	if (size > 8)
	{
		unsigned short rev_order;
		if      (memcmp(data, iitiff_sig, 4) == 0) { rev_order = 0; }
		else if (memcmp(data, mmtiff_sig, 4) == 0) { rev_order = 1; }
		else { return 0; }

		// Get offset to first IFD
		const uint32_t IFDOffset = get_uint32(data + 4, rev_order);
		if (IFDOffset > size) { return 0; }

		// Get number of tags in IFD
		const uint16_t tags = get_uint16(data + IFDOffset, rev_order);
		const uint32_t directory_size = 2 + tags * 12 + 4;
		if (IFDOffset + directory_size > size) { return 0; }

		// Iterate through directory
		unsigned long tag_num = 0;
		for(tag_num = 0; tag_num < tags; ++tag_num)
		{
			unsigned long tag_value = 0;
			const unsigned long entry_offset = IFDOffset + 2 + tag_num * 12;

			const unsigned char *entry   = data + entry_offset;
			const uint16_t tag      = get_uint16(entry + 0, rev_order);
			const uint16_t tag_type = get_uint16(entry + 2, rev_order);
			
			switch(tag_type)
			{
				case TIFF_TAG_FMT_BYTE:
				case TIFF_TAG_FMT_SBYTE:
					tag_value = entry[8];
					break;
				case TIFF_TAG_FMT_USHORT:
					tag_value = get_uint16(entry + 8, rev_order);
					break;
				case TIFF_TAG_FMT_SSHORT:
					tag_value = get_uint16(entry + 8, rev_order);
					break;
				case TIFF_TAG_FMT_ULONG:
					tag_value = get_uint32(entry + 8, rev_order);
					break;
				case TIFF_TAG_FMT_SLONG:
					tag_value = get_uint32(entry + 8, rev_order);
					break;
				default:
					continue;
			}

			switch(tag)
			{
				case TIFF_TAG_IMAGEWIDTH:
					hv_store(hash, "width", 5, newSViv(tag_value), 0);
					break;
				case TIFF_TAG_COMP_IMAGEWIDTH:
					hv_store(hash, "exif_width", 10, newSViv(tag_value), 0);
					break;
				case TIFF_TAG_IMAGEHEIGHT:
					hv_store(hash, "height", 6, newSViv(tag_value), 0);
					break;
				case TIFF_TAG_COMP_IMAGEHEIGHT:
					hv_store(hash, "exif_height", 11, newSViv(tag_value), 0);
					break;
				case TIFF_TAG_BITS:
//					hv_store(hash, "bits", 4, newSViv(tag_value), 0);
					break;
				case TIFF_TAG_COMPRESSION:
					switch(tag_value)
					{
						case TIFF_COMPRESSION_NONE:
							hv_store(hash, "compression", 11, newSVpv("None",0), 0); 
							break;
						case TIFF_COMPRESSION_CCITTRLE:
							hv_store(hash, "compression", 11, newSVpv("CCITT modified Huffman RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_CCITTFAX3:
							hv_store(hash, "compression", 11, newSVpv("CCITT Group 3 fax encoding",0), 0); 
							break;
						case TIFF_COMPRESSION_CCITTFAX4:
							hv_store(hash, "compression", 11, newSVpv("CCITT Group 4 fax encoding",0), 0); 
							break;
						case TIFF_COMPRESSION_LZW:
							hv_store(hash, "compression", 11, newSVpv("LZW",0), 0); 
							break;
						case TIFF_COMPRESSION_OJPEG:
							hv_store(hash, "compression", 11, newSVpv("Original JPEG / Old-style JPEG (6.0)",0), 0); 
							break;
						case TIFF_COMPRESSION_JPEG:
							hv_store(hash, "compression", 11, newSVpv("JPEG",0), 0); 
							break;
						case TIFF_COMPRESSION_NEXT:
							hv_store(hash, "compression", 11, newSVpv("NeXT 2-bit RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_CCITTRLEW:
							hv_store(hash, "compression", 11, newSVpv("CCITT RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_PACKBITS:
							hv_store(hash, "compression", 11, newSVpv("Macintosh RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_THUNDERSCAN:
							hv_store(hash, "compression", 11, newSVpv("ThunderScan RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_IT8CTPAD:
							hv_store(hash, "compression", 11, newSVpv("IT8 CT w/padding",0), 0); 
							break;
						case TIFF_COMPRESSION_IT8LW:
							hv_store(hash, "compression", 11, newSVpv("IT8 Linework RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_IT8MP:
							hv_store(hash, "compression", 11, newSVpv("IT8 Monochrome picture",0), 0); 
							break;
						case TIFF_COMPRESSION_IT8BL:
							hv_store(hash, "compression", 11, newSVpv("IT8 Binary line art",0), 0); 
							break;
						case TIFF_COMPRESSION_PIXARFILM:
							hv_store(hash, "compression", 11, newSVpv("Pixar companded 10bit LZW",0), 0); 
							break;
						case TIFF_COMPRESSION_PIXARLOG:
							hv_store(hash, "compression", 11, newSVpv("Pixar companded 11bit ZIP",0), 0); 
							break;
						case TIFF_COMPRESSION_DEFLATE:
							hv_store(hash, "compression", 11, newSVpv("Deflate",0), 0); 
							break;
						case TIFF_COMPRESSION_ADOBE_DEFLATE:
							hv_store(hash, "compression", 11, newSVpv("Adobe deflate",0), 0); 
							break;
						case TIFF_COMPRESSION_DCS:
							hv_store(hash, "compression", 11, newSVpv("Kodak DCS",0), 0); 
							break;
						case TIFF_COMPRESSION_JBIG:
							hv_store(hash, "compression", 11, newSVpv("ISO JBIG",0), 0); 
							break;
						case TIFF_COMPRESSION_SGILOG:
							hv_store(hash, "compression", 11, newSVpv("SGI Log Luminance RLE",0), 0); 
							break;
						case TIFF_COMPRESSION_SGILOG24:
							hv_store(hash, "compression", 11, newSVpv("SGI Log 24-bit",0), 0); 
							break;
						case TIFF_COMPRESSION_JP2000:
							hv_store(hash, "compression", 11, newSVpv("JPEG2000",0), 0); 
							break;
					}
					break;
				case TIFF_TAG_COLORTYPE:
					if (tag_value <= sizeof(tiff_color) / sizeof(tiff_color[0]))
						hv_store(hash, "color_type", 10, newSVpv(tiff_color[tag_value], 0), 0);
					break;
			}
		}
	}
	
	hv_store(hash, "file_media_type", 15, newSVpv("image/tiff", 0), 0);
	hv_store(hash, "file_ext", 8, newSVpv("tif", 0), 0);
	
	return 1;
}


IV get_ico_info(const unsigned char *data, const size_t size, HV *hash) 
{
	if (size > 8)
	{
		unsigned long pos = 4;


		hv_store(hash, "file_media_type", 15, newSVpv("image/x-icon", 0), 0);
		hv_store(hash, "file_ext", 8, newSVpv("ico", 0), 0);

		uint16_t icon_count = (data[pos + 1] << 8) | data[pos];

		hv_store(hash, "icon_count", 10, newSViv(icon_count), 0);

		unsigned long offset = (icon_count - 1) * sizeof(ImageInfoICO);
		
		pos += offset + 2;
		
		if (size < (4 + offset + sizeof(ImageInfoICO))) return 0;
		
		ImageInfoICO *ico = (ImageInfoICO*) (data + pos);
		
		hv_store(hash, "width", 5, newSViv(ico->width), 0);
		hv_store(hash, "height", 6, newSViv(ico->height), 0);
		hv_store(hash, "bits", 4, newSViv(ico->bitCount), 0);
		
		if (ico->nColors == 0)
		{
			hv_store(hash, "color_type", 10, newSVpv("RGB", 0), 0);
			hv_store(hash, "colors", 6, newSViv(256), 0);
		}
		else
		{
			hv_store(hash, "color_type", 10, newSVpv("Indexed", 0), 0);
			hv_store(hash, "colors", 6, newSViv(ico->nColors), 0);
		}
	}
	
	return 1;
}



MODULE = Image::Info::XS		PACKAGE = Image::Info::XS		

SV* image_info(source)
	SV *source;
	PREINIT:
	size_t image_data_size;
	unsigned char *image_data;
	unsigned short from_file = 0;
	
	CODE:
		if (SvTYPE(source) == SVt_PV)
		{
			FILE *f = fopen(SvPV_nolen(source), "r");
			if (!f) 
			{
				warn("File open error");
				XSRETURN_UNDEF;
			}
			
			image_data = malloc(BUF_SIZE);
			image_data_size = fread(image_data, 1, BUF_SIZE, f);
			
			fclose(f);
			
			from_file = 1;
		}
		else if (SvROK(source) && SvTYPE(SvRV(source)) == SVt_PV)
		{
			image_data_size = SvCUR(SvRV(source));
			image_data = SvPV_nolen(SvRV(source));
			
		}
		else XSRETURN_UNDEF;
		
		ImageType image_type = get_image_type(image_data, image_data_size);
		
		HV *hash = newHV();
		
		unsigned short result = 0;
		
		switch(image_type)
		{
			case IMAGE_BMP: result = get_bmp_info(image_data, image_data_size, hash); break;

			case IMAGE_GIF: result = get_gif_info(image_data, image_data_size, hash);break;

			case IMAGE_PNG: result = get_png_info(image_data, image_data_size, hash); break;

			case IMAGE_PSD: result = get_psd_info(image_data, image_data_size, hash); break;

			case IMAGE_JPEG: result = get_jpeg_info(image_data, image_data_size, hash); break;

			case IMAGE_TIFF: result = get_tiff_info(image_data, image_data_size, hash); break;

			case IMAGE_ICO: result = get_ico_info(image_data, image_data_size, hash); break;

		}
		
		if (from_file) free(image_data);
		
		if (result == 1) 
			RETVAL = newRV_noinc((SV*) hash);
		else 
		{
			SvREFCNT_dec((SV*) hash);
			XSRETURN_UNDEF;
		}
	OUTPUT:
		RETVAL


SV* image_type(source)
	SV *source;
	PREINIT:
	size_t image_data_size;
	unsigned char *image_data;
	unsigned short from_file = 0;
	
	CODE:
		if (SvTYPE(source) == SVt_PV)
		{

			FILE *f = fopen(SvPV_nolen(source), "r");
			if (!f) 
			{
				warn("File open error");
				XSRETURN_UNDEF;
			}
			
			image_data = malloc(BUF_SIZE);
			image_data_size = fread(image_data, 1, BUF_SIZE, f);
			
			fclose(f);
			
			from_file = 1;
		}
		if (SvROK(source) && SvTYPE(SvRV(source)) == SVt_PV)
		{
			image_data_size = SvCUR(SvRV(source));
			image_data = SvPV_nolen(SvRV(source));
			
		}
		
		ImageType image_type = get_image_type(image_data, image_data_size);
		
		if (from_file) free(image_data);
		
		RETVAL = NULL;
		
		switch(image_type)
		{
			case IMAGE_BMP: RETVAL = newSVpv("BMP", 0); break;

			case IMAGE_GIF: RETVAL = newSVpv("GIF", 0); break;

			case IMAGE_PNG: RETVAL = newSVpv("PNG", 0); break;

			case IMAGE_PSD: RETVAL = newSVpv("PSD", 0); break;

			case IMAGE_JPEG: RETVAL = newSVpv("JPEG", 0); break;

			case IMAGE_TIFF: RETVAL = newSVpv("TIFF", 0); break;

			case IMAGE_ICO: RETVAL = newSVpv("ICO", 0); break;
		}
		
	OUTPUT:
		RETVAL
