#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <pthread.h>
#include <unistd.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/types.h>
#include <poll.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>

#define AUTOCREATE 1
#define OR_DIE 2

struct socketalarm;

#include "SocketAlarm_util.h"
#include "SocketAlarm_action.h"
#include "pollfd_rbhash.h"
#include "SocketAlarm_watcher.h"

#define EVENT_SHUT      0x01
#define EVENT_EOF       0x02
#define EVENT_CLOSE     0x04
#define EVENT_IN        0x08
#define EVENT_PRI       0x10

#ifdef POLLRDHUP
#define EVENT_DEFAULTS EVENT_SHUT
#else
#define EVENT_DEFAULTS (EVENT_SHUT|EVENT_EOF)
#endif

struct socketalarm {
   int list_ofs;      // position within watch_list, initially -1 until activated
   int watch_fd;
   dev_t watch_fd_dev;
   ino_t watch_fd_ino;
   int event_mask;
   int action_count;
   SV *owner;
   AV *actions_av;    // lazy-built
   bool unwaitable;         //
   int cur_action;          // used during execution
   struct timespec wake_ts; //
   struct action actions[];
};

static void socketalarm_exec_actions(struct socketalarm *sa);

#include "SocketAlarm_util.c"
#include "SocketAlarm_action.c"
#include "SocketAlarm_watcher.c"

struct socketalarm *
socketalarm_new(int watch_fd, struct stat *statbuf, int event_mask, SV **action_spec, size_t spec_count) {
   size_t n_actions= 0, aux_len= 0, len_before_aux;
   struct socketalarm *self= NULL;

   parse_actions(action_spec, spec_count, NULL, &n_actions, NULL, &aux_len);
   // buffer needs aligned to pointer, which sizeof(struct action) is not guaranteed to be
   len_before_aux= sizeof(struct socketalarm) + n_actions * sizeof(struct action);
   len_before_aux += sizeof(void*)-1;
   len_before_aux &= ~(sizeof(void*)-1);
   self= (struct socketalarm *) safecalloc(1, len_before_aux + aux_len);
   // second call should succeed, because we gave it back it's own requested buffer sizes.
   // could fail if user did something evil like a tied scalar that changes length...
   if (!parse_actions(action_spec, spec_count, self->actions, &n_actions, ((char*)self) + len_before_aux, &aux_len))
      croak("BUG: buffers not large enough for parse_actions");
   // If user requests EVENT_SHUT and not available on the platform, warn and downgrade to EVENT_EOF
   if (!(EVENT_DEFAULTS & EVENT_SHUT) && (event_mask & EVENT_SHUT) && !(event_mask & EVENT_EOF)) {
      SV *warned= get_sv("IO::SocketAlarm::_warned_EVENT_SHUT_unavail", GV_ADD);
      if (!SvTRUE(warned)) {
         warn("IO::SocketAlarm EVENT_SHUT is not available on this platform, using EVENT_EOF instead");
         sv_setsv(warned, &PL_sv_yes);
      }
      event_mask |= EVENT_EOF;
   }
   self->watch_fd= watch_fd;
   self->watch_fd_dev= statbuf->st_dev;
   self->watch_fd_ino= statbuf->st_ino;
   self->event_mask= event_mask;
   self->actions_av= NULL;
   self->action_count= n_actions;
   self->list_ofs= -1; // initially not in the watch list
   self->owner= NULL;
   return self;
}

void socketalarm_exec_actions(struct socketalarm *self) {
   bool resume= self->cur_action >= 0;
   struct timespec now_ts= { 0, -1 };
   if (!resume)
      self->cur_action= 0;
   while (self->cur_action < self->action_count) {
      if (!execute_action(self->actions + self->cur_action, resume, &now_ts, self))
         break;
      resume= false;
      ++self->cur_action;
   }
}

static void socketalarm__build_actions(struct socketalarm *self) {
   Size_t i;
   if (!self->actions_av) {
      self->actions_av= newAV();
      av_extend(self->actions_av, self->action_count-1);
      for (i= 0; i < self->action_count; i++) {
         AV *act_spec= newAV();
         inflate_action(self->actions+i, act_spec);
         SvREADONLY_on((SV*) act_spec);
         av_push(self->actions_av, newRV_noinc((SV*) act_spec));
      }
      SvREADONLY_on((SV*) self->actions_av);
   }
}

