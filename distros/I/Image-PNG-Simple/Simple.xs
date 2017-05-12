#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "png.h"
#include <stdio.h>

#include "BmpIoLib.h"

/* Windows setjmp and longjmp don't work by Perl default */
#if defined(_WIN32) || defined(_WIN64)
#  undef setjmp
#  undef longjmp

#  if defined(__MINGW32__)
     // Copied from MinGW setjmp.h
#    ifdef _WIN64
#      if (__MINGW_GCC_VERSION < 40702)
#        define setjmp(BUF) _setjmp((BUF), mingw_getsp())
#      else
#        define setjmp(BUF) _setjmp((BUF), __builtin_frame_address (0))
#      endif
#    else
#      define setjmp(BUF) _setjmp3((BUF), NULL)
#    endif
     __declspec(noreturn) __attribute__ ((__nothrow__)) void __cdecl longjmp(jmp_buf _Buf,int _Value);
#  else
#    include <setjmp.h>
#  endif
#endif

typedef struct {
  IBMP* pBmp;
} ImagePNGSimple;

MODULE = Image::PNG::Simple PACKAGE = Image::PNG::Simple

SV
new(...)
  PPCODE:
{
  char* class_name = SvPV_nolen(ST(0));
  
  ImagePNGSimple* ips = (ImagePNGSimple*)malloc(sizeof(ImagePNGSimple));
  
  size_t ips_iv = PTR2IV(ips);
  
  SV* ips_sv = sv_2mortal(newSViv(ips_iv));
  
  SV* ips_svrv = sv_2mortal(newRV_inc(ips_sv));
  
  SV* ips_obj = sv_bless(ips_svrv, gv_stashpv(class_name, 1));
  
  XPUSHs(ips_obj);
  XSRETURN(1);
}

SV
DESTORY(...)
  PPCODE:
{
  SV* ips_obj = ST(0);
  SV* ips_sv = SvROK(ips_obj) ? SvRV(ips_obj) : ips_obj;
  size_t ips_iv = SvIV(ips_sv);
  ImagePNGSimple* ips = INT2PTR(ImagePNGSimple*, ips_iv);
  
  if (ips->pBmp != NULL) {
    free(ips->pBmp);
  }
  free(ips);
  
  XSRETURN(0);
}

SV
read_bmp_file(...)
  PPCODE :
{
  SV* ips_obj = ST(0);
  SV* ips_sv = SvROK(ips_obj) ? SvRV(ips_obj) : ips_obj;
  size_t ips_iv = SvIV(ips_sv);
  ImagePNGSimple* ips = INT2PTR(ImagePNGSimple*, ips_iv);
  
  // Open bitmap file
  SV* sv_file = ST(1);
  char* file = SvPV_nolen(sv_file);
  FILE* in_fh = fopen(file, "rb");
  if (in_fh ==  NULL) {
    croak("Can't open bitmap file %s", file);
  }
  
  // Create bitmap data
  IBMP *pBmp = BmpIO_Load(in_fh);
  fclose(in_fh);
  if (pBmp == NULL) {
    croak("Can't parse bitmap file %s", file);
  }
  ips->pBmp = pBmp;
  
  XSRETURN(0);
}

SV
write_bmp_file(...)
  PPCODE:
{
  SV* ips_obj = ST(0);
  SV* ips_sv = SvROK(ips_obj) ? SvRV(ips_obj) : ips_obj;
  size_t ips_iv = SvIV(ips_sv);
  ImagePNGSimple* ips = INT2PTR(ImagePNGSimple*, ips_iv);

  // Not exists bitmap data
  if (ips->pBmp == NULL) {
    croak("Can't write bitmap because bitmap data is not loaded");
  }
    
  // Open file for write
  SV* sv_file = ST(1);
  char* file = SvPV_nolen(sv_file);
  FILE* out_fh = fopen(file, "wb" );
  if (out_fh ==  NULL) {
    croak("Can't open file %s for writing", file);
  }  
  BmpIO_Save(out_fh, ips->pBmp);
  fclose(out_fh);

  XSRETURN(0);
}

