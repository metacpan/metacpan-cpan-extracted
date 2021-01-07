#ifndef __GTK_RECENT_FILES_PERL_H__
#define __GTK_RECENT_FILES_PERL_H__
#include "gtk2perl.h"

#include "recent-files/egg-recent.h"

#ifndef EGG_TYPE_RECENT_MODEL_SORT
#define EGG_TYPE_RECENT_MODEL_SORT (egg_recent_perl_model_sort_get_type ())
GType egg_recent_perl_model_sort_get_type (void) G_GNUC_CONST;
#endif

#include "build/recentfiles-autogen.h"

#endif /* __GTK_RECENT_FILES_PERL_H__ */
