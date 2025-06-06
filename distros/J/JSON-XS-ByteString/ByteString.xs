#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef UNLIKELY
#  define UNLIKELY(x) (x)
#endif
#ifndef LIKELY
#  define LIKELY(x) (x)
#endif

#ifndef SvREFCNT_dec_NN
#  define SvREFCNT_dec_NN SvREFCNT_dec
#endif

#define CONCAT_PASTE(prefix, suffix) prefix ## suffix
#define CONCAT(prefix, suffix) CONCAT_PASTE(prefix, suffix)

static SV** visited;
int visited_capacity;
int visited_p;

static inline void reserve_visited_capacity(){
    if( visited_p >= visited_capacity ){
        visited_capacity += visited_capacity / 4;
        Renew(visited, visited_capacity, SV*);
    }
}

static inline STRLEN estimate_str(unsigned char * str, STRLEN len){
    unsigned char * str_begin = str;
    STRLEN out_len = len+2;
    for(unsigned char * str_end=str+len; str!=str_end; ++str){
        if( *str < 0x20 ){
            switch( *str ){
                case '\n': case '\t': case '\r': case '\b': case '\f':
                    ++out_len;
                    break;
                default:
                    out_len += 5;
            }
        }
        else switch( *str ){
            case '\\': case '"':
                ++out_len;
                break;
            case '/':
                if( str!=str_begin && *(str-1)=='<' )
                    ++out_len;
            default:
                ;
        }
    }
    return out_len;
}

static inline char hex(unsigned char ch){
    if( ch>9 )
        return 'A' + ch - 10;
    else
        return '0' + ch;
}
static inline unsigned int decode_hex(unsigned char ch){
    if( ch<='9' )
        return ch - '0';
    if( ch<='Z' )
        return ch - 'A' + 10;
    return ch - 'a' + 10;
}

static inline unsigned char * encode_str(unsigned char * buffer, unsigned char * str, STRLEN len){
    unsigned char * str_begin = str;
    *buffer++ = '"';
    for(unsigned char * str_end=str+len; str!=str_end; ++str){
        if( *str < 0x20 ){
            *buffer++ = '\\';
            switch( *str ){
                case '\n':
                    *buffer++ = 'n';
                    break;
                case '\t':
                    *buffer++ = 't';
                    break;
                case '\r':
                    *buffer++ = 'r';
                    break;
                case '\b':
                    *buffer++ = 'b';
                    break;
                case '\f':
                    *buffer++ = 'f';
                    break;
                default:
                    *buffer++ = 'u';
                    *buffer++ = '0';
                    *buffer++ = '0';
                    *buffer++ = hex(*str >> 4);
                    *buffer++ = hex(*str & 15);
            }
        }
        else{
            switch( *str ){
                case '\\': case '"':
                    *buffer++ = '\\';
                    break;

                case '/':
                    if( str!=str_begin && *(str-1)=='<' )
                        *buffer++ = '\\';

                default:
                    ;
            }
            *buffer++ = *str;
        }
    }
    *buffer++ = '"';
    return buffer;
}

#define NAME normal
#define UNBLESSED FALSE
#include "encode_gen.h"
#undef UNBLESSED
#undef NAME

#define NAME unblessed
#define UNBLESSED TRUE
#include "encode_gen.h"
#undef UNBLESSED
#undef NAME

static inline unsigned char * skip_bom(unsigned char * str, unsigned char * str_end){
    if( str_end - str >= 3 && str[0]==(unsigned char)'\xEF' && str[1]==(unsigned char)'\xBB' && str[2]==(unsigned char)'\xBF' )
        return str+3;
    return str;
}

static inline unsigned char * skip_space(unsigned char * str, unsigned char * str_end){
    while( str!=str_end && isSPACE(*str) )
        ++str;
    return str;
}

static inline bool is_identity(unsigned char ch){
    return !isSPACE(ch) && ch!=',' && ch!=':' && ch!=']' && ch!='}';
}

static inline bool is_key(unsigned char ch){
    return !isSPACE(ch) && ch!=':';
}

