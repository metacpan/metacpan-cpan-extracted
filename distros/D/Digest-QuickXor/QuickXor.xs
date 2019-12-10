#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "qxhash.h"

MODULE = Digest::QuickXor  PACKAGE = Digest::QuickXor::HashPtr  PREFIX = QX_

PROTOTYPES: ENABLE

Digest::QuickXor::Hash*
QX_new(class)
    char* class
  CODE:
    RETVAL = QX_new();
  OUTPUT:
    RETVAL

void
QX_add(self, addData, addSize)
    Digest::QuickXor::Hash* self
    unsigned char* addData
    size_t addSize
  CODE:
    QX_add(self, addData, addSize);

char*
QX_b64digest(self)
    Digest::QuickXor::Hash* self
  CODE:
    RETVAL = QX_b64digest(self);
  OUTPUT:
    RETVAL

void
QX_reset(self)
    Digest::QuickXor::Hash* self
  CODE:
    QX_reset(self);

void
QX_DESTROY(self)
    Digest::QuickXor::Hash* self
  CODE:
    QX_free(self);
