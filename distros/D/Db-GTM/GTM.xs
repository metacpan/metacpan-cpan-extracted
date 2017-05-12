#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "gtmxc_types.h"   // For GTM call-in function prototypes
#include "string.h"        // strlen(), memcpy(), strncmp()
#include "GTM.h"           // my prototypes
#include "stdlib.h"        // setenv

static void err_gtm(const GtmEnv *gt) {
  char *msgbuf = gt ? gt->errmsg : (char *)calloc(1024,sizeof(gtm_char_t)); 
  gtm_zstatus(msgbuf,1024); if(!gt || (gt && !(gt->flags & NO_WARN))) { 
    warn("GTM ERROR: (%d) %s\n", gt->last_err, msgbuf); 
  }
  if(!gt) free(msgbuf); return;
}

// Returns 1 if you should free the GVN after you're done with it
int packgvn(GtmEnv *gtenv, unsigned len,strpack strs[],
            const unsigned flags, gtm_string_t *gvn) {
  unsigned i,xlen=(gtenv && !(flags & NO_PREFIX))?gtenv->pfx_elem:0,sz,tmp; 
  unsigned err=0,freestrs=0; char *ret=NULL,*loc; strpack *seek;

  if(!gvn) return; sz = ((len+xlen)>1) ? (len+xlen)*3 : 2; if(xlen) {
    sz += (unsigned)gtenv->pfx_length;  
    for(i=xlen;i--;) if(gtenv->prefix[i].num) sz -= 2;
  }
  if((flags & TIED) && len == 1 && strchr(strs[0].address,'\034')) {
    // Multidimensional array with \034 separators
    loc = strs[0].address; while( loc = index(loc,'\034') ) { len++; loc++; }
    loc = strs[0].address; freestrs=len; i = 0; sz += (len-1)*3;
    strs = (strpack *)calloc(len,sizeof(strpack)); 
    while( loc ) {
      ret = index(loc,'\034'); if(ret) *ret = '\0'; tmp = strlen(loc);
      strs[i].address = (char *)calloc(tmp+1,sizeof(char));
      strs[i].length  = tmp; memcpy(strs[i].address, loc, tmp); 
      loc = ret ? ret+1 : ret; i++;
    }
  } 
  // Validate global, calculate final GLVN size
  if(len||xlen) ret = (xlen) ? gtenv->prefix->address : strs[0].address; 
  if(len == 1 && *strs[0].address == '^') { 
    gvn->address = strs[0].address; gvn->length  = strs[0].length; return 0;
  } else if(!(len || xlen) || !ret ||
          !(xlen || (strs[0].length && strs[0].length <= _GT_MAX_GVNSIZE)) || 
          !((*ret >= 'a' && *ret <= 'z') || (*ret >= 'A' && *ret <= 'Z')) 
  ) err++; else for(i=len;i--;) {
      if(!strs[i].length && !((flags & ZEROLEN_OK) && i==(len-1))) err++;
      else sz += strs[i].length; 
      if(is_number(strs[i].address)) { sz -= 2; strs[i].num++; }
  }
  if(err || !sz || sz > _GT_MAX_GVNLENGTH) {
    if(!(flags & NO_WARN)) warn("ERROR: Poorly-specified node name.\n"); 
    if(gtenv) {
      gtenv->last_err = 1;
      sprintf(gtenv->errmsg,"ERROR: Poorly-specified node name.");
    }
    if(freestrs) strpack_clear(strs,len); gvn->address = NULL; return 0;
  } else ret = (char *)calloc(sz+1,sizeof(char)); loc = ret; 

  *loc = '^'; loc++; for(i=0;i<(len+xlen);i++) {
    seek = (i<xlen) ? &gtenv->prefix[i] : &strs[i-xlen];
    if(i) {
      if(!seek->num) { *loc = '"'; loc++; }
      memcpy(loc, seek->address, seek->length); loc += seek->length;
      if(!seek->num) { *loc = '"'; loc++; }
      *loc = ((i+1) == (len+xlen)) ? ')' : ','; loc++;
    } else {
      memcpy(loc, seek->address, seek->length); loc += seek->length;
      if((len+xlen) > 1) { *loc = '('; loc++; }
    }
  }
  if(freestrs) strpack_clear(strs,len); 
  gvn->address = ret; gvn->length = sz; return 1;
}