static inline STRLEN is_number(unsigned char * str, unsigned char * str_end){
    if( str==str_end )
        return 0;

    STRLEN len = 0;
    bool has_digit = FALSE;
    if( *str=='+' || *str=='-' ){
        str = skip_space(str+1, str_end);
        ++len;
    }

    if( str!=str_end && isDIGIT(*str) )
        has_digit = TRUE;
    while( str!=str_end && isDIGIT(*str) ){
        ++len;
        ++str;
    }
    if( str!=str_end && *str=='.' ){
        ++len;
        ++str;
    }
    if( str!=str_end && isDIGIT(*str) )
        has_digit = TRUE;
    while( str!=str_end && isDIGIT(*str) ){
        ++len;
        ++str;
    }
    if( !has_digit )
        return 0;

    if( str!=str_end && (*str=='e' || *str=='E') ){
        ++len;
        ++str;
        if( str!=str_end && (*str=='+' || *str=='-') ){
            ++len;
            ++str;
        }
        while( str!=str_end && isDIGIT(*str) ){
            ++len;
            ++str;
        }
    }
    return len;
}

static inline unsigned char * decode_number_r(unsigned char * str, unsigned char * str_end, unsigned char ** out, unsigned char ** out_capacity_end, unsigned char ** out_end){
    STRLEN len = is_number(str, str_end);
    if( len<=0 ){
        *out_end = NULL;
        return str;
    }

    if( !*out ){
        Newx(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }
    else if( *out_capacity_end - *out < len + 1 ){
        Renew(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }

    *out_end = *out + len;
    **out_end = 0;
    unsigned char * out_cur = *out;

    if( *str=='+' || *str=='-' ){
        *out_cur++ = *str;
        --len;
        str = skip_space(str+1, str_end);
    }
    while( len-- )
        *out_cur++ = *str++;
    return str;
}

static inline STRLEN estimate_orig_key(unsigned char * str, unsigned char * str_end){
    if( str==str_end )
        return 0;
    if( *str=='"' || *str=='\'' ){
        char delimiter = *str;
        ++str;
        STRLEN len = 0;
        while(TRUE){
            if( str==str_end )
                return -1;
            if( *str==delimiter )
                return len;
            if( *str=='\\' ){
                ++str;
                switch( *str++ ){
                    case 'u': {
                        unsigned int d = 0;

                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);

                        if( d <= 0x7f )
                            ++len;
                        else if( d <= 0x7ff )
                            len += 2;
                        else if( d <= 0xffff )
                            len += 3;
                        else
                            len += 4;

                        break;
                    }
                    case 'n': case '\\': case 't': case 'r': case '/': case 'b': case 'f':
                        ++len;
                        break;
                    default:
                        if( *(str-1)==delimiter )
                            ++len;
                        else
                            len += 2;
                }
            }
            else{
                ++len;
                ++str;
            }
        }
    }
    else{
        STRLEN len = 0;
        while( str!=str_end && is_key(*str) ){
            ++len;
            ++str;
        }
        return len;
    }
}

static inline STRLEN estimate_orig_str(unsigned char * str, unsigned char * str_end){
    if( str==str_end )
        return -1;
    if( *str=='"' || *str=='\'' ){
        char delimiter = *str;
        ++str;
        STRLEN len = 0;
        while(TRUE){
            if( str==str_end )
                return -1;
            if( *str==delimiter )
                return len;
            if( *str=='\\' ){
                ++str;
                switch( *str++ ){
                    case 'u': {
                        unsigned int d = 0;

                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);

                        if( d <= 0x7f )
                            ++len;
                        else if( d <= 0x7ff )
                            len += 2;
                        else if( d <= 0xffff )
                            len += 3;
                        else
                            len += 4;

                        break;
                    }
                    case 'n': case '\\': case 't': case 'r': case '/': case 'b': case 'f':
                        ++len;
                        break;
                    default:
                        if( *(str-1)==delimiter )
                            ++len;
                        else
                            len += 2;
                }
            }
            else{
                ++len;
                ++str;
            }
        }
    }
    else
        return -1;
}

