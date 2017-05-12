
MODULE = MIME::Fast		PACKAGE = MIME::Fast::InternetAddress	PREFIX=internet_address_

MIME::Fast::InternetAddress
internet_address_new(Class, name, address)
    CASE: items <= 1
        char *		Class
    CODE:
        RETVAL = internet_address_new();
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 2
        char *		Class
        char *		name
    CODE:
        RETVAL = internet_address_new_group(name);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL
    CASE: items == 3
        char *		Class
        char *		name
        char *		address
    CODE:
        RETVAL = internet_address_new_name(name, address);
        plist = g_list_prepend(plist, RETVAL);
    OUTPUT:
        RETVAL

void
DESTROY(ia)
        MIME::Fast::InternetAddress	ia
    CODE:
        if (g_list_find(plist,ia)) {
          internet_address_unref(ia);
          plist = g_list_remove(plist, ia);
        }

AV *
internet_address_parse_string(str)
        const char *		str
    PREINIT:
        InternetAddressList *		addrlist;
        AV * 		retav;
    CODE:
        addrlist = internet_address_parse_string(str);
	retav = newAV();
        while (addrlist) {
          SV * address = newSViv(0);
          sv_setref_pv(address, "MIME::Fast::InternetAddress", (MIME__Fast__InternetAddress)(addrlist->address));
          av_push(retav, address);
          addrlist = addrlist->next;
        }
        RETVAL = retav;
    OUTPUT:
        RETVAL


void
interface_ia_set(ia, value)
        MIME::Fast::InternetAddress	ia
	char *				value
    INTERFACE_MACRO:
	XSINTERFACE_FUNC
	XSINTERFACE_FUNC_MIMEFAST_IA_SET
    INTERFACE:
	set_name
	set_addr

 #
 # Unsupported functions:
 # internet_address_list_prepend
 # internet_address_list_append
 # internet_address_list_concat
 #
 
SV *
internet_address_to_string(ia, encode = TRUE)
        MIME::Fast::InternetAddress	ia
        gboolean		encode
    PREINIT:
	char *		textdata;
    CODE:
	textdata = internet_address_to_string(ia, encode);
	if (textdata == NULL)
	  XSRETURN_UNDEF;
	RETVAL = newSVpv(textdata, 0);
    OUTPUT:
	RETVAL

void
internet_address_set_group(ia, ...)
        MIME::Fast::InternetAddress	ia
    PREINIT:
        MIME__Fast__InternetAddress	addr;
        InternetAddressList *		addrlist = NULL;
        int			i;
    CODE:
        if (items < 2) {
          croak("Usage: internet_address_set_group(InternetAddr, [InternetAddr]+");
	  XSRETURN_UNDEF;
        }
        for (i=items - 1; i>0; --i) {
          /* retrieve each address from the perl array */
          if (sv_derived_from(ST(items - i), "MIME::Fast::InternetAddress")) {
            IV tmp = SvIV((SV*)SvRV(ST(items - i)));
            addr = INT2PTR(MIME__Fast__InternetAddress, tmp);
          } else
            croak("Usage: internet_address_set_group(InternetAddr, [InternetAddr]+");
          if (addr)
            internet_address_list_append (addrlist, addr);
        }
        if (addrlist)
          internet_address_set_group(ia, addrlist);

void
internet_address_add_member(ia, member)
        MIME::Fast::InternetAddress	ia
        MIME::Fast::InternetAddress	member

MIME::Fast::InternetAddressType
internet_address_type(ia)
        MIME::Fast::InternetAddress	ia
    CODE:
        RETVAL = ia->type;
    OUTPUT:
        RETVAL

