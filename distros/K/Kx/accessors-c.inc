/*
    Here we add the accessors for the structure
    #define kG(x)   ((x)->G0)
    #define kC(x)   kG(x)
    #define kH(x)   ((H*)kG(x))
    #define kI(x)   ((I*)kG(x))
    #define kJ(x)   ((J*)kG(x))
    #define kE(x)   ((E*)kG(x))
    #define kF(x)   ((F*)kG(x))
    #define kS(x)   ((S*)kG(x))
    #define kK(x)   ((K*)kG(x))
*/

// Is this a perl scalar value we can handle?
#define SCALAR(x) (x == SVt_IV || x == SVt_NV || x == SVt_PV || x == SVt_PVNV)

#define dumpK(x,s) {fprintf(stderr,"%s -> Ref:%d Typ:%d Num:%d g:%hhu h:%d i:%d j:%g e:%g f:%g G01:%hhu G02:%hhu\n",s,x->r,x->t,x->n,x->g,x->h,x->i,x->j,x->e,x->f,x->G0[0],x->G0[1]);}

#define myerr(s) {fprintf(stderr,s);}

// 0 ==> turn off Z to epoch conversion
// 1 ==> turn on Z to epoch conversion
// 2 ==> turn on Z to epoch plus millisecond conversion
static int __Z2e = 1;
int __Z2epoch(int mode)  { __Z2e = mode; R(__Z2e);}

/*
Recall that a UNIX time is the number of seconds since
1970.01.01T00:00:00 while a Kdb+ datetime is a 64 bit float number of
days since 2000.01.01
	// return 86400*(datetime+10957);
	// return epoch/8.64e4-10957;
*/
#define KX2UNIX_EPOCH 10957

double epoch2Z(int epoch)
{
	double datetime =  epoch/8.64e4 - KX2UNIX_EPOCH;
	// fprintf(stderr,"epoch2Z: %d -> %g\n",epoch,datetime);
	return(datetime);
}

double Z2epochf(double datetime)
{
	double frac, epoch;

	if(__Z2e == 0)
		return datetime;
	
	// days * secs in day + secs to 1/1/2000
	epoch = ((int) datetime + KX2UNIX_EPOCH) * 86400;

	// now get hours added in
	// fraction of datetime * seconds in day / seconds in hour
	// gives hh.blah
	frac = ((datetime - (int)datetime) * 86400)/3600;
	epoch += ((int) frac) * 3600;

	// minutes
	frac = (frac - (int) frac) * 60;
	epoch += ((int) frac) * 60;

	// Seconds
	frac = (frac - (int) frac) * 60;
	epoch += ((int) frac);

	// milli Seconds 
	frac = (frac - (int) frac) * 1000;
	frac = round(frac) / 1000.0;
	epoch += frac;

	return(epoch);
}

int Z2epoch(double datetime)
{
	int epoch =  Z2epochf(datetime);
	// fprintf(stderr,"Z2epoch: %g -> %d\n",datetime,epoch);
	return(epoch);
}

int D2epoch(double datetime)
{
	int epoch =  86400*(datetime + KX2UNIX_EPOCH);
	// fprintf(stderr,"D2epoch: %g -> %d\n",datetime,epoch);
	return(epoch);
}

unsigned char
kChar (Kstruct * x) {
    return kC(x)[0];
};

short *
kShort (Kstruct * x) {
    return kH(x);
};

int *
kInt (Kstruct * x) {
    return kI(x);
};

long long *
kLong (Kstruct * x) {
    return kJ(x);
};

float *
kReal (Kstruct * x) {
    return kE(x);
};

double *
kFloat (Kstruct * x) {
    return kF(x);
};

char *
kSymbol (Kstruct * x) {
    return (char*)kS(x);
};

Kstruct *
kStruct (Kstruct * x) {
    return (Kstruct *)kK(x);
};

Kstruct *
kStructi (Kstruct * x, int i) {
    return (Kstruct *)kK(x)[i];
};

/* An accessor for the number */
short
kNum (Kstruct * x) {
    return ((x)->n);
};

