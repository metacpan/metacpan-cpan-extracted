
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#include "GenerateFunctions.h"

int GF_paranoia = 0;

SV * GF_escape_html(SV * str, int b_inplace, int b_lftobr, int b_sptonbsp, int b_leaveknown) {
  int i, maxentitylen = 0;
  STRLEN origlen, extrachars;
  char * sp, *newsp, c, lastc;
  SV * newstr;

  /* Get string pointer and length (in bytes) */
  if (b_inplace) {
    sp = SvPV_force(str, origlen);
  } else {
    sp = SvPV(str, origlen);
  }

  /* Calculate extra space required */
  extrachars = 0;
  c = '\0';
  for (i = 0; i < origlen; i++) {
    /* Need to keep track of previous char for '  ' => ' &nbsp;' expansion */
    lastc = c;
    c = sp[i];
    if (c == '<' || c == '>')
      extrachars += 3;
    else if (c == '&' && (!b_leaveknown || !GF_is_known_entity(sp, i, origlen, &maxentitylen)))
      extrachars += 4;
    else if (c == '"')
      extrachars += 5;
    else if (b_lftobr && c == '\n')
      extrachars += 3;
    else if (b_sptonbsp && c == ' ' && lastc == ' ') {
      extrachars += 5;
      /* don't pick up immediately again */
      c = '\0';
    } else if (GF_paranoia && (c == '{' || c == '}')) {
      extrachars += 5;
    }

  }

  /* Special single space case */
  if (b_sptonbsp && origlen == 1 && sp[0] == ' ') {
    extrachars += 5;
  }

  /*
   * Include maxentitylen in extrachars. Since in the actual substitution
   * phase, we work backwards copying characters towards the end of the
   * string as we go, we might overwrite part of an entity, and then try
   * and call GF_is_known_entity() on the string, which searches forward,
   * and then fails because we already overwrote the entity. So we always
   * make sure we've got maxentitylen extra chars, and then use the perl
   * OOK hack to offset the start of the string at the end
   */
  if (b_inplace) extrachars += maxentitylen;

  /* Create new SV, or grow existing SV */
  if (b_inplace) {
    newstr = str;
    SvGROW(newstr, origlen + extrachars + 1);
  } else {
    newstr = newSV(origlen + extrachars + 1);
    SvPOK_on(newstr);
    /* Make new string UTF-8 if input string was UTF-8 */
    if (SvUTF8(str))
      SvUTF8_on(newstr);
  }

  /* Set the length of the string */
  SvCUR_set(newstr, origlen + extrachars);

  /* Now do actual replacement (need to work
     backward for inplace change to work */

  /* Original string might have moved due to grow */
  sp = SvPV_nolen(str);

  /* Null terminate new string */
  newsp = SvPV_nolen(newstr) + origlen + extrachars;
  *newsp = '\0';

  c = '\0';
  for (i = origlen-1; i >= 0; i--) {
    lastc = c;
    c = sp[i];
    if (c == '<') {
      newsp -= 4;
      memcpy(newsp, "&lt;", 4);
    }
    else if (c == '>') {
      newsp -= 4;
      memcpy(newsp, "&gt;", 4);
    }
    else if (c == '&' && (!b_leaveknown || !GF_is_known_entity(sp, i, origlen, 0))) {
      newsp -= 5;
      memcpy(newsp, "&amp;", 5);
    }
    else if (c == '"') {
      newsp -= 6;
      memcpy(newsp, "&quot;", 6);
    }
    else if (b_lftobr && c == '\n') {
      newsp -= 4;
      memcpy(newsp, "<br>", 4);
    }
    else if (b_sptonbsp && c == ' ' && lastc == ' ') {
      newsp -= 6;
      memcpy(newsp, "&nbsp; ", 7);
      /* don't pick up immediately again */
      c = '\0';
    } else if (GF_paranoia && (c == '{' || c == '}')) {
      newsp -= 6;
      memcpy(newsp, c == '{' ? "&#123;" : "&#125;", 6);
    } else
      *--newsp = c;
  }

  /* Special single space case */
  if (b_sptonbsp && origlen == 1 && sp[0] == ' ') {
    newsp -= 5;
    memcpy(newsp, "&nbsp;", 6);
  }

  if (b_inplace && maxentitylen)
    sv_chop(newstr, newsp);

  if (SvPV_nolen(newstr) != newsp) {
    croak("Unexpected length mismatch");
    return 0;
  }

  return newstr;
}