void socketalarm_free(struct socketalarm *sa) {
   // Must remove the socketalarm from the active list, if present
   watch_list_remove(sa);
   // Release reference to lazy-built action AV
   if (sa->actions_av)
      SvREFCNT_dec((SV*) sa->actions_av);
   // was allocated as one chunk
   Safefree(sa);
}

/* Return an SV array of an AV.
 * Returns NULL if it wasn't an AV or arrayref.
 */
static SV** unwrap_array(SV *array, ssize_t *len_out) {
   AV *av;
   SV **vec;
   ssize_t n;
   if (array && SvTYPE(array) == SVt_PVAV)
      av= (AV*) array;
   else if (array && SvROK(array) && SvTYPE(SvRV(array)) == SVt_PVAV)
      av= (AV*) SvRV(array);
   else
      return NULL;
   n= av_count(av);
   vec= AvARRAY(av);
   /* tied arrays and non-allocated empty arrays return NULL */
   if (!vec) {
      if (n == 0) /* don't return a NULL for an empty array, but doesn't need to be a real pointer */
         vec= (SV**) 8;
      else {
         /* in case of a tied array, extract the elements into a temporary buffer */
         ssize_t i;
         Newx(vec, n, SV*);
         SAVEFREEPV(vec);
         for (i= 0; i < n; i++) {
            SV **el= av_fetch(av, i, 0);
            vec[i]= el? *el : NULL;
         }
      }
   }
   if (len_out) *len_out= n;
   return vec;
}

/*------------------------------------------------------------------------------------
 * Definitions of Perl MAGIC that attach C structs to Perl SVs
 */

// destructor for Watch objects
static int socketalarm_magic_free(pTHX_ SV* sv, MAGIC* mg) {
   if (mg->mg_ptr) {
      socketalarm_free((struct socketalarm*) mg->mg_ptr);
      mg->mg_ptr= NULL;
   }
   return 0; // ignored anyway
}
#ifdef USE_ITHREADS
static int socketalarm_magic_dup(pTHX_ MAGIC *mg, CLONE_PARAMS *param) {
   croak("This object cannot be shared between threads");
   return 0;
};
#else
#define socketalarm_magic_dup 0
#endif

// magic table for Watch objects
static MGVTBL socketalarm_magic_vt= {
   0, /* get */
   0, /* write */
   0, /* length */
   0, /* clear */
   socketalarm_magic_free,
   0, /* copy */
   socketalarm_magic_dup
#ifdef MGf_LOCAL
   ,0
#endif
};

// Return the socketalarm that was attached to a perl Watch object via MAGIC.
// The 'obj' should be a reference to a blessed magical SV.
static struct socketalarm*
get_magic_socketalarm(SV *obj, int flags) {
   SV *sv;
   MAGIC* magic;

   if (!sv_isobject(obj)) {
      if (flags & OR_DIE)
         croak("Not an object");
      return NULL;
   }
   sv= SvRV(obj);
   if (SvMAGICAL(sv)) {
      /* Iterate magic attached to this scalar, looking for one with our vtable */
      if ((magic= mg_findext(sv, PERL_MAGIC_ext, &socketalarm_magic_vt)))
         /* If found, the mg_ptr points to the fields structure. */
         return (struct socketalarm*) magic->mg_ptr;
   }
   if (flags & OR_DIE)
      croak("Object lacks 'struct TreeRBXS_item' magic");
   return NULL;
}

static void attach_magic_socketalarm(SV *obj_inner_sv, struct socketalarm *sa) {
   MAGIC *magic;
   if (sa->owner)
      croak("BUG: already attached to perl object");
   sa->owner= obj_inner_sv;
   magic= sv_magicext((SV*) sa->owner, NULL, PERL_MAGIC_ext, &socketalarm_magic_vt, (const char*) sa, 0);
#ifdef USE_ITHREADS
   magic->mg_flags |= MGf_DUP;
#else
   (void)magic; // suppress 'unused' warning
#endif
}

