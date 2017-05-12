#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#define NEED_sv_2pv_flags_GLOBAL
#include "ppport.h"
#include <math.h>
#include "xshelper.h"

static char PIECES[32] = {
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
    'b', 'c', 'd', 'e', 'f', 'g', 'h', 'j', 'k', 'm',
    'n', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z',
};

STATIC_INLINE
void
encode(char *buf, STRLEN precision, NV lat, NV lon) {
    IV which = 0;
    STRLEN count = 0;
    NV 
        lat_min = -90,
        lat_max = 90,
        lon_min = -180,
        lon_max = 180
    ;

    while ( count < precision ) {
        IV i;
        IV bits = 0;
        for( i = 0; i < 5; i++ ) {
            IV bit;
            if (which) {
                NV mid = (lat_max + lat_min) / 2;
                bit = lat >= mid ? 1 : 0;
                if ( bit ) { lat_min = mid; }
                else       { lat_max = mid; }
            } else {
                NV mid = (lon_max + lon_min) / 2;
                bit = lon >= mid ? 1 : 0;
                if ( bit ) { lon_min = mid; }
                else       { lon_max = mid; }
            }
            bits = ( ( bits << 1 ) | bit );
            which ^= 1;
        }

        buf[count] = PIECES[bits];
        count++;
    }


    buf[count] = '\0';
}

STATIC_INLINE
void
decode_to_interval(char *hash, STRLEN len, NV *lat_min_out, NV *lat_max_out, NV *lon_min_out, NV *lon_max_out) {
    STRLEN i, j;
    IV which = 0, min_or_max;
    NV 
        lat_min = -90,
        lat_max = 90,
        lon_min = -180,
        lon_max = 180
    ;
    for (i = 0; i < len; i++ ) {
        IV bits;
        int x = (int) hash[i];
        if (x >= 48 && x <= 57) {
            bits = x - 48;
        } else if ( x >= 98 && x <= 104 ) {
            bits = x - 88;
        } else if ( x >= 106 && x <= 107 ) {
            bits = x - 89;
        } else if ( x >= 109 && x <= 110 ) {
            bits = x - 90;
        } else if ( x >= 112 && x <= 122 ) {
            bits = x - 91;
        } else {
            croak("Bad character '%c' in hash '%s'", hash[i], hash);
        }

        for (j = 0; j < 5; j++){ 
            min_or_max = ( bits & 16 ) >> 4;
            if (which) {
                NV mid = (lat_max + lat_min ) / 2;
                if (min_or_max) { /* max */
                    lat_min = mid;
                } else {
                    lat_max = mid;
                }
            } else {
                NV mid = (lon_max + lon_min ) / 2;
                if (min_or_max) { /* max */
                    lon_min = mid;
                } else {
                    lon_max = mid;
                }
            }

            which ^= 1;
            bits <<= 1;
        }
    }

    *lat_min_out = lat_min;
    *lat_max_out = lat_max;
    *lon_min_out = lon_min;
    *lon_max_out = lon_max;
}

STATIC_INLINE
void
decode(char *hash, IV len, NV *lat, NV *lon) {
    NV lat_min = 0, lat_max = 0, lon_min = 0, lon_max = 0;
    decode_to_interval(hash, len, &lat_min, &lat_max, &lon_min, &lon_max);
    *lat = (lat_max + lat_min) / 2;
    *lon = (lon_max + lon_min) / 2;
}

static char* NEIGHBORS[4][2] = {
    { "bc01fg45238967deuvhjyznpkmstqrwx", "p0r21436x8zb9dcf5h7kjnmqesgutwvy" },
    { "238967debc01fg45kmstqrwxuvhjyznp", "14365h7k9dcfesgujnmqp0r2twvyx8zb" },
    { "p0r21436x8zb9dcf5h7kjnmqesgutwvy", "bc01fg45238967deuvhjyznpkmstqrwx" },
    { "14365h7k9dcfesgujnmqp0r2twvyx8zb", "238967debc01fg45kmstqrwxuvhjyznp" }
};

static char* BORDERS[4][2] = {
    { "bcfguvyz", "prxz" },
    { "0145hjnp", "028b" },
    { "prxz", "bcfguvyz" },
    { "028b", "0145hjnp" }
};