SV * GF_generate_attributes(HV * attrhv) {
  int i, j, estimatedlen = 1;
  I32 keylen;
  char * key, tmp[64];
  SV * attrstr, * val;

  /* Iterate through keys to work out an estimated final length */
  while ((val = hv_iternextsv(attrhv, &key, &keylen))) {
    estimatedlen += keylen + 1;
    estimatedlen += GF_estimate_attribute_value_len(val) + 3;
  }

  /* warn("estimated len: %d", estimatedlen); */

  attrstr = newSV(estimatedlen);
  SvPOK_on(attrstr);

  /* Now iteratre and build actual string */
  hv_iterinit(attrhv);
  while ((val = hv_iternextsv(attrhv, &key, &keylen))) {

    /* Add space to string if already something in it */
    if (SvCUR(attrstr))
      sv_catpvn(attrstr, " ", 1);

    /* For key, convert to lower case and add to attrstr */
    if (keylen < 64) {
      /* If key starts with - (eg -width => '10%'), skip - */
      j = 0;
      i = (keylen && key[0] == '-' ? 1 : 0);
      for (; i < keylen; i++)
        tmp[j++] = toLOWER(key[i]);
      sv_catpvn(attrstr, tmp, j);

    } else {
      sv_catpvn(attrstr, key, keylen);
    }

    /* Add '="value"' part if present*/
    if (SvOK(val)) {
      sv_catpvn(attrstr, "=\"", 2);
      GF_generate_attribute_value(attrstr, val);
      sv_catpvn(attrstr, "\"", 1);
    }
  }

  /* warn("real len: %d, %s", SvCUR(attrstr), SvPV_nolen(attrstr)); */

  return attrstr;
}

SV * GF_generate_tag(SV * tag, HV * attrhv, SV * val, int b_escapeval, int b_addnewline, int b_closetag) {
  char * tagsp, * valsp;
  STRLEN taglen, vallen, estimatedlen;
  SV * tagstr, * attrstr = 0;

  /* Force tag to string when getting length */
  tagsp = SvPV(tag, taglen);
  estimatedlen = taglen + 3 + (b_addnewline ? 1 : 0);

  /* Create attributes as string */
  if (attrhv) {
    attrstr = GF_generate_attributes(attrhv);
    estimatedlen += SvCUR(attrstr) + 1;
  }

  if (val) {
    /* If asked to escape, escape the val */
    if (b_escapeval)
      val = GF_escape_html(val, 0, 0, 0, 0);
    /* Force value to string when getting length */
    valsp = SvPV(val, vallen);
    estimatedlen += vallen + taglen + 3;
  }

  /* If asked to close the tag, add ' /' */
  if (b_closetag)
    estimatedlen += 2;

  /* Create new string to put final result in */
  tagstr = newSV(estimatedlen);
  SvPOK_on(tagstr);

  sv_catpvn(tagstr, "<", 1);
  sv_catsv(tagstr, tag);
  if (attrstr) {
    if (SvCUR(attrstr)) {
      sv_catpvn(tagstr, " ", 1);
      sv_catsv(tagstr, attrstr);
    }
    SvREFCNT_dec(attrstr);
  }
  if (b_closetag)
    sv_catpvn(tagstr, " />", 3);
  else 
    sv_catpvn(tagstr, ">", 1);

  if (val) {
    sv_catsv(tagstr, val);
    if (b_escapeval)
      SvREFCNT_dec(val);
    sv_catpvn(tagstr, "</", 2);
    sv_catsv(tagstr, tag);
    sv_catpvn(tagstr, ">", 1);
  }

  if (b_addnewline)
    sv_catpvn(tagstr, "\n", 1);

  return tagstr;
}

static char * hexlookup = "0123456789ABCDEF";

SV * GF_escape_uri(SV * str, SV * escchars, int b_inplace) {
  int i;
  STRLEN origlen, esclen, extrachars;
  char * sp, *newsp, *escsp;
  unsigned char c;
  SV * newstr;

  /* Get string pointer and length (in bytes) */
  if (b_inplace) {
    sp = SvPV_force(str, origlen);
  } else {
    sp = SvPV(str, origlen);
  }

  escsp = SvPV(escchars, esclen);

  /* Calculate extra space required */
  extrachars = 0;
  for (i = 0; i < origlen; i++) {
    c = (unsigned char)sp[i];
    /* Always escape control on 8-bit chars or chars in our escape set */
    if (c <= 0x20 || c >= 0x80 || memchr(escsp, c, esclen)) {
      extrachars += 2;
    }
  }

  /* Create new SV, or grow existing SV */
  if (b_inplace) {
    newstr = str;
    /* Always turn of utf8-ness in escaped string */
    SvUTF8_off(newstr);
    SvGROW(newstr, origlen + extrachars + 1);
  } else {
    newstr = newSV(origlen + extrachars + 1);
    SvPOK_on(newstr);
  }

  /* Set the length of the string */
  SvCUR_set(newstr, origlen + extrachars);

  /* Now do actual replacement (need to work
     backward for inplace change to work */

  /* Original string might have moved due to grow */
  sp = SvPV_nolen(str);

  /* Null terminate new string */
  newsp = SvPV_nolen(newstr) + origlen + extrachars;
  *newsp = '\0';

  for (i = origlen-1; i >= 0; i--) {
    c = (unsigned char)sp[i];
    if (c <= 0x20 || c >= 0x80 || memchr(escsp, c, esclen)) {
      newsp -= 3;
      newsp[0] = '%';
      newsp[1] = hexlookup[(c>>4) & 0x0f];
      newsp[2] = hexlookup[c & 0x0f];
    } else
      *--newsp = (char)c;
  }

  if (newsp != SvPV_nolen(newstr)) {
    croak("Unexpected length mismatch");
    return 0;
  }

  return newstr;
}

