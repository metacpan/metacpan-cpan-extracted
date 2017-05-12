#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <iostream.h>

#include "camera.h"
#include "imager.h"

//#include "rcfile.h"

#include "config.h"

#define NL "\n";

// Ofcourse a lot of this code is just from cqcam.C
// but I had to base my code on something :)

static float bulb = -1;
static int auto_adj = AUTO_ADJ_DEFAULT;
static int red = -1, green = -1, blue = -1;
static int iport = DEFAULT_PORT, idetect = DEFAULT_DETECT_MODE;
static int ibpp = DEFAULT_BPP;
static int idecimation = DEFAULT_DECIMATION;
static int width = 320;
static int height = 240;
static char *filename = "default.jpg";
static int use_file = 0;
static int debug = 0;
static int http = 0;
static int ways_to_leave_your_lover = 50;
#ifdef JPEG
static int jpeg = 1, jpeg_quality = 50;
#endif

class MyClass {
public:
 MyClass ()
 { if (debug) { cout << "Device::QuickCam instantiated" << NL; }
 }

 // Default is 50%
 void set_quality (int q)
 { if (q > 100 || q < 1)
   { q = jpeg_quality; }
   jpeg_quality = q; 
   if (debug) { cout << "JPEG Quality is " << jpeg_quality << NL; }
 }

 // Default is 24 bits
 // Possible values : 24 or 32
 void set_bpp (int q)
 { if (q != 24 && q != 32)
   { q = 24; }
   ibpp = q;
   if (debug) { cout << "Bits per Pixel is " << ibpp << NL; }
 }
 
 // 640 is apparently a maximum width
 void set_width (int q)
 { if (q > 640 || q <  0)
   { q = width; }
   width = q; 
   if (debug) { cout << "Width is " << width << NL; }
 }

 // 480 is apparently a maximum height
 void set_height (int q)
 { if (q > 480 || q <  0)
   { q = height; }
   height = q; 
   if (debug) { cout << "Height is " << height << NL; }
 }

 // 1:1 2:1 or 4:1 decimation bits per pixel
 void set_decimation (int q)
 { if (q != 1 && q != 2 && q != 4)
   { q = idecimation; }
   idecimation = q; 
   if (debug) { cout << "Decimation is " << idecimation << NL; }
 }

 // Filename
 void set_file (char *f)
 { filename = f;
   use_file = 1; 
   if (debug) { cout << "Output file is " << filename << NL; }
 }

 // Define port
 // 0 is autodetect
 // 0x378, 0x278 and 0x3bc are possible values
 void set_port (int p)
 { if (p != 0 && p != 0x378 && p != 0x278 && p != 0x3bc)
   { p = 0; }
   iport = p; 
   if (debug) { cout << "Port is " << iport << NL; }
 }

 // 0-255 is a valid range
 void set_red (int q)
 { if (q > 255 || q <  0)
   { q = red; }
   red = q; 
   if (debug) { cout << "Red factor is " << red << NL; }
 }

 // 0-255 is a valid range
 void set_green (int q)
 { if (q > 255 || q <  0)
   { q = green; }
   green = q; 
   if (debug) { cout << "Green factor is " << green << NL; }
 }

 // 0-255 is a valid range
 void set_blue (int q)
 { if (q > 255 || q <  0)
   { q = blue; }
   blue = q; 
   if (debug) { cout << "Blue factor is " << blue << NL; }
 }

 // 0 to turn off debugging
 // 1 to turn on debugging
 void set_debug (int q)
 { if (q != 0 && q != 1)
   { q = debug; }
   debug = q; 
   if (debug) { cout << "Debugging is " << debug << NL; }
 }

 // 0 to turn off HTTP support
 // 1 to turn on HTTP support
 void set_http (int q)
 { if (q != 0 && q != 1)
   { q = http; }
   http = q; 
   if (debug) { cout << "HTTP Mode is " << debug << NL; }
 }


 //automatically adjust brightness and color balance on startup?  
 //1=yes, 0=no
 void set_autoadj (int q)
 { if (q != 1 && q !=  0)
   { q = auto_adj; }
   auto_adj = q; 
   if (debug) { cout << "Auto Adjust is " << auto_adj << NL; }
 }