#define LOG2_OF_10 3.32192809488736
#define LOG2_OF_180 7.49185309632967
#define LOG2_OF_360 8.49185309632968

STATIC_INLINE
IV
bits_for_number(char *number) {
    for(; *number != '\0'; number++){
        if(*number == '.'){
            number++; /* skip dot */
            return (IV) (strlen(number)) * LOG2_OF_10 + 1;
        }
    }
    return 0;
}

STATIC_INLINE
IV
precision(SV *lat, SV *lon) {
    IV lab = bits_for_number(SvPV_nolen(lat)) + 8;  /* 8 > log_2(180) */
    IV lob = bits_for_number(SvPV_nolen(lon)) + 9;  /* 9 > log_2(360) */

    /* Though it seems I should use ceil(), I copied the logic from Geo::Hash */
    return (IV) ( ( ( lab > lob ? lab : lob ) + 1 ) / 2.5 );
}

enum GH_DIRECTION {
    ADJ_RIGHT = 0,
    ADJ_LEFT = 1,
    ADJ_TOP = 2,
    ADJ_BOTTOM = 3
};

/* need to free this return value! */
#define HASHBASE_BUFSIZ 8192
STATIC_INLINE
char *
adjacent(char *hash, STRLEN hashlen, enum GH_DIRECTION direction) {
    char base[HASHBASE_BUFSIZ];
    char last_ch = hash[ hashlen - 1 ];
    char *pos, *ret;
    IV type = hashlen % 2;
    IV base_len;

    if (hashlen < 1)
        croak("PANIC: hash too short!");
    if (hashlen > HASHBASE_BUFSIZ)
        croak("PANIC: hash too big!");

    memcpy(base, hash, hashlen - 1);
    *(base + hashlen - 1) = '\0';

    if (hashlen > 1) {
        pos = strchr(BORDERS[direction][type], last_ch);
        if (pos != NULL) {
           char *tmp = adjacent(base, strlen(base), direction);
           strcpy(base, tmp);
           Safefree(tmp);
        }
    }
    base_len = strlen(base);
    Newxz( ret, base_len + 2, char );
    strcpy( ret, base );
    ret[ base_len ] = PIECES[ strchr(NEIGHBORS[direction][type], last_ch) - NEIGHBORS[direction][type] ]; 
    *(ret + base_len + 1) = '\0';
    return ret;
}

STATIC_INLINE
void
neighbors(char *hash, STRLEN hashlen, int around, int offset, char ***neighbors, int *nsize) {
    char *xhash;
    STRLEN xhashlen = hashlen;
    int i = 1;

    Newxz( xhash, hashlen + 1, char );
    Copy( hash, xhash, hashlen, char );
    *(xhash + hashlen) = '\0';

    *nsize = ( (around + offset) * 2 + 1 ) * ( (around + offset) * 2 + 1 )
             - (offset * 2 + 1) * (offset * 2 + 1);
    Newxz( *neighbors, *nsize, char *);

    while ( offset > 0 ) {
        char *top = adjacent( xhash, xhashlen, ADJ_TOP );
        char *left = adjacent( top, strlen(top), ADJ_LEFT );
        Safefree(top);
        Safefree(xhash);
        xhash = left;
        xhashlen = strlen(left);

        offset--;
        i++;
    }

    {
    int m = 0;
    char *tmp = xhash;
    while (around-- > 0) {
        int j;
        /* going to insert this many neighbors */
        (*neighbors)[m++] = adjacent(xhash, xhashlen, ADJ_TOP);

        for ( j = 0; j < 2 * i - 1; j ++ ) {
            xhash = (*neighbors)[m - 1];
            xhashlen = strlen( xhash );
            (*neighbors)[m++] = adjacent(xhash, xhashlen, ADJ_RIGHT);
        }
        for ( j = 0; j < 2 * i; j ++ ) {
            xhash = (*neighbors)[m - 1];
            xhashlen = strlen( xhash );
            (*neighbors)[m++] = adjacent(xhash, xhashlen, ADJ_BOTTOM);
        }
        for ( j = 0; j < 2 * i; j ++ ) {
            xhash = (*neighbors)[m - 1];
            xhashlen = strlen( xhash );
            (*neighbors)[m++] = adjacent(xhash, xhashlen, ADJ_LEFT);
        }
        for ( j = 0; j < 2 * i; j ++ ) {
            xhash = (*neighbors)[m - 1];
            xhashlen = strlen( xhash );
            (*neighbors)[m++] = adjacent(xhash, xhashlen, ADJ_TOP);
        }
        i++;
        xhash = (*neighbors)[m - 1];
        xhashlen = strlen( xhash );
    }
        Safefree(tmp);
    }
}

