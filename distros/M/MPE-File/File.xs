#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "longptr.h"
#include "mpefile.h"
#include <mpe.h>
#include <limits.h>
/* #include <stdio.h>   /* STDIO for testing only */
#define MAXPARMS 41

/* static FILE *dbg; /* For testing  only */

static int mpestatus;
static int maxwaitreclen;
static int lastwaitfilenum;

#define ARRAYLIMIT 100
static int reclens[ARRAYLIMIT];
HV *hashreclen;

static void
setreclen(int file, int reclen)
{
  if (file >= 0 && file < ARRAYLIMIT) {
      reclens[file] = reclen;
  } else {
    SV *sreclen = newSViv(reclen);
    int hashkey=0;
    if (!hashreclen)
      hashreclen = newHV();
    hv_store(hashreclen, (char*)&file, sizeof(file), sreclen, hashkey);
  }
}



static void
seterrmpe(int status)
{
   int create=1;
   SV *exterr;
   char buffer[256];
   int buflength;
   short len;
   exterr = get_sv("MPE::File::MPE_error", create);
   if (status >= 0 && status <=65535) {
      short fserrorcode=status;
      FERRMSG(&fserrorcode, buffer, &len);
      buffer[len] = '\0';
   } else {
      int status1;
      len = sizeof(buffer) - 1;
      HPERRMSG(7, 3, 0, 0, status,
	                  buffer, &len, &status1);
      buffer[len] = '\0';
   }
   sv_setpvn(exterr, buffer, len);
   sv_setiv(exterr, status);
   SvPOK_on(exterr);
}

static int
getreclen(int file)
{
  int result=0;
  if (file >= 0 && file < ARRAYLIMIT) {
      result = reclens[file];
  } else {
    SV **val=NULL;
    if (hashreclen)
      val = hv_fetch(hashreclen, (char*)&file, sizeof(file), 0);
    if (val)
      result = SvIV(*val);
  }
  return result;
}

static void
savestats(int file)
{
  aoptions aopts;
  short shortreclen;
  int   reclen;
  int access;
  int chompout;
  int rectype;

  FFILEINFO(file, 3, &aopts, 4, &shortreclen, 67, &reclen,
	  90,&rectype,0, NULL);
  if (ccode() == CCE) {
    if (rectype == 9) {
       reclen = LINE_MAX;
    } else if (shortreclen) {
      if (shortreclen<0)
	reclen = - shortreclen;
      else
	reclen = 2 * shortreclen;
    }
    if (aopts.as.no_wait) {
      int access= aopts.as.access;
      if (access<1 || access > 3) {
	if (reclen > maxwaitreclen)
	  maxwaitreclen = reclen;
      }
    }
    setreclen(file, reclen);
  } else {
    /* who knows ? */
  }
}


MODULE = MPE::File		PACKAGE = MPE::File		
short
mpefopen(name, fopt, aopt)
    char *name
    short fopt
    short aopt
  PROTOTYPE: $$$
  CODE:
    RETVAL = FOPEN(name, fopt, aopt,0,0,0,0,0,0,0,0,0,0);
    if (ccode() != CCE) {
      short shorterr;
      FCHECK(RETVAL, &shorterr,0,0,0);
      seterrmpe(shorterr);
    } else {
      savestats(RETVAL);
    }
  OUTPUT:
    RETVAL
    

