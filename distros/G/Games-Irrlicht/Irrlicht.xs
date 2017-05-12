#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdlib.h>
#include <Irrlicht/irrlicht.h>
#include <time.h>

struct timespec my_time_spec;

/* ************************************************************************ */
/* our framerate monitor memory */
#define FRAMES_MAX 4096
unsigned int frames[FRAMES_MAX] = { 0 };
/* two pointers into the ringbuffer frames[] */
unsigned int frames_start = 0;
unsigned int frames_end = 0;
unsigned int last = 0;

double max_fps = 0;
double min_fps = 20000000;

unsigned int max_frame_time = 0;
unsigned int min_frame_time = 20000;

/* wake_time: the time we waited to long in this frame, and thus must be awake
   (e.g. not sleep) the next frame to correct for this */
unsigned int wake_time = 0;

/* ************************************************************************ */
using namespace irr;

using namespace core;
using namespace scene;
using namespace video;
using namespace gui;
// this clashes with XSUBPP
//using namespace io;

IrrlichtDevice* device;
IVideoDriver* driver;
ISceneManager* smgr;
IGUIEnvironment* guienv;
ITimer* timer;
irr::io::IFileSystem* filesystem;

/* ************************************************************************ */

/*
To get events like mouse and keyboard input, or GUI events like
"the OK button has been clicked", we need an object wich is derived from the
IEventReceiver object. There is only one method to override: OnEvent.
This method will be called by the engine when an event happened.
*/

int disable_logging = 0;

// for xsubpp not to stumble
#define Cclass class

Cclass MyEventReceiver : public IEventReceiver
  {
  public: virtual bool OnEvent(SEvent event)
    {
    if (event.EventType == EET_LOG_TEXT_EVENT && disable_logging)
      {
      // consume this event and thus prevent log output
      return true;
      }


    printf ("received event\n");
    // should call a perl callback here and store the event
    //return true;
    return false;
    }
  };

MyEventReceiver receiver;

int _irrlicht_init_engine (
 unsigned int rtype,
 unsigned int w, unsigned int h, unsigned int d, unsigned int fs,
 unsigned int ll)
  {
  ILogger* logger;

  disable_logging = ll;

  device =
     createDevice(
        (EDriverType)rtype,		// renderer
        dimension2d<s32>(w, h),		// size
        d,				// bit depth
        fs,				// fullscreen?
        false,				// stencilbuffer
        &receiver);			// event receiver
  if (NULL == device) { return 0; }     // error

  logger = device->getLogger();
  logger->setLogLevel(ELL_ERROR);

  driver = device->getVideoDriver();
  smgr = device->getSceneManager();
  guienv = device->getGUIEnvironment();
  timer = device->getTimer();
  filesystem = device->getFileSystem();

  if (NULL == driver)
    {
    printf ("Could not get VideoDriver from Irrlicht device.\n");
    return 0;                           // error
    }
  if (NULL == smgr)
    {
    printf ("Could not get SceneManager from the Irrlicht device.\n");
    return 0;                           // error
    }
  if (NULL == guienv)
    {
    printf ("Could not get GUIEnvironment from the Irrlicht device.\n");
    return 0;                           // error
    }
  if (NULL == filesystem)
    {
    printf ("Could not get FileSystem from the Irrlicht device.\n");
    return 0;                           // error
    }
  
  // DEBUG XXX TODO 
  // add a static string
//  guienv->addStaticText(L"Hello Perl! This is the Irrlicht Software engine!",
//         rect<int>(10,10,200,30), true);

  // add a camera
//  smgr->addCameraSceneNode(0, vector3df(0,10,-40), vector3df(0,0,0));

  return 1;
  }

/* ************************************************************************ */

/*
Games::Irrlicht XS code (C) by Tels <http://bloodgate.com/perl/> 
*/

MODULE = Games::Irrlicht		PACKAGE = Games::Irrlicht

PROTOTYPES: DISABLE
#############################################################################
        
int
_init_engine(SV* classname, unsigned int rtype, unsigned int w, unsigned int h, unsigned int d, unsigned int fs, unsigned int ll)
    CODE:
        RETVAL = _irrlicht_init_engine(rtype,w,h,d,fs,ll);
    OUTPUT:
        RETVAL

void
_done_engine(SV* classname)
    CODE:
        device->drop();

#############################################################################

