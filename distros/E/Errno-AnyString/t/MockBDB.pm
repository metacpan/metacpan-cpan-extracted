package MockBDB;
use strict;
use warnings;

# For testing inter-operation between Errno::AnyString and BDB, both of which
# make changes to the magic on $!.

do_patch_errno();

use Inline C => <<'END_C';

#ifndef PERL_MAGIC_sv
#  define PERL_MAGIC_sv '\0'
#endif

static char *
db_strerror(int e)
{
    static char msg[256];

    snprintf(msg, sizeof(msg), "Fake BDB error %d", e);
    return msg;
}
    
/***************************************************************/
/* The following copied verbatim from F<BDB.xs> in L<BDB> 1.84 */

static int
errno_get (pTHX_ SV *sv, MAGIC *mg)
{
  if (*mg->mg_ptr == '!') // should always be the case
    if (-30999 <= errno && errno <= -30800)
      {
        sv_setnv (sv, (NV)errno);
        sv_setpv (sv, db_strerror (errno));
        SvNOK_on (sv); /* what a wonderful hack! */
                       // ^^^ copied from perl sources
        return 0;
      }

  return PL_vtbl_sv.svt_get (aTHX_ sv, mg);
}

static MGVTBL vtbl_errno;

// this wonderful hack :( patches perl's $! variable to support our errno values
static void
patch_errno (void)
{
  SV *sv;
  MAGIC *mg;

  if (!(sv = get_sv ("!", 1)))
    return;

  if (!(mg = mg_find (sv, PERL_MAGIC_sv)))
    return;

  if (mg->mg_virtual != &PL_vtbl_sv)
    return;

  vtbl_errno = PL_vtbl_sv;
  vtbl_errno.svt_get = errno_get;
  mg->mg_virtual = &vtbl_errno;
}

/*            end of verbatim copied bit                       */
/***************************************************************/

void
do_patch_errno()
{
    patch_errno();
}

END_C

1;


