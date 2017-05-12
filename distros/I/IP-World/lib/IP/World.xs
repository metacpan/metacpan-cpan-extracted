/* World.xs - XS module of the IP::World module

   this module maps from IP addresses to country codes, using 
   the free WorldIP database from wipmania.com and 
   the free GeoIPCountry database from maxmind.com */
   
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#if U32SIZE != 4
#error IP::World can only be run on a system in which the U32 type is 4 bytes long
#endif

typedef unsigned char uc;

typedef struct {
    char   *addr;
    union {
#ifdef USE_PERLIO
      PerlIO *p;
#endif
      FILE   *f;
    } io;
    UV   entries;
    U32  mode;
} wip_self;

/* there doesn't seem to be a way to check if function inet_pton is defined */
int ck_ip4(const char *src, uc *dest) {
    unsigned parts = 0;
    int part = -1;
    char c;

    while (c = *src++) {
        if (c == '.') {
            if (++parts > 3 || part < 0) return 0;
            *dest++ = (uc)part;
            part = -1;
        } else if ((c -= '0') >= 0
                && c <= 9) {
            if (part < 0) part = c;
            else if ((part = part*10 + c) > 255) return 0;
        } else return 0;
    }
    if (part < 0 || parts < 3) return 0;
    *dest = (uc)part;
    return 1;
}

/* subsequent code is in the specialized 'XS' dialect of C */

MODULE = IP::World       PACKAGE = IP::World

PROTOTYPES: DISABLE

SV * 
allocNew(filepath, fileLen, mode=0)
    const char *filepath
    STRLEN fileLen
    unsigned mode
    PREINIT:
        wip_self self;
        int readLen;
    CODE:
        /* XS part of IP::World->new
            allocate a block of memory and fill it from the ipworld.dat file */
        if (mode > 3) croak("operand of IP::World::new = %d, should be 0-3", mode);
#ifdef USE_PERLIO
        if (mode != 2) self.io.p = PerlIO_open(filepath, "rb");
        else
#endif
        self.io.f = fopen(filepath, "rb");
        if (!self.io.f) croak("Can't open %s: %s", filepath, strerror(errno));
        self.mode = mode;
#ifdef HAS_MMAP
#include <sys/mman.h>
        if (mode == 1) {
            /* experimental feature: use mmap rather than read */
#ifdef USE_PERLIO
            int fd = PerlIO_fileno(self.io.p);
#else
            int fd = fileno(self.io.f);
#endif
            self.addr = (char *)mmap(0, fileLen, PROT_READ, MAP_SHARED, fd, 0);
            if (self.addr == MAP_FAILED) 
                croak ("mmap failed on %s: %s\n", filepath, strerror(errno));
        } else 
#endif
        if (mode < 2) {
            /* malloc a block of size fileLen */
#if (PERL_VERSION==8 && PERL_SUBVERSION > 7) || (PERL_VERSION==9 && PERL_SUBVERSION > 2) || PERL_VERSION > 9
            Newx(self.addr, fileLen, char);
#else
            New(0, self.addr, fileLen, char);
#endif
            if (!self.addr) croak ("memory allocation for %s failed", filepath);
            /* read the data from the .dat file into the new block */
#ifdef USE_PERLIO
            readLen = PerlIO_read(self.io.p, self.addr, fileLen);
#else
            readLen = fread(self.addr, 1, fileLen, self.io.f);
#endif
            if (readLen < 0) croak("read from %s failed: %s", filepath, strerror(errno));
            if ((STRLEN)readLen != fileLen) 
                croak("should have read %d bytes from %s, actually read %d", 
                      fileLen, filepath, readLen);
            self.mode = 0;
        }
        /* all is well */
        if (mode < 2) 
#ifdef USE_PERLIO
            PerlIO_close(self.io.p);
#else
            fclose(self.io.f);
#endif
        /* For each entry there is a 4 byte address plus a 10 bit country code.
             At 3 codes/word, the number of entries = 3/16 * the number of bytes */
        self.entries = fileLen*3 >> 4;        
        /* {new} in World.pm will bless the object we return */
        RETVAL = newSVpv((const char *)(&self), sizeof(wip_self));   
    OUTPUT:
        RETVAL

