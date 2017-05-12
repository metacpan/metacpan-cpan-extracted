#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define HEX_SZ (16*10 + 1)
#define CHR_SZ (16*8 + 1)

typedef struct {
	U8 row;
	U8 hpad;
	U8 cpad;
	U8 hsp;
	U8 csp;
	U8 cols;
} hexdump_conf;

static SV * myhexdump(char *data, STRLEN size, hexdump_conf *cf)
{
	/* dumps size bytes of *data to stdout. Looks like:
	 * [0000] 75 6E 6B 6E 6F 77 6E 20 30 FF 00 00 00 00 39 00 unknown 0.....9.
	 * src = 16 bytes.
	 * dst = 6       +  16 * 3   +      4*2         +  16       + 1
	 *       prefix    byte+pad    sp between col    visual     newline
	 */
	U8 row  = cf->row;
	U8 hpad = cf->hpad;
	U8 cpad = cf->cpad;
	U8 hsp  = cf->hsp;
	U8 csp  = cf->csp;
	U8 sp   = cf->cols;
	
	U8 every = (U8)row / sp;
	
	
	unsigned char *p = data;
	unsigned char c;
	STRLEN n;
	UV addr;
	char bytestr[4] = {0};
	char addrstr[10] = {0};
	char hexstr[ HEX_SZ ] = {0};
	char chrstr[ CHR_SZ ] = {0};
	STRLEN hex_sz = row*(2+hpad) + hsp * sp + 1; /* size = bytes<16*2> + 16*<hpad> + col<hsp*sp> */
	STRLEN chr_sz = row*(2+cpad) + csp * sp + 1; /* size = bytes<16> + 16*cpad + col<csp*sp> */
	SV * rv = newSVpvn("",0);
	
	if ( hex_sz > HEX_SZ ) {
		warn("Parameters too big: estimated hex size will be %d, but have only %d", hex_sz, HEX_SZ);
		return sv_newmortal();
	}
	if ( chr_sz > CHR_SZ ) {
		warn("Parameters too big: estimated chr size will be %d, but have only %d", chr_sz, CHR_SZ);
		return sv_newmortal();
	}
	
	STRLEN sv_sz = ( size + row-1 ) * ( (U8)( 6 + 3 + hex_sz + 2 + chr_sz + 1 + row-1 ) / row );
	/*                      ^ reserve for incomplete string             \n      ^ emulation of ceil */
	SvGROW(rv,sv_sz);
	
	char *curhex = hexstr;
	char *curchr = chrstr;
	for(n=1; n<=size; n++) {
		if (n % row == 1)
			snprintf(addrstr, sizeof(addrstr), "%04"UVxf, ( PTR2UV(p)-PTR2UV(data) ) & 0xffff );
		
		c = *p;
		if (c < 0x20 || c > 0x7f) {
			c = '.';
		}
		
		/* store hex str (for left side) */
		my_snprintf(curhex, 3+hpad, "%02X%-*s", *p, hpad,""); curhex += 2+hpad;
		
		/* store char str (for right side) */
		my_snprintf(curchr, 2+cpad, "%c%-*s", c, cpad, ""); curchr += 1+cpad;
		
		//warn("n=%d, row=%d, every=%d\n",n,row,every);
		if( n % row == 0 ) {
			/* line completed */
			//printf("[%-4.4s]   %s  %s\n", addrstr, hexstr, chrstr);
			sv_catpvf(rv,"[%-4.4s]   %s  %s\n", addrstr, hexstr, chrstr);
			//sv_catpvf(rv,"[%-4.4s]   %-*s %-*s\n", addrstr, hex_sz-1, hexstr, chr_sz-1, chrstr);
			hexstr[0] = 0; curhex = hexstr;
			chrstr[0] = 0; curchr = chrstr;
		} else if( every && ( n % every == 0 ) ) {
			/* half line: add whitespaces */
			my_snprintf(curhex, 1+hsp, "%-*s", hsp, ""); curhex += hsp;
			my_snprintf(curchr, 1+csp, "%-*s", csp, ""); curchr += csp;
		}
		p++; /* next byte */
	}
	
	if (curhex > hexstr) {
		/* print rest of buffer if not empty */
		//printf("[%4.4s]   %s  %s\n", addrstr, hexstr, chrstr);
		sv_catpvf(rv,"[%-4.4s]   %-*s %-*s\n", addrstr, hex_sz-1, hexstr, chr_sz-1, chrstr);
	}
	//warn("String length: %d, sv_sz=%d",SvCUR(rv),sv_sz);
	return rv;
}

MODULE = Devel::Hexdump		PACKAGE = Devel::Hexdump

SV *
xd(buf,...)
	SV *buf
	PROTOTYPE: $;$
	CODE:
		STRLEN l;
		U8 *p;
		hexdump_conf cf;
		cf.row  = 16;
		cf.hpad = 1;
		cf.cpad = 0;
		cf.hsp  = 1;
		cf.csp  = 1;
		cf.cols   = 4;
		if (items > 1){
			if ( SvOK(ST(1)) && SvROK(ST(1)) && SvTYPE( SvRV( ST(1) ) ) == SVt_PVHV) {
				HV * conf = (HV *) SvRV(ST(1));
				SV **key;
				if ((key = hv_fetch(conf, "row", 3, 0)) && SvIOK(*key))  cf.row = SvIV(*key);
				if ((key = hv_fetch(conf, "hpad", 4, 0)) && SvIOK(*key)) cf.hpad = SvIV(*key);
				if ((key = hv_fetch(conf, "cpad", 4, 0)) && SvIOK(*key)) cf.cpad = SvIV(*key);
				if ((key = hv_fetch(conf, "hsp", 3, 0)) && SvIOK(*key))  cf.hsp = SvIV(*key);
				if ((key = hv_fetch(conf, "csp", 3, 0)) && SvIOK(*key)) cf.csp = SvIV(*key);
				if ((key = hv_fetch(conf, "cols", 4, 0)) && SvIOK(*key)) cf.cols = SvIV(*key);
				
			} else {
				croak("Usage: xd($buffer [, \%config ])");
			}
		}
		p = SvPV(buf,l);
		RETVAL = myhexdump(p, l, &cf);
	OUTPUT:
		RETVAL
