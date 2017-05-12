
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#define BUFFER_SIZE (8192)
#define BUFFER_2SIZE (BUFFER_SIZE*2)


typedef unsigned long t_myInt;

typedef struct ts_Data
{
  t_myInt mask, 
prime, 
maskbits, 
charcount, 
modulo;

  t_myInt values[256];
} t_Data;



MODULE = Digest::ManberHash         PACKAGE = Digest::ManberHash


SV*
Init(maskbits,prime, charcount)
	unsigned long maskbits
	unsigned long prime
	unsigned long charcount;
CODE:
  {
    t_Data *data;
    int i;
    t_myInt p;

    RETVAL=newSVpvf("%*s",sizeof(*data),"a");
    //	SvGROW(RETVAL,sizeof(*data));

    data=(t_Data*)SvPV_nolen(RETVAL);

    data->maskbits=maskbits;
    data->prime=prime;
    data->charcount=charcount;
    data->modulo=-1;
    data->mask= ~(-1 << maskbits);


    for(p=1,i=0; i<data->charcount; i++)
      p=(p * data->prime) & data->modulo;

    for(i=0; i<256; i++)
      data->values[i]=(i*p) & data->modulo;

  }
OUTPUT:
	RETVAL


int
ManberHash(set, filename, output)
        char *set
	char *filename
        SV *output
CODE:
  {
    int fh;
    t_myInt curr,last,prev;
    char buffer[BUFFER_2SIZE];
    int i,b2d,b2use,i_last,count,j;
    HV * hv;
    HE * he;
    SV *sv,**svp;
	t_Data *settings;
  char hex[11];

	RETVAL=0;
  if (SvTYPE(SvRV(output)) != SVt_PVHV)
  return;
 /*  if (SvTYPE(SvRV(set)) != SVt_PV)
   return;
 settings=(t_Data*)SVPV_nolen(SvRV(set));
  */
 settings=(t_Data*)set;
  memset(hex,0,sizeof(hex));


    /*
       if (strcmp(fn,"-")==0)
       {
       fp=stdin;
       }
       else
       {
       fp=fopen(fn,"rb");
       if (fp == NULL) 
       {
       fprintf(stderr,"Can't open '%s': %s (%d)\n",
       fn,strerror(errno),errno);
       exit(1);
       }
       }
     */

    fh=open(filename,O_RDONLY);
    if (fh<0) 
      return;

  //  printf("file opend\n");

    b2d=read(fh,buffer,BUFFER_2SIZE);
    b2use=0;

    if (b2d < settings->charcount)
      return;

    for(i=curr=0; i<settings->charcount; i++)
    {
      curr=curr*settings->prime + buffer[i];
    }
    last=prev=curr;
    i_last=0;
    b2d-=settings->charcount;

    hv=(HV*)SvRV(output);

    while (b2d>=0)
    {
      if (b2d == BUFFER_SIZE)
      {
	b2d += read(fh,buffer + (b2use ? BUFFER_SIZE : 0),BUFFER_SIZE);
	b2use = !b2use;
      }

      curr= ( curr * settings->prime + 
	  buffer[i] - 
	  settings->values[buffer[i_last]] ) 
	& settings->modulo;


      if (curr != last)
  {
      if ((curr & settings->mask) == 0)
      {
  sprintf(hex,"0x%08X",prev);
    //printf("found hash  %08X\n",curr);
	//      hash=curr >> settings->maskbits;
	svp=hv_fetch(hv, hex, sizeof(hex)-1, 1);
	if (!svp) return;
	 sv=*svp;
  if (SvIOK(sv))
	  count=SvIV(sv)+1;
  else
    count=1;

	sv_setiv(sv,count);

	  last=curr;
      }
    prev=curr;
  }


      i=(i+1) % BUFFER_2SIZE;
      i_last=(i_last+1) % BUFFER_2SIZE;
      b2d--;
    }

    close(fh);

  //   printf("finished hashing\n");

  //  XPUSHs( sv_2mortal(newRV_noinc((SV*)hv)));
	RETVAL=1;
  }
OUTPUT:
	RETVAL


