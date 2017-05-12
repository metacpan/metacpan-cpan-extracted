/*  You may distribute under the terms of either the GNU General Public License
 *  or the Artistic License (the same terms as Perl itself)
 *
 *  (C) Paul Evans, 2016 -- leonerd@leonerd.org.uk
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/* Until GNU libc supports termios2, we'll have to go the direct approach
 *
 * Because of this there's some extra mess we have to account for. Namely,
 * that <asm/termios.h> wants to provide two structs already known by this
 * point (because "perl.h" brought them in). gcc will complain. But since we
 * don't care about the new definitions of these new structs, we'll just throw
 * them away.
 */

#define winsize ASM_TERMIOS_winsize
#define termio  ASM_TERMIOS_termio
#  include <asm/termios.h>
#  include <asm/ioctls.h>
#undef winsize
#undef termio

typedef struct termios2 *Linux__Termios2;

MODULE = Linux::Termios2    PACKAGE = Linux::Termios2

Linux::Termios2
new(package)
  char *package
  CODE:
    Newx(RETVAL, 1, struct termios2);
  OUTPUT:
    RETVAL

void
DESTROY(self)
  Linux::Termios2 self
  CODE:
    Safefree(self);

void
getattr(self, fd)
  Linux::Termios2 self
  int             fd
  PPCODE:
    if(ioctl(fd, TCGETS2, self))
      XSRETURN_UNDEF;

    ST(0) = &PL_sv_yes;
    XSRETURN(1);

void
setattr(self, fd, act)
  Linux::Termios2 self
  int             fd
  int             act
  PPCODE:
  {
    int ctl;
    switch(act) {
      case TCSANOW:   ctl = TCSETS2; break;
      case TCSADRAIN: ctl = TCSETSW2; break;
      case TCSAFLUSH: ctl = TCSETSF2; break;
      default:
        SETERRNO(EINVAL, LIB_INVARG);
        XSRETURN_UNDEF;
    }
    if(ioctl(fd, ctl, self))
      XSRETURN_UNDEF;

    ST(0) = &PL_sv_yes;
    XSRETURN(1);
  }

int
getcflag(self)
  Linux::Termios2 self
ALIAS:
  getcflag  = 0
  getiflag  = 1
  getlflag  = 2
  getoflag  = 3
  getispeed = 4
  getospeed = 5
  CODE:
    switch(ix) {
      case 0: RETVAL = self->c_cflag; break;
      case 1: RETVAL = self->c_iflag; break;
      case 2: RETVAL = self->c_lflag; break;
      case 3: RETVAL = self->c_oflag; break;
      case 4: RETVAL = self->c_ispeed; break;
      case 5: RETVAL = self->c_ospeed; break;
    }
  OUTPUT:
    RETVAL

void
setcflag(self, val)
  Linux::Termios2 self
  int             val
ALIAS:
  setcflag  = 0
  setiflag  = 1
  setlflag  = 2
  setoflag  = 3
  CODE:
    switch(ix) {
      case 0: self->c_cflag  = val; break;
      case 1: self->c_iflag  = val; break;
      case 2: self->c_lflag  = val; break;
      case 3: self->c_oflag  = val; break;
    }

void
setispeed(self, val)
  Linux::Termios2 self
  int             val
ALIAS:
  setispeed = 0
  setospeed = 1
  CODE:
    switch(ix) {
      case 0: self->c_ispeed = val; break;
      case 1: self->c_ospeed = val; break;
    }
    self->c_cflag &= ~CBAUD;
    self->c_cflag |= BOTHER;
