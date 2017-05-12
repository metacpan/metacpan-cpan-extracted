
#include <X11/keysym.h>
#include <il/ilImage.h>
#include <ifl/iflMinMax.h>

#include "imgProcess.h"
#include "imgDisplay.h"

imgDisplay::~imgDisplay()
{

}

imgDisplay::imgDisplay(imgProcess *image)
{
  iflXYint winSize(image->_image->getXsize(), image->_image->getYsize());
  int Xattributes = ilVisDoubleBuffer;

  _display = XOpenDisplay(NULL);

  if (_display != NULL) {

    int screen = DefaultScreen(_display);
    winSize.x = iflMin(winSize.x, DisplayWidth(_display, screen));
    winSize.y = iflMin(winSize.y, DisplayHeight(_display, screen));
    
    // Create X window viewer
    ilViewer viewer(_display, winSize.x, winSize.y, 
		    Xattributes);
    
    viewer.addView(image->_image, ilLast, ilClip|ilCenter|ilDefer);
    viewer.setStop(TRUE);
    
    XEvent event;
    short done = FALSE;
    while (!done) {

      XNextEvent(_display, &event);

      switch (event.type) {
      
      case KeyPress:
	switch(XLookupKeysym(&event.xkey, 0)) {
	  // center the selected view(s) in the viewer
	case XK_Home:
	  viewer.display(NULL, ilCenter|ilClip);
	  break;
	  
	  // control-Q and escape exit the program
	case XK_q:
	  if (!(event.xkey.state&ControlMask))
	    break;
	  /*FALLTHROUGH*/
	case XK_Escape:
	  done = TRUE;
	  break;
	  
	  // raise and lower the current view(s)
	case XK_Up:
	  viewer.raise();
	  break;
	case XK_Down:
	  viewer.lower();
	  break;
	  
	  // enable/disable paint pipelining
	case XK_p:
	  viewer.enableQueueing(!viewer.isQueueingEnabled());
	  break;
	}
	break;
	
      case DestroyNotify: 
	viewer.destroyNotify();
	done = TRUE; 
	break;
	
      default: 
	viewer.event(&event);
	break;
      }
    }
    viewer.remove();
    XCloseDisplay(_display);
  }
}