/* An accessor for the reference count details */
int
kRefCnt (Kstruct * x) {
    return ((x)->r);
};

/* An accessor for the type details */
short
kType (Kstruct * x) {
    return ((x)->t);
};

/* An accessor for the Attributes */
short
kAtt (Kstruct * x) {
    return ((x)->u);
};

#define Assert(e,s)  {if(e) printf("%s\n",s);}
/* accessor for a ktd*/
Kstruct *
Ktd (Kstruct * x) {

	K y,keys;

	// Connection broken
	if( x == 0 ) 
	{ 
		myerr("Kx::Ktd connection broken\n"); 
		return(x); 
	}

	// Error
	if( x->t == -128 ) 
	{ 
		myerr("Kx::Ktd syntax error\n"); 
		return(x); 
	}

	// Assert(!(x=ktd(x)),"type")
	x=ktd(x);
	if( x == 0 ) { myerr("Kx::Ktd ktd() type failure\n"); return(x); }

	y = x->k;   // dict from flip above.
	if( !(y->t == 99) ) 
	{ 
		myerr("Kx::Ktd ktd() can't convert to a dict\n");
		return(x); 
	}
	
	keys=kK(x->k)[0];   // holds an array of symbols
	if( !(keys->t == KS) ) 
	{ 
		myerr("Kx::Ktd ktd() Keys should be an array of symbols\n");
		return(x); 
	}

    return(x);
};

/* accessor for a table select */
Kstruct *
kTable (int c, char * cmd) {
	K x,y,tmp,keys;

	// run command and return a result, New k object created
	x = k(c,cmd,0);

	// Connection broken
	if( x == 0 ) 
	{ 
		myerr("Kx::kTable connection broken\n"); 
		return(x); 
	}

	// Error
	if( x->t == -128 ) 
	{ 
		myerr("Kx::kTable syntax error\n"); 
		return(x); 
	}

	// Assert(!(t=ktd(x)),"type")
	tmp=ktd(x);
	if( tmp == 0 ) { myerr("Kx::kTable ktd() type failure\n"); return(x); }
	x = tmp;  // x was deallocated in ktd

	y = x->k;   // dict from flip above.
	if( !(y->t == 99) ) 
	{ 
		myerr("Kx::kTable ktd() can't convert to a dict\n"); return(x); 
	}
	
	keys=kK(x->k)[0];   // holds an array of symbols
	if( !(keys->t == KS) ) 
	{ 
		myerr("Kx::kTable ktd() Keys should be an array of symbols\n");
		return(x); 
	}

    return(x);
};

/* accessor for a table column headings */
Kstruct *
kTableH (Kstruct * x) {
	K keys=kK(x->k)[0];
	Assert(!(keys->t == KS),"kTableH Keys should be an array of symbols")
	return(keys);
};

/* accessor for K list of arrays of values by type for each column */
Kstruct *
kTableCols (Kstruct * x) {
	K keys=kK(x->k)[0];
	K vals=kK(x->k)[1];
	Assert(!(keys->t == KS),"kTableCols Keys should be an array of symbols")
	return(vals);
};

int
kTableNumRows (Kstruct * x) {
	K y;
	K keys=kK(x->k)[0];
	K vals=kK(x->k)[1];
	Assert(!(keys->t == KS),"kTableNumRows Keys should be an array of symbols")
	y = kK(vals)[0];
	return(y->n);
};

int
kTableNumCols (Kstruct * x) {
	K keys=kK(x->k)[0];
	K vals=kK(x->k)[1];
	Assert(!(keys->t == KS),"kTableNumCols Keys should be an array of symbols")
	return(vals->n);
};

static SV* klistelem2p(Kstruct* lst, int idx, H typ);

/* Return the value found at index(row,col) */
SV * k2p (Kstruct * );
SV *
kTableIndex (Kstruct * x, int row, int col) {
	K chdr;
	H ctyp;
	K keys=kK(x->k)[0];
	K vals=kK(x->k)[1];
	Assert(!(keys->t == KS),"Keys should be an array of symbols")

	chdr = kK(vals)[col];   // the head of this column
	ctyp = chdr->t;         // this columns type

    return klistelem2p(chdr, row, ctyp);
}