static unsigned is_number(char *i) {
  unsigned dec=0; 

  if(*i == '-') i++; if(*i == '0') {
    i++; if(*i != '.') return 0; else { dec++; i++; }
  } else if(*i < '0' || *i > '9') return 0; else i++;
  while(*i) {
    if(*i == '.') { if(dec) return 0; else { dec++; } }
    else if(*i < '0' || *i > '9') return 0; 
    i++;
  }
  return (dec && (*(i-1) == '0')) ? 0 : 1;
}

cppack *unpackgvn(const char *gvn) {
  char *at = (char *)gvn, *seek;
  unsigned quot=0,err=0; cppack *ret, *working, *new;

  if(!gvn || (*gvn != '^') || strlen(gvn) > _GT_MAX_GVNLENGTH) return NULL;
  ret = (cppack *)calloc(1,sizeof(cppack));
  at++; ret->loc = at; seek = index(at, '('); 
  if(!seek) return ret; else { *seek = '\0'; at = seek+1; }
  seek = rindex(at, ')'); if(!seek) {free(ret); return NULL;} else *seek='\0';
  working = ret; while(at) {
    if(*at == '"') { 
      at++; seek = index(at, '"'); 
      while(seek && seek[1] == '"') { seek = index(&seek[2],'"'); }
      if(!seek) err++; else { *seek = '\0'; seek += 2; }
    } else { seek = index(at, ','); if(seek) { *seek = '\0'; seek++; } }
    if(!err && *at) { 
      new = (cppack *)calloc(1,sizeof(cppack));
      new->loc = at; working->next = new; working = new; at = seek; 
    } else { at = NULL; }
  }
  return ret;
}

static void strpack_clear(strpack *start,unsigned len) {
  strpack *zap; if(start) {
    for(;len--;) free(start[len].address); free(start); 
  }
}

static void gtenv_clear(GtmEnv *dmw) {
  if(dmw) {
    strpack_clear(dmw->prefix,dmw->pfx_elem); 
    if(dmw->errmsg)   free(dmw->errmsg);
    if(dmw->xfer_buf) free(dmw->xfer_buf);
    free(dmw); 
  }
  return;
}


MODULE = Db::GTM		PACKAGE = GTMDB

PROTOTYPES: ENABLE

GtmEnv *
new(...)
	ALIAS:
	  TIEHASH = 1
	  TIESCALAR = 2
	  GtmEnvPtr::sub  = 3
	CODE:
	{
	  strpack *strp, *gvnprefix; 
	  GtmEnv *setup = (GtmEnv *)calloc(1,sizeof(GtmEnv)), *sub; 
	  unsigned i,len=0,tlen=0,err=0; char *test;
#ifdef _GT_NEED_SIGFIX
	  sig_t sigint;
#endif

	  setup->errmsg   = (char *)calloc(1024,sizeof(char));	
	  setup->xfer_buf = (char *)calloc(_GT_MAX_BLOCKSIZE,sizeof(char));	
          setup->flags &= (ix == 0 || ix == 3) ? NO_WARN : TIED;
	  if(items > 256) { warn("Init fail; excessive prefixes...\n"); err++; }
	  else if(items < 2) { warn("Init fail; no prefix given...\n"); err++; }
	  else {
	    if(ix == 3 && sv_isa(ST(0),"GtmEnvPtr") ) {
	      sub = (GtmEnv *)SvIV((SV*)SvRV(ST(0))); 
              len = sub->pfx_elem; tlen = sub->pfx_length;
	    } else {
              test = (char *)SvPV(ST(1),i); len = 0; tlen = 0;
	      if(!((*test>='a' && *test<='z')||(*test>='A' && *test<='Z'))) {
	        warn("Init fail; invalid starting prefix character.\n"); err++;
	      } 
	    }
	    setup->prefix = (strpack *)calloc(items+len-1,sizeof(strpack));
	    if(ix==3&&sv_isa(ST(0),"GtmEnvPtr")) for(i=sub->pfx_elem;i--;) {
	      strp = &sub->prefix[i]; gvnprefix = &setup->prefix[i];
	      gvnprefix->length = strp->length; gvnprefix->num = strp->num;
	      gvnprefix->address=(char *)calloc(strp->length+1,sizeof(char));
	      memcpy(gvnprefix->address, strp->address, strp->length);
	    }
	    for(i=1;i<items;i++) {
	      strp = &setup->prefix[i-1+len];
              test = (char *)SvPV(ST(i), strp->length);
              strp->address = (char *)calloc((strp->length)+1,sizeof(char));
	      memcpy(strp->address, test, strp->length);
	      strp->num = is_number(strp->address);
	      if(!strp->length) { warn("Init fail; null subscript.\n"); err++; }
              else tlen += strp->length;
	    }
            setup->pfx_elem = (items+len-1); setup->pfx_length = tlen; 
	    if(tlen > _GT_MAX_GVNLENGTH) { 
              warn("Init fail; prefix too long...\n"); err++; 
            }
	    if(err) { gtenv_clear(setup); }
          } 
          if(!err) { 
	    if(!_GTMinvoc) { // Save terminal settings to restore during END()
#ifdef _GT_NEED_TERMFIX
              _GTMterm = (struct termios *)calloc(1,sizeof(struct termios));
	      tcgetattr(STDIN_FILENO, _GTMterm);
#endif
#ifdef _GT_NEED_SIGFIX
	      sigint = signal(SIGINT, SIG_DFL); // Save SIGINT handler
#endif
	      setenv("GTMCI",_GT_GTMCI_LOC,0);
	      setenv("gtmroutines",_GT_GTMRTN_LOC,0);
	      setenv("gtmgbldir",_GT_GTMGBL_LOC,0);

              setup->last_err = gtm_init(); 
#ifdef _GT_NEED_SIGFIX
	      signal(SIGINT, sigint); // Restore SIGINT handler
#endif
            } else setup->last_err = 0;
            if(setup->last_err) { 
	      err_gtm(setup); gtenv_clear(setup); XSRETURN_UNDEF; 
	    } else { 
	      _GTMinvoc++; setup->gtmEnvId = _GTMinvoc; RETVAL = setup; 
            }
	  } else XSRETURN_UNDEF;
	}
	OUTPUT:
	RETVAL