SV*
getcc(self_ref, ip_sv)
    SV* self_ref
    SV* ip_sv
    PREINIT:
        SV* self_deref;		
        char *s;
        STRLEN len = 0;
        wip_self self;
        I32 flgs;
        uc netip[4];
        register U32 ip, *ips;
        register UV i, bottom = 0, top;
        U32 word;
        char c[3] = "**";
    CODE:
        /* $new_obj->getcc is only in XS/C
           check that self_ref is defined ref; dref it; check len; copy to self */
        if (sv_isobject(self_ref)) {
            self_deref = SvRV(self_ref);
            if (SvPOK(self_deref)) s = SvPV(self_deref, len);
        }
        if (len != sizeof(wip_self))
            croak("automatic 'self' operand to getcc is not of correct type"); 
        memcpy (&self, s, sizeof(wip_self));
        /* the ip_sv argument can be of 2 types (if error return '**') */
        if (!SvOK(ip_sv)) goto set_retval;
        flgs = SvFLAGS(ip_sv);
        if (!(flgs & (SVp_POK|SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK))) goto set_retval;
        s = SvPV(ip_sv, len);
        /* if the the ip operand is a dotted string, convert it to network-order U32 
           else if the operand does't look like a network-order U32, lose */
        if (ck_ip4(s, netip) > 0) s = (char *)netip; 
        else if (len != 4) goto set_retval;
        /* if necessary, convert network order (big-endian) to native endianism */
        ip = (uc)s[0] << 24 | (uc)s[1] << 16 | (uc)s[2] << 8 | (uc)s[3];        
        /* binary-search the IP table */
        top = self.entries;
        if (self.mode < 2) {
            /* memory mode */
            ips = (U32 *)self.addr;
            while (bottom < top-1) {
                /* compare ip to the table entry halfway between top and bottom */
                i = (bottom + top) >> 1;
                if (ip < ips[i]) top = i;
                else bottom = i;
            }
            /* the table of country codes (3 per word) follows the table of IPs
                copy the corresponding 3 entries to word */
            word = *(ips + self.entries + bottom/3);
        } else {
            /* DASD mode */
            while (bottom < top-1) {
                /* compare ip to the table entry halfway between top and bottom */
                i = (bottom + top) >> 1;
#ifdef USE_PERLIO
                if (self.mode == 3) {
                    PerlIO_seek(self.io.p, i<<2, 0);
                    PerlIO_read(self.io.p, &word, 4);
                } else {
#endif
                    fseek(self.io.f, i<<2, 0);
                    fread(&word, 4, 1, self.io.f);
#ifdef USE_PERLIO
                }
#endif  
                if (ip < word) top = i;
                else bottom = i;
            }
#ifdef USE_PERLIO
            /* the table of country codes (3 per word) follows the table of IPs
                read the corresponding 3 entries into word */
            if (self.mode == 3) {
                PerlIO_seek(self.io.p, (self.entries + bottom/3)<<2, 0);
                PerlIO_read(self.io.p, &word, 4);
            } else {
#endif
                fseek(self.io.f, (self.entries + bottom/3)<<2, 0);
                fread(&word, 4, 1, self.io.f);
#ifdef USE_PERLIO
            }
#endif  
        }
        switch (bottom % 3) {
          case 0:  word >>= 20; break;
          case 1:  word = word>>10 & 0x3FF; break;
          default: word &= 0x3FF;
        }
        if (word == 26*26) c[0] = c[1] = '?';
        else {
          c[0] = (char)(word / 26) + 'A';
          c[1] = (char)(word % 26) + 'A';
        }
        set_retval:
        RETVAL = newSVpv(c, 2);
    OUTPUT:
        RETVAL

void
DESTROY(self_ref)
    SV* self_ref
    PREINIT:
        SV *self_deref;		
        char *s;
        STRLEN len = 0;
        wip_self self;
    CODE:
        /* DESTROY gives back allocated memory
           check that self_ref is defined ref; dref it; check len; copy to self */
        if (sv_isobject(self_ref)) {
            self_deref = SvRV(self_ref);
            if (SvPOK(self_deref)) 
                s = SvPV(self_deref, len);
        }
        if (len != sizeof(wip_self))
            croak("automatic 'self' operand to DESTROY is not of correct type"); 
        memcpy (&self, s, sizeof(wip_self));
#ifdef HAS_MMAP
        if (self.mode == 1) munmap((caddr_t)self.addr, (size_t)((self.entries<<4)/3));
        else 
#endif
        if (self.mode < 2) Safefree(self.addr);
        else 
#ifdef USE_PERLIO
        if (self.mode == 3) PerlIO_close(self.io.p);
        else
#endif
        fclose(self.io.f);
