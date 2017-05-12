/* declarations for aesths */
/* $Id: aesth.h,v 1.1 1993/05/26 23:22:27 coleman Exp $ */

#ifndef aesth_h
# define aesth_h 1

# include "aglo.h"
# include "defines.h"
# include "point.h"

# define declare_aesth(AESTHETIC_NAME) \
	aglo_aesth_gradient_fx ae_##AESTHETIC_NAME;	\
	aglo_aesth_setup_fx ae_setup_##AESTHETIC_NAME;
	

# define define_aesth(AESTHETIC_NAME)				\
	void ae_##AESTHETIC_NAME(pTHX_ aglo_state state,	\
				 aglo_gradient gradient,	\
                                 void *private)

# define define_setup(AESTHETIC_NAME) \
	void *ae_setup_##AESTHETIC_NAME(pTHX_ SV *force_sv,		\
					SV *state_sv,			\
					aglo_state state)

# define define_cleanup(AESTHETIC_NAME) \
	void ae_cleanup_##AESTHETIC_NAME(pTHX_ aglo_state state, void *private)

# define PRIVATE	((struct private *) private)

#endif /* aesth.h */