int GF_is_known_entity(char * sp, int i, int origlen, int *maxlen) {
  int start = i;

  if (++i < origlen) {
    /* Check for unicode ref (eg &#1234;) */
    if (sp[i] == '#') {
      int is_hex = 0;

      /* Check for hex unicode ref (eg &#x12af;) */
      if (i+1 < origlen && (sp[i+1] == 'x' || sp[i+1] == 'X')) {
        is_hex = 1;
        i++;
      }

      /* Not quite right, says "&#" and "&#;" are ok */
      while (++i < origlen) {
        if (sp[i] >= '0' && sp[i] <= '9') continue;
        if (is_hex && ((sp[i] >= 'a' && sp[i] <= 'f') || (sp[i] >= 'A' && sp[i] <= 'F'))) continue;
        if (sp[i] == ';' || sp[i] == ' ') {
          /* Keep track of maximum entity length */
          i++;
          if (maxlen && (i - start > *maxlen)) *maxlen = i-start;
          return 1;
        }
        break;
      }

    /* Check for entity ref (eg &nbsp;) */
    } else if ((sp[i] >= 'a' && sp[i] <= 'z') || (sp[i] >= 'A' && sp[i] <= 'Z')) {
      while (++i < origlen) {
        if ((sp[i] >= 'a' && sp[i] <= 'z') || (sp[i] >= 'A' && sp[i] <= 'Z')) continue;
        /* We should check to see if matched text string is known enity,
           but it's not that important */
        if (sp[i] == ';' || sp[i] == ' ') {
          /* Keep track of maximum entity length */
          i++;
          if (maxlen && (i - start > *maxlen)) *maxlen = i-start;
          return 1;
        }
        break;
      }
    }
  }
  return 0;
}

int GF_estimate_attribute_value_len(SV * val) {
  STRLEN vallen;
  I32 valtype;

  /* If reference, de-reference ... */
  if (SvROK(val)) {
    val = SvRV(val);
  }

  valtype = SvTYPE(val);

  /* Array case */
  if (valtype == SVt_PVAV) {
    int estimatedlen = 0;
    AV * aval = (AV *)val;
    I32 alen = av_len(aval), i;
    for (i = 0; i <= alen; i++) {
      SV **av_val;
      if ((av_val = av_fetch(aval, i, 0)) && SvOK(val = *av_val)) {
        estimatedlen += GF_estimate_attribute_value_len(val) + 1;
      }
    }
    return estimatedlen;
  }

  /* Hash case */
  if (valtype == SVt_PVHV) {
    int estimatedlen = 0;
    HV * hval = (HV *)val;
    char * key; I32 keylen;
    hv_iterinit(hval);
    while ((val = hv_iternextsv(hval, &key, &keylen))) {
      estimatedlen += keylen + 1;
    }
    return estimatedlen;
  }

  /* Ignore other non-scalar types */
  if (!SvOK(val)) return 0;

  /* Most common case of a string */
  if (SvPOK(val)) return SvCUR(val);

  /* Other SV case, turn it into a string */
  if (SvOK(val)) return (SvPV(val, vallen), vallen);

  return 0;
}

void GF_generate_attribute_value(SV * attrstr, SV * val) {
  I32 valtype;
  int no_escape = 0;

  /* If reference, de-reference ... */
  if (SvROK(val)) {
    val = SvRV(val);
    no_escape = 1;
  }

  valtype = SvTYPE(val);

  /* Array? Iterate over array items space separated... */
  if (valtype == SVt_PVAV) {
    AV * aval = (AV *)val;
    I32 alen = av_len(aval), i;
    for (i = 0; i <= alen; i++) {
      SV **av_val;
      if ((av_val = av_fetch(aval, i, 0)) && SvOK(val = *av_val)) {
        GF_generate_attribute_value(attrstr, val);
        if (i != alen) sv_catpvn(attrstr, " ", 1);
      }
    }
    return;
  }

  /* Hash? Iterate over keys space separated... */
  if (valtype == SVt_PVHV) {
    HV * hval = (HV *)val;
    char * key; I32 keylen;
    I32 hlen = hv_iterinit(hval), i = 0;
    HE * hentry;
    while ((hentry = hv_iternext(hval))) {
      key = hv_iterkey(hentry, &keylen);
      sv_catpvn(attrstr, key, keylen);
      if (++i != hlen) sv_catpvn(attrstr, " ", 1);
    }
    return;
  }

  /* Ignore other non-scalar types */
  if (!SvOK(val)) return;

  /* Otherwise just append to attribute string */

  /* If value was reference, use that unescaped */
  if (no_escape) {
    sv_catsv(attrstr, val);

  /* For the value part, escape special html chars, then dispose of result */
  } else {
    val = GF_escape_html(val, 0, 0, 0, 0);
    sv_catsv(attrstr, val);
    SvREFCNT_dec(val);
  }

  return;
}

void GF_set_paranoia(int paranoia) {
  GF_paranoia = paranoia;
  return;
}