void
gvn2list(...)
	ALIAS:
	  _str2list = 1
	  GTM::gvn2list  = 2
	  GTM::_str2list  = 3
	  GtmEnvPtr::gvn2list  = 4
	  GtmEnvPtr::_str2list  = 5
	PPCODE:
	{
          cppack *start = NULL, *next; SV *ret; unsigned s , x; char *glvn;
	  s = (ix < 4) ? 0 : 1; if(items < s) XSRETURN_UNDEF; 
	  start = unpackgvn( SvPV(ST(s),x) ); while(start) {
	    ret = sv_newmortal(); sv_setpv(ret, start->loc); XPUSHs(ret);
	    next = start->next; free(start); start = next;
          }
	}

void
list2gvn(...)
	ALIAS:
	  _list2str = 1
	  GTM::list2gvn = 2
	  GTM::_list2str = 3
	  GtmEnvPtr::list2gvn = 4
	  GtmEnvPtr::_list2str = 5
	  GtmEnvPtr::node = 6
	PPCODE:
	{
	  strpack *args; 
	  GtmEnv *pfx = (ix<4) ? NULL : (GtmEnv *)SvIV((SV*)SvRV(ST(0)));
	  unsigned i,s = (ix<4) ? 0 : 1, n; SV *ret;
	  gtm_string_t value, glvn;

	  EXTEND(SP,1); if(items>s) {
	    args = (strpack *)calloc(items-s,sizeof(strpack));
            for(i=s;i<items;i++) 
              args[i-s].address = (char *)SvPV(ST(i),args[i-s].length);
	    n=packgvn(pfx,items-s,args,(ix<4)?NO_PREFIX:0,&glvn); free(args); 
	  } else { n = packgvn(pfx,0,NULL,0,&glvn); }
	  if(glvn.address) { 
	    ret = sv_newmortal(); sv_setpv(ret, glvn.address); PUSHs(ret);
	    if(n) free(glvn.address);
	  } else PUSHs(&PL_sv_undef); 
	}

void
END()
	PPCODE:
	{
	   if( _GTMinvoc ) {
	     gtm_exit();
#ifdef _GT_NEED_TERMFIX
	     tcsetattr(STDIN_FILENO,0,_GTMterm); free(_GTMterm); 
#endif
	     _GTMinvoc = 0;
           }
	}

MODULE = Db::GTM		PACKAGE = GtmEnvPtr

