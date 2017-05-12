/* Transaction.xs: Perl interface for manipulation of transactions
 *
 * $Id: Transaction.xs 8232 2009-07-26 02:49:54Z FREQUENCY@cpan.org $
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <errno.h>
#include <libjio.h>
#include <sys/types.h>
#include <unistd.h>
#include "model.h"

MODULE = IO::Journal::Transaction    PACKAGE = IO::Journal::Transaction

PROTOTYPES: DISABLE

IO::Journal::Transaction
new(class, journal)
  char *class
  IO::Journal journal
  PREINIT:
    transaction *self;
  INIT:
    Newx(self, 1, transaction); /* allocate 1 transaction instance */
  CODE:
    self->complete = 0; /* becomes true after a commit or rollback */
    self->journal = journal;
    jtrans_init(&(journal->jfs), &(self->jtrans));
    RETVAL = self;
  OUTPUT:
    RETVAL

void
syswrite(self, text, ...)
  IO::Journal::Transaction self
  char *text
  PREINIT:
    size_t count;
    off_t offset;
    int ret;
  CODE:
    if (!SvIOK(ST(2))) /* count */
      count = strlen(text);

    if (!SvIOK(ST(3))) /* offset */
      offset = jlseek(&(self->journal->jfs), 0, SEEK_CUR);

    ret = jtrans_add(&(self->jtrans), text, count, offset);
    if (ret > 0) /* If success, advance file pointer */
      jlseek(&(self->journal->jfs), count, SEEK_CUR);

int
finished(self)
  IO::Journal::Transaction self
  CODE:
    RETVAL = self->complete;
  OUTPUT:
    RETVAL

void
commit(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_commit(&(self->jtrans));
    if (r < 0)
      croak("Error during commit. Data may be lost.");
    self->complete = 1;

void
rollback(self)
  IO::Journal::Transaction self
  PREINIT:
    int r;
  CODE:
    r = jtrans_rollback(&(self->jtrans));
    if (r < 0)
      croak("Error encountered while rolling back");
    self->complete = 1;

void
DESTROY(self)
  IO::Journal::Transaction self
  CODE:
    jtrans_free(&(self->jtrans));
    Safefree(self);