int
mpehpfopen(...)
   PROTOTYPE: $$;@
   PREINIT:
       int  extraitems;
       int  parm[MAXPARMS];
       char *parmval[MAXPARMS];
       char isalloced[MAXPARMS];
       int  intparms[MAXPARMS];
       int nparms;
       int itemsin;
       int i;
       int dummylen;
       int intfilenum;
       STRLEN len;
       SV *svparmval;
   CODE:
       itemsin = 0;
       intfilenum = 0;
       mpestatus = 0;
       
       for (nparms=0; nparms<MAXPARMS && itemsin<items; nparms++, itemsin+=2) {
	 parm[nparms] = sv_iv(ST(itemsin));
         svparmval = ST(itemsin+1);
	 switch (parm[nparms]) {
	   case  2:
	   case  8:
	   case 22:
	   case 23:
	   case 25:
	   case 26:
	   case 28:
	   case 31:
	   case 32:
	   case 42:
	   case 52:
	     isalloced[nparms] = 1;
	     New(413, parmval[nparms], 2+SvCUR(svparmval),char);
	     sprintf(parmval[nparms], "%c%s", 0, SvPVX(svparmval));
	     break;

	   case 43: /* UFID */
	   case 45: /* fill char */
	   case 51: /* Pascal string */
	   case 54: /* KSAM parm */
	     isalloced[nparms] = 0;
	     parmval[nparms] = SvPVX(svparmval);

	     break;


	   case 64:
	     isalloced[nparms] = 0;
	     parmval[nparms] = SvPVX(svparmval);
	     if (parmval[nparms][SvCUR(svparmval)] != '\r') {
	       isalloced[nparms] = 1;
	       New(413, parmval[nparms], 2+SvCUR(svparmval),char);
	       sprintf(parmval[nparms], "%s\r", SvPVX(svparmval));
	     } 
	     break;

	   case 18:
	   default:
	       isalloced[nparms] = 0;
	       parmval[nparms] = (char *)&intparms[nparms];
	       intparms[nparms] = SvIV(svparmval);

	 }
       }
       if (nparms < MAXPARMS) {
         parm[nparms] = 0;
       }
       HPFOPEN(2+2*nparms,
	    &intfilenum, &mpestatus,
	    parm[0],	parmval[0],
	    parm[1],	parmval[1],
	    parm[2],	parmval[2],
	    parm[3],	parmval[3],
	    parm[4],	parmval[4],
	    parm[5],	parmval[5],
	    parm[6],	parmval[6],
	    parm[7],	parmval[7],
	    parm[8],	parmval[8],
	    parm[9],	parmval[9],
	    parm[10],	parmval[10],
	    parm[11],	parmval[11],
	    parm[12],	parmval[12],
	    parm[13],	parmval[13],
	    parm[14],	parmval[14],
	    parm[15],	parmval[15],
	    parm[16],	parmval[16],
	    parm[17],	parmval[17],
	    parm[18],	parmval[18],
	    parm[19],	parmval[19],
	    parm[20],	parmval[20],
	    parm[21],	parmval[21],
	    parm[22],	parmval[22],
	    parm[23],	parmval[23],
	    parm[24],	parmval[24],
	    parm[25],	parmval[25],
	    parm[26],	parmval[26],
	    parm[27],	parmval[27],
	    parm[28],	parmval[28],
	    parm[29],	parmval[29],
	    parm[30],	parmval[30],
	    parm[31],	parmval[31],
	    parm[32],	parmval[32],
	    parm[33],	parmval[33],
	    parm[34],	parmval[34],
	    parm[35],	parmval[35],
	    parm[36],	parmval[36],
	    parm[37],	parmval[37],
	    parm[38],	parmval[38],
	    parm[39],	parmval[39],
	    parm[40],	parmval[40],
	    parm[41],	parmval[41]);

	  
	  /* freeing Memory */
	  for (i=0; i<nparms; i++) {
	    if (isalloced[i]) {
	      Safefree(parmval[i]);
	    }
	  }

	 /*
	  sv_setiv(filenum, intfilenum);
	  sv_setiv(status, mpestatus);
	  */
	  if (mpestatus) {
	    seterrmpe(mpestatus);
	  }

	  if (intfilenum) {
	    savestats(intfilenum);
	  }

	RETVAL = intfilenum;
   OUTPUT:
     RETVAL

int
mpeffileinfo(filenum, item1, item1o, item2, item2o, item3, item3o, item4, item4o, item5, item5o)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    short item1
    char *item1o
    short item2
    char *item2o
    short item3
    char *item3o
    short item4
    char *item4o
    short item5
    char *item5o
  CODE:
      FFILEINFO(filenum, item1, item1o, item2, item2o, item3, item3o, item4, item4o, item5, item5o);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  OUTPUT:
    RETVAL