void
DESTROY(gt_env)
	GtmEnv *gt_env
	PPCODE:
	{
	   gtenv_clear(gt_env);
	}

void
get(gt_env,...)
	GtmEnv *gt_env
	ALIAS:
	  retrieve = 1
	  FETCH = 2
	  EXISTS = 3
	  exists = 4
	PPCODE:
	{
	  strpack *args; unsigned i; 
	  unsigned long exst=0,n; gtm_string_t value,glvn; 
	  SV *ret=sv_newmortal(); EXTEND(SP, 1);

          if( GIMME_V==G_VOID ) XSRETURN_UNDEF; if(items>1) { 
            args = (strpack *)calloc(items-1,sizeof(strpack));
	    for(i=1;i<items;i++) 
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
	    n=packgvn(gt_env,items-1,args,(gt_env->flags & TIED),&glvn);
            free(args); 
	  } else { n=packgvn(gt_env,0,NULL,0,&glvn); }
	  if(glvn.address) {
	    value.address = gt_env->xfer_buf;
	    gt_env->last_err=gtm_ci("get",&value,&glvn,&exst);
            if(n) free(glvn.address); 
	
            if(gt_env->last_err) { err_gtm(gt_env); PUSHs(&PL_sv_undef); }
            else if(ix == 3 || ix == 4) PUSHs(newSViv(exst ? 1 : 0));
            else if(ix == 5)            PUSHs(newSViv(exst > 1 ? 1 : 0));
            else if(exst == 0 || exst == 10) PUSHs(&PL_sv_undef); 
	    else { sv_setpvn(ret, value.address, value.length); PUSHs(ret); } 
          }   else PUSHs(&PL_sv_undef); // Bad GVN name
	}

void
set(gt_env,...)
	GtmEnv *gt_env
	ALIAS:
	  store = 1
	  STORE = 2
	PPCODE:
	{
	  strpack *args; unsigned i,n; gtm_string_t glvn;

	  if(items>2) {
	    args = (strpack *)calloc(items-2,sizeof(strpack));
	    for(i=1;i<(items-1);i++) 
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
	    n=packgvn(gt_env,items-2,args,(gt_env->flags & TIED),&glvn);
            free(args); 
	  } else { n=packgvn(gt_env,0,NULL,0,&glvn); }
	  EXTEND(SP,1); if(glvn.address) {
            if(inTxn(gt_env)) {
	      gt_env->last_err = gtm_ci("txset", &glvn,
                                        (char *)SvPV(ST(items-1),i),
					gt_env->gtmEnvId
                                       );
            } else {
	      gt_env->last_err=gtm_ci("set",&glvn,(char *)SvPV(ST(items-1),i));
            }
	    if(n) free(glvn.address); if(gt_env->last_err) {
	      err_gtm(gt_env); 
	      XPUSHs(newSViv(gt_env->last_err)); // GTM error
	    } else XPUSHs(newSViv(0)); // Set OK
          }   else XPUSHs(newSViv(1)); // Bad GVN name
	}

void
order(gt_env,...)
	GtmEnv *gt_env
	ALIAS:
	  next = 1
	  NEXTKEY = 2
	  first = 3
	  FIRSTKEY = 4
	  haschildren = 5
	  last = 6
	  revorder = 7
	  prev = 8
	PPCODE:
	{
	  strpack *args,*x; unsigned i, aq=0,n; int dir=(ix>5)?-1:1; SV *ret;
	  char *addquot=""; gtm_string_t value, glvn;

          if( GIMME_V==G_VOID ) XSRETURN_UNDEF;
	  if(items==1 || (ix>2 && ix<7) ) { items++; aq++; }
	  args = (strpack *)calloc(items-1,sizeof(strpack));
          for(i=1;i<(items-aq);i++) 
            args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
	  if(aq) { args[items-2].address = addquot; args[items-2].length  = 0; }
	  n=packgvn(gt_env,items-1,args,ZEROLEN_OK|(gt_env->flags&TIED),&glvn);
          free(args); EXTEND(SP,1); if(glvn.address) {
	    value.address = gt_env->xfer_buf;
	    gt_env->last_err = gtm_ci("order",&value,&glvn,dir);
	    if(gt_env->last_err) { err_gtm(gt_env); PUSHs(&PL_sv_undef); } 
            else if(!value.length && GIMME_V==G_ARRAY) ; // Nothing to do
            else if(!value.length) PUSHs(&PL_sv_undef); 
	    else if(ix == 5) PUSHs(newSViv(1)); 
            else {
              if( GIMME_V==G_ARRAY ) {
                EXTEND(SP,items-1); for(i=1;i<(items-1);i++) PUSHs(ST(i));
              }
              PUSHs(newSVpvn(value.address, value.length));
            }
	    if(n) free(glvn.address); 
          } else PUSHs(&PL_sv_undef); // Bad GVN name
	}

