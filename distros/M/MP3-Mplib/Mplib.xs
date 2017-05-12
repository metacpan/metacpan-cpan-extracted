#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/time.h>
#include <time.h>

#include "./mplib/mplib.h"

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant__(char *name, int len, int arg)
{
    if (1 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 1]) {
    case 'B':
	if (strEQ(name + 1, "_BEGIN_DECLS")) {	/* _ removed */
#ifdef __BEGIN_DECLS
	    return __BEGIN_DECLS;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 1, "_END_DECLS")) {	/* _ removed */
#ifdef __END_DECLS
	    return __END_DECLS;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_UTF1(char *name, int len, int arg)
{
    if (3 + 1 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[4 + 1]) {
    case '\0':
	if (strEQ(name + 4, "6")) {	/* UTF1 removed */
#ifdef UTF16
	    return UTF16;
#else
	    goto not_there;
#endif
	}
    case 'B':
	if (strEQ(name + 4, "6BE")) {	/* UTF1 removed */
#ifdef UTF16BE
	    return UTF16BE;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_U(char *name, int len, int arg)
{
    if (1 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 2]) {
    case '1':
	if (!strnEQ(name + 1,"TF", 2))
	    break;
	return constant_UTF1(name, len, arg);
    case '8':
	if (strEQ(name + 1, "TF8")) {	/* U removed */
#ifdef UTF8
	    return UTF8;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MP_A(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'L':
	if (strEQ(name + 4, "LBUM")) {	/* MP_A removed */
#ifdef MP_ALBUM
	    return MP_ALBUM;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 4, "RTIST")) {	/* MP_A removed */
#ifdef MP_ARTIST
	    return MP_ARTIST;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MP_T(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'I':
	if (strEQ(name + 4, "ITLE")) {	/* MP_T removed */
#ifdef MP_TITLE
	    return MP_TITLE;
#else
	    goto not_there;
#endif
	}
    case 'R':
	if (strEQ(name + 4, "RACK")) {	/* MP_T removed */
#ifdef MP_TRACK
	    return MP_TRACK;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MP_EF(char *name, int len, int arg)
{
    switch (name[5 + 0]) {
    case 'C':
	if (strEQ(name + 5, "COMPR")) {	/* MP_EF removed */
#ifdef MP_EFCOMPR
	    return MP_EFCOMPR;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (strEQ(name + 5, "ENCR")) {	/* MP_EF removed */
#ifdef MP_EFENCR
	    return MP_EFENCR;
#else
	    goto not_there;
#endif
	}
    case 'N':
	if (strEQ(name + 5, "NF")) {	/* MP_EF removed */
#ifdef MP_EFNF
	    return MP_EFNF;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_MP_E(char *name, int len, int arg)
{
    switch (name[4 + 0]) {
    case 'E':
	if (strEQ(name + 4, "ERROR")) {	/* MP_E removed */
#ifdef MP_EERROR
	    return MP_EERROR;
#else
	    goto not_there;
#endif
	}
    case 'F':
	return constant_MP_EF(name, len, arg);
    case 'V':
	if (strEQ(name + 4, "VERSION")) {	/* MP_E removed */
#ifdef MP_EVERSION
	    return MP_EVERSION;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant_M(char *name, int len, int arg)
{
    if (1 + 2 >= len ) {
	errno = EINVAL;
	return 0;
    }
    switch (name[1 + 2]) {
    case 'A':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_MP_A(name, len, arg);
    case 'C':
	if (strEQ(name + 1, "P_COMMENT")) {	/* M removed */
#ifdef MP_COMMENT
	    return MP_COMMENT;
#else
	    goto not_there;
#endif
	}
    case 'E':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_MP_E(name, len, arg);
    case 'G':
	if (strEQ(name + 1, "P_GENRE")) {	/* M removed */
#ifdef MP_GENRE
	    return MP_GENRE;
#else
	    goto not_there;
#endif
	}
    case 'T':
	if (!strnEQ(name + 1,"P_", 2))
	    break;
	return constant_MP_T(name, len, arg);
    case 'Y':
	if (strEQ(name + 1, "P_YEAR")) {	/* M removed */
#ifdef MP_YEAR
	    return MP_YEAR;
#else
	    goto not_there;
#endif
	}
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

static double
constant(char *name, int len, int arg)
{
    errno = 0;
    switch (name[0 + 0]) {
    case 'I':
	if (strEQ(name + 0, "ISO_8859_1")) {	/*  removed */
#ifdef ISO_8859_1
	    return ISO_8859_1;
#else
	    goto not_there;
#endif
	}
    case 'M':
	return constant_M(name, len, arg);
    case 'U':
	return constant_U(name, len, arg);
    case '_':
	return constant__(name, len, arg);
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

/* maintain backwards compatibility to at least 5.00503 */

#ifndef SvPV_nolen
#   define SvPV_nolen(sv) SvPV(sv, PL_na)
#endif

#ifndef newSVuv
#   define newSVuv(i) newSViv(i)
#endif

#ifdef FIX_ANTIQUE_PERL
#   define hv_store_fx(hv,str,strlen,sv,lval) \
        hv_store(hv,(char*)str,strlen,(SV*)sv,lval)
#   define get_sv(name,create) \
        perl_get_sv(name,create)
#else
#   define hv_store_fx(hv,str,strlen,sv,lval) \
        hv_store(hv,str,strlen,sv,lval)
#endif

#define isHaSHref(sv) (SvROK(sv)) && (SvTYPE(SvRV(sv)) == SVt_PVHV)

/* the id3v2-tag fields we check for. 
 * I don't have the slightest idea what all these are four.
 * So check the standard. :-) */

#define V2FRAMES 74
const char * fields[V2FRAMES] = {
    "COMM", "WXXX", "AENC", "APIC", "COMR", "ENCR", "EQUA", "ETCO", "GEOB", 
    "GRID", "IPLS", "LINK", "MCDI", "MLLT", "OWNE", "PRIV", "PCNT", "POPM", 
    "POSS", "RBUF", "RVAD", "RVRB", "SYLT", "SYTC", "TALB", "TBPM", "TCOM", 
    "TCON", "TCOP", "TDAT", "TDLY", "TENC", "TEXT", "TFLT", "TIME", "TIT1", 
    "TIT2", "TIT3", "TKEY", "TLAN", "TLEN", "TMED", "TOAL", "TOFN", "TOLY", 
    "TOPE", "TORY", "TOWN", "TPE1", "TPE2", "TPE3", "TPE4", "TPOS", "TPUB", 
    "TRCK", "TRDA", "TRSN", "TRSO", "TSIZ", "TSRC", "TSSE", "TYER", "TXXX", 
    "UFID", "USER", "USLT", "WCOM", "WCOP", "WOAF", "WOAR", "WOAS", "WORS", 
    "WPAY", "WPUB",  };

const char * fieldsv1[MP_TRACK] = {
    "ARTIST", "TITLE", "ALBUM", "GENRE", "COMMENT", "YEAR", "TRACK",
};

/* MP3::Mplib::Error */
SV * mp3_lib_err;

/* turn mpeg_header into hash-ref */
SV * map_mpeg_header_to_sv(mpeg_header * header) {
    HV * hash = newHV();

    /* so sucky: perhaps we should have used a typemap, eh? */
    hv_store(hash, "syncword", 8, newSVuv(header->syncword), 0);
    hv_store(hash, "version", 7, newSVpv(mp_get_str_version(header), 0), 0);
    hv_store(hash, "layer", 5, newSVpv(mp_get_str_layer(header), 0), 0);
    hv_store(hash, "protbit", 7, newSVuv(header->protbit), 0);
    hv_store(hash, "bitrate", 7, newSVpv(mp_get_str_bitrate(header), 0), 0);
    hv_store(hash, "samplingfreq", 12, 
             newSVpv(mp_get_str_samplingfreq(header), 0), 0);
    hv_store(hash, "padbit", 6, newSVuv(header->padbit), 0);
    hv_store(hash, "privbit", 7, newSVuv(header->privbit), 0);
    hv_store(hash, "mode", 4, newSVpv(mp_get_str_mode(header), 0), 0);
    hv_store(hash, "mode_ext", 8, newSVuv(header->mode_ext), 0);
    hv_store(hash, "copyright", 9, newSVuv(header->copyright), 0);
    hv_store(hash, "originalhome", 12, newSVuv(header->originalhome), 0);
    hv_store(hash, "emphasis", 8, newSVuv(header->emphasis), 0);

    return newRV_noinc((SV *)hash);
}

/* turn id3v2 header into hash-ref */
SV * map_id3v2_header_to_sv (id3v2_header * header) {
    HV * hash = newHV();

    id3v2_extended_header * extheader;
    
    hv_store(hash, "ver_minor", 9, newSVuv(header->version_minor), 0);
    hv_store(hash, "ver_revision", 12, newSVuv(header->version_revision), 0);
    hv_store(hash, "unsync", 6, newSVuv(header->unsyncronization), 0);
    hv_store(hash, "experimental", 12, newSVuv(header->is_experimental), 0);
    hv_store(hash, "footer", 6, newSVuv(header->has_footer), 0);
    hv_store(hash, "total_tag_size", 14, newSVuv(header->total_tag_size), 0);
    
    /* make extended header */
    extheader = header->extended_header;
    if (extheader != NULL) {
        HV * ext = newHV();
        
        hv_store(ext, "size", 4, newSVuv(extheader->size), 0);
        hv_store(ext, "flag_bytes", 10, newSVpv(extheader->flag_bytes, 0), 0);
        hv_store(ext, "no_flag_bytes", 13, 
                      newSVuv(extheader->no_flag_bytes), 0);
        hv_store(ext, "is_update", 9, newSVuv(extheader->is_update), 0); 
        hv_store(ext, "crc_data_present", 9, 
                      newSVuv(extheader->crc_data_present), 0);
        hv_store(ext, "crc_data_length", 15, 
                      newSVuv(extheader->crc_data_length), 0);
        hv_store(ext, "crc_data", 8, newSVpv(extheader->crc_data, 0), 0);
        hv_store(ext, "restrictions", 12,
                      newSVuv(extheader->restrictions), 0);
        hv_store(ext, "restrictions_data_length", 24,
                      newSVuv(extheader->restrictions_data_length), 0);
        hv_store(ext, "restrictions_data", 17, 
                      newSVpv(extheader->restrictions_data, 0), 0);
        
        /* nest ext as hash-ref in previous hash */
        hv_store(hash, "extended_header", 15, newRV_noinc((SV *) ext), 0);
    }
    return newRV_noinc((SV *)hash);
}

/* turn id3_tag into hash-ref */
SV * map_id3_tag_to_sv(id3_tag * tag) {
    HV * hash = newHV();

    if (tag->version == 1)
        fill_sv_v1tag(hash, tag);
    if (tag->version == 2)
        fill_sv_v2tag(hash, tag);
    if (tag->version == -1)
        return NULL;
    
    return newRV_noinc((SV *)hash);
}

/* returns to the tag of the specified version from the tag list
 * returns NULL if no such tag has been found */
id3_tag * get_tag (id3_tag_list * tag_list, int ver) {

    id3_tag * tag = NULL;

    if(tag_list == NULL) 
        return NULL;

    while (1) {
        if (tag_list->tag->version == ver) 
            return tag_list->tag;
        if (tag_list->next == NULL)
            return NULL;
        tag_list = tag_list->next;
    }
}

/* add a new tag to the taglist: this happens when a tag is set that is not
 * yet there */
id3_tag_list * add_tag (id3_tag_list * tag_list, id3_tag * tag) {
  
    id3_tag_list *new = malloc(sizeof(id3_tag_list));
    new->tag = tag;
    new->first = NULL;
    new->next = NULL;
    
    /* no tag_list: return our newly created one */
    if (tag_list == NULL) {
        tag_list = new;
        tag_list->first = tag_list;
        return tag_list;
    }
    
    /* tag_list present: replace existing tag with new one */
    else {   
        while (1) {
            if (tag_list->tag->version == tag->version) {
                new->first = tag_list;
                new->next = tag_list->next;
                tag_list = new;
                break;
            }
            if (tag_list->next) 
                tag_list = tag_list->next;
            else {
                tag_list->next = new;
                new->next = NULL;
                new->first = tag_list;
                break;
            }
        }
        return tag_list;
    }
}

/* populates hv with content of id3_tag (v1!) structure */
int fill_sv_v1tag(HV * hv, id3_tag * t) {
    id3_content * content;
   
    /* kill me */
    content = mp_get_content(t, MP_ARTIST);
    hv_store(hv, "ARTIST", 6, 
                 newSVpv(content ? mp_parse_artist(content)->text : "", 0), 0);
    
    content = mp_get_content(t, MP_TITLE);
    hv_store(hv, "TITLE", 5, 
                 newSVpv(content ? mp_parse_title(content)->text : "", 0), 0);

    content = mp_get_content(t, MP_ALBUM);
    hv_store(hv, "ALBUM", 5, 
                 newSVpv(content ? mp_parse_album(content)->text : "", 0), 0);

    content = mp_get_content(t, MP_GENRE);
    hv_store(hv, "GENRE", 5, 
                 newSVpv(content ? mp_parse_genre(content)->text : "", 0), 0);
    
    content = mp_get_content(t, MP_TRACK);
    hv_store(hv, "TRACK", 5, 
                 newSVpv(content ? mp_parse_track(content)->text : "", 0), 0);
    
    content = mp_get_content(t, MP_YEAR);
    hv_store(hv, "YEAR", 4, 
                 newSVpv(content ? mp_parse_year(content)->text : "", 0), 0);

    content = mp_get_content(t, MP_COMMENT);
    hv_store(hv, "COMMENT", 7, 
                 newSVpv(content ? mp_parse_comment(content)->text : "", 0), 0);

    free(content);
    
}

/* populates hv with content of id3_tag (v2!) structure */
int fill_sv_v2tag(HV * hv, id3_tag * t) {
    id3_content * content;
    int i;
    
    /* COMM frame is special */
    content = mp_get_content_custom (t, "COMM");
    if (content != NULL) {
        HV * comhsh = newHV();
        id3_comment_content * comment = mp_parse_comment(content);
        if (comment != NULL) {
            hv_store_fx(comhsh, "text", 4, 
                        newSVpv(comment->text != NULL
                                ? comment->text : "", 0), 0);
            hv_store_fx(comhsh, "lang", 4, 
                        newSVpv(comment->language != NULL 
                                ? comment->language : "", 0), 0);
            hv_store_fx(comhsh, "short", 5, 
                        newSVpv(comment->short_descr != NULL 
                                ? comment->short_descr : "", 0), 0);
        }
        hv_store_fx(hv, "COMM", 4, newRV_inc((SV*)comhsh), 0);
        mp_free_comment_content(comment);
    } 

    /* WXXX frame:
     * I have to rely on my own patches to mplib here :-( */
    content = mp_get_content_custom (t, "WXXX");
    if (content != NULL) {
        HV* wxhsh = newHV();
        id3_wxxx_content *wxxx = mp_parse_wxxx(content);

        hv_store(wxhsh, "description", 11,
                 newSVpv(wxxx->description ? wxxx->description : "", 0), 0);
        hv_store(wxhsh, "url", 3,
                 newSVpv(wxxx->url ? wxxx->url : "", 0), 0);
        hv_store_fx(hv, "WXXX", 4, newRV_noinc((SV*)wxhsh), 0);
        mp_free_wxxx_content(wxxx);
    }

    /* quick and painless */
    for (i = 2; i < 74; i++) {
        content = mp_get_content_custom (t, fields[i]);
        if (content == NULL)
            continue;
        hv_store_fx(hv, fields[i], 4, 
                    newSVpv(mp_parse_text(content)->text, 0), 0);
    }
    free(content);
} 

int set_v1_tag (const char * filename, HV * t, int enc) {

    id3_tag_list *newlist;

    /* need those to iterate over the hash t */
    HE *iter_struct;
    I32 key_len;
    char *key;
    char *val;
    int ret;
    
    /* construct new tag */
    id3_tag_list *taglist = mp_get_tag_list_from_file(filename);
    id3_tag *new_tag = mp_alloc_tag_with_version(1);
    id3_content *content;
    

    hv_iterinit(t);
    sv_setpv(mp3_lib_err, "");
    while ((iter_struct = hv_iternext(t)) != NULL) {
        int err;
        key = hv_iterkey(iter_struct, &key_len);
        val = SvPV_nolen(hv_iterval(t, iter_struct));
        
        if (strcmp(key, "TRACK") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_TRACK, content)) != 0) 
                sv_catpvf(mp3_lib_err, "%s\034%i", "TRACK", err);
            continue;
        }
        if (strcmp(key, "ARTIST") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_ARTIST, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "ARTIST", err);
            continue;
        }
        if (strcmp(key, "COMMENT") == 0) {
            content = mp_assemble_comment_content(val, NULL, enc, NULL);
            if ((err = mp_set_content(new_tag, MP_COMMENT, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "COMMENT", err);
            continue;
        }
        if (strcmp(key, "GENRE") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_GENRE, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "GENRE", err);
            continue;
        }
        if (strcmp(key, "ALBUM") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_ALBUM, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "ALBUM", err);
            continue;
        }
        if (strcmp(key, "TITLE") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_TITLE, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "TITLE", err);
            continue;
        }
        if (strcmp(key, "YEAR") == 0) {
            content = mp_assemble_text_content(val, enc);
            if ((err = mp_set_content(new_tag, MP_YEAR, content)) != 0)
                sv_catpvf(mp3_lib_err, "%s\034%i", "YEAR", err);
            continue;
        }
        
        /* we made it that far so there was an invalid tag */
        sv_setpv(mp3_lib_err, "");
        sv_catpvf(mp3_lib_err, "%s%c%i", key, '\034', MP_EFNF);

        /* we don't overwrite existing tag in this case */
        mp_free_list(taglist);
        return -1;
    }
    
    newlist = add_tag(taglist, new_tag);
    ret = mp_write_to_file(newlist, filename); 
    
    mp_free_list(newlist);
    mp_free_content(content);

    return ret;
}

int set_v2_tag (const char * filename, HV * t, int enc) {
    
    id3_tag_list *newlist;

    /* need those to iterate over the hash t */
    HE * iter_struct;
    I32 key_len;
    char *key;
    char *val;
    int ret;

    /* construct new tag */
    id3_tag_list *taglist = mp_get_tag_list_from_file(filename);
    id3_tag *new_tag = mp_alloc_tag_with_version(2);
    
    hv_iterinit(t);
    while ((iter_struct = hv_iternext(t)) != NULL) {
        
        id3_content *content;
        key = hv_iterkey(iter_struct, &key_len);

        /* handle comments */
        if (strcmp(key, "COMM") == 0) {
            SV *comval = hv_iterval(t, iter_struct);
            /* hash-ref? */
            if (isHaSHref(comval)) {
                SV **comtext, **comshort, **comlang;
                HV *comhsh = (HV *) SvRV(comval);
                comtext  = hv_fetch(comhsh, "text", 4, FALSE);
                comshort = hv_fetch(comhsh, "short", 5, FALSE);
                comlang  = hv_fetch(comhsh, "lang", 4, FALSE);
                content = mp_assemble_comment_content(
                        comtext  != NULL  ? SvPV_nolen(*comtext)  : "",
                        comshort != NULL  ? SvPV_nolen(*comshort) : "",
                        enc,
                        comlang  != NULL  ? SvPV_nolen(*comlang)  : "ENG");
            } else {
                val = SvPV_nolen(hv_iterval(t, iter_struct));
                content = mp_assemble_comment_content(
                        val != NULL ? val : "", "", enc, "ENG");
            }
            mp_set_custom_content(new_tag, "COMM", content);
            continue;
        } /* COMM */
        
        if (strcmp(key, "WXXX") == 0) {
            SV *wxval = hv_iterval(t, iter_struct);
            if (isHaSHref(wxval)) {
                SV **wxurl, **wxdesc;
                HV *wxhsh = (HV *) SvRV(wxval);
                wxurl  = hv_fetch(wxhsh, "url", 3, FALSE);
                wxdesc = hv_fetch(wxhsh, "description", 11, FALSE);
                content = mp_assemble_wxxx_content(
                        wxurl  != NULL ? SvPV_nolen(*wxurl)  : "",
                        wxdesc != NULL ? SvPV_nolen(*wxdesc) : "",
                        enc);
            } else {
                val = SvPV_nolen(hv_iterval(t, iter_struct));
                content = mp_assemble_wxxx_content(
                        val != NULL ? val : "", "", enc);
            }
            mp_set_custom_content_at_pos(new_tag, "WXXX", content, 0);
            continue;
        } /* WXXX */

        /* all other frames */
        val = SvPV_nolen(hv_iterval(t, iter_struct));
        content = mp_assemble_text_content(val, enc);
        ret = mp_set_custom_content_at_pos(new_tag, key, content, 0);
        mp_free_content(content);

        if (ret != 0) { 
            sv_setpv(mp3_lib_err, "");
            sv_catpvf(mp3_lib_err, "%s%c%i", key, '\034', MP_EFNF);
        }
    }
    newlist = add_tag(taglist, new_tag);
    ret = mp_write_to_file(newlist, filename);
    mp_free_list(newlist);
                         
    return ret;
}

MODULE = MP3::Mplib		PACKAGE = MP3::Mplib		

double
constant(sv,arg)
    PREINIT:
	    STRLEN	len;
    INPUT:
	    SV * sv
        char * s = SvPV(sv, len);
        int	arg
    CODE:
        RETVAL = constant(s,len,arg);
    OUTPUT:
        RETVAL

void
get_header(filename)
        char * filename;
    PROTOTYPE: $
    INIT:
        mpeg_header * header;
    PPCODE:
        header = mp_get_mpeg_header_from_file(filename);
        if (header == NULL) 
            XSRETURN_UNDEF;
            
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(map_mpeg_header_to_sv(header)));

void
get_tag(filename, ver)
        char * filename;
        int ver;
    PROTOTYPE: $$
    INIT:
        id3_tag_list * taglist;
        id3_tag * tag;
    PPCODE:
        taglist = mp_get_tag_list_from_file(filename);
        if (taglist == NULL)
            XSRETURN_UNDEF;
        
        tag = get_tag(taglist, ver);
        if (tag == NULL) 
            XSRETURN_UNDEF;
            
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(map_id3_tag_to_sv(tag)));     
        mp_free_list(taglist);

void
get_id3v2_header(filename)
        char * filename;
    PROTOTYPE: $
    INIT:
        id3_tag_list * taglist;
        id3_tag * tag;
    PPCODE:
        taglist = mp_get_tag_list_from_file(filename);
        if (taglist == NULL)
            XSRETURN_UNDEF;
        tag = get_tag(taglist, 2);
        if (tag == NULL) 
            XSRETURN_UNDEF;
        EXTEND(SP, 1);
        PUSHs(sv_2mortal(map_id3v2_header_to_sv(((id3v2_tag*)tag->tag)->header)));
        mp_free_list(taglist);
        
void
set_tag (filename, ver, tag, enc = ISO_8859_1)
        char * filename;
        int ver;
        SV * tag;
        int enc;
    PREINIT:
        int ret;
    PROTOTYPE: $$$;$
    PPCODE:
        if ( (!SvROK(tag)) ||
             (SvTYPE(SvRV(tag)) != SVt_PVHV) )
            croak("MP3::Mplib::set_tag expects a hash-ref as third arg");

        if (ver == 1) 
            ret = set_v1_tag(filename, (HV *) SvRV(tag), enc);
        else if (ver == 2) 
            ret = set_v2_tag(filename, (HV *) SvRV(tag), enc);
        else
            croak("Unsupported tag version (v%i) in MP3::Mplib::set_header", 
                  ver);

        if (ret == MP_EERROR)
            sv_setpvf(mp3_lib_err, "mp_file\034%i", MP_EERROR);

        EXTEND(SP, 1);
        PUSHs(sv_2mortal(newSViv(ret == 0 ? 1 : 0)));

void
delete_tags(filename, ver)
        char * filename;
        int ver;
    PROTOTYPE: $$
    PPCODE:
        EXTEND(SP, 1);
        switch(mp_del_tags_by_ver_from_file(filename, ver)) {
            case 0: 
                PUSHs(sv_2mortal(newSVuv(1))); 
                break;
            case 1:
                PUSHs(sv_2mortal(newSVuv(0)));
                break;
        }

void 
_clean_up(filename)
        char * filename;
    PROTOTYPE: $
    PPCODE:
        id3_tag_list *taglist;
        id3_tag * tag;
        int i, j;

        taglist = mp_get_tag_list_from_file(filename);
        tag = get_tag(taglist, 2);
        
        if (tag == NULL) 
            XSRETURN_UNDEF;

        for (i = 0; i < V2FRAMES; i++) {
            j = 1;
            while (1) {
                if (mp_get_content_custom_at_pos(tag, fields[i], j))
                    mp_set_custom_content_at_pos(tag, (char*) fields[i], 
                                                 NULL, j);
                else
                    break;
                j++;
            }
        }
        if (mp_write_to_file(taglist, filename) == MP_EERROR) 
            sv_setpvf(mp3_lib_err, "mp_file\034%i", MP_EERROR);
        mp_free_list(taglist->first);

void
_dump_structure(filename)
        char * filename;
    INIT:
        id3_tag_list * taglist, *iter;
        int c = 0;
    PROTOTYPE: $
    PPCODE:
        taglist = mp_get_tag_list_from_file(filename);
        if (taglist == NULL) {
            printf("No tags found\n");
            XSRETURN_UNDEF;
        }
        iter = taglist;
        while (iter) {
            id3_tag *tag = iter->tag;
            printf("Tag at position %i:\n", ++c);
            printf("Version: %i", tag->version);
            if (tag->version == 2) {
                int i, j;
                id3v2_header* head = ((id3v2_tag*)tag->tag)->header;
                printf(" (id3v2.%i.%i)\n", head->version_minor, 
                                           head->version_revision);
                printf("Fields set:\n");
                for (i = 0; i < V2FRAMES; i++, j = 0) {
                    while (mp_get_content_custom_at_pos(tag, fields[i], j)) {
                        int k;
                        char ind[4*(j+1)+1];
                        for (k = 0; k < j+1; k++) {
                                strcpy(&ind[4*k], "    ");
                        }
                        ind[4*k+1] = 0;
                        printf("%s+%s at pos %i\n", ind, fields[i], j++);
                    }
                }
                printf("\n");
            }
            if (tag->version == 1) {
                int i;
                printf(" (id3v1.1)\n");
                printf("Fields set:\n");
                for (i = MP_ARTIST; i <= MP_TRACK; i++) {
                    if (mp_get_content(tag, i))
                        printf("\t+%s\n", fieldsv1[i - 1]);
                }
                printf("\n");
            }
            iter = iter->next;
        }
        mp_free_list(taglist);

BOOT:
    mp3_lib_err = get_sv("MP3::Mplib::Error", TRUE);
