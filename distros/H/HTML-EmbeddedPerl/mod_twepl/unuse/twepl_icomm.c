#ifndef __TWEPL_ICOMM_C__
#define __TWEPL_ICOMM_C__

int nw(char c)
{
  if(c < 0x30||(c > 0x39 && c < 0x41)||(c > 0x5a && c < 0x5f)||c == 0x60||c > 0x7a){
    return 1;
  }
  return 0;
}
int ns(char c)
{
  if(c < 0x21||(c > 0x2f && c < 0x3a)||(c > 0x40 && c < 0x5b)||(c > 0x60 && c < 0x7b)){
    return 1;
  }
  return 0;
}
char *ht(char *c)
{

  char *x;
   int  e =0;
   int  i;

  if(c[0] == 0x22 || c[0] == 0x27 || c[0] == '`'){
    for(i=1;c[i]!='\0';i++){
      if(c[i] == 0x22 || c[i] == 0x27 || c[i] == '`'){
        e = i; break;
      }
    }
  } else{
    for(i=0;c[i]!='\0';i++){
      if(nw(c[i])){
        e = i; break;
      }
    }
  }

  if(e == 0){ return NULL; }

  if((x = (char *)malloc(e+1)) == NULL){
    return NULL;
  }

  strncpy(x,c,e);

  x[e] = '\0';

  return x;

}
int sc(char *c,int p)
{
  int i;
  for(i=0;i>(0-p);i--){
    if(c[i] > 0x20 || c[i] == '\r' || c[i] == '\n'){ break; }
  }
  return i;
}
char *cc(pTHX_ char *c,int l)
{

  char *x;
  char *h;
  char  z;
  char  t;
   int  i,j,k,p,r;
   int  f;

  for(i=f=0;i<l;i++){
    if(c[i] == '#' || (c[i] == '/' && c[(i+1)] == '/') || (c[i] == '/' && c[(i+1)] == '*')){ f++; break; }
  }

  if(! f){ return c; }

  if((x = (char *)malloc(l+1)) == NULL){
    Perl_croak(aTHX_ "failed malloc in function cc");
    return NULL;
  }

  for(i=j=f=0;i<l;i++){
    if(c[i] == '#'){
      for(;i<l;i++){
        if(c[i] == '\r' || c[i] == '\n'){
          j = j + sc(x+(j-1),j);
          x[j++] = c[i];
          break;
        }
      }
    } else if((c[i] == '/' && c[(i+1)] == '*')){
      if(l > (i+=2)){
        j = j + sc(x+(j-1),j);
        for(;i<l;i++){
          if(c[i] == '\r' || c[i] == '\n'){
            x[j++] = c[i];
          } else if(c[i] == '*' && c[(i+1)] == '/'){
            i++; f++; break;
          }
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of comment in function cc(/**/)");
        return NULL;
      }
    } else if(c[i] == '/' && c[(i+1)] == '/'){
      for(r=i-1;r>0;r--){
        if(c[r] == 0x09 || c[r] == 0x20){ continue; }
        if(c[r] == '~'){ f++; }
        break;
      }
      if(f){
        x[j++] = c[i];
        x[j++] = c[++i];
      } else{
        for(;i<l;i++){
          if(c[i] == '\r' || c[i] == '\n'){
            j = j + sc(x+(j-1),j);
            x[j++] = c[i];
            break;
          }
        }
      }
    } else if(c[i] == '/'){
      x[j++] = c[i];
      for(i+=1;i<l;i++){
        x[j++] = c[i];
        if(c[(i-1)] != '\\' && c[i] == '/'){
            f++; break;
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of regexp in function cc(//)");
        return NULL;
      }
    } else if(c[i] == '<' && c[(i+1)] == '<'){
      x[j++] = c[i];
      x[j++] = c[(i+1)];
      if(l > (i+=2)){
        if((h = ht(c+i)) == NULL){
          x[j++] = c[i];
          continue;
        }
        p = strlen(h);
        for(k=0;k<p;k++){
          x[j++] = c[(i+k)];
        }
        for(i+=p;i<l;i++){
          if(strncmp(c+i,h,p) == 0){
            f++; i--; break;
          } else{
            x[j++] = c[i];
          }
        }
        free(h);
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of here-document in function cc(&gt;&gt;)");
        return NULL;
      }
    } else if(c[i] == '<'){
      x[j++] = c[i];
      for(r=i-1;r>0;r--){
        if(c[r] == 0x09 || c[r] == 0x20){ continue; }
        if(c[r] == '~'){ f++; }
        break;
      }
      if(!f){
        continue;
      } else{
        for(i+=1,f=0;i<l;i++){
          x[j++] = c[i];
          if(c[(i-1)] != '\\' && c[i] == '>'){
            f++; break;
          }
        }
        if(!f){
          Perl_croak(aTHX_ "could not find end of regexp in function cc(&lt;&gt;)");
          return NULL;
        }
      }
    } else if(c[i] == 0x22 || c[i] == 0x27 || c[i] == '`'){
      x[j++] = c[i];
      z = c[i];
      for(i+=1;i<l;i++){
        x[j++] = c[i];
        if(c[(i-1)] != '\\' && c[i] == z){
            f++; break;
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of quote in function cc(%c)",z);
        return NULL;
      }
    } else if(c[i] == 'q' && (c[(i+1)] == 'q' || c[(i+1)] == 'r' || c[(i+1)] == 'w' || c[(i+1)] == 'x')){
      x[j++] = c[i];
      x[j++] = c[(i+1)];
      t = c[(i+1)];
      if(l > (i+=2)){
        if(ns(c[i])){
          x[j++] = c[i];
          continue;
        }
        x[j++] = c[i];
        switch(c[i]){
          case '(': z = ')'; break;
          case '[': z = ']'; break;
          case '{': z = '}'; break;
          case '<': z = '>'; break;
          default: z = c[i];
        }
        for(i+=1;i<l;i++){
          x[j++] = c[i];
          if(c[(i-1)] != '\\' && c[i] == z){
            f++; break;
          }
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of quote in function in cc(q%c)",t);
        return NULL;
      }
    } else if(c[i] == 'm' || c[i] == 'q'){
      x[j++] = c[i];
      t = c[i];
      if(ns(c[(i+1)])){
        continue;
      }
      if(l > ++i){
        x[j++] = c[i];
        switch(c[i]){
          case '(': z = ')'; break;
          case '[': z = ']'; break;
          case '{': z = '}'; break;
          case '<': z = '>'; break;
          default: z = c[i];
        }
        for(i+=1;i<l;i++){
          x[j++] = c[i];
          if(c[(i-1)] != '\\' && c[i] == z){
            f++; break;
          }
        }
      }
      if(!f){
        if(t == 'm'){
          Perl_croak(aTHX_ "could not find end of regexp in function in cc(%c)",t);
        } else{
          Perl_croak(aTHX_ "could not find end of quote in function in cc(%c)",t);
        }
        return NULL;
      }
    } else if(c[i] == 's'){
      x[j++] = c[i];
      if(ns(c[(i+1)])){
        continue;
      }
      if(l > ++i){
        switch(c[i]){
          case '(': t = c[i]; z = ')'; break;
          case '[': t = c[i]; z = ']'; break;
          case '{': t = c[i]; z = '}'; break;
          case '<': t = c[i]; z = '>'; break;
          default: t = '\0'; z = c[i];
        }
        x[j++] = c[i];
        if(t == '\0'){
          for(i+=1;i<l;i++){
            x[j++] = c[i];
            if(c[(i-1)] != '\\' && c[i] == z){
              if(++f > 1){ break; }
            }
          }
        } else{
          for(i+=1;i<l;i++){
            x[j++] = c[i];
            if(c[(i-1)] != '\\' && c[i] == z){
              f++; break;
            }
          }
          if(! f || c[(i+1)] != t){
            Perl_croak(aTHX_ "could not find end of regexp in function in cc(s)");
            return NULL;
          } else{
            for(i+=1,f=0;i<l;i++){
              x[j++] = c[i];
              if(c[(i-1)] != '\\' && c[i] == z){
                f++; break;
              }
            }
          }
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of regexp in function in cc(s)");
        return NULL;
      }
    } else if(c[i] == 't' && c[(i+1)] == 'r'){
      x[j++] = c[i];
      x[j++] = c[(i+1)];
      if(l > (i+=2)){
        if(ns(c[i])){
          x[j++] = c[i];
          continue;
        }
        switch(c[i]){
          case '(': t = c[i]; z = ')'; break;
          case '[': t = c[i]; z = ']'; break;
          case '{': t = c[i]; z = '}'; break;
          case '<': t = c[i]; z = '>'; break;
          default: t = '\0'; z = c[i];
        }
        x[j++] = c[i];
        if(t == '\0'){
          for(i+=1;i<l;i++){
            x[j++] = c[i];
            if(c[(i-1)] != '\\' && c[i] == z){
              if(++f > 1){ break; }
            }
          }
        } else{
          for(i+=1;i<l;i++){
            x[j++] = c[i];
            if(c[(i-1)] != '\\' && c[i] == z){
              f++; break;
            }
          }
          if(! f || c[(i+1)] != t){
            Perl_croak(aTHX_ "could not find end of regexp in function in cc(tr)");
            return NULL;
          } else{
            for(i+=1,f=0;i<l;i++){
              x[j++] = c[i];
              if(c[(i-1)] != '\\' && c[i] == z){
                f++; break;
              }
            }
          }
        }
      }
      if(!f){
        Perl_croak(aTHX_ "could not find end of regexp in function in cc(tr)");
        return NULL;
      }
    } else{
      x[j++] = c[i];
    }
    f = 0;
  }

  x[j] = '\0';

  return x;

}

#endif