MODULE = Geo::Hash::XS PACKAGE = Geo::Hash::XS

PROTOTYPES: DISABLE

SV *
encode(self, lat, lon, p = 0)
        SV *self;
        SV *lat;
        SV *lon;
        IV p;
    PREINIT:
        char *encoded;
    CODE:
        if (! looks_like_number(lat) || ! looks_like_number(lon) ) {
            croak("encode() only works on degrees, not dms values");
        }  

        if (p <= 0) {
            p = precision(lat, lon);
        }
        PERL_UNUSED_VAR(self);

        Newxz(encoded, p + 1, char);
        encode(encoded, p, SvNV(lat), SvNV(lon));

        RETVAL = newSV(0);
        sv_setpv( RETVAL, encoded );
        Safefree( encoded );
    OUTPUT:
        RETVAL

void
decode_to_interval(self, hash)
        SV *self;
        char *hash;
    PREINIT:
        NV lat_min = 0, lat_max = 0, lon_min = 0, lon_max = 0;
        STRLEN len = strlen(hash);
        AV *lat_range = (AV *)sv_2mortal((SV *)newAV());
        AV *lon_range = (AV *)sv_2mortal((SV *)newAV());
    PPCODE:
        PERL_UNUSED_VAR(self);
        decode_to_interval(hash, len, &lat_min, &lat_max, &lon_min, &lon_max);

        av_push(lat_range, newSVnv(lat_max));
        av_push(lat_range, newSVnv(lat_min));
        av_push(lon_range, newSVnv(lon_max));
        av_push(lon_range, newSVnv(lon_min));

        XPUSHs(sv_2mortal(newRV_inc((SV *)lat_range)));
        XPUSHs(sv_2mortal(newRV_inc((SV *)lon_range)));

void
decode(self, hash)
        SV *self;
        char *hash;
    PREINIT:
        NV lat = 0, lon = 0;
        STRLEN len = strlen(hash);
    PPCODE:
        PERL_UNUSED_VAR(self);
        decode(hash, len, &lat, &lon);
        mXPUSHn(lat);
        mXPUSHn(lon);

IV
precision(self, lat, lon)
        SV *self
        SV *lat
        SV *lon;
    CODE:
        PERL_UNUSED_VAR(self);
        RETVAL = precision(lat, lon);
    OUTPUT:
        RETVAL

SV *
adjacent(self, hash, direction)
        SV *self;
        char *hash;
        int direction;
    PREINIT:
        char *adj;
    CODE:
        PERL_UNUSED_VAR(self);
        adj = adjacent(hash, strlen(hash), direction);

        RETVAL = newSV(0);
        sv_setpv(RETVAL, adj);
        Safefree(adj);
    OUTPUT:
        RETVAL

void
neighbors(self, hash, around = 1, offset = 0)
        SV *self;
        char *hash;
        int around;
        int offset;
    PREINIT:
        int i;
        int nsize;
        char **list;
    PPCODE:
        PERL_UNUSED_VAR(self);
        neighbors(hash, strlen(hash), around, offset, &list, &nsize);

        for( i = 0; i < nsize; i++ ) {
            mXPUSHp( list[i], strlen(list[i]) );
        }
        for( i = 0; i < nsize; i++ ) {
            Safefree(list[i]);
        }
        Safefree(list);

IV
_constant()
    ALIAS:
        ADJ_TOP = ADJ_TOP
        ADJ_RIGHT = ADJ_RIGHT
        ADJ_LEFT = ADJ_LEFT
        ADJ_BOTTOM = ADJ_BOTTOM
    CODE:
        RETVAL = ix;
    OUTPUT:
        RETVAL