SV*
_run_engine(SV* classname)
    PREINIT:
        int rc;
    CODE:
        rc = device->run();             /* true when we still run */
  /* Anything can be drawn between a beginScene() and an endScene() call.
    The beginScene clears the screen with a color and also the depth buffer
    if wanted. Then we let the Scene Manager and the GUI Environment draw
    their content. With the endScene() call everything is presented on the
    screen.
  */
        driver->beginScene(true, true, SColor(0,100,100,100));
          smgr->drawAll();
          guienv->drawAll();
        driver->endScene();
        RETVAL = newSViv( rc );                 /* return result */
    OUTPUT:
        RETVAL

#############################################################################

SV*
_get_ticks(SV* classname)
    PREINIT:
	int rc;
    CODE:
	rc = timer->getTime();
	RETVAL = newSVuv( rc );
    OUTPUT:	
	RETVAL

##############################################################################
# _delay() - if the time between last and this frame was too short, delay the
#            app a bit. Also returns current time corrected by base_ticks.

SV*
_delay(min_time,base_ticks)
        unsigned int    min_time
        unsigned int    base_ticks
  CODE:
    /*
     min_time  - ms to spent between frames minimum
     wake_time - ms we were late in last frame, so we slee this time shorter
     last      - time in ticks of last frame
    */
    /* caluclate how long we should sleep */
    unsigned int now, time, frame_cnt, diff;
    int to_sleep;
    double framerate;

    //if (last == 0)
    //  {
    //  last = timer->getTime() - base_ticks;
    //  }
    now = timer->getTime() - base_ticks;

    if (min_time > 0)
      {
      to_sleep = min_time - wake_time - (now - last) - 1;

      # sometimes Delay() does not seem to work, so retry until it we sleeped
      # long enough
      while (to_sleep > 2)
        {
//	printf ("to_sleep: %i\n", to_sleep);
	my_time_spec.tv_sec = 0;
	my_time_spec.tv_nsec = to_sleep * 1000;
	nanosleep( &my_time_spec, NULL);	// struct timespec *rem);
        now = timer->getTime() - base_ticks;
//	printf ("now: %i\n", now);
        to_sleep = min_time - (now - last);
        }
      wake_time = 0;

      if (now - last > min_time)
        {
        wake_time = now - last - min_time;
        }
      }
//	printf ("  now: %i\n", now);
    diff = now - last;
    ST(0) = newSViv(now);
    ST(1) = newSViv(diff);
    last = now;
    /* ******************************************************************** */
    /* monitor the framerate */

    /* add current value to ringbuffer */
    frames[frames_end] = now; frames_end++;
    if (frames_end >= FRAMES_MAX)
      {
      frames_end = 0;
      }
    /* buffer full? if so, remove oldest entry */
    if (frames_end == frames_start)
      {
      frames_start++;
      if (frames_start >= FRAMES_MAX)
        {
        frames_start = 0;
        }
      }
    /* keep only values in the buffer, that are at most 1000 ms old */
    while (now - frames[frames_start] > 1000)
      {
      /* remove value from start */
      frames_start++;
      if (frames_start >= FRAMES_MAX)
        {
        frames_start = 0;
        }
      if (frames_start == frames_end)
        {
        /* buffer empty */
        break;
        }
      }
    framerate = 0;
    if (frames_start != frames_end)
      {
      /* got some frames, so calc. current frame rate */
      time = now - frames[frames_start] + 1;
      /* printf ("time %i start %i (%i) end %i (%i) ",
        time,frames_start,frames[frames_start],frames_end,now); */
      if (frames_start < frames_end)
        {
        frame_cnt = frames_end - frames_start + 1;
        }
      else
        {
        frame_cnt = 1024 - (frames_start - frames_end - 1);
        }
      /* does it make sense to calc. fps? */
      if (frame_cnt > 20)
        {
        framerate = (double)(10000 * frame_cnt / time) / 10;
        if (min_fps > framerate) { min_fps = framerate; }
        if (max_fps < framerate) { max_fps = framerate; }
        if (diff > max_frame_time) { max_frame_time = diff; }
        if (diff < min_frame_time && diff > 0) { min_frame_time = diff; }
        }
      /* printf (" frames %i time %i fps %f\n",frame_cnt,time,framerate);
      printf (" min %f max %f\n",min_fps,max_fps); */
      }

    ST(2) = newSVnv(framerate);
    XSRETURN(3);

##############################################################################
SV*
min_fps(SV* classname)
    CODE:
      RETVAL = newSVnv(min_fps);
    OUTPUT:
      RETVAL

SV*
max_fps(SV* classname)
    CODE:
      RETVAL = newSVnv(max_fps);
    OUTPUT:
      RETVAL

