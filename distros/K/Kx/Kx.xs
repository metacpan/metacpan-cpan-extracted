#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifndef KXVER
#define KXVER 3
#endif

#include "./k.h"

typedef struct k0 Kstruct;

#include "accessors-c.inc"
#include "const-c.inc"

MODULE = Kx		PACKAGE = Kx		

INCLUDE: accessors-xs.inc
INCLUDE: const-xs.inc

PROTOTYPES: ENABLE

int
khp(host,port)
	char * host
	int   port

int
khpu(host,port,userpass)
	char * host
	int   port
	char * userpass

Kstruct *
k(dbi,command)
	int  dbi
	char * command
  PREINIT:
    void *arg3 = 0;
  CODE:
    if(items != 2)
        croak("Kx::k(dbi,command)");
    RETVAL = k(dbi,command,arg3);
  OUTPUT:
    RETVAL

Kstruct *
k1(dbi,command,a1)
	int  dbi
	char * command
	Kstruct * a1
  PREINIT:
    void *end = 0;
  CODE:
	if(items != 3)
		croak("Kx::k1(dbi,command,K1) needs 3 args");
	r1(a1);
	RETVAL = k(dbi,command,a1,end);
  OUTPUT:
	RETVAL

Kstruct *
k2(dbi,command,a1,a2)
	int  dbi
	char * command
	Kstruct * a1
	Kstruct * a2
  PREINIT:
    void *end = 0;
  CODE:
	if(items != 4)
		croak("Kx::k2(dbi,command,K1,K2) needs 4 args");
	r1(a1);
	r1(a2);
	RETVAL = k(dbi,command,a1,a2,end);
  OUTPUT:
	RETVAL

Kstruct *
ktd(kobject)
	Kstruct * kobject

Kstruct *
ka(integer)
	int integer

Kstruct *
kb(integer)
	int integer

Kstruct *
kg(integer)
	int integer

Kstruct *
kh(integer)
	int integer

Kstruct *
ki(integer)
	int integer

Kstruct *
kj(longval)
	long long longval

Kstruct *
ke(realval)
	float realval

Kstruct *
kf(floatval)
	double floatval

Kstruct *
kc(charval)
	int charval

Kstruct *
ks(symbol)
	unsigned char * symbol

int
ymd(y,m,d)
	int y
	int m
	int d

Kstruct *
kd(date)
	int date

Kstruct *
kz(datetime)
	double datetime

Kstruct *
kt(time)
	int time

Kstruct *
ktn(type,length)
	int type
	int length

Kstruct *
knk(...)
  PREINIT:
	Kstruct *a[7];
	int i = 0;
  CODE:
	if(items > 8)
		croak("Kx::knk() can handle only upto 8 arguments");
	if(items < 1)
		croak("Kx::knk() needs at least one argument");
	for(;i < items; i++)
	{
            IV tmp = SvIV((SV*)SvRV(ST(i)));
            a[i] = INT2PTR(Kstruct *,tmp);
	}
	RETVAL = knk(items,a[0],a[1],a[2],a[3],a[4],a[5],a[6],a[7]);
  OUTPUT:
	RETVAL


Kstruct *
kp(symbol)
	unsigned char * symbol

Kstruct *
kpn(string,length)
	unsigned char * string
	int length

Kstruct *
ja(klist,atom)
	Kstruct ** klist
	void * atom

Kstruct *
js(klist,string)
	Kstruct ** klist
	unsigned char * string

Kstruct *
jk(klist,kobject)
	Kstruct ** klist
	Kstruct * kobject

Kstruct *
xT(dict)
	Kstruct * dict

Kstruct *
xD(keys,values)
	Kstruct * keys
	Kstruct * values

Kstruct *
r1(kobject)
	Kstruct * kobject

Kstruct *
krr(error)
	unsigned char * error

Kstruct *
orr(syserror)
	unsigned char * syserror

void
r0(kobject)
	Kstruct * kobject