void
kill(gt_env,...)
	GtmEnv *gt_env
	ALIAS:
	  DELETE = 1
	  CLEAR = 2
	  ks = 3
	  kv = 4
	PPCODE:
	{
	  strpack *args; unsigned i,n; gtm_string_t glvn;

          if(items>1) {
	    args = (strpack *)calloc(items-1,sizeof(strpack));
            for(i=1;i<items;i++) 
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
	    n = packgvn(gt_env,items-1,args,(gt_env->flags & TIED),&glvn); 
            free(args); 
	  } else { n = packgvn(gt_env,0,NULL,0,&glvn); }
	  EXTEND(SP,1); if(glvn.address) {
            if(inTxn(gt_env)) {
              i = (gtm_long_t)gt_env->gtmEnvId;
	      switch(ix) {
	        case 0: case 1: case 2:
                        gt_env->last_err = gtm_ci("txkill",&glvn,i); break;
	        case 3: gt_env->last_err = gtm_ci("txks",&glvn,i);   break;
	        case 4: gt_env->last_err = gtm_ci("txkv",&glvn,i);   break;
	        default: break;
	      }
            } else {
	      switch(ix) {
	        case 0: case 1: case 2:
                        gt_env->last_err = gtm_ci("kill",&glvn); break;
	        case 3: gt_env->last_err = gtm_ci("ks",&glvn);   break;
	        case 4: gt_env->last_err = gtm_ci("kv",&glvn);   break;
	        default: break;
	      }
            }
	    if(n) free(glvn.address); if(gt_env->last_err) {
	      err_gtm(gt_env); PUSHs(newSViv(gt_env->last_err));
	    } else PUSHs(newSViv(0)); // Kill OK
          }   else PUSHs(newSViv(1)); // Bad GVN name
	}

void
query(gt_env,...)
	GtmEnv *gt_env
	PPCODE:
	{
	  SV *ret; char **brk; 
	  strpack *args; cppack *start=NULL,*next; gtm_string_t value, glvn;
	  unsigned i,z,n; 

          if( GIMME_V==G_VOID ) XSRETURN_UNDEF; if(items>1) {
	    args = (strpack *)calloc(items-1,sizeof(strpack));
	    for(i=1;i<items;i++) 
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
	    n=packgvn(gt_env,items-1,args,0,&glvn); free(args); 
	  } else { n = packgvn(gt_env,0,NULL,0,&glvn); }
	  if(glvn.address) {
	    value.address = gt_env->xfer_buf;
	    gt_env->last_err = gtm_ci("query",&value,&glvn);
	    if(n) free(glvn.address); if(gt_env->last_err) {
              err_gtm(gt_env); XPUSHs(&PL_sv_undef);
	    } else {
	      value.address[value.length] = '\0'; 
	      start = unpackgvn(value.address); z=0; 
	        for(i=(gt_env->pfx_elem);i--;) {
		if(!start && 
	            strncmp(start->loc,
                            gt_env->prefix[i].address,
                            gt_env->prefix[i].length) 
                  ) z++;
		if(start) { next = start->next; free(start); start = next; }	
	      }
	      if(z) { // We're not in kansas anymore
		while(start) { next = start->next; free(start); start = next; }
	      } else while(start) {
	        ret = sv_newmortal(); sv_setpv(ret, start->loc); XPUSHs(ret);
		next = start->next; free(start); start = next;
              }
	    }
          } else XPUSHs(&PL_sv_undef);
	}

