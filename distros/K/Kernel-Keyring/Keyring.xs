#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "INLINE.h"

#include <keyutils.h>

int _key_add(char* type, char* desc, char* data, int datalen, int keyring) {
    return add_key(type, desc, data, datalen, keyring);
}

void _key_read(key_serial_t key_id) {
    Inline_Stack_Vars;
    void* key = NULL;
    int ret = keyctl_read_alloc(key_id, &key);

    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(ret)));
    if (key != NULL)
        Inline_Stack_Push(sv_2mortal(newSVpv(key, ret)));
    Inline_Stack_Done;
}

long _key_timeout(key_serial_t key_id, unsigned int timeout) {
    return keyctl_set_timeout(key_id, timeout);
}

long _key_unlink(key_serial_t key_id, key_serial_t keyring) {
    return keyctl_unlink(key_id, keyring);
}

int _key_session(char* desc) {
    return keyctl_join_session_keyring(desc);
}

long _key_perm(key_serial_t key_id, key_perm_t perm) {
    return keyctl_setperm(key_id, perm);
}

long _key_revoke(key_serial_t key_id) {
    return keyctl_revoke(key_id);
}

MODULE = Kernel::Keyring  PACKAGE = Kernel::Keyring  

PROTOTYPES: DISABLE


int
_key_add (type, desc, data, datalen, keyring)
	char *	type
	char *	desc
	char *	data
	int	datalen
	int	keyring

void
_key_read (key_id)
	int	key_id
        PREINIT:
        I32* temp;
        PPCODE:
        temp = PL_markstack_ptr++;
        _key_read(key_id);
        if (PL_markstack_ptr != temp) {
          /* truly void, because dXSARGS not invoked */
          PL_markstack_ptr = temp;
          XSRETURN_EMPTY; /* return empty stack */
        }
        /* must have used dXSARGS; list context implied */
        return; /* assume stack size is correct */

long
_key_timeout (key_id, timeout)
	int	key_id
	unsigned int	timeout

long
_key_unlink (key_id, keyring)
	int	key_id
	int	keyring

int
_key_session (desc)
	char *	desc

long
_key_perm (key_id, perm)
	int	key_id
	unsigned int	perm

long
_key_revoke (key_id)
	int	key_id