SV*
klistelem2p(Kstruct* lst, int idx, H typ) {
	if ( typ > 0 )
    {
        switch(typ)
        {
            CS(KB,return newSViv(kG(lst)[idx]))
            CS(KG,return newSViv(kG(lst)[idx]))
            CS(KH,return newSViv(kH(lst)[idx]))
            CS(KI,return newSViv(kI(lst)[idx]))
            CS(KE,return newSVnv((double)kE(lst)[idx]))
            CS(KF,return newSVnv((double)kF(lst)[idx]))
            CS(KJ,return newSVnv((double)kJ(lst)[idx]))
            CS(KC,return newSViv(kC(lst)[idx]))
            CS(KS,return newSVpv((const char*)kS(lst)[idx],0))
            CS(KM,return newSViv(kI(lst)[idx]))
            CS(KD,return newSViv(D2epoch((double)kI(lst)[idx])))
            CS(KZ,return __Z2e == 1 ? newSViv(Z2epoch(kF(lst)[idx])) : newSVnv(Z2epochf(kF(lst)[idx])))
            CS(KU,return newSViv(kI(lst)[idx]))
            CS(KV,return newSViv(kI(lst)[idx]))
            CS(KT,return newSViv(kI(lst)[idx]))
            CD: return newSV(0);
        };
    }
	else
	{
		return k2p(kK(lst)[idx]);
	}
}

/* 
Return a Perl Scalar value representation for the K value handed in.
K types 'date' and 'datetime' are converted to epoch seconds. Symbols are
converted to strings

If x->t is negative then the object is a scalar and we should use the
scalar accessors. If x->t is greater than zero then we use
vector accessors as all the elements are of that type (eg. x->t == 9
for a vector of Kdb+ floats). A more interesting case is where x->t is
exactly zero. This means that the K object contains a mixed list of other
K objects. Each element in the list is a pointer to another K object. To
access each element of the object x we use the kK object accessor.

At the moment we assume (no require) the object to hold a simple scalar
*/

SV *
k2pscalar (Kstruct * x) {

	// The type should be negative for an atom.
	H typ = x->t;       // this objects type

	if(typ >= 0)
	{
		return k2p(x);   // bail out, let k2p handle it
	}

	typ = abs(typ);
	switch(typ)
	{
		  CS(KB,return newSViv((int)x->g))
		  CS(KG,return newSViv((int)x->g))
		  CS(KH,return newSViv((int)x->h))
		  CS(KI,return newSViv(x->i))
		  CS(KE,return newSVnv((double)x->e))
		  CS(KF,return newSVnv((double)x->f))
		  CS(KJ,return newSVnv((double)x->j))
		  CS(KC,return newSViv((int)x->g))
		  CS(KS,return newSVpv((const char*)x->s,0))
		  CS(128,return newSVpv((const char*)x->s,0))   // -128 is error
		  CS(KM,return newSViv(x->i))
		  CS(KD,return newSViv(D2epoch((double)x->i)))
		  CS(KZ,return __Z2e == 1 ? newSViv(Z2epoch(x->f)) : newSVnv(Z2epochf(x->f)))
		  CS(KU,return newSViv(x->i))
		  CS(KV,return newSViv(x->i))
		  CS(KT,return newSViv(x->i))
		  CD: return newSV(0);
	};
};

SV *
k2pscalar0 (Kstruct * x) {
	SV *sv = k2pscalar(x);
	r0(x);
	return sv;
}

#define DOAV(n,AV,x) {I i=0,_i=(n);for(;i<_i;++i){av_push(AV, x);}}
HV* k2phash (Kstruct *x);

