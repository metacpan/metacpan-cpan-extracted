
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "GtkDefs.h"
#include "GnomeDefs.h"


static void dns_callback(guint32 ip_addr, void * data)
{
	AV * args = (AV*)data;
    SV * handler = *av_fetch(args, 0, 0);
    char address[64];
    int i;
    dSP;

    PUSHMARK(SP);
    for (i=1;i<=av_len(args);i++)
            XPUSHs(sv_2mortal(newSVsv(*av_fetch(args, i, 0))));
    
    sprintf(address, "%d.%d.%d.%d",
    	(ip_addr >> 24) & 0xff,
    	(ip_addr >> 16) & 0xff,
    	(ip_addr >> 8) & 0xff,
    	(ip_addr >> 0) & 0xff);
    XPUSHs(sv_2mortal(newSVpv(address,0)));
    PUTBACK;

    perl_call_sv(handler, G_DISCARD);
	
}

MODULE = Gnome::DNS		PACKAGE = Gnome::DNS		PREFIX = gnome_dns_

void
gnome_dns_init(Class, servers=0)
	int	servers
	CODE:
	gnome_dns_init(servers);

int
gnome_dns_lookup(Class, hostname, callback, ...)
	char *	hostname
	SV *	callback
	CODE:
	{
		AV * args = newAV();
		PackCallbackST(args, 2);
		RETVAL = gnome_dns_lookup(hostname, dns_callback, args);
	}
	OUTPUT:
	RETVAL

void
gnome_dns_abort(Class, tag)
	int	tag
	CODE:
	gnome_dns_abort(tag);