void
children(gt_env,...)
	GtmEnv *gt_env
	PPCODE:
	{
          char *end="\")\x00\x00",*loc; unsigned count=0,n,kids=0,base;
	  strpack *args; gtm_string_t value,glvn,buf; 

          if( GIMME_V==G_VOID ) XSRETURN_UNDEF;
	  buf.address = (char *)calloc(_GT_MAX_GVNLENGTH+5,sizeof(char));
	  if(items>1) {
	    unsigned i; items--;
            args = (strpack *)calloc(items,sizeof(strpack));
	    for(i=0;i<items;i++) 
              args[i].address = (char *)SvPV(ST(i+1),args[i].length);
	    n=packgvn(gt_env,items,args,0,&glvn); free(args); 
	  } else { n = packgvn(gt_env,0,NULL,0,&glvn); }
	  if(glvn.address) {
            count=glvn.length-1; 
            memcpy(buf.address,glvn.address,count); loc=buf.address+count-1; 
            if( buf.address[count-1] == ')' ) { *loc = ','; loc++; }
	    else { loc++; *loc = '('; loc++; }
            sprintf(loc,"\"\")"); loc++; value.address = loc;
	    base=(unsigned)(loc - buf.address); buf.length = base+2;
	   
	    gt_env->last_err = gtm_ci("order",&value,&buf,1); 
            unsigned wantarray=(GIMME_V==G_ARRAY); 
	    while(!gt_env->last_err && value.length) {
              if(wantarray) XPUSHs(newSVpvn(value.address, value.length));
	      kids++; memcpy(value.address+value.length, end, 4);
	      buf.length = base + value.length + 2;
	      gt_env->last_err = gtm_ci("order",&value,&buf,1); 
            }
	    if(gt_env->last_err) err_gtm(gt_env); if(n) free(glvn.address);
          }
	  free(buf.address); if(GIMME_V == G_SCALAR) XPUSHs(newSViv(kids));
	}

void
copy(...)
	ALIAS:
	  GTM::copy  = 4
	  GTMDB::copy  = 8
	  merge = 1
	  GTM::merge  = 5
	  GTMDB::merge  = 9
	  clobber = 2
	  GTM::clobber = 6
	  GTMDB::clobber = 10
	  overwrite = 3
	  GTM::overwrite = 7
	  GTMDB::overwrite = 11
	PPCODE:
	{
	  strpack *args; unsigned i,mid=0,ov=(ix & 2)?1:0,ob=(ix<4)?1:0,s=1,d=1;
	  GtmEnv *gt_env = (ob) ? (GtmEnv *)SvIV((SV*)SvRV(ST(0))) : NULL;
	  gtm_string_t src, dst; unsigned fs, fd; strpack value; SV *ret;

	  EXTEND(SP,1); if(items == (ob+2)) { 
	    // Two arguments passed in...
	    // They could either be GtmEnvPtrs (PERL GTMDB objects)
	    //   or they could be global names like ^FOO("BAR"), or both
	    if(!sv_isa(ST(ob),"GtmEnvPtr")) { 
              fs=0; src.address=(char *)SvPV(ST(ob),src.length);
            } else fs=packgvn((GtmEnv *)SvIV((SV*)SvRV(ST(ob))),0,NULL,0,&src);
	    if(!sv_isa(ST(ob+1),"GtmEnvPtr")) { 
              fd=0; dst.address=(char *)SvPV(ST(ob+1),dst.length);
            }else fd=packgvn((GtmEnv *)SvIV((SV*)SvRV(ST(ob+1))),0,NULL,0,&dst);

	  } else if(ob && items == 2 && sv_isa(ST(1),"GtmEnvPtr") ) {
            fs = packgvn((GtmEnv *)SvIV((SV*)SvRV(ST(1))),0,NULL,0,&src);
	    fd = packgvn(gt_env,0,NULL,0,&dst); 
	  } else if(items>ob) {
	    args = (strpack *)calloc(items-ob,sizeof(strpack)); fs = 1; fd = 1;
	    for(i=ob;i<items;i++) {
              args[i-ob].address = (char *)SvPV(ST(i),args[i-ob].length);
	      if(!args[i-ob].length && !mid) mid = i-ob;
	    }
	    if(!mid && ob) { // No target specified, assume it's us
	      packgvn(gt_env,items-1,args,0,&src); 
	      packgvn(gt_env,0,NULL,0,&dst); 
	    } else {
	      packgvn(gt_env,mid,args,0,&src); 
	      packgvn(gt_env,(items-(mid+1+ob)),&args[mid+1],0,&dst);
            }
            free(args); 
	  }
	  if(src.address && dst.address) {
            if(inTxn(gt_env)) {
              i = gt_env->gtmEnvId;
	      if(!ov) gt_env->last_err = gtm_ci("txcopy",&src,&dst,i); 
	      else    gt_env->last_err = gtm_ci("txclone",&src,&dst,i); 
            } else {
	      if(!ov) gt_env->last_err = gtm_ci("copy",&src,&dst); 
	      else    gt_env->last_err = gtm_ci("clone",&src,&dst); 
            }
	    if(gt_env->last_err) { 
	      err_gtm(gt_env); PUSHs(newSViv(gt_env->last_err)); 
            } else PUSHs(newSViv(0));
	  } else PUSHs(newSViv(1)); // Bad GVN name(s)
	  if(fs && src.address) free(src.address); 
          if(fd && dst.address) free(dst.address); 
	}