// Convert a K vector of objects to a Perl array
AV *
k2parray (Kstruct * x) 
{
	AV *av1;
	HV *hv;
	H typ = x->t;       // this arrays type
	AV *av = newAV();

	if(typ < 0)
	{
		warn("Kx::k2parray arg is not right type got %i\n",typ);
		return av; // bail out as its a scalar
	}

	// warn("    In k2parray doing type = %i, num = %i\n",typ,x->n);

	// is it a mixed list?
	if(typ == 0)
	{
		/* Loop through the list working out what the types are and doing
		 * the conversion as required
		 */
		I i=0;
		for(; i < x->n; ++i)
		{
			K atom = kK(x)[i];
			if(atom->t == XT || atom->t == XD)
			{
				// a table/dict
				hv = k2phash(atom);
				av_push(av, newRV_noinc((SV*) hv));
			}
			else if(atom->t >= 0)
			{
				// another vector, so recurse
				av1 = k2parray(atom);
				av_push(av, newRV_noinc((SV*) av1));
			}
			else
			{
				av_push(av, k2pscalar(atom));
			}
		}
		// warn("    Out k2parray doing type = %i, num = %i\n\n",typ,x->n);
		return av;
	}
	else
	{
		/* The list is of a single consistent type. So the 'for' loop is
		 * done within each case statement. KG (bytes) and KC (chars) are
		 * converted into a single string.
		 */
		 HV *hv;
		switch(typ)
		{
			  CS(KB, DOAV(x->n,av,newSViv(kG(x)[i])))
			  CS(KG, av_push(av, newSVpv((const char*)kG(x),x->n)))
			  CS(KH, DOAV(x->n,av,newSViv(kH(x)[i])))
			  CS(KI, DOAV(x->n,av,newSViv(kI(x)[i])))
			  CS(KE, DOAV(x->n,av,newSVnv((double)kE(x)[i])))
			  CS(KF, DOAV(x->n,av,newSVnv((double)kF(x)[i])))
			  CS(KJ, DOAV(x->n,av,newSVnv((double)kJ(x)[i])))
			  CS(KC, av_push(av, newSVpvn((const char*)kC(x),x->n)))
			  CS(KS, DOAV(x->n,av,newSVpv((const char*)kS(x)[i],0)))
			  CS(KM, DOAV(x->n,av,newSViv(kI(x)[i])))
			  CS(KD, DOAV(x->n,av,newSViv(D2epoch((double)kI(x)[i]))))
			  CS(KZ, DOAV(x->n,av,__Z2e == 1 ? newSViv(Z2epoch(kF(x)[i])) : newSVnv(Z2epochf(kF(x)[i])) ))
			  CS(KU, DOAV(x->n,av,newSViv(kI(x)[i])))
			  CS(KV, DOAV(x->n,av,newSViv(kI(x)[i])))
			  CS(KT, DOAV(x->n,av,newSViv(kI(x)[i])))
			  CS(XT, hv = k2phash(x); av_push(av, newRV_noinc((SV*) hv)))
			  CS(XD, hv = k2phash(x); av_push(av, newRV_noinc((SV*) hv)))
			  // CD: warn("Null Array type=%i\n",typ);return av; // undef
			  CD: return av; // undef
		};
	}
	// warn("    Out k2parray doing type = %i, num = %i\n\n",typ,x->n);
	return av;
}

// Convert a K vector of objects to a Perl array, drop refcount on x
AV *
k2parray0 (Kstruct * x) {
	AV *av = k2parray(x);
	r0(x);
	return av;
}

