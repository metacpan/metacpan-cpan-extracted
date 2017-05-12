#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <irc_crypt.h>

#include "const-c.inc"

MODULE = IRC::Crypt		PACKAGE = IRC::Crypt PREFIX = irc_

INCLUDE: const-xs.inc

int
irc_add_known_key(key)
		char *	key
	OUTPUT:
		RETVAL

int
irc_delete_known_key(key)
		char *	key
	OUTPUT:
		RETVAL
		
int
irc_add_default_key(addr, key)
		char *	addr
		char *	key
	OUTPUT:
		RETVAL
		
int
irc_delete_default_key(addr)
		char *	addr
	OUTPUT:
		RETVAL
		
int
irc_delete_all_keys()
	OUTPUT:
		RETVAL
		
int
irc_delete_all_default_keys()
	OUTPUT:
		RETVAL
		
int
irc_delete_all_known_keys()
	OUTPUT:
		RETVAL
		
char *
irc_encrypt_message_to_address(addr, nick, message)
		char *	addr
		char *	nick
		char *	message
	PPCODE:
		char * ret;
		ret = irc_encrypt_message_to_address(addr,nick,message);
		if(ret)
		{
			XPUSHs(sv_2mortal(newSVpv(ret, 0)));
			free(ret); 
			XSRETURN(1);
		}
		XSRETURN(0);

char *
irc_encrypt_message_with_key(key, nick, message)
		char *	key
		char *	nick
		char *	message
	PPCODE:
		char * ret;
		ret = irc_encrypt_message_with_key(key,nick,message);
		if(ret)
		{
			XPUSHs(sv_2mortal(newSVpv(ret, 0)));
			free(ret); 
			XSRETURN(1);
		}
		XSRETURN(0);

void
irc_decrypt_message(msg)
		char *	msg
	PPCODE:
		char *rmsg;
		char *rnick;
		unsigned int tdiff = 0;
		int ret;
		
		ret = irc_decrypt_message(msg, &rmsg, &rnick, &tdiff);
		if(ret)
		{
			XPUSHs(sv_2mortal(newSVpv(rmsg, 0)));
			XPUSHs(sv_2mortal(newSVpv(rnick, 0)));
			XPUSHs(sv_2mortal(newSViv(tdiff)));
			free(rmsg);
			free(rnick);
			XSRETURN(3);
		}
		else
		{
			XPUSHs(sv_2mortal(newSVpv(rmsg, 0)));
			free(rmsg);
			XSRETURN(1);
		}

int
irc_is_encrypted_message_p(msg)
		char *	msg
	OUTPUT:
		RETVAL

int
irc_set_key_expand_version(n)
		int	n
	OUTPUT:
		RETVAL
		
int
irc_key_expand_version()
	OUTPUT:
		RETVAL