SV*
max_frame_time(SV* classname)
    CODE:
      RETVAL = newSViv(max_frame_time);
    OUTPUT:
      RETVAL

SV*
min_frame_time(SV* classname)
    CODE:
      RETVAL = newSViv(min_frame_time);
    OUTPUT:
      RETVAL

##############################################################################
# driver interface

double
getPrimitiveCountDrawn(SV* classname)
    CODE:
      RETVAL = driver->getPrimitiveCountDrawn();
    OUTPUT:
      RETVAL

# getTexture

double
getTexture(SV* classname)
    CODE:
      RETVAL = driver->getPrimitiveCountDrawn();
    OUTPUT:
      RETVAL

##############################################################################
# device interface

#virtual 	~IrrlichtDevice ()
#virtual bool 	run ()=0
#virtual video::IVideoDriver * 	getVideoDriver ()=0
#virtual io::IFileSystem * 	getFileSystem ()=0
#virtual gui::IGUIEnvironment * 	getGUIEnvironment ()=0
#virtual scene::ISceneManager * 	getSceneManager ()=0
#virtual gui::ICursorControl * 	getCursorControl ()=0
#virtual ILogger * 	getLogger ()=0
#virtual video::IVideoModeList * 	getVideoModeList ()=0
#virtual IOSOperator * 	getOSOperator ()=0
#virtual ITimer * 	getTimer ()=0
#virtual void 	setWindowCaption (const wchar_t *text)=0
#virtual bool 	isWindowActive ()=0
#virtual void 	closeDevice ()=0
#virtual const wchar_t * 	getVersion ()=0
#virtual void 	setEventReceiver (IEventReceiver *receiver)=0

void
setVisible(SV* classname, int vis)
  CODE:
    device->getCursorControl()->setVisible(vis);

# set window title

void
setWindowCaption(SV* classname, char* caption)
  PREINIT:
    wchar_t mytitle[512];
  CODE:
    // TODO: find out length of scalar and alloc memory for myTitle?
    mbstowcs(&mytitle[0], caption, 512); 
    device->setWindowCaption(mytitle);

char*
getVersion(SV* classname)
  PREINIT:
    char myversion[512];
    const wchar_t* myver;
  CODE:
    myver = device->getVersion();
    // TODO: find out length of scalar and alloc memory for myTitle?
    wcstombs( &myversion[0], myver, 512);
    RETVAL = myversion;
  OUTPUT:
    RETVAL

bool
isWindowActive(SV* classname)
  CODE:
    RETVAL = device->isWindowActive();
  OUTPUT:
    RETVAL

##############################################################################
# OSOperator

char*
getOperationSystemVersion(SV* classname)
  PREINIT:
    char myversion[512];
    const wchar_t* myver;
    IOSOperator* os;
  CODE:
    os = device->getOSOperator();
    myver = os->getOperationSystemVersion();
    // TODO: find out length of scalar and alloc memory for myTitle?
    wcstombs( &myversion[0], myver, 512);
    RETVAL = myversion;
  OUTPUT:
    RETVAL

##############################################################################
# scene manager interface

int
addCameraSceneNodeFPS(SV* classname)
  CODE:
    smgr->addCameraSceneNodeFPS();
    RETVAL = 1;	
  OUTPUT:
    RETVAL
        
int
loadBSP(SV* classname, char* name)
  CODE:
    scene::IAnimatedMesh* mesh = smgr->getMesh(name);
    scene::ISceneNode* node = 0;
    RETVAL = 0;
    if (mesh)
      {
      node = smgr->addOctTreeSceneNode(mesh->getMesh(0));
      RETVAL = 1;
      }

##############################################################################
# file system interface

bool
addZipFileArchive(SV* classname, char* archive)
  CODE:
    RETVAL = filesystem->addZipFileArchive( archive );
  OUTPUT:
    RETVAL

# this does not work in Irrlicht v0.6 in Linux (returns always false)

bool
changeWorkingDirectoryTo(SV* classname, char* directory)
  CODE:
    RETVAL = filesystem->changeWorkingDirectoryTo( directory );
    printf ("%i\n", filesystem->changeWorkingDirectoryTo( directory ));
  OUTPUT:
    RETVAL

# this does not work in Irrlicht v0.6 in Linux (returns null)

char*
getWorkingDirectory(SV* classname)
  CODE:
    RETVAL = (char*) filesystem->getWorkingDirectory( );
  OUTPUT:
    RETVAL

# EOF
##############################################################################