SV
write_png_file(...)
  PPCODE:
{
  SV* ips_obj = ST(0);
  SV* ips_sv = SvROK(ips_obj) ? SvRV(ips_obj) : ips_obj;
  size_t ips_iv = SvIV(ips_sv);
  ImagePNGSimple* ips = INT2PTR(ImagePNGSimple*, ips_iv);

  // Bitmap information
  IBMP* pBmp = ips->pBmp;

  // Not exists bitmap data
  if (ips->pBmp == NULL) {
    croak("Can't write bitmap because bitmap data is not loaded");
  }
    
  // Open file for write
  SV* sv_file = ST(1);
  char* file = SvPV_nolen(sv_file);
  FILE* out_fh = fopen(file, "wb" );
  if (out_fh ==  NULL) {
    croak("Can't open file %s for writing", file);
  }
  
  // PNG information
  IV x;
  IV y;
  
  // Create png write struct
  png_structp png = png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL);
  if (png == NULL)
  {
    fclose(out_fh);
    croak("Fail png_create_write_struct");
  }
  
  // Create png information
  png_infop info = png_create_info_struct(png);
  if (info == NULL) {
    png_destroy_write_struct(&png, (png_infopp)NULL);
    fclose(out_fh);
    croak("Fail png_create_info_struct");
  }
  
  // Set png error callback
  png_bytep* lines = NULL;
  if (setjmp(png_jmpbuf(png))) {
    png_destroy_write_struct(&png, &info);
    if (lines != NULL) {
      free(lines);
    }
    fclose(out_fh);
    croak("libpng internal error");
  }
  
  // Initialize png IO
  png_init_io(png, out_fh);
  
  // Image width
  IV bmp_height = BmpIO_GetHeight(pBmp);
  
  // Image height
  IV bmp_width = BmpIO_GetWidth(pBmp);
  
  // Set png IHDR
  IV bit_per_pixcel = BmpIO_GetBitPerPixcel(pBmp);
  png_set_IHDR(png, info, bmp_width, bmp_height, 8, 
      (bit_per_pixcel == 32 ? PNG_COLOR_TYPE_RGB_ALPHA : PNG_COLOR_TYPE_RGB),
      PNG_INTERLACE_NONE, PNG_COMPRESSION_TYPE_DEFAULT, PNG_FILTER_TYPE_BASE);

  // Set png sbit
  png_color_8 sBIT;
  sBIT.red = 8;
  sBIT.green = 8;
  sBIT.blue = 8;
  sBIT.alpha = (png_byte)(bit_per_pixcel == 32 ? 8 : 0);
  png_set_sBIT(png, info, &sBIT);
  
  // Write png information
  png_write_info(png, info);
  
  // Set png bgr
  png_set_bgr(png);
  
  // Set png lines
  unsigned char* rgb_data = malloc(bmp_height * bmp_width * 3);
  lines = (png_bytep *)malloc(sizeof(png_bytep *) * bmp_height);
  for (y = 0; y < bmp_height; y++) {
    for (x = 0; x < bmp_width; x++) {
      rgb_data[((bmp_height - y - 1) * bmp_width * 3) + (x * 3)] = BmpIO_GetB(x, y, pBmp);
      rgb_data[((bmp_height - y - 1) * bmp_width * 3) + (x * 3) + 1] = BmpIO_GetG(x, y, pBmp);
      rgb_data[((bmp_height - y - 1) * bmp_width * 3) + (x * 3) + 2] = BmpIO_GetR(x, y, pBmp);
    }
    lines[y] = (png_bytep)&(rgb_data[y * bmp_width * 3]);
  }
  
  // Write png image
  png_write_image(png, lines);
  png_write_end(png, info);
  png_destroy_write_struct(&png, &info);
  
  // Release resource
  free(lines);
  free(rgb_data);
  BmpIO_DeleteBitmap(pBmp);
  fclose(out_fh);

  XSRETURN(0);
}
