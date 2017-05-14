/*
 * functions for mapping k structs to perl variables
 */
#include "k.h"
#include "kparse.h"
#include <string.h>

#define MATH_INT64_NATIVE_IF_AVAILABLE
#include "perl_math_int64.h"

SV* sv_from_k(K k) {

    SV* result;

    if (k == NULL) {
        result = &PL_sv_undef;
    }
    else if (k->t < 0) {
        result = scalar_from_k(k);
    }
    else if (k->t > 0) {
        result = vector_from_k(k);
    }
    else {
        result = mixed_list_from_k(k);
    }

    return result;
}

SV* scalar_from_k(K k) {
    SV *result = NULL;

    switch (- k->t) {

        case KB: // boolean
            result = bool_from_k(k);
            break;

        case KG: // byte
            result = byte_from_k(k);
            break;

        case KC: // char
            result = char_from_k(k);
            break;

        case KH: // short
            result = short_from_k(k);
            break;

        case KI: // int
        case KM: // month
        case KD: // date
        case KU: // minute
        case KV: // second
        case KT: // time
            result = int_from_k(k);
            break;

        case KJ: // long
        case KN: // timespan
            result = long_from_k(k);
            break;

        case KP: // timestamp
            result = timestamp_from_k(k);
            break;

        case KE: // real
            result = real_from_k(k);
            break;

        case KF: // float
        case KZ: // time *don't use*
            result = float_from_k(k);
            break;

        case KS: // symbol
            result = symbol_from_k(k);
            break;

        case 128: // error
            croak(k->s);
            break;

        default:
            croak("unrecognized scalar type '%d'\n", k->t);
            break;
    }

    return result;
}

SV* vector_from_k(K k) {
    SV *result = NULL;

    switch (k->t) {

        case KB: // boolean
            result = bool_vector_from_k(k);
            break;

        case KG: // byte
            result = byte_vector_from_k(k);
            break;

        case KC: // char
            result = char_vector_from_k(k);
            break;

        case KH: // short
            result = short_vector_from_k(k);
            break;

        case KI: // int
        case KM: // month
        case KD: // date
        case KU: // minute
        case KV: // second
        case KT: // time
            result = int_vector_from_k(k);
            break;

        case KJ: // long
        case KN: // timespan
            result = long_vector_from_k(k);
            break;

        case KP: // timestamp
            result = timestamp_vector_from_k(k);
            break;

        case KE: // real
            result = real_vector_from_k(k);
            break;

        case KF: // float
        case KZ: // time *don't use*
            result = float_vector_from_k(k);
            break;

        case KS: // symbol
            result = symbol_vector_from_k(k);
            break;

        case XT: // table or flip
            result = table_from_k(k);
            break;

        case XD: // dict or table w/ primary keys
            result = xd_from_k(k);
            break;

        // enumerations (start at 20?) other stuff?

        case 100: // function
            return &PL_sv_undef;
            break;

        case 101: // generic null
            return &PL_sv_undef;
            break;

        case 102: // not sure actually. the q cmd '{:}[]' returns a 102h
            return &PL_sv_undef;
            break;

        default:
            croak("unrecognized vector type '%d'\n", k->t);
            break;
    }

    return result;
}

/*
 * K structs of type XD are either a partitioned table or a dictionary.
 * Dispath accordingly.
 */
SV* xd_from_k(K k) {
    if (kK(k)[0]->t == XT && kK(k)[1]->t == XT) {
        return ptable_from_k(k);
    }
    else {
        return dict_from_k(k);
    }
}

/* copy the contents of hv into store_hv */
void hv_store_hv(HV *store_hv, HV *hv) {
    int i;
    int h_size = hv_iterinit(hv);
    HE *store_ret, *he;
    SV *key, *val;

    for (i = 0; i < h_size; i++) {

        he  = hv_iternext(hv);
        key = hv_iterkeysv(he);
        val = hv_iterval(hv, he);

        store_ret = hv_store_ent(store_hv, key, val, 0);
        if (store_ret == NULL) {
            croak("Failed to store hash entry");
        }

        SvREFCNT_inc(val);
    }
}