/* Return a Perl Hash that describes a K dict or Table object */
HV* 
k2phash (Kstruct *tb)
{
	K x, tmp;
	SV *sv;
	SV **skey;
	SV **test;
	AV *av, *keys;
	I32 len;
	int cols, i;
	HV *hv = newHV();

	int releaseX = 0;  // do we need to release mem

	// warn("In khash\n");

	if(tb->t == 99 && (kK(tb)[0])->t == 98 && (kK(tb)[1])->t == 98) // Keyed Table
	{
		// Convert keyed table to an unkeyed version, then to dict
		r1(tb);
		tmp = ktd(tb);
		if(tmp != 0) 
		{ 
			x = tmp->k;   // dict from table, tb has been deallocated
			releaseX=1;   // x is a merged copy of tb that needs r0
		}
		else
		{
			warn("Failed to convert Keyed table to normal table\n");
			r0(tb);
			return hv;
		}
	}
	else if(tb->t == 99) // Dict
	{
		x = tb;
	}
	else if (tb->t == 98) // Normal Table
	{
		x = tb->k;  // dict from table
	}
	else
	{
		myerr("Kx::k2phash wrong type");
		return hv;
	}


	// Ok we now are sure we have dict to play with

	// Loop through each column list and assign that vector (*AV) to the
	// appropriate key (column name)
	// $a = { 'col1' => [1,2,3,4], 'col2' => [0,8,7,6] } effectively

	keys   = k2parray(xx);

	cols = xx->n;       // number of columns
	for(i=0;i<cols;i++)
	{
		// Get a scalar to store from the list
		if(xy->t > 0 && xy->t < XT)
		{
			H typ = xy->t;       // this objects type
			typ = abs(typ);

            sv = klistelem2p(xy, i, typ);
		}
		else if(xy->t == 0) // its a mixed list of possible other lists/scalars
		{
			if((kK(xy)[i])->t < 0)
			{
				sv = k2pscalar(kK(xy)[i]);
			}
			else // assume a list
			{
				av = k2parray(kK(xy)[i]);

				// Now is this vector a singleton array holding a perl Hash data
				// structure. If so promote it.
				len = av_len(av);  // get its last index value
				if(len== 0)
				{
					// Get at the value so we can test it
					test = av_fetch(av,0,0);
					if(SvROK(*test))  // its a reference
					{
						int typ = SvTYPE(SvRV(*test));

						// if(typ == SVt_PVAV || typ == SVt_PVHV) // array or hash
						if(typ == SVt_PVHV) // array or hash
						{
							sv = newRV_inc((SV*) SvRV(*test)); // hmm inc
							av_undef(av); // av not required anymore
						}
						else 
						{
							sv = newRV_noinc((SV*) av);
						}
					}
					else // Not a reference do normal stuff
					{
						sv = newRV_noinc((SV*) av);
					}
				}
				else // Normal stuff
				{
					sv = newRV_noinc((SV*) av);
				}
			}
		}
		else // something weird here
		{
			croak("Kx::k2phash something weird here, probably death");
		}

		// Get at the symbol and convert it to a string
		skey = av_fetch(keys,i,0);
		if(!hv_store_ent(hv, *skey, sv, 0))
		{
			myerr("Kx::k2phash: hv_store failed");
		}
	}
	// warn("Out khash\n\n");

	if(releaseX)
		r0(tmp);
	
	av_undef(keys); // get rid of keys array as they are in the hash proper

	return hv;
}

// Convert a K dict/table to a Perl hash, drop refcount on x
HV *
k2phash0 (Kstruct * x) 
{
	HV *hv = k2phash(x);
	r0(x);
	return hv;
}

/* Return a Perl ref that describes a K object */
SV* 
k2p (Kstruct * k)
{
	SV* rtn;
	AV* av;
	HV* hv;

	if(k->t < 0)  // scalar
	{
		return k2pscalar(k);
	}
	else if (k->t == XD || k->t == XT) // dict/table with prim key or table
	{
		hv = k2phash(k);
		rtn = newRV_noinc((SV*) hv);
		return rtn;
	}
	else if (k->t >= 0 && k->t <= KT) // mixed => time
	{
		av = k2parray(k);
		rtn = newRV_noinc((SV*) av);
		return rtn;
	}
	else
	{
		return newSV(0);
	}
}

SV *
getKarray(K list, int i)
{
	if(i >= list->n || list->t < 0)
	{
		return newSV(0); // undef
	}
	if(i < 0)
	{
		i = list->n + i - 1;
		if(i < 0) { return newSV(0); } // undef
	}

    switch (list->t)
    {
        CS(XT,return(k2p(kK(list)[i])))
        CS(XD,return(k2p(kK(list)[i])))
    }
    return klistelem2p(list, i, list->t);
}

