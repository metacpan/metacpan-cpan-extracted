/*
 * $Id: util.c,v 0.70 2005/08/09 15:47:00 dankogai Exp $
 */

#ifndef _INC_UTIL_C_
# define _INC_UTIL_C_

#include <sys/param.h>
#undef I_POLL
#include <Files.h>

#ifdef _INC_PERL_XSUB_H
static int
seterr(int err)
{
    SV *OSerr;
    if (err){
	OSerr = perl_get_sv("MacOSX::File::OSErr", 1);
	sv_setiv(OSerr, err);
    }
    return err;
}
#endif /* _INC_PERL_XSUB_H */

#define  char2OSType(s) (OSType)(s[0]<<24|s[1]<<16|s[2]<<8|s[3])


/*
 * unlike pure-Carbonated functions,
 * MoreFiles functions hate colons in thier name field
 * in FSSpec that are fed as arguments.  There must be
 * replaced to '/'.  Then Darwin make it look like they
 * are colons (sigh).
 * So we define this function just for Copy.xs
 *
 */

static char *
colon2slash(char *str){
    char *p;
    for(p = str; *p != '\0'; p++){
	if (*p == ':') *p = '/';
    }
    return str;
}

static char *
dirname(char *path){
    static unsigned char result[MAXPATHLEN];
    int i, len;
    if (strchr(path, '/') == NULL){
	return ".";
    }else{
	for (i = 0; path[i] != '\0'; i++){
	    if (path[i] == '/'){ len = i; }
	}
	strncpy(result, path, len);
	result[len] = '\0'; /* make sure you terminate the string! */
    }
    return result;
}

static char *
basename(char *path){
    static unsigned char result[MAXPATHLEN];
    int i, len;
    if (strchr(path, '/') == NULL){
	return path;
    }else{
	for (i = 0; path[i] != '\0'; i++){
	    if (path[i] == '/'){ len = i; }
	}
	strncpy(result, path+len+1, MAXPATHLEN);
    }
    return result;
}

static unsigned char *
str2pstr(unsigned char *str, unsigned char *pstr){
    pstr[0] = strlen(str);
    strncpy(pstr+1, str, pstr[0]);
    return pstr;
}

#define FSRef2FSSpec(r, s) FSGetCatalogInfo((r),kFSCatInfoNone,NULL,NULL,(s),NULL)

#endif /* _INC_UTIL_C_ */