int
mpeflabelinfo(name, mode, items, itemsout, itemerror)
    char *name
    short mode
    char *items
    char *itemsout
    char *itemerror
  CODE:
  {
    short fserr=0;
    FLABELINFO(name, mode, &fserr, items, itemsout, itemerror);
    if (fserr) {
      seterrmpe(fserr);
    }
    RETVAL = !fserr;
  }
  OUTPUT:
     RETVAL


int
mpe_fileno(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
    RETVAL = filenum;
  OUTPUT:
    RETVAL

SV *
readrec(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
  {
    short reclen = getreclen(filenum);
    char *buf = alloca(reclen);
    reclen = FREAD(filenum, longaddr(buf), -reclen);
    if (ccode() == CCE) {
      buf[reclen] = '\0';
      RETVAL = newSVpvn(buf, reclen);
    } else {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL

int
writerec(filenum, buffer, ...)
      short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
      SV *buffer
  CODE:
  {
     short cctl=0;
     int reclen;
     char *bufptr;
     if (items>2)
         cctl=SvIV(ST(2));
     bufptr = SvPV(buffer, reclen);
     if (reclen > 32767) {
       reclen /= 2;
     } else {
       reclen = -reclen;
     }
     FWRITE(filenum, longaddr(bufptr), (short)reclen, cctl);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  }
  OUTPUT:
    RETVAL



int
hperrmsg(displaycode,...)
    int displaycode
   PROTOTYPE: $;@
   CODE:
   {
      int depth=0;
      int errornum=0;
      SV *buffer=NULL;
      char *pbuf;
      short buflength=0;
      int status=0;
      int parm_ct;
      if (items>1) {
	depth = SvIV(ST(1));

	if (items > 3) {
	  errornum = SvIV(ST(3));
	  if (items > 4) {
	    buffer = ST(4);
	    if (items == 5) {
	      buflength = 256;
	    } else {
	      buflength = SvIV(ST(5));
	    }
	  }
	}
      }

       if (buffer == NULL || SvREADONLY(buffer)) {
         pbuf = NULL;
       } else {
         int dummylen;
	 SvPV_force(buffer, dummylen);
	 pbuf = SvGROW(buffer, buflength+1);
       }

	parm_ct = items;

   	HPERRMSG(parm_ct, displaycode, depth, 0, errornum,
	                  pbuf, &buflength, &status);
	if (buflength) {
	  pbuf[buflength] = '\0';  
	  SvPOK_on(buffer);
	  SvCUR_set(buffer, buflength);
	}
	if (items==7) {
	  sv_setiv(ST(6), status);
	}
	if (status) {
	  seterrmpe(status);
	}
	RETVAL = !status;
   }
   OUTPUT:
     RETVAL

int
fread(filenum, buffer, bufsize)
       short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
       SV *buffer
       short bufsize
   PROTOTYPE: $$$
   CODE:
   {
     int tmplen;
     longpointer lpbuf;
     int dummylen;
     if (bufsize < 0)
       tmplen = -bufsize;
     else
       tmplen = 2 * bufsize;
     SvPV_force(buffer, dummylen);
     SvGROW(buffer, tmplen);
     lpbuf = longaddr(SvPVX(buffer));

     RETVAL = FREAD(filenum, lpbuf, bufsize);
     if (ccode() != CCE) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
     }
     SvCUR_set(buffer, RETVAL);
  }
  OUTPUT:
       RETVAL

int
ccode()

 
int
fcheck(...)
  CODE:
  {
    short filenum=0;
    short fserrorcode;
    short translog;
    int   blocknum;
    short numrecs;

    if (items > 0) {
      filenum = SvIV(SvROK(ST(0))?SvRV(ST(0)):ST(0));
    }
    FCHECK(filenum,&fserrorcode,&translog,&blocknum,&numrecs);
    RETVAL = (ccode() == CCE);

    if (items>1) {
      if (!SvREADONLY(ST(1)))
	  sv_setiv(ST(1), fserrorcode);
      if (items>2) {
	if (!SvREADONLY(ST(2)))
	    sv_setiv(ST(2), translog);
	if (items>3) {
	  if (!SvREADONLY(ST(3)))
	      sv_setiv(ST(3), blocknum);
	  if (items>4) {
	    if (!SvREADONLY(ST(4)))
		sv_setiv(ST(4), numrecs);
	  }
	}
      }
    }
  }
  OUTPUT:
    RETVAL

int
fwrite(filenum, buffer, length, controlcode)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    char  *buffer
    short length
    short controlcode
  PROTOTYPE: $$$$
  CODE:
    FWRITE(filenum, longaddr(buffer), length, controlcode);
    RETVAL = (ccode() == CCE);
    if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL


int
mpeprint(buffer, ...)
    SV  *buffer
  PROTOTYPE: $;$$
  CODE:
    int length;
    short cctl=0;
    char *bufptr=SvPV(buffer, length);

    if (items>1 && SvIOK(ST(1))) {
      length=SvIV(ST(1));
    } else {
      length = -length;
    }
    if (items>2 && SvIOK(ST(2))) {
      cctl=SvIV(ST(2));
    }
    PRINT(longaddr(bufptr), (short)length, cctl);
    RETVAL = (ccode() == CCE);
    if (!RETVAL) {
       short shorterr;
       FCHECK(0, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL


SV *
printopreply (buffer)
    SV  *buffer
  PROTOTYPE: $
  CODE: 
  {
    int length;
    char *bufptr=SvPV(buffer, length);
    char reply[32];
    short lenread;

    memset(reply, 0, sizeof reply);

    lenread=PRINTOPREPLY(bufptr, -(short)length, 0, reply, 31);
    if (ccode() != CCE) {
       short shorterr;
       FCHECK(0, &shorterr,0,0,0);
       seterrmpe(shorterr);
	RETVAL = &PL_sv_undef;
    } else {
      reply[lenread] = '\0';
      RETVAL = newSVpvn(reply, lenread);
    }
  }
  OUTPUT:
    RETVAL

int
printop(buffer, ...)
    SV  *buffer
  PROTOTYPE: $;$$
  CODE:
    int length;
    short cctl=0;
    char *bufptr=SvPV(buffer, length);

    if (items>1 && SvIOK(ST(1))) {
      length=SvIV(ST(1));
    } else {
      length = -length;
    }
    if (items>2 && SvIOK(ST(2))) {
      cctl=SvIV(ST(2));
    }
    PRINTOP(bufptr, (short)length, cctl);
    RETVAL = (ccode() == CCE);
    if (!RETVAL) {
       short shorterr;
       FCHECK(0, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL



int
fclose(filenum, disposition, securitycode)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    short disposition
    short securitycode
  PROTOTYPE: $$$
  CODE:
    FCLOSE(filenum, disposition, securitycode);
    RETVAL = (ccode() == CCE);
    if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL


int
flock(filenum, lockflag)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    unsigned short lockflag
  PROTOTYPE: $$
  CODE:
    FLOCK(filenum, lockflag);
    RETVAL = (ccode() == CCE);
    if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL

int
funlock(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  PROTOTYPE: $
  CODE:
    FUNLOCK(filenum);
    RETVAL = (ccode() == CCE);
    if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL

int
fpoint(filenum,lrecnum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    int lrecnum
  PROTOTYPE: $$
  CODE:
    FPOINT(filenum, lrecnum);
    RETVAL = (ccode() == CCE);
    if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
  OUTPUT:
       RETVAL


int
fcontrol(filenum,itemnum,item)
  short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  short itemnum
  SV  *item
  PROTOTYPE: $$$
  CODE:
  {
    unsigned short sitem=SvIV(item);
    FCONTROL(filenum,itemnum,longaddr(&sitem));
    RETVAL = (ccode() == CCE);
    if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
    }
    if (sitem != SvIV(item))
      sv_setiv(item, sitem);
  }
  OUTPUT:
    RETVAL

int
fdelete(filenum, ...)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  PROTOTYPE: $;@
  CODE:
  {
     long lrecnum=-1;
     if (items>1)
         lrecnum=SvIV(ST(1));
     FDELETE(filenum, lrecnum);
     RETVAL = (ccode() == CCE);
     if (RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
     }
  }
  OUTPUT:
    RETVAL



SV *
ferrmsg(fserrorcode)
    int fserrorcode
  PROTOTYPE: $
  CODE:
    if (fserrorcode >= 0 && fserrorcode <=65535) {
      short shorterr=fserrorcode;
      char buffer[74];
      short len;
      FERRMSG(&shorterr, buffer, &len);
      buffer[len] = '\0';
      RETVAL = newSVpvn(buffer, len);
    } else {
      char buffer[256];
      short  buflength = sizeof(buffer) - 1;
      int status;
      HPERRMSG(7, 3, 0, 0, fserrorcode,
	                  buffer, &buflength, &status);
      buffer[buflength] = '\0';  
      RETVAL = newSVpvn(buffer, buflength);
    }
  OUTPUT:
    RETVAL


void
printfileinfo(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  PROTOTYPE: $
  CODE:
    PRINTFILEINFO(filenum);


SV *
iowait(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
  {
     short reclen;
     char *buf;
     if (filenum == 0) {
        reclen = maxwaitreclen;
     } else {
       reclen = getreclen(filenum);
     }
     buf = alloca(reclen);
     lastwaitfilenum = IOWAIT(filenum, longaddr(buf), &reclen, 0);
     if (ccode() == CCE) {
       RETVAL = newSVpvn(buf, reclen);
     } else {
      short shorterr;
      FCHECK(lastwaitfilenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL
 
SV *
iodontwait(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
  {
     short reclen;
     char *buf;
     if (filenum == 0) {
        reclen = maxwaitreclen;
     } else {
       reclen = getreclen(filenum);
     }
     buf = alloca(reclen);
     lastwaitfilenum = IODONTWAIT(filenum, longaddr(buf), &reclen, 0);
     if (ccode() == CCE) {
       RETVAL = newSVpvn(buf, reclen);
     } else {
      short shorterr;
      FCHECK(lastwaitfilenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL
 
int
mpe_iowait(filenum,buffer,length,cstation)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    SV *buffer
    SV *length
    SV *cstation
  PROTOTYPE: $$$$
  CODE:
  {
    longpointer lpbuf = longaddr(SvPVX(buffer));
    short _length;
    short _cstation;
    IOWAIT(filenum, lpbuf, &_length, &_cstation);
    RETVAL = (ccode() == CCE);
    if (!RETVAL) {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
    }
    SvCUR_set(buffer, _length);
    sv_setiv(length, _length);
    sv_setiv(cstation, _cstation);
  }
  OUTPUT:
    RETVAL

int
mpe_iodontwait(filenum,buffer,length,cstation)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    SV *buffer
    SV *length
    SV *cstation
  PROTOTYPE: $$$$
  CODE:
  {
    longpointer lpbuf = longaddr(SvPVX(buffer));
    short _length;
    short _cstation;
    IODONTWAIT(filenum, lpbuf, &_length, &_cstation);
    RETVAL = (ccode() == CCE);
    if (!RETVAL) {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
    }
    SvCUR_set(buffer, _length);
    sv_setiv(length, _length);
    sv_setiv(cstation, _cstation);
  }
  OUTPUT:
    RETVAL



int
ffindbykey( filenum,value,location,length,relop)
       short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
       char *value
       short location
       short length
       short relop
   CODE:
     FFINDBYKEY(filenum, longaddr(value), location, length, relop);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
   OUTPUT:
     RETVAL



int
fgetkeyinfo(filenum, param, control)
       short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
       SV *param
       SV *control
    CODE:
    {
      int dummylen;
      SvPV_force(param, dummylen);
      SvGROW(param, 162);
      SvPV_force(control, dummylen);
      SvGROW(control, 256);
      FGETKEYINFO(filenum, SvPVX(param), SvPVX(control));
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
    }
   OUTPUT:
     RETVAL


SV *
freaddir(filenum, lrecnum)
     short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
     int lrecnum
  CODE:
  {
    short reclen = getreclen(filenum);
    char *buf = alloca(reclen);
    FREADDIR(filenum, longaddr(buf), -reclen, lrecnum);
    if (ccode() == CCE) {
      buf[reclen] = '\0';
      RETVAL = newSVpvn(buf, reclen);
    } else {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL


SV *
freadlabel(filenum, ...)
     short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
  {
    short labelid;
    char *buf = alloca(257);
    FREADLABEL(filenum, longaddr(buf), 128, labelid);
    if (items>2)
	 labelid=SvIV(ST(2));
    if (ccode() == CCE) {
      buf[256] = '\0';
      RETVAL = newSVpvn(buf, 256);
    } else {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL


int
fremove(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
     FREMOVE(filenum);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  OUTPUT:
    RETVAL


int
fsetmode(filenum, modeflags)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
    unsigned short modeflags;
  CODE:
     FSETMODE(filenum, modeflags);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  OUTPUT:
    RETVAL


int
fwritedir(filenum, buffer, lrecnum)
      short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
      SV *buffer
      int lrecnum
  CODE:
  {
     short cctl=0;
     short reclen;
     if (SvCUR(buffer) > 32767) {
       reclen = SvCUR(buffer)/2;
     } else {
       reclen = -SvCUR(buffer);
     }
     FWRITEDIR(filenum, longaddr(SvPVX(buffer)), reclen, lrecnum);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  }
  OUTPUT:
    RETVAL



int
fupdate(filenum, buffer)
      short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
      SV *buffer
  CODE:
  {
     short cctl=0;
     short reclen;
     if (SvCUR(buffer) > 32767) {
       reclen = SvCUR(buffer)/2;
     } else {
       reclen = -SvCUR(buffer);
     }
     FUPDATE(filenum, longaddr(SvPVX(buffer)), reclen);
     RETVAL = (ccode() == CCE);
     if (!RETVAL) {
       short shorterr;
       FCHECK(filenum, &shorterr,0,0,0);
       seterrmpe(shorterr);
       mpestatus = shorterr;
     }
  }
  OUTPUT:
    RETVAL


SV *
freadbykey(filenum, key, keyloc)
     short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
     char *key
     short keyloc
  CODE:
  {
    short reclen = getreclen(filenum);
    char *buf = alloca(reclen);
    reclen = FREADBYKEY(filenum, longaddr(buf), -reclen, 
	               longaddr(key), keyloc);
    if (ccode() == CCE) {
      buf[reclen] = '\0';
      RETVAL = newSVpvn(buf, reclen);
    } else {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL


SV *
freadc(filenum)
    short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
  CODE:
  {
    short reclen = getreclen(filenum);
    char *buf = alloca(reclen);
    reclen = FREAD(filenum, longaddr(buf), -reclen);
    if (ccode() == CCE) {
      buf[reclen] = '\0';
      RETVAL = newSVpvn(buf, reclen);
    } else {
      short shorterr;
      FCHECK(filenum, &shorterr,0,0,0);
      seterrmpe(shorterr);
      RETVAL = &PL_sv_undef;
    }
  }
  OUTPUT:
    RETVAL

int
lastwaitfilenum()
  CODE:
    RETVAL = lastwaitfilenum;
  OUTPUT:
    RETVAL

int
fwritelabel(filenum, svbuf, ...)
      short filenum = SvIV(SvROK($arg)?SvRV($arg):$arg);
      SV *svbuf
    CODE:
    {
      int len;
      short labelid=0;
      char *buf = SvPV(svbuf, len);
      if (items>2)
	   labelid=SvIV(ST(2));
      if (len>256) {
	len = 128;
      } else {
	len = (1+len)/2;
      }
      FWRITELABEL(filenum, longaddr(buf), len, labelid);
      RETVAL = (ccode() == CCE);
      if (!RETVAL) {
        short shorterr;
        FCHECK(filenum, &shorterr,0,0,0);
        seterrmpe(shorterr);
        mpestatus = shorterr;
      }
    }
  OUTPUT:
    RETVAL