/* creating K object from Perl */
K phash2k(HV * h);
K pscalar2k(SV * p);
K parray2k(AV * a);
K
p2k(SV * ref)
{
	K kv;
	int typ;

	if(!SvROK(ref))
	{
		warn("Kx::p2k(perl_ref) has have a perl reference\n");
		return (K)0;
	}
	typ = SvTYPE(SvRV(ref));

	if(SCALAR(typ))
	{
		kv = pscalar2k((SV *)SvRV(ref));
	}
	else if(typ == SVt_PVAV) // array
	{
		kv = parray2k((AV *)SvRV(ref));
	}
	else if(typ == SVt_PVHV) // hash
	{
		kv = phash2k((HV *)SvRV(ref));
	}
	else
	{
		warn("Kx::p2k(perl_ref) unknown type(%i)\n",typ);
		return (K)0;
	}
	return kv;
}

K
pscalar2k(SV * p)
{
	K k;
	SV * sv = p;

	if(!SvOK(sv))
	{
		// Hmm check if its a reference
		if(SvROK(sv))
		{
			sv = SvRV(sv);
		}
		else
		{
			warn("pscalar2k arg not a scalar. Type is %i\n",SvTYPE(sv)); 
			return ki(0);
		}
	}
	
	if(SvIOK(sv))  // Its an integer
	{
		IV i = SvIV(sv);
		return kj(i);
	}
	else if(SvNOK(sv)) // real
	{
		double i = SvNV(sv);
		return kf(i);
	}
	else if(SvPOK(sv)) // its a symbol... maybe
	{
		STRLEN len;
		unsigned char * ptr = (unsigned char *)SvPV(sv, len);
		return ks(sn(ptr, len));
	}
	else // What on earth is it?
	{
		warn("pscalar2k what on earth is this type(%i)?\n",SvTYPE(sv)); 
	}
}

K
parray2k(AV * av)
{
	K k;
	int mixed, typ;
	I32 i;
	SV** svp;

	I32 len = av_len(av);  // get its last index value
	if(len == -1)
	{
		// empty array TODO
	}

	/*
	* Need to get an idea of what sorts of things are in this list. That
	* way we can work out if its a mixed list we need to create or a
	* simple list type. This requires us to loop through the list
	* checking the type doesn't change. If it does then we do the mixed
	* list option. This is slower but uses less memory than building as
	* we go and assuming it is a simple list
	*/
	i = 0;
	mixed = 0;
	svp = av_fetch(av,0,0);  // get 1st val so can find type
	typ = SvTYPE(*svp);
	for(i=1; i <= len; i++)
	{
		svp = av_fetch(av,i,0);
		if(typ != SvTYPE(*svp))
		{
			mixed++;
			break;
		}
	}

	// OK now we know what sort of K list to create
	if(mixed || SvROK(*svp))
	{
		K kv = ktn(0,len+1);
		for(i=0; i <= len; i++)
		{
			svp = av_fetch(av,i,0);
			typ = SvTYPE(*svp);

			if(!SvROK(*svp) && SCALAR(typ))
			{
				kK(kv)[i] = pscalar2k(*svp);
			}
			else if(SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVAV) // array
			{
				kK(kv)[i] = parray2k((AV*) SvRV(*svp));
			}
			else if(SvROK(*svp) && SvTYPE(SvRV(*svp)) == SVt_PVHV) // hash
			{
				kK(kv)[i] = phash2k((HV*) SvRV(*svp));
			}
			else
			{
				warn("Kx::parray2k unknown type(%i)\n",typ);
				return (K)0;
			}
		}
		return kv;
	}
	else // simple list
	{
		K kv;
		if(typ == SVt_IV || typ == SVt_NV || typ == SVt_PV)
		{
			if(typ == SVt_IV)  // int
			{
				kv = ktn(KJ,len+1);
				for(i=0; i <= len; i++)
				{
					svp = av_fetch(av,i,0);
					kJ(kv)[i] = (long) SvIV(*svp);
				}
			}
			else if(typ == SVt_NV) // double
			{
				kv = ktn(KF,len+1);
				for(i=0; i <= len; i++)
				{
					svp = av_fetch(av,i,0);
					kF(kv)[i] = (double) SvNV(*svp);
				}
			}
			else // typ == SVt_PV) // symbol
			{
				STRLEN l;
				unsigned char * ptr;
				kv = ktn(KS,len+1);
				for(i=0; i <= len; i++)
				{
					svp = av_fetch(av,i,0);
					ptr = (unsigned char *) SvPV(*svp, l);
					kS(kv)[i] = sn(ptr, l);
				}
			}
			return kv;
		}
		else if(typ == SVt_PVAV) // array of array
		{
			kv = ktn(0,len+1);
			for(i=0; i <= len; i++)
			{
				svp = av_fetch(av,i,0);
				kK(kv)[i] = parray2k((AV *)(*svp));
			}
		}
		else if(typ == SVt_PVHV) // array of hash
		{
			kv = ktn(0,len+1);
			for(i=0; i <= len; i++)
			{
				svp = av_fetch(av,i,0);
				kK(kv)[i] = phash2k((HV *)(*svp));
			}
		}
		else
		{
			warn("Kx::parry2k unknown type %i\n",typ);
			return (K)0;
		}
		return kv;
	}
}