// Return existing Watch object, or create a new one.
// Returned SV has a non-mortal refcount, which is what the typemap
// wants for returning a "struct socketalarm*" to perl-land
static SV* wrap_socketalarm(struct socketalarm *sa) {
   SV *obj;
   HV *hv;
   // Since this is used in typemap, handle NULL gracefully
   if (!sa)
      return &PL_sv_undef;
   // If there is already a node object, return a new reference to it.
   if (sa->owner)
      return newRV_inc((SV*) sa->owner);
   // else create a node object
   hv= newHV();
   obj= newRV_noinc((SV*) hv);
   sv_bless(obj, gv_stashpv("IO::SocketAlarm", GV_ADD));
   attach_magic_socketalarm((SV*) hv, sa);
   return obj;
}

#define EXPORT_ENUM(x) newCONSTSUB(stash, #x, new_enum_dualvar(aTHX_ x, newSVpvs_share(#x)))
static SV * new_enum_dualvar(pTHX_ IV ival, SV *name) {
   SvUPGRADE(name, SVt_PVNV);
   SvIV_set(name, ival);
   SvIOK_on(name);
   SvREADONLY_on(name);
   return name;
}

/*------------------------------------------------------------------------------------
 * Perl API
 */

MODULE = IO::SocketAlarm               PACKAGE = IO::SocketAlarm

void
_init_socketalarm(self, sock_sv, eventmask_sv, actions_sv)
   SV *self
   SV *sock_sv
   SV *eventmask_sv
   SV *actions_sv
   INIT:
      int sock_fd= fileno_from_sv(sock_sv);
      int eventmask= EVENT_DEFAULTS;
      struct stat statbuf;
      struct socketalarm *sa;
      SV **action_list= NULL;
      size_t n_actions= 0;
   PPCODE:
      if (!sv_isobject(self))
         croak("Not an object");
      if ((sa= get_magic_socketalarm(self, 0)))
         croak("Already initialized");
      if (!(sock_fd >= 0 && fstat(sock_fd, &statbuf) == 0 && S_ISSOCK(statbuf.st_mode)))
         croak("Not an open socket");
      if (eventmask_sv && SvOK(eventmask_sv))
         eventmask= SvIV(eventmask_sv);
      if (actions_sv && SvOK(actions_sv)) {
         action_list= unwrap_array(actions_sv, &n_actions);
         if (!action_list)
            croak("Actions must be an arrayref (or undefined)");
      }
      sa= socketalarm_new(sock_fd, &statbuf, eventmask, action_list, n_actions);
      attach_magic_socketalarm(SvRV(self), sa);
      XSRETURN(1); // return $self

int
socket(alarm)
   struct socketalarm *alarm
   CODE:
      RETVAL= alarm->watch_fd;
   OUTPUT:
      RETVAL

int
events(alarm)
   struct socketalarm *alarm
   CODE:
      RETVAL= alarm->event_mask;
   OUTPUT:
      RETVAL

void
actions(alarm)
   struct socketalarm *alarm
   PPCODE:
      if (!alarm->actions_av);
         socketalarm__build_actions(alarm);
      ST(0)= sv_2mortal(newRV_inc((SV*) alarm->actions_av));
      XSRETURN(1);

int
action_count(alarm)
   struct socketalarm *alarm
   CODE:
      RETVAL= alarm->action_count;
   OUTPUT:
      RETVAL

int
cur_action(alarm)
   struct socketalarm *alarm
   CODE:
      watch_list_item_get_status(alarm, &RETVAL);
   OUTPUT:
      RETVAL

bool
start(alarm)
   struct socketalarm *alarm
   CODE:
      RETVAL= watch_list_add(alarm);
   OUTPUT:
      RETVAL

bool
cancel(alarm)
   struct socketalarm *alarm
   CODE:
      RETVAL= watch_list_remove(alarm);
   OUTPUT:
      RETVAL

