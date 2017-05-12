#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <pwd.h>

#ifdef HAVE_SHADOW_H
#include <shadow.h>
#endif

#ifdef __cplusplus
}
#endif

MODULE = File::LckPwdF		PACKAGE = File::LckPwdF
PROTOTYPES: ENABLE

int
lckpwdf()

int
ulckpwdf()
