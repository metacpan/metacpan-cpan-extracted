#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "time.h"
#include "Xlib.h"

static Display            *disp;
static Window              comms_win;
static Window              my_win;
static Window              client_win;
static Window              root_win;

/*
 * A bunch of routines copied and hacked from the eesh source code
 */

void SetupX() {
   char *display_name = NULL;
   disp = XOpenDisplay(display_name);
   /* if cannot connect to display */
   if (!disp)
     {
	fprintf(stderr,
	   "Eesh cannot connect to the display nominated by\n"
	   "your shell's DISPLAY environment variable.\n"
	);
	exit(1);
     }

   root_win = DefaultRootWindow(disp);

   /* warn, if necessary about X version problems */
   if (ProtocolVersion(disp) != 11)
     {
	fprintf(
	   stderr,
	   "WARNING:\n"
	   "This is not an X11 Xserver. It infact talks the X%i protocol.\n",
	   ProtocolVersion(disp)
	);
     }
}


void
CommsSend( char *command )
{
   char                ss[21];
   int                 i, j, k, len;
   XEvent              ev;
   Atom                a;

   if ( !command ) croak( "No command passed to C routine CommsSend" ) ;

   len = strlen(command);
   a = XInternAtom(disp, "ENL_MSG", True);
   ev.xclient.type = ClientMessage;
   ev.xclient.serial = 0;
   ev.xclient.send_event = True;
   ev.xclient.window = comms_win ;
   ev.xclient.message_type = a;
   ev.xclient.format = 8;

   for (i = 0; i < len + 1; i += 12)
     {
	sprintf(ss, "%8x", (int)my_win);
	for (j = 0; j < 12; j++)
	  {
	     ss[8 + j] = command[i + j];
	     if (!command[i + j])
		j = 12;
	  }
	ss[20] = 0;
	for (k = 0; k < 20; k++)
	   ev.xclient.data.b[k] = ss[k];
	XSendEvent(disp, comms_win, False, 0, (XEvent *) & ev);
     }
}

void
CommsFindCommsWindow()
{
   unsigned char      *s;
   Atom                a, ar;
   unsigned long       num, after;
   int                 format;
   Window              rt;
   int                 dint;
   unsigned int        duint;

   a = XInternAtom(disp, "ENLIGHTENMENT_COMMS", True);
   if (a != None)
     {
	s = NULL;
	XGetWindowProperty(disp, root_win, a, 0, 14, False, AnyPropertyType, &ar,
			   &format, &num, &after, &s);
	if (s)
	  {
	     sscanf((char *)s, "%*s %x", (unsigned int *)&comms_win);
	     XFree(s);
	  }
	else
	   (comms_win = 0);
	if (comms_win)
	  {
	     if (!XGetGeometry(disp, comms_win, &rt, &dint, &dint,
			       &duint, &duint, &duint, &duint))
		comms_win = 0;
	     s = NULL;
	     if (comms_win)
	       {
		  XGetWindowProperty(disp, comms_win, a, 0, 14, False,
				  AnyPropertyType, &ar, &format, &num, &after,
				     &s);
		  if (s)
		     XFree(s);
		  else
		     comms_win = 0;
	       }
	  }
     }
}


MODULE = Eesh		PACKAGE = Eesh		

void
e_open()
   CODE:
      /* Inspired by eesh's main.c.  Yeah, that's it: 'inspired'. */

      SetupX() ;
      my_win = XCreateSimpleWindow(disp, root_win, -100, -100, 5, 5, 0, 0, 0);
      CommsFindCommsWindow();
      XSelectInput(disp, comms_win, StructureNotifyMask);
      XSelectInput(disp, root_win, PropertyChangeMask);
      CommsSend( "set clientname Eesh.pm");
      CommsSend( "set version 0.1");
      CommsSend( "set author The Rasterman interpreted by Barrie Slaymaker");
      CommsSend( "set email barries@slaysys.com");
      CommsSend( "set web http://www.slaysys.com/");
   /*  CommsSend( "set address NONE"); */
      CommsSend( "set info Eesh.pm: Enlightenment IPC - talk to E from Perl");
   /*  CommsSend( "set pixmap 0"); */

      XSync(disp, False) ;


void
e_send(command)
   char *command ;
   CODE:
      CommsSend(command);
      XSync(disp,False);


int
e_fileno()
   CODE:
      RETVAL = ConnectionNumber(disp) ;


SV *
e_recv_nb(blocking)
   int blocking ;
   PREINIT:
      fd_set          in_fds ;
      struct timeval  tv, *tvp ;
      int             c ;
      XEvent          ev ;
      int             chunk_len ;
      char           *msg ;
      int             msg_len ;
      int             max_msg_len ;
   CODE:
      msg = 0 ;
      do {
         if ( blocking )
	    tvp = NULL ;
	 else {
	    tvp = &tv ;
	    tv.tv_sec = 0 ;
	    tv.tv_usec = 0 ;
	 }
	 FD_ZERO( &in_fds );
	 FD_SET( ConnectionNumber(disp), &in_fds );
	 c = select( ConnectionNumber(disp)+1, &in_fds, NULL, NULL, tvp ) ;
	 if ( c < 0 )
	    croak( "select() returned < 0" ) ;
	 if ( !c && !blocking ) {
	    XSRETURN_UNDEF ;
	 }

	 chunk_len = 0 ;
	 while (XPending(disp)) {
	    XNextEvent(disp,&ev) ;
	    if (ev.type == ClientMessage) {
	       if ( !msg ) {
		  max_msg_len = 1000 ;
		  msg = malloc( max_msg_len + 1 );
		  if ( !msg ) {
		     XSRETURN_UNDEF;
		  }
		  for (
		     chunk_len = 0, msg_len = 0 ;
		     chunk_len < 12;
		     ++chunk_len, ++msg_len
		  ) {
		     msg[msg_len] = ev.xclient.data.b[ chunk_len + 8 ];
		     if ( ! msg[msg_len] ) break ;
		  }
	       }
	       else {
		  for (
		     chunk_len = 0 ;
		     chunk_len < 12 ;
		     ++chunk_len, ++msg_len
		  ) {
		     if ( msg_len > max_msg_len ) {
		        max_msg_len += 1000 ;
			msg = realloc( msg, max_msg_len + 1 );
			if ( !msg ) {
			   XSRETURN_UNDEF;
			}
		     }
		     msg[msg_len] = ev.xclient.data.b[ chunk_len + 8 ];
		     if ( ! msg[msg_len] ) break ;
		  }
	       }
	    }
	 }
      } while ( chunk_len >= 12 ) ;
      ST(0) = sv_newmortal() ;
      if ( msg ) {
	 msg[msg_len] = '\0' ;
	 sv_setpv( ST(0), msg ) ;
      }
      else
	 ST(0) = &PL_sv_undef ;