SV*
stringify(alarm)
   struct socketalarm *alarm
   INIT:
      SV *out= sv_2mortal(newSVpvn("",0));
      Size_t i;
   CODE:
      sv_catpvf(out, "watch fd: %d\n", alarm->watch_fd);
      sv_catpvf(out, "event mask:%s%s\n",
         alarm->event_mask & EVENT_SHUT? " SHUT":"",
         alarm->event_mask & EVENT_CLOSE? " CLOSE":""
      );
      sv_catpv(out, "actions:\n");
      for (i= 0; i < alarm->action_count; i++) {
         char buf[256];
         snprint_action(buf, sizeof(buf), alarm->actions+i);
         sv_catpvf(out, "%4d: %s\n", i, buf);
      }
      SvREFCNT_inc(out);
      RETVAL= out;
   OUTPUT:
      RETVAL

void
_terminate_all()
   PPCODE:
      shutdown_watch_thread();

MODULE = IO::SocketAlarm               PACKAGE = IO::SocketAlarm::Util

struct socketalarm *
socketalarm(sock_sv, ...)
   SV *sock_sv
   INIT:
      int sock_fd= fileno_from_sv(sock_sv);
      int eventmask= EVENT_DEFAULTS;
      int action_ofs= 1;
      struct stat statbuf;
   CODE:
      if (!(sock_fd >= 0 && fstat(sock_fd, &statbuf) == 0 && S_ISSOCK(statbuf.st_mode)))
         croak("Not an open socket");
      if (items > 1) {
         // must either be a scalar, a scalar followed by actions specs, or action specs
         if (SvOK(ST(1)) && looks_like_number(ST(1))) {
            eventmask= SvIV(ST(1));
            action_ofs++;
         }
      }
      RETVAL= socketalarm_new(sock_fd, &statbuf, eventmask, &(ST(action_ofs)), items - action_ofs);
      watch_list_add(RETVAL);
   OUTPUT:
      RETVAL

bool
is_socket(fd_sv)
   SV *fd_sv
   INIT:
      int fd= fileno_from_sv(fd_sv);
      struct stat statbuf;
   CODE:
      RETVAL= fd >= 0 && fstat(fd, &statbuf) == 0 && S_ISSOCK(statbuf.st_mode);
   OUTPUT:
      RETVAL

SV *
get_fd_table_str(max_fd=1024)
   int max_fd
   INIT:
      SV *out= newSVpvn("",0);
      size_t avail= 0, needed= 1023;
   CODE:
      // FD status could change between calls, changing the length requirement, so loop.
      // 'avail' count includes the NUL byte, and 'needed' does not.
      while (avail <= needed) {
         sv_grow(out, needed+1);
         avail= needed+1;
         needed= snprint_fd_table(SvPVX(out), avail, max_fd);
      }
      SvCUR_set(out, needed);
      RETVAL= out;
   OUTPUT:
      RETVAL

# For unit test purposes only, export _poll that polls on a single file
# descriptor to verify the statuses for sockets in various states.

void
_poll(fd, events, timeout)
   int fd
   SV *events;
   int timeout;
   INIT:
      struct pollfd pollbuf;
   PPCODE:
      pollbuf.fd= fd;
      pollbuf.events= SvIV(events);
      EXTEND(SP, 2);
      PUSHs(sv_2mortal(newSViv(poll(&pollbuf, 1, timeout))));
      PUSHs(sv_2mortal(newSViv(pollbuf.revents)));

#-----------------------------------------------------------------------------
#  Constants
#

BOOT:
   HV* stash= gv_stashpvn("IO::SocketAlarm::Util", 21, GV_ADD);
   EXPORT_ENUM(EVENT_SHUT);
   EXPORT_ENUM(EVENT_EOF);
   EXPORT_ENUM(EVENT_IN);
   EXPORT_ENUM(EVENT_PRI);
   EXPORT_ENUM(EVENT_CLOSE);
   EXPORT_ENUM(POLLIN);
   EXPORT_ENUM(POLLOUT);
   EXPORT_ENUM(POLLPRI);
   EXPORT_ENUM(POLLERR);
   EXPORT_ENUM(POLLHUP);
   EXPORT_ENUM(POLLNVAL);
   #ifdef POLLRDHUP
   EXPORT_ENUM(POLLRDHUP);
   #endif

PROTOTYPES: DISABLE
