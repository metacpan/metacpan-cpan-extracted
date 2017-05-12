#ifndef bool
#include <iostream.h>
#endif
extern "C" {
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"
}
#ifdef bool
#undef bool
#include <iostream.h>
#endif

class Foo {
 public:
   Foo() {
 	secret=0;
   }

   ~Foo() { }

   int get_secret() { return secret; }
   void set_secret(int s) {
        Inline_Stack_Vars;
        secret = s;
   }

 protected:
   int secret;
};

class Bar : public Foo {
 public:
   Bar(int s) { secret = s; }
   ~Bar() {  }

   void set_secret(int s) { secret = s * 2; }
};

MODULE = Math::Geometry::Planar::GPC::Inherit     	PACKAGE = main::Foo

PROTOTYPES: DISABLE

Foo *
Foo::new()

void
Foo::DESTROY()

int
Foo::get_secret()

void
Foo::set_secret(s)
	int	s
    PREINIT:
	I32 *	__temp_markstack_ptr;
    PPCODE:
	__temp_markstack_ptr = PL_markstack_ptr++;
	THIS->set_secret(s);
        if (PL_markstack_ptr != __temp_markstack_ptr) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = __temp_markstack_ptr;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */


MODULE = Math::Geometry::Planar::GPC::Inherit     	PACKAGE = main::Bar

PROTOTYPES: DISABLE

Bar *
Bar::new(s)
	int	s

void
Bar::DESTROY()

void
Bar::set_secret(s)
	int	s
    PREINIT:
	I32 *	__temp_markstack_ptr;
    PPCODE:
	__temp_markstack_ptr = PL_markstack_ptr++;
	THIS->set_secret(s);
        if (PL_markstack_ptr != __temp_markstack_ptr) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = __temp_markstack_ptr;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

MODULE = Math::Geometry::Planar::GPC::Inherit     	PACKAGE = main

PROTOTYPES: DISABLE

BOOT:
{
#ifndef get_av
    AV *isa = perl_get_av("main::Bar::ISA", 1);
#else
    AV *isa = get_av("main::Bar::ISA", 1);
#endif
    av_push(isa, newSVpv("main::Foo", 0));
}