static inline unsigned char * decode_key_r(unsigned char * str, unsigned char * str_end, unsigned char ** out, unsigned char ** out_capacity_end, unsigned char ** out_end){
    STRLEN len = estimate_orig_key(str, str_end);
    if( len==-1 ){
        *out_end = NULL;
        return str;
    }

    if( !*out ){
        Newx(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }
    else if( *out_capacity_end - *out < len + 1 ){
        Renew(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }

    *out_end = *out + len;
    **out_end = 0;
    unsigned char * out_cur = *out;

    if( *str=='"' || *str=='\'' ){
        char delimiter = *str;
        ++str;
        while(TRUE){
            if( *str==delimiter )
                return str+1;
            if( *str=='\\' ){
                ++str;
                switch( *str++ ){
                    case 'u': {
                        unsigned int d = 0;

                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);
                        if( str!=str_end && isXDIGIT(*str) )
                            d = (d << 4) + decode_hex(*str++);

                        if( d <= 0x7f )
                            *out_cur++ = (unsigned char) d;
                        else if( d <= 0x7ff ){
                            *out_cur++ = (unsigned char)( d >> 6          | 0xC0);
                            *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                        }
                        else if( d <= 0xffff ){
                            *out_cur++ = (unsigned char)( d >> 12         | 0xE0);
                            *out_cur++ = (unsigned char)((d >> 6  & 0x3F) | 0x80);
                            *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                        }
                        else{
                            *out_cur++ = (unsigned char)( d >> 18         | 0xF0);
                            *out_cur++ = (unsigned char)((d >> 12 & 0x3F) | 0x80);
                            *out_cur++ = (unsigned char)((d >>  6 & 0x3F) | 0x80);
                            *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                        }

                        break;
                    }
                    case 'n':
                        *out_cur++ = '\n';
                        break;
                    case '\\':
                        *out_cur++ = '\\';
                        break;
                    case 't':
                        *out_cur++ = '\t';
                        break;
                    case 'r':
                        *out_cur++ = '\r';
                        break;
                    case '/':
                        *out_cur++ = '/';
                        break;
                    case 'b':
                        *out_cur++ = '\b';
                        break;
                    case 'f':
                        *out_cur++ = '\f';
                        break;
                    default:
                        if( *(str-1)!=delimiter )
                            *out_cur++ = '\\';
                        *out_cur++ = *(str-1);
                }
            }
            else
                *out_cur++ = *str++;
        }
    }
    else{
        while( str!=str_end && is_key(*str) )
            *out_cur++ = *str++;
        return str;
    }
}

static inline unsigned char * decode_str_r(unsigned char * str, unsigned char * str_end, unsigned char ** out, unsigned char ** out_capacity_end, unsigned char ** out_end){
    STRLEN len = estimate_orig_str(str, str_end);
    if( len==-1 ){
        *out_end = NULL;
        return str;
    }

    if( !*out ){
        Newx(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }
    else if( *out_capacity_end - *out < len + 1 ){
        Renew(*out, len+1, unsigned char);
        *out_capacity_end = *out + len + 1;
    }

    *out_end = *out + len;
    **out_end = 0;
    unsigned char * out_cur = *out;

    char delimiter = *str;
    ++str;
    while(TRUE){
        if( *str==delimiter )
            return str+1;
        if( *str=='\\' ){
            ++str;
            switch( *str++ ){
                case 'u': {
                    unsigned int d = 0;

                    if( str!=str_end && isXDIGIT(*str) )
                        d = (d << 4) + decode_hex(*str++);
                    if( str!=str_end && isXDIGIT(*str) )
                        d = (d << 4) + decode_hex(*str++);
                    if( str!=str_end && isXDIGIT(*str) )
                        d = (d << 4) + decode_hex(*str++);
                    if( str!=str_end && isXDIGIT(*str) )
                        d = (d << 4) + decode_hex(*str++);

                    if( d <= 0x7f )
                        *out_cur++ = (unsigned char) d;
                    else if( d <= 0x7ff ){
                        *out_cur++ = (unsigned char)( d >> 6          | 0xC0);
                        *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                    }
                    else if( d <= 0xffff ){
                        *out_cur++ = (unsigned char)( d >> 12         | 0xE0);
                        *out_cur++ = (unsigned char)((d >> 6  & 0x3F) | 0x80);
                        *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                    }
                    else{
                        *out_cur++ = (unsigned char)( d >> 18         | 0xF0);
                        *out_cur++ = (unsigned char)((d >> 12 & 0x3F) | 0x80);
                        *out_cur++ = (unsigned char)((d >>  6 & 0x3F) | 0x80);
                        *out_cur++ = (unsigned char)((d       & 0x3F) | 0x80);
                    }

                    break;
                }
                case 'n':
                    *out_cur++ = '\n';
                    break;
                case '\\':
                    *out_cur++ = '\\';
                    break;
                case 't':
                    *out_cur++ = '\t';
                    break;
                case 'r':
                    *out_cur++ = '\r';
                    break;
                case '/':
                    *out_cur++ = '/';
                    break;
                case 'b':
                    *out_cur++ = '\b';
                    break;
                case 'f':
                    *out_cur++ = '\f';
                    break;
                default:
                    if( *(str-1)!=delimiter )
                        *out_cur++ = '\\';
                    *out_cur++ = *(str-1);
            }
        }
        else
            *out_cur++ = *str++;
    }
}

// the created SV has refcnt=1
unsigned char * decode(unsigned char * str, unsigned char * str_end, SV**out){
    str = skip_space(str, str_end);
    if( str==str_end )
        goto GIVEUP;

    switch( *str ){
        case '[': {
            AV * av = newAV();
            *out = newRV_noinc((SV*) av);
            str = skip_space(str+1, str_end);

            while(TRUE){
                if( str==str_end )
                    goto ROLLBACK;
                if( *str == ']' )
                    return str+1;

                SV * elem;
                str = decode(str, str_end, &elem);
                if( elem==NULL )
                    goto ROLLBACK;
                av_push(av, elem);

                str = skip_space(str, str_end);
                if( str==str_end )
                    goto ROLLBACK;
                if( *str == ']' )
                    return str+1;
                if( *str==',' )
                    str = skip_space(str+1, str_end);
                else
                    goto ROLLBACK;
            }
        }
        case '{': {
            HV * hv = newHV();
            *out = newRV_noinc((SV*) hv);
            str = skip_space(str+1, str_end);
            unsigned char *key_buffer=0, *key_buffer_end, *key_end;
            while(TRUE){
                if( str==str_end ){
                    if( key_buffer )
                        Safefree(key_buffer);
                    goto ROLLBACK;
                }
                if( *str=='}' ){
                    if( key_buffer )
                        Safefree(key_buffer);
                    return str+1;
                }
                str = decode_key_r(str, str_end, &key_buffer, &key_buffer_end, &key_end);
                if( !key_end ){
                    if( key_buffer )
                        Safefree(key_buffer);
                    goto ROLLBACK;
                }
                str = skip_space(str, str_end);

                SV * elem = NULL;
                if( *str==':' )
                    str = decode(str+1, str_end, &elem);
                if( elem==NULL ){
                    Safefree(key_buffer);
                    goto ROLLBACK;
                }
                hv_store(hv, (char*)key_buffer, key_end-key_buffer, elem, 0);

                str = skip_space(str, str_end);
                if( str==str_end ){
                    Safefree(key_buffer);
                    goto ROLLBACK;
                }
                if( *str=='}' ){
                    Safefree(key_buffer);
                    return str+1;
                }
                if( *str==',' )
                    str = skip_space(str+1, str_end);
                else{
                    Safefree(key_buffer);
                    goto ROLLBACK;
                }
            }
            break;
        }
        case '"': case '\'': {
            unsigned char *value_buffer=0, *value_buffer_end, *value_end;
            str = decode_str_r(str, str_end, &value_buffer, &value_buffer_end, &value_end);
            if( !value_end )
                goto GIVEUP;
            *out = newSV(0);
            sv_upgrade(*out, SVt_PV);
            SvPOK_on(*out);
            SvPV_set(*out, (char*)value_buffer);
            SvCUR_set(*out, value_end - value_buffer);
            SvLEN_set(*out, value_buffer_end - value_buffer);
            return str;
        }
        default: {
            if( str_end-str==4 || (str_end-str>4 && !is_identity(str[4])) ){
                if( (str[0]=='T' || str[0]=='t') && (str[1]=='R' || str[1]=='r') && (str[2]=='U' || str[2]=='u') && (str[3]=='E' || str[3]=='e') ){
                    *out = newSViv(1);
                    return str+4;
                }
                if( (str[0]=='N' || str[0]=='n') && (str[1]=='U' || str[1]=='u') && (str[2]=='L' || str[2]=='l') && (str[3]=='L' || str[3]=='l') ){
                    *out = newSV(0);
                    return str+4;
                }
            }
            if( str_end-str==5 || (str_end-str>5 && !is_identity(str[5])) ){
                if( (str[0]=='F' || str[0]=='f') && (str[1]=='A' || str[1]=='a') && (str[2]=='L' || str[2]=='l') && (str[3]=='S' || str[3]=='s') && (str[4]=='E' || str[4]=='e') ){
                    *out = newSVpvn("", 0);
                    return str+5;
                }
            }

            unsigned char *value_buffer=0, *value_buffer_end, *value_end;
            str = decode_number_r(str, str_end, &value_buffer, &value_buffer_end, &value_end);
            if( value_end ){
                *out = newSV(0);
                sv_upgrade(*out, SVt_PV);
                SvPOK_on(*out);
                SvPV_set(*out, (char*)value_buffer);
                SvCUR_set(*out, value_end - value_buffer);
                SvLEN_set(*out, value_buffer_end - value_buffer);
                return str;
            }

            goto GIVEUP;
        }
    }

ROLLBACK:
    SvREFCNT_dec_NN(*out);
GIVEUP:
    *out = NULL;
    return str;
}

MODULE = JSON::XS::ByteString		PACKAGE = JSON::XS::ByteString		

void
encode_json(SV * data)
    PPCODE:
        visited_p = 0;
        STRLEN need_size = estimate_normal(data);
        SV * out_sv = sv_2mortal(newSV(need_size));
        SvPOK_only(out_sv);
        visited_p = 0;
        char * cur = (char*)encode_normal((unsigned char*)SvPVX(out_sv), data);
        SvCUR_set(out_sv, cur - SvPVX(out_sv));
        *SvEND(out_sv) = 0;
        PUSHs(out_sv);

void
encode_json_unblessed(SV * data)
    PPCODE:
        visited_p = 0;
        STRLEN need_size = estimate_unblessed(data);
        SV * out_sv = sv_2mortal(newSV(need_size));
        SvPOK_only(out_sv);
        visited_p = 0;
        char * cur = (char*)encode_unblessed((unsigned char*)SvPVX(out_sv), data);
        SvCUR_set(out_sv, cur - SvPVX(out_sv));
        *SvEND(out_sv) = 0;
        PUSHs(out_sv);

void
decode_json(SV * json)
    PPCODE:
        unsigned char *str, *str_end, *str_adv;
        STRLEN len;
        SV * out = NULL;
        str = (unsigned char*) SvPV(json, len);
        str_end = str + len;
        str_adv = skip_space(decode(skip_bom(str, str_end), str_end, &out), str_end);
        if( str_end != str_adv ){
            warn("decode_json: Unconsumed characters from offset %d", (int)(str_adv-str));
            SvREFCNT_dec(out);
            PUSHs(&PL_sv_undef);
        }
        else if( out==NULL )
            PUSHs(&PL_sv_undef);
        else
            PUSHs(sv_2mortal(out));

void
decode_json_safe(SV * json)
    PPCODE:
        unsigned char *str, *str_end, *str_adv;
        STRLEN len;
        SV * out = NULL;
        str = (unsigned char*) SvPV(json, len);
        str_end = str + len;
        str_adv = skip_space(decode(skip_bom(str, str_end), str_end, &out), str_end);
        if( str_end != str_adv ){
            SvREFCNT_dec(out);
            PUSHs(&PL_sv_undef);
        }
        else if( out==NULL )
            PUSHs(&PL_sv_undef);
        else
            PUSHs(sv_2mortal(out));

BOOT:
    visited_capacity = 32;
    Newx(visited, visited_capacity, SV*);
