#ifndef __TWEPL_PARSE_C__
#define __TWEPL_PARSE_C__

#include "twepl_parse.h"

char strnchr(char src, char *cmp){

  long i;

  for(i=0; i<(long)strlen(cmp); i++){
    if(src == cmp[i]) return cmp[i];
  }

  return 0;

}

long twepl_serach_optag(char *src, long ssz, long idx, char *tmc, char *fmc){

  char *tmp;
  char  fmt;
  long  i;

  tmp = src + idx;

  for(i=0; (i+idx)<ssz&&*tmp!='\0'; i++){
    if(*tmp == '<' && (fmt = strnchr(tmp[1], tmc)) != 0){
      fmc[0] = fmt; return i;
    }; tmp++;
  }

  return i;

}

long twepl_serach_edtag(char *src, long ssz, long idx, char *emc){

  char *tmp;
  long  i;

  tmp = src + idx;

  for(i=0; (i+idx)<ssz&&*tmp!='\0'; i++){
    if(strncmp(tmp, emc, 2) == 0){
      return i;
    }; tmp++;
  }

  return i;

}

long count_quote(char *src, long stp, long edp){

  long  c = 0;
  long  i;

  for(i=stp; i<(stp+edp)&&src[i]!='\0'; i++){
    if(src[i] == '\x22'){
      c += 4;
    } else{
      c++;
    }
  }

  return c;

}

int twepl_optagstr_skip(char *src, int idx){

    if(strncasecmp((src + idx), "p5\0", 2) == 0){
      return 2;
    } else if(strncasecmp((src + idx), "pl5\0", 3) == 0){
      return 3;
    } else if(strncasecmp((src + idx), "pl\0", 2) == 0){
      return 2;
    } else if(strncasecmp((src + idx), "perl5\0", 5) == 0){
      return 5;
    } else if(strncasecmp((src + idx), "perl\0", 4) == 0){
      return 4;
    }

  return 0;

}

enum TWEPL_STATE twepl_lint(char *src, long ssz, long *nsz, int opf){

  long  idx = 0;
  long  ret = 0;
  long  qqc = 0;
  long  erf = 0;

  char *tmc;
  char *fmc;
  char *emc;

  if((tmc = (char*)malloc(8)) == NULL){
    return TWEPL_FAIL_MALOC;
  } else if((fmc = (char*)malloc(2)) == NULL){
    free(tmc); return TWEPL_FAIL_MALOC;
  } else if((emc = (char*)malloc(3)) == NULL){
    free(tmc); free(fmc); return TWEPL_FAIL_MALOC;
  }

  memset(tmc, '\0', 8);
  memset(fmc, '\0', 2);
  memset(emc, '\0', 3);
  strcpy(tmc, EPL_TAG_DEF);

  if(is_EPL(opf)) strcat(tmc, EPL_TAG_EPL);
  if(is_DOL(opf)) strcat(tmc, EPL_TAG_DOL);
  if(is_PHP(opf)) strcat(tmc, EPL_TAG_PHP);
  if(is_ASP(opf)) strcat(tmc, EPL_TAG_ASP);

  while(ssz > idx){

    ret = twepl_serach_optag(src, ssz, idx, tmc, fmc);

    if(ret != 0){

      *nsz += HTML_LS;
      qqc = count_quote(src, idx, ret);
      *nsz += (qqc + HTML_LE);

    }

    if((idx+ret) >= ssz){
      break;
    }

    idx += (ret + 2);
    idx += twepl_optagstr_skip(src, idx);

    emc[0] = fmc[0]; emc[1] = '>'; emc[2] = '\0';

    ret = twepl_serach_edtag(src, ssz, idx, emc);

    if((idx+ret) >= ssz){
      erf = 1; break;
    }

    idx += (ret + 2);

    *nsz += idx;

  }

  free(tmc); free(fmc); free(emc);

  if(erf == 1){
    return TWEPL_FAIL_TAGED;
  } else{
    return TWEPL_OKEY_NOERR;
  }

}

int twepl_quote(char *src, char *cnv, long stp, long edp){

  char *tmp = cnv;
  long  c = 0;
  long  i;

  for(i=stp; i<(stp+edp)&&src[i]!='\0'; i++){

    if(src[i] == '\x22'){
      strcpy(tmp, "\\x22");
      tmp += 4;
      c += 4;
    } else{
      *tmp = src[i];
      tmp++;
      c++;
    }
  }

  return c;

}

enum TWEPL_STATE twepl_parse(char *src, char *cnv, long ssz, int opf){

