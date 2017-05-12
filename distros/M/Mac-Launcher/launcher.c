#include "launcher.h"

/*Function to launch URL with default app.*/
void launchurl(char* url) {


  //get url string, convert to CFURL
  CFStringRef baseurl = CFStringCreateWithCString(NULL, url,kCFStringEncodingUTF8);
  CFURLRef runurl = CFURLCreateWithString(kCFAllocatorDefault, baseurl, NULL);
  CFRelease(baseurl);

  //fire URL in default app
  LSOpenCFURLRef(runurl, NULL);

  CFRelease(runurl);

}

/*Function to launch file with default app.*/
void launchfile(char* filepath) {

 
  //get url string, convert to CFURL
  CFStringRef baseurl = CFStringCreateWithCString(NULL, filepath, kCFStringEncodingUTF8);
  CFRelease(baseurl);

  CFURLRef runurl = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, baseurl, kCFURLPOSIXPathStyle, false);

  //fire URL in default app
  LSOpenCFURLRef(runurl, NULL);

  CFRelease(runurl);

}