SV* ptable_from_k(K k) {
    HV *hv = newHV();

    K t0   = kK(k)[0]; // partitioned tables have 2 sub-tables
    K t1   = kK(k)[1];

    SV *t0_rv = table_from_k(t0);
    SV *t1_rv = table_from_k(t1);

    HV *t0_hv = (HV*) SvRV( t0_rv );
    HV *t1_hv = (HV*) SvRV( t1_rv );

    hv_store_hv(hv, t0_hv);
    hv_store_hv(hv, t1_hv);

    SvREFCNT_dec(t0_rv);
    SvREFCNT_dec(t1_rv);

    return newRV_noinc( (SV*)hv );
}

SV* dict_from_k(K k) {
    int i;
    SV **key;
    SV **val;
    HV *hv = newHV();
    HE *store_ret;

    SV* keys_ref = sv_from_k( kK(k)[0] );
    SV* vals_ref = sv_from_k( kK(k)[1] );

    AV* keys = (AV*) SvRV( keys_ref );
    AV* vals = (AV*) SvRV( vals_ref );

    int key_count = av_len(keys) + 1;

    /*  k dicts can have the same key multiple times.  When such dicts are
     *  referenced using a key, the value for the first occurance of the key
     *  is the one returned.  Perl has the opposite.  Here we go through the
     *  keys backward to ensure the value for any duplicate keys ends up being
     *  the value associated with the first occurance of the key as it would
     *  in k/q.
     */
    for (i = key_count -1; i >= 0; i--) {
        key = av_fetch(keys, i, 0);
        val = av_fetch(vals, i, 0);

        if (val == NULL) {
            store_ret = hv_store_ent(hv, *key, &PL_sv_undef, 0);
        }
        else {
            store_ret = hv_store_ent(hv, *key, *val, 0);
            SvREFCNT_inc(*val);
        }

        if (store_ret == NULL) {
            croak("Failed to convert k hash entry to perl hash entry");
        }
    }

    SvREFCNT_dec(keys_ref);
    SvREFCNT_dec(vals_ref);

    return newRV_noinc( (SV*)hv );
}

SV* table_from_k(K k) {
    K dict = k->k;
    return dict_from_k(dict);
}

SV* mixed_list_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        av_push(av, sv_from_k( kK(k)[i] ) );
    }

    return newRV_noinc((SV* )av);
}

/*
 * scalar helpers
 */

SV* bool_from_k(K k) {
    if (k->g == 0) {
        return &PL_sv_undef;
    }

    return newSViv( k->g );
}

SV* byte_from_k(K k) {
    return newSVuv( k->g );
}

SV* char_from_k(K k) {
    char byte_str[1];
    byte_str[0] = k->g;
    return newSVpvn(byte_str, 1);
}

SV* short_from_k(K k) {
    if (k->h == nh) {
        return &PL_sv_undef;
    }

    if (k->h == wh) {
        return newSVpvn("inf", 3);
    }

    if (k->h == -wh) {
        return newSVpvn("-inf", 4);
    }

    return newSViv(k->h);
}

SV* int_from_k(K k) {
    if (k->i == ni) {
        return &PL_sv_undef;
    }

    if (k->i == wi) {
        return newSVpvn("inf", 3);
    }

    if (k->i == -wi) {
        return newSVpvn("-inf", 4);
    }

    return newSViv(k->i);
}

SV* timestamp_from_k(K k) {
    if (k->j == nj) {
        return &PL_sv_undef;
    }

    if (k->j == wj) {
        return newSVpvn("inf", 3);
    }

    if (k->j == -wj) {
        return newSVpvn("-inf", 4);
    }

    return newSVi64(k->j);
}