 void grab ()
 { FILE *out;
   camera_t camera(iport, idetect); // probe for and initialize the beast
   if (debug) { cout << "Grabbing..." << NL; }
#ifndef LYNX
  setgid(getgid());
  setuid(getuid());
#endif
  camera.set_bpp(ibpp);
  camera.set_decimation(idecimation);
  camera.set_width(width);
  camera.set_height(height);
  unsigned char *scan;
  int width = camera.get_pix_width();
  int height = camera.get_pix_height();

  if (auto_adj) {
    int done = 0;
    int upper_bound = 253, lower_bound = 5, loops = 0;
    do {
      scan = camera.get_frame();
      if (camera.get_bpp() == 32)
        scan = raw32_to_24(scan, width, height);
      int britemp = 0;
      done = get_brightness_adj(scan, width * height, britemp);
      if (!done) {
        int cur_bri = camera.get_brightness() + britemp;
        if (cur_bri > upper_bound)
          cur_bri = upper_bound - 1;
        if (cur_bri < lower_bound)
          cur_bri = lower_bound + 1;
        if (britemp > 0)
          lower_bound = camera.get_brightness() + 1;
        else
          upper_bound = camera.get_brightness() - 1;

        camera.set_brightness(cur_bri);
        delete[] scan;
      }
    } while (!done && upper_bound > lower_bound && ++loops <= 10);
    scan = camera.get_frame();
    if (camera.get_bpp() == 32)
      scan = raw32_to_24(scan, width, height);
  }
  else {
    if (bulb != -1) {
      scan = camera.get_frame();
      delete[] scan;
      camera.set_brightness(255);
      fprintf(stderr, "Bulb mode: sleeping %d microseconds\n",
        (int)(1000000*bulb));
      usleep((int)(1000000*bulb));
    }
    scan = camera.get_frame();
    if (camera.get_bpp() == 32)
      scan = raw32_to_24(scan, width, height);
  }

  if (red == -1 && green == -1 && blue == -1) {
    get_rgb_adj(scan, width * height, red, green, blue);
  }
  else {
    if (red == -1) red = 128;
    if (green == -1) green = 128;
    if (blue == -1) blue = 128;
  }
  camera.set_red(red);
  camera.set_green(green);
  camera.set_blue(blue);

#ifdef DESPECKLE
  if (camera.get_bpp() == 24)
    scan = despeckle(scan, width, height);
#endif

  do_rgb_adj(scan, width * height,
    camera.get_red(), camera.get_green(), camera.get_blue());

#ifdef JPEG
  if (jpeg)
    if(use_file)
    { out = fopen(filename, "w");
      write_jpeg(out, scan, width, height, jpeg_quality);
      fclose(out);
    }
    else
    { if(http)
      { cout << "Content-type: image/jpeg\n\n"; }
      write_jpeg(stdout, scan, width, height, jpeg_quality); }
  #else
#endif
//    write_ppm(stdout, scan, width, height);

  delete[] scan;
}

~MyClass() { 
   if (debug) { cout << "Destroy" << NL; }
}

};

/* 'E's not pinin'! 'E's passed on! This parrot is no more!
   He has ceased to be! 'E's expired and gone to meet 'is maker!
   'E's a stiff! Bereft of life, 'e rests in peace! If you hadn't 
   nailed 'im to the perch, 'e'd be pushing up the daisies!
   'Is metabolic processes are now 'istory! 'E's off the twig!
   'E's kicked the bucket, 'E's shuffled off 'is mortal coil,
   run down the curtain and joined the bleedin' choir invisible!!
   THIS IS AN EX-PARROT
*/
  
MODULE = Device::QuickCam		PACKAGE = Device::QuickCam		

MyClass * 
MyClass::new()

void 
MyClass::grab()

void 
MyClass::set_quality(int q)

void 
MyClass::set_bpp(int q)

void 
MyClass::set_width(int q)

void 
MyClass::set_height(int q)

void 
MyClass::set_red(int q)

void 
MyClass::set_green(int q)

void 
MyClass::set_blue(int q)

void 
MyClass::set_decimation(int q)

void 
MyClass::set_autoadj(int q)

void 
MyClass::set_port(int q)

void 
MyClass::set_debug(int q)

void 
MyClass::set_http(int q)

void 
MyClass::set_file(char *f)

void 
MyClass::DESTROY()