K
phash2k(HV * h)
{
	int i, typ;
	SV * sv;
	char * key;
	I32 keylen;

	int n = hv_iterinit(h);
	K x = xD(ktn(KS,n), ktn(0,n));
	for(i = 0; i < n ; ++i) 
	{
		// Pick up the next key and value
		sv = hv_iternextsv(h, &key, &keylen);

		// Store em in the Dict
		kS(xx)[i] = sn((unsigned char *)key, keylen);
		typ = SvTYPE(sv);

		// If we have a reference then we need to dereference it
		while(SvROK(sv))
		{
			typ = SvTYPE(SvRV(sv)); //  underlying typ
			sv  = SvRV(sv);         //  dereference
		}

		if(SCALAR(typ))
		{
			kK(xy)[i] = pscalar2k(sv);
		}
		else if(typ == SVt_PVAV) // array
		{
			kK(xy)[i] = parray2k((AV*) sv);
		}
		else if(typ == SVt_PVHV) // hash
		{
			kK(xy)[i] = phash2k((HV*) sv);
		}
		else
		{
			warn("Kx::phash2k unknown type\n");
			return (K)0;
		}
	}
	return x;
}

/* 
 * We assume arref is valid and has stuff in it! It must also be of only
 * one type and that type must un-mixed
 */
#define NEWKDO(n,x) {for(i=0;i<n;i++){sv=av_shift(arref);x;}}
K
newKarray(int typ, AV * arref)
{
	K list;
	int i;   // needed for NEWKDO
	SV* sv;  // needed for NEWKDO


	int len = av_len(arref);
	len++;
	list = ktn(typ,len);

	switch(typ)
	{
		  CS(KB, NEWKDO(len,(kG(list)[i] = SvIV(sv) )))
		  CS(KG, NEWKDO(len,(kG(list)[i] = SvIV(sv) )))
		  CS(KH, NEWKDO(len,(kH(list)[i] = SvIV(sv) )))
		  CS(KI, NEWKDO(len,(kI(list)[i] = SvIV(sv) )))
		  CS(KE, NEWKDO(len,(kE(list)[i] = (float)SvNV(sv) )))
		  CS(KF, NEWKDO(len,(kF(list)[i] = SvNV(sv) )))
		  CS(KJ, NEWKDO(len,(kJ(list)[i] = (long long)SvNV(sv) )))
		  CS(KC, NEWKDO(len,(kC(list)[i] = SvIV(sv) )))
		  CS(KS, NEWKDO(len,(kS(list)[i] = ss((S)SvPV_nolen(sv)) )))
		  CS(KM, NEWKDO(len,(kI(list)[i] = SvIV(sv) )))
		  CS(KD, NEWKDO(len,(kI(list)[i] = (int)(floor(epoch2Z(SvIV(sv)))) )))
		  CS(KZ, NEWKDO(len,(kF(list)[i] = epoch2Z(SvNV(sv)) )))
		  CS(KU, NEWKDO(len,(kI(list)[i] = SvIV(sv) )))
		  CS(KV, NEWKDO(len,(kI(list)[i] = SvIV(sv) )))
		  CS(KT, NEWKDO(len,(kI(list)[i] = SvIV(sv) )))
		  CD: return 0; 
	};
	return list;
}