void
txnstart(gt_env)
	GtmEnv *gt_env
	ALIAS:
	  txnabort = 1
	  txncommit = 2
	PPCODE:
	{
	  EXTEND(SP,1); switch(ix) {
            case 0: gt_env->flags |= IN_TXN; break;
            case 1: if(inTxn(gt_env)) {
		      gt_env->last_err = gtm_ci("tabort",gt_env->gtmEnvId); 
		      gt_env->flags -= IN_TXN;
		    }
                    break;
            case 2: if(inTxn(gt_env)) {
		      gt_env->last_err = gtm_ci("tcommit",gt_env->gtmEnvId); 
		      if(!gt_env->last_err) gt_env->flags -= IN_TXN;
                    }
		    break;
	  }
	  if(gt_env->last_err) {
            err_gtm(gt_env); PUSHs(newSViv(gt_env->last_err)); // GTM error
          } else PUSHs(newSViv(0)); // Txn command OK
	}

void
lock(gt_env,...)
	GtmEnv *gt_env
	PPCODE:
	{
          strpack *args; unsigned i,n; gtm_string_t glvn;
	  gtm_long_t value, timeout = 0;

          if(items>1) {
            timeout = (gtm_long_t)SvIV(ST(items-1));
            args = (strpack *)calloc(items-2,sizeof(strpack));
            for(i=1;i<(items-1);i++)
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
            n=packgvn(gt_env,items-2,args,(gt_env->flags & TIED),&glvn);
            free(args);
          } else { n=packgvn(gt_env,0,NULL,0,&glvn); }

	  if(glvn.address) {
	    EXTEND(SP,1); 
            gt_env->last_err=gtm_ci("lock",&value,&glvn,timeout);
            if(n) free(glvn.address); 

	    if(!value) { 
              gt_env->last_err=1; PUSHs(newSViv(1));
              sprintf(gt_env->errmsg,"ERROR: Lock not obtained.");
            } else if(gt_env->last_err) {
              err_gtm(gt_env); PUSHs(newSViv(gt_env->last_err)); // GTM error
            } else PUSHs(newSViv(0)); // Lock OK
	  }
	}

void
unlock(gt_env,...)
	GtmEnv *gt_env
	PPCODE:
	{
          strpack *args; unsigned i,n; gtm_string_t glvn;

          if(items>1) {
            args = (strpack *)calloc(items-1,sizeof(strpack));
            for(i=1;i<items;i++)
              args[i-1].address = (char *)SvPV(ST(i),args[i-1].length);
            n=packgvn(gt_env,items-1,args,(gt_env->flags & TIED),&glvn);
            free(args);
          } else { n=packgvn(gt_env,0,NULL,0,&glvn); }

	  if(glvn.address) {
	    EXTEND(SP,1); gt_env->last_err=gtm_ci("unlock",&glvn);
            if(n) free(glvn.address); if(gt_env->last_err) {
              err_gtm(gt_env); PUSHs(newSViv(gt_env->last_err)); // GTM error
            } else PUSHs(newSViv(0));  // Unlock OK
	  }
	}

void
getid(gt_env)
	GtmEnv *gt_env
	PPCODE:
	{
	  XPUSHs(newSViv(gt_env->gtmEnvId));
	}

void
getprefix(gt_env)
	GtmEnv *gt_env
	PPCODE:
	{
          strpack *x; unsigned i; EXTEND(SP,gt_env->pfx_elem);
	  if(gt_env->prefix) for(i=0;i<(gt_env->pfx_elem);i++) {
	    x=&gt_env->prefix[i]; PUSHs(newSVpvn(x->address, x->length));
          }
	}
