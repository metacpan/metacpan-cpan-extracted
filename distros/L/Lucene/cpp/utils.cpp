
void
MarkObjCppOwned(SV *obj)
{
    HV *hv = (HV *) SvRV(obj);
    SV **sv = hv_fetch(hv, "_cppowned", 9, 0);
    if (!sv)
        hv_store(hv, "_cppowned", 9, newSViv(1), 0);
}

bool
IsObjCppOwned(SV *obj)
{
    HV *hv = (HV *) SvRV(obj);
    SV **sv = hv_fetch(hv, "_cppowned", 9, 0);
    if (!sv)
        return false;
    return true;
}

SV*
PtrToSv(const char* CLASS, void* ptr, SV* dest)
{
    HV* new_hv = newHV(); 
    SV* tmp_rv = newRV_noinc((SV*) new_hv);
    hv_store(new_hv, "_objptr", 7, newSViv(PTR2IV(ptr)), 0);
    sv_setsv(dest, sv_bless(tmp_rv, gv_stashpv(CLASS, 1)));
    SvREFCNT_dec((SV*) tmp_rv);
    return dest;
}

template <class T>
T
SvToPtr(SV* src)
{
    T var = NULL;
    if (sv_isobject(src) && SvTYPE(SvRV(src)) == SVt_PVHV) {
        HV *hv = (HV *) SvRV(src);
        SV **sv = hv_fetch(hv, "_objptr", 7, 0);
        if (sv) {
            var = INT2PTR(T, SvIV(*sv));
            if (!var) {
                warn("${Package}::$func_name(): C++ object pointer is NULL");
            }
        } else {
            warn("${Package}::$func_name(): key _objptr is missing");
        }
    } else {
        warn("${Package}::$func_name(): not a blessed hash reference");
    }
    return var;
}

wchar_t*
SvToWChar(SV* arg)
{
    wchar_t* ret;
    // Get string length of argument. This works for PV, NV and IV.
    // The STRLEN typdef is needed to ensure that this will work correctly
    // in a 64-bit environment.
    STRLEN arg_len;
    SvPV(arg, arg_len);

    // Alloc memory for wide char string.  This could be a bit more
    // then necessary.
    Newz(0, ret, arg_len + 1, wchar_t);

    U8* src = (U8*) SvPV_nolen(arg);
    wchar_t* dst = ret;

    if (SvUTF8(arg)) {
        // UTF8 to wide char mapping
        STRLEN len;
        while (*src) {
            *dst++ = utf8_to_uvuni(src, &len);
            src += len;
        }
    } else {
        // char to wide char mapping
        while (*src) {
            *dst++ = (wchar_t) *src++;
        }
    }
    *dst = 0;
    return ret;
}

SV*
WCharToSv(wchar_t* src, SV* dest)
{
    U8* dst;
    U8* d;

    // Alloc memory for wide char string.  This is clearly wider
    // then necessary in most cases but no choice.
    Newz(0, dst, 3 * wcslen(src) + 1, U8);

    d = dst;
    while (*src) {
        d = uvuni_to_utf8(d, *src++);
    }
    *d = 0;

    sv_setpv(dest, (char*) dst);
    sv_utf8_decode(dest);

    Safefree(dst);
    return dest;
}


/* Used by the INPUT typemap for char**.
 * Will convert a Perl AV* (containing strings) to a C char**.
 */
char ** XS_unpack_charPtrPtr(SV* rv )
{
	AV *av;
	SV **ssv;
	char **s;
	int avlen;
	int x;

	if( SvROK( rv ) && (SvTYPE(SvRV(rv)) == SVt_PVAV) )
		av = (AV*)SvRV(rv);
	else {
		warn("XS_unpack_charPtrPtr: rv was not an AV ref");
		return( (char**)NULL );
	}

	/* is it empty? */
	avlen = av_len(av);
	if( avlen < 0 ){
		warn("XS_unpack_charPtrPtr: array was empty");
		return( (char**)NULL );
	}

	/* av_len+2 == number of strings, plus 1 for an end-of-array sentinel.
	 */
	s = (char **)safemalloc( sizeof(char*) * (avlen + 2) );
	if( s == NULL ){
		warn("XS_unpack_charPtrPtr: unable to malloc char**");
		return( (char**)NULL );
	}
	for( x = 0; x <= avlen; ++x ){
		ssv = av_fetch( av, x, 0 );
		if( ssv != NULL ){
			if( SvPOK( *ssv ) ){
				s[x] = (char *)safemalloc( SvCUR(*ssv) + 1 );
				if( s[x] == NULL )
					warn("XS_unpack_charPtrPtr: unable to malloc char*");
				else
					strcpy( s[x], SvPV( *ssv, PL_na ) );
			}
			else
				warn("XS_unpack_charPtrPtr: array elem %d was not a string.", x );
		}
		else
			s[x] = (char*)NULL;
	}
	s[x] = (char*)NULL; /* sentinel */
	return( s );
}

/* Will convert a C char** to a Perl AV*     */
void XS_pack_charPtrPtr(SV* st, char **s)
{
	AV *av = newAV();
	SV *sv;
	char **c;

	for( c = s; *c != NULL; ++c ){
		sv = newSVpv( *c, 0 );
		av_push( av, sv );
	}
	sv = newSVrv( st, NULL );	/* upgrade stack SV to an RV */
	SvREFCNT_dec( sv );	/* discard */
	SvRV( st ) = (SV*)av;	/* make stack RV point at our AV */
}


/* cleanup the temporary char** from XS_unpack_charPtrPtr */
void XS_release_charPtrPtr(char **s)
{
	char **c;
	for( c = s; *c != NULL; ++c )
		safefree( *c );
	safefree( s );
}