SV* long_from_k(K k) {
    if (k->j == nj) {
        return &PL_sv_undef;
    }

    if (k->j == wj) {
        return newSVpvn("inf", 3);
    }

    if (k->j == -wj) {
        return newSVpvn("-inf", 4);
    }

    return newSVi64(k->j);
}

SV* real_from_k(K k) {
    if (isnan(k->e)) {
        return &PL_sv_undef;
    }

    return newSVnv(k->e);
}

SV* float_from_k(K k) {
    if (isnan(k->f)) {
        return &PL_sv_undef;
    }

    return newSVnv(k->f);
}

SV* symbol_from_k(K k) {
    if (strncmp(k->s, "", k->n) == 0) {
        return &PL_sv_undef;
    }

    return newSVpv(k->s, 0);
}

/*
 * vector helpers
 */

SV* bool_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kG(k)[i] == 0) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        av_push(av, newSViv( kG(k)[i]) );
    }

    return newRV_noinc( (SV*)av );
}

SV* byte_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        av_push(av, newSVuv( kG(k)[i] ));
    }

    return newRV_noinc( (SV*)av );
}

SV* char_vector_from_k(K k) {
    AV *av = newAV();
    char byte_str[1];
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kG(k)[i] == 0) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        byte_str[0] = kG(k)[i];
        av_push(av, newSVpvn(byte_str, 1));
    }

    return newRV_noinc( (SV*)av );
}

SV* short_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kH(k)[i] == nh) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        if (kH(k)[i] == wh) {
            av_push(av, newSVpvn("inf", 3));
            continue;
        }

        if (kH(k)[i] == -wh) {
            av_push(av, newSVpvn("-inf", 4));
            continue;
        }

        av_push(av, newSViv( kH(k)[i]) );
    }

    return newRV_noinc( (SV*)av );
}

SV* int_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kI(k)[i] == ni) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        if (kI(k)[i] == wi) {
            av_push(av, newSVpvn("inf", 3));
            continue;
        }

        if (kI(k)[i] == -wi) {
            av_push(av, newSVpvn("-inf", 4));
            continue;
        }

        av_push(av, newSViv( kI(k)[i]) );
    }

    return newRV_noinc( (SV*)av );
}

SV* long_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kJ(k)[i] == nj) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        if (kJ(k)[i] == wj) {
            av_push(av, newSVpvn("inf", 3));
            continue;
        }

        if (kJ(k)[i] == -wj) {
            av_push(av, newSVpvn("-inf", 4));
            continue;
        }

        av_push(av, newSVi64(kJ(k)[i]) );
    }

    return newRV_noinc( (SV*)av );
}

SV* timestamp_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (kJ(k)[i] == nj) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        if (kJ(k)[i] == wj) {
            av_push(av, newSVpvn("inf", 3));
            continue;
        }

        if (kJ(k)[i] == -wj) {
            av_push(av, newSVpvn("-inf", 4));
            continue;
        }

        av_push(av, newSVi64(kJ(k)[i]) );
    }

    return newRV_noinc( (SV*)av );
}

SV* real_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (isnan( kE(k)[i] )) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        av_push(av, newSVnv( kE(k)[i] ) );
    }

    return newRV_noinc( (SV*)av );
}

SV* float_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;

    for (i = 0; i < k->n; i++) {
        if (isnan( kF(k)[i] )) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        av_push(av, newSVnv( kF(k)[i] ) );
    }

    return newRV_noinc( (SV*)av );
}

SV* symbol_vector_from_k(K k) {
    AV *av = newAV();
    int i = 0;
    char *sym = NULL;

    for (i = 0; i < k->n; i++) {
        sym = kS(k)[i];

        if (strncmp(sym, "", strlen(sym)) == 0) {
            av_push(av, &PL_sv_undef);
            continue;
        }

        av_push(av, newSVpv( kS(k)[i], 0 ) );
    }

    return newRV_noinc( (SV*)av );
}
