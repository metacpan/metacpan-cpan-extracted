#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "keybinder.h"

static HV * cb_mapping = (HV*)NULL;

void _initialize() {
  keybinder_init();
  cb_mapping = newHV();
}

void callback_bridge(const char *keystring, void *user_data){
  dSP;
  SV** cb = hv_fetch(cb_mapping, keystring, strlen(keystring), 0);
  if (cb == (SV**)NULL)
    croak("Internal error: no callback can't be found\n");
  PUSHMARK(SP);
  call_sv(*cb, G_NOARGS|G_DISCARD|G_VOID);
}


gboolean bind_key(const char *keystring, SV* cb){
  SvGETMAGIC(cb);
  if(!SvROK(cb)
     || (SvTYPE(SvRV(cb)) != SVt_PVCV))
  {
    croak("Second argument for bind_key should be a closure...\n");
  }
  if(!cb_mapping) _initialize();

  SV* cb_copy = newSVsv(cb);
  gboolean success = keybinder_bind(keystring, callback_bridge, (void*) cb_copy);
  if ( success ) {
    hv_store(cb_mapping, keystring, strlen(keystring), cb_copy, 0);
  }
  else {
    SvREFCNT_dec(cb_copy);
  }

  return success;
}


void unbind_key(const char *keystring){
  if(!cb_mapping) _initialize();
  SV** cb_copy = (SV**)hv_delete(cb_mapping, keystring, strlen(keystring), 0);
  if ( cb_copy ) {
    keybinder_unbind(keystring, callback_bridge);
  }
}

MODULE = Keybinder		PACKAGE = Keybinder		

gboolean
bind_key(keystring, cb)
  const char *keystring
  SV* cb
  PROTOTYPE: $$

void
unbind_key(keystring)
  const char *keystring
  PROTOTYPE: $