int
setKarraysimple(K list, int x, SV * val)
{
	if(x < 0)
	{
		x = list->n + x -1;
		if(x < 0) { return 0; }  // too negative to be of any use
	}
	if(x >= list->n) { return 0; }

	/* The list is of a single consistent type.
	 */
	switch(list->t)
	{
		  CS(KB, (kG(list)[x]) = SvIV(val))
		  CS(KG, (kG(list)[x]) = SvIV(val))
		  CS(KH, (kH(list)[x]) = SvIV(val))
		  CS(KI, (kI(list)[x]) = SvIV(val))
		  CS(KE, (kE(list)[x]) = (float)SvNV(val))
		  CS(KF, (kF(list)[x]) = SvNV(val))
		  CS(KJ, (kJ(list)[x]) = (long long)SvNV(val))
		  CS(KC, (kC(list)[x]) = SvIV(val))
		  CS(KS, (kS(list)[x]) = ss((S)SvPV_nolen(val)))
		  CS(KM, (kI(list)[x]) = SvIV(val))
		  CS(KD, (kI(list)[x]) = (int)(floor(SvIV(val))))
		  CS(KZ, (kF(list)[x]) = epoch2Z(SvNV(val)))
		  CS(KU, (kI(list)[x]) = SvIV(val))
		  CS(KV, (kI(list)[x]) = SvIV(val))
		  CS(KT, (kI(list)[x]) = SvIV(val))
		  CD: return 0; 
	};

	return 1;
}

int
setKarraymixed(K list, int x, K val)
{
	if(x < 0)
	{
		x = list->n + x -1;
		if(x < 0) { return 0; }  // too negative to be of any use
	}
	if(x >= list->n) { return 0; }

	r1(val);
	kK(list)[x] = val;
	return 1;
}

/*
 * Take a Perl string and map it directly onto a KDB+ data structure
 * starting at index x. The list must be of type KG list and the string
 * must fit the length
 */
int
setKarraybinary(K list, int x, SV * val)
{
	STRLEN len;
	char * ptr;
	int i;
	ptr = SvPV(val, len);

	if(x < 0)
	{
		x = list->n + x -1;
		if(x < 0) { return 0; }  // too negative to be of any use
	}
	if(x+len > list->n) { myerr("x+len too big"); return 0; }
	if(list->t != KG) { myerr("Not a byte list"); return 0; }

	for(i=0; i < len; i++)
	{
		kG(list)[i+x] = *(ptr+i);
	}
	return 1;
}

SV *
getKarraybinary(K list, int from, int sz)
{
	if(from+sz >= list->n || list->t != KG || from < 0 || sz < 0)
	{
		return newSV(0); // undef
	}

	if(sz == 0)
	{
		sz = list->n - from;
	}

	return(newSVpv((const char*)(&(kG(list)[from])),sz));
}

K 
call_ja(K list, SV* atom)
{
	int i;
	double d;
	unsigned char * s, c;
	float f;
	long long l;
	
	i = SvIV(atom);
	d = SvNV(atom);
	s = (unsigned char *)SvPV_nolen(atom);

	if(list->t == KE) { f = (float) d; }
	if(list->t == KJ) { l = (long long) d; }
	if(list->t == KC) { c = (unsigned char) i; }
	if(list->t == KS) { s = ss(s); }
	if(list->t == KD) { i = (int)(floor(epoch2Z(i))); }

	switch(list->t)
	{
		  CS(KB, ja(&list,&i))
		  CS(KG, ja(&list,&i))
		  CS(KH, ja(&list,&i))
		  CS(KI, ja(&list,&i))
		  CS(KE, ja(&list,&f))
		  CS(KF, ja(&list,&d))
		  CS(KJ, ja(&list,&l))
		  CS(KC, ja(&list,&c))
		  CS(KS, ja(&list,&s))
		  CS(KM, ja(&list,&i))
		  CS(KD, ja(&list,&i))
		  CS(KZ, ja(&list,&d))
		  CS(KU, ja(&list,&i))
		  CS(KV, ja(&list,&i))
		  CS(KT, ja(&list,&i))
		  CD: return list;
	};
	return list;
}