  long  idx = 0;
  long  ret = 0;
  long  qqc = 0;
  long  erf = 0;

  char *tmc;
  char *fmc;
  char *emc;

  if((tmc = (char*)malloc(8)) == NULL){
    return TWEPL_FAIL_MALOC;
  } else if((fmc = (char*)malloc(2)) == NULL){
    free(tmc); return TWEPL_FAIL_MALOC;
  } else if((emc = (char*)malloc(3)) == NULL){
    free(tmc); free(fmc); return TWEPL_FAIL_MALOC;
  }

  memset(tmc, '\0', 8);
  memset(fmc, '\0', 2);
  memset(emc, '\0', 3);
  strcpy(tmc, EPL_TAG_DEF);

  if(is_EPL(opf)) strcat(tmc, EPL_TAG_EPL);
  if(is_DOL(opf)) strcat(tmc, EPL_TAG_DOL);
  if(is_PHP(opf)) strcat(tmc, EPL_TAG_PHP);
  if(is_ASP(opf)) strcat(tmc, EPL_TAG_ASP);

  while(ssz > idx){

    ret = twepl_serach_optag(src, ssz, idx, tmc, fmc);

    if(ret != 0){

      strcpy(cnv, HTML_PS);
      cnv += HTML_LS;

      qqc = twepl_quote(src, cnv, idx, ret);
      cnv += qqc;

      strcpy(cnv, HTML_PE);
      cnv += HTML_LE;

      *cnv = '\0';

    }

    if((idx+ret) >= ssz){
      break;
    }

    idx += (ret + 2);
    idx += twepl_optagstr_skip(src, idx);

    emc[0] = fmc[0]; emc[1] = '>'; emc[2] = '\0';

    ret = twepl_serach_edtag(src, ssz, idx, emc);

    if((idx+ret) >= ssz){
      erf = 1; break;
    }

    strncpy(cnv, (src + idx), ret);
    cnv += ret;

    *cnv = '\0';

    idx += (ret + 2);

  }

  free(tmc); free(fmc); free(emc);

  if(erf == 1){
    return TWEPL_FAIL_TAGED;
  } else{
    return TWEPL_OKEY_NOERR;
  }

}

enum TWEPL_STATE twepl_file(char *ifp, char **cnv, int opf){

  enum TWEPL_STATE  ret;

              FILE *epf;

              char *src;

              long  fsz;
              long  csz = 0;

  if((epf = fopen(ifp, "rb")) == NULL){
    return TWEPL_FAIL_FOPEN;
  }

  /* fseek (MAX: 2GB) */
  if((fseek(epf, 0, SEEK_END)) == -1){
    return TWEPL_FAIL_FSEEK;
  }
  /* File size */
  if((fsz = ftell(epf)) == -1){
    return TWEPL_FAIL_FTELL;
  }
  /* Return */
  if((fseek(epf, 0, SEEK_SET)) == -1){
    return TWEPL_FAIL_FSEEK;
  }

  if((src = (char *)malloc(fsz+1)) == NULL){
    return TWEPL_FAIL_MALOC;
  }; src[fsz] = '\0';

  if((fread(src, sizeof(char), fsz, epf)) == -1){
    return TWEPL_FAIL_FREAD;
  }

  fclose(epf);

  if((ret = twepl_lint(src, fsz, &csz, opf)) != TWEPL_OKEY_NOERR){
    free(src);
    return ret;
  }

  if((*cnv = (char *)malloc(csz+1)) == NULL){
    free(src);
    return TWEPL_FAIL_MALOC;
  }; memset(*cnv, '\0', (csz + 1));

  twepl_parse(src, *cnv, fsz, opf);

  free(src);

  return TWEPL_OKEY_NOERR;

}

enum TWEPL_STATE twepl_code(char *src, char **cnv, int opf){

  enum TWEPL_STATE  ret;

              long  ssz;
              long  csz = 0;

  if(!(ssz = strlen(src))){
    return TWEPL_FAIL_SLENG;
  }

  if((ret = twepl_lint(src, ssz, &csz, opf)) != TWEPL_OKEY_NOERR){
    return ret;
  }

  if((*cnv = (char *)malloc(csz+1)) == NULL){
    return TWEPL_FAIL_MALOC;
  }; memset(*cnv, '\0', (csz + 1));

  twepl_parse(src, *cnv, ssz, opf);

  return TWEPL_OKEY_NOERR;

}

const char *twepl_strerr(enum TWEPL_STATE state){
  return (const char*)TWEPL_ERROR_STRING[state];
}

#endif
