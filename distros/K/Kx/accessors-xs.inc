
unsigned char
kChar(x)
	Kstruct * x

short *
kShort(x)
	Kstruct * x

int *
kInt(x)
	Kstruct * x

long long *
kLong(x)
	Kstruct * x

float *
kReal(x)
	Kstruct * x

double *
kFloat(x)
	Kstruct * x

char *
kSymbol(x)
	Kstruct * x

Kstruct *
kStruct(x)
	Kstruct * x

Kstruct *
kStructi(x,i)
	Kstruct * x
	int i

int
kNum(x)
	Kstruct * x

int
kRefCnt(x)
	Kstruct * x

short
kType(x)
	Kstruct * x

short
kAtt(x)
	Kstruct * x

Kstruct *
kTable(c, cmd)
    int c
	char * cmd

Kstruct *
Ktd(x)
	Kstruct * x

Kstruct *
kTableH(x)
	Kstruct * x

Kstruct *
kTableCols(x)
	Kstruct * x

int
kTableNumCols(x)
	Kstruct * x

int
kTableNumRows(x)
	Kstruct * x

SV *
kTableIndex(x,row,col)
	Kstruct * x
	int row
	int col

SV *
k2pscalar0 (x)
	Kstruct * x

SV *
k2pscalar (x)
	Kstruct * x

AV *
k2parray0(x)
	Kstruct * x
	CODE:
		RETVAL = k2parray0(x);
		sv_2mortal((SV*)RETVAL);
	OUTPUT:
		RETVAL

AV *
k2parray(x)
	Kstruct * x
	CODE:
		RETVAL = k2parray(x);
		sv_2mortal((SV*)RETVAL);
	OUTPUT:
		RETVAL

HV *
k2phash(x)
	Kstruct * x
	CODE:
		RETVAL = k2phash(x);
		sv_2mortal((SV*)RETVAL);
	OUTPUT:
		RETVAL

HV *
k2phash0(x)
	Kstruct * x
	CODE:
		RETVAL = k2phash0(x);
		sv_2mortal((SV*)RETVAL);
	OUTPUT:
		RETVAL

int
__Z2epoch(mode)
    int mode

double
Z2epochf(datetime)
    double datetime

int
Z2epoch(datetime)
	double datetime

double
epoch2Z(epoch)
	int epoch

SV *
getKarray(list, i)
	Kstruct * list 
	int i

SV *
getKarraybinary(list, i, sz)
	Kstruct * list 
	int i
	int sz

int
setKarraybinary(list, i, val)
	Kstruct * list
	int i
	SV * val

int
setKarraysimple(list, i, val)
	Kstruct * list
	int i
	SV * val

int
setKarraymixed(list, i, val)
	Kstruct * list
	int i
	Kstruct * val

Kstruct *
call_ja(list,atom)
	Kstruct * list
	SV * atom

Kstruct *
newKarray(typ,arref)
	int typ
	AV * arref

Kstruct *
pscalar2k(ref)
	SV * ref

Kstruct *
parray2k(ref)
	AV * ref

Kstruct *
phash2k(ref)
	HV * ref

Kstruct *
p2k(ref)
	SV * ref

SV *
k2p(k)
	Kstruct * k

