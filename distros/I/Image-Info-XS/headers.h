#include <sys/types.h>

typedef struct ImageInfoBMPStruct    /**** BMP file info structure ****/
{
	uint32_t   biSize;           /* Size of info header */
	uint32_t   biWidth;          /* Width of image */
	uint32_t   biHeight;         /* Height of image */
	uint16_t   biPlanes;         /* Number of color planes */
	uint16_t   biBitCount;       /* Number of bits per pixel */
	uint32_t   biCompression;    /* Type of compression to use */
	uint32_t   biSizeImage;      /* Size of image data */
	uint32_t   biXPelsPerMeter;  /* X pixels per meter */
	uint32_t   biYPelsPerMeter;  /* Y pixels per meter */
	uint32_t   biClrUsed;        /* Number of colors used */
	uint32_t   biClrImportant;   /* Number of important colors */
} ImageInfoBMP;

typedef struct ImageInfoICOStruct
{
	uint8_t  width;
	uint8_t  height;
	uint8_t  nColors;
	uint8_t  reserved;
	uint16_t nPlanes;
	uint16_t bitCount;
	uint32_t sizeInBytes;
	uint32_t fileOffset;
} ImageInfoICO;


typedef struct ImageInfoPNGStruct
{
	unsigned char width[4];
	unsigned char height[4];
	uint8_t depth;
	uint8_t color_type;
	uint8_t compression;
	uint8_t filter;
	uint8_t interlace;

} ImageInfoPNG;

typedef struct ImageInfoGIFStruct
{
	unsigned char Header[3];
	unsigned char Version[3];
	uint16_t      ScreenWidth;      /* Width of Display Screen in Pixels */
	uint16_t      ScreenHeight;     /* Height of Display Screen in Pixels */
	uint8_t       Packed;           /* Screen and Color Map Information */
	uint8_t       BackgroundColor;  /* Background Color Index */
	uint8_t       AspectRatio;      /* Pixel Aspect Ratio */
} ImageInfoGIF;

typedef struct ImageInfoPSDStruct
{
	uint16_t version;
	unsigned char reserved[6];
	unsigned char channels[2];
	unsigned char height[4];
	unsigned char width[4];
	unsigned char depth[2];
	unsigned char mode[2];

} ImageInfoPSD;



#define TIFF_TAG_IMAGEWIDTH        0x0100
#define TIFF_TAG_IMAGEHEIGHT       0x0101
#define TIFF_TAG_BITS              0x0102
#define TIFF_TAG_COMPRESSION       0x0103
#define TIFF_TAG_COLORTYPE         0x0106
#define TIFF_TAG_COMP_IMAGEWIDTH   0xA002
#define TIFF_TAG_COMP_IMAGEHEIGHT  0xA003

#define TIFF_TAG_FMT_BYTE           1
#define TIFF_TAG_FMT_STRING         2
#define TIFF_TAG_FMT_USHORT         3
#define TIFF_TAG_FMT_ULONG          4
#define TIFF_TAG_FMT_URATIONAL      5
#define TIFF_TAG_FMT_SBYTE          6
#define TIFF_TAG_FMT_UNDEFINED      7
#define TIFF_TAG_FMT_SSHORT         8
#define TIFF_TAG_FMT_SLONG          9
#define TIFF_TAG_FMT_SRATIONAL     10
#define TIFF_TAG_FMT_SINGLE        11
#define TIFF_TAG_FMT_DOUBLE        12


#define TIFF_COMPRESSION_NONE          1
#define TIFF_COMPRESSION_CCITTRLE      2
#define TIFF_COMPRESSION_CCITTFAX3     3
#define TIFF_COMPRESSION_CCITTFAX4     4
#define TIFF_COMPRESSION_LZW           5
#define TIFF_COMPRESSION_OJPEG         6
#define TIFF_COMPRESSION_JPEG          7
#define TIFF_COMPRESSION_NEXT          32766
#define TIFF_COMPRESSION_CCITTRLEW     32771
#define TIFF_COMPRESSION_PACKBITS      32773
#define TIFF_COMPRESSION_THUNDERSCAN   32809
#define TIFF_COMPRESSION_IT8CTPAD      32895
#define TIFF_COMPRESSION_IT8LW         32896
#define TIFF_COMPRESSION_IT8MP         32897
#define TIFF_COMPRESSION_IT8BL         32898
#define TIFF_COMPRESSION_PIXARFILM     32908
#define TIFF_COMPRESSION_PIXARLOG      32909
#define TIFF_COMPRESSION_DEFLATE       32946
#define TIFF_COMPRESSION_ADOBE_DEFLATE 8
#define TIFF_COMPRESSION_DCS           32947
#define TIFF_COMPRESSION_JBIG          34661
#define TIFF_COMPRESSION_SGILOG        34676
#define TIFF_COMPRESSION_SGILOG24      34677
#define TIFF_COMPRESSION_JP2000        34712


#define JPEG_TYPE_BASELINE                     0xC0
#define JPEG_TYPE_EXTENDED_SEQUENTIAL          0xC1
#define JPEG_TYPE_PROGRESSIVE                  0xC2
#define JPEG_TYPE_LOSSLESS                     0xC3
#define JPEG_TYPE_DIFFERENTIAL_SEQUENTIAL      0xC5
#define JPEG_TYPE_DIFFERENTIAL_PROGRESSIVE     0xC6
#define JPEG_TYPE_DIFFERENTIAL_LOSSLESS        0xC7
#define JPEG_TYPE_EXTENDED_SEQUENTIAL_AC       0xC9
#define JPEG_TYPE_PROGRESSIVE_AC               0xCA
#define JPEG_TYPE_LOSSLESS_AC                  0xCB
#define JPEG_TYPE_DIFFERENTIAL_SEQUENTIAL_AC   0xCD
#define JPEG_TYPE_DIFFERENTIAL_PROGRESSIVE_AC  0xCE
#define JPEG_TYPE_DIFFERENTIAL_LOSSLESS_AC     0xCF
