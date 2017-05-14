// vim: filetype=xs

STRLEN CONCAT(estimate_, NAME)(SV * sv){
    if( sv!=NULL ){
        if( SvROK(sv) && (!UNBLESSED || !sv_isobject(sv)) ){
            SV * rvs = SvRV(sv);
            for(int i=visited_p-1; i>=0; --i)
                if( visited[i] == rvs )
                    return 4;
            reserve_visited_capacity();
            visited[visited_p++] = rvs;
            switch( SvTYPE(rvs) ){
                case SVt_PVAV: {
                    AV * av = (AV*) rvs;
                    SSize_t n = av_len(av);
                    if( n<0 ){
                        --visited_p;
                        return 2;
                    }

                    STRLEN len = 2 + n;
                    SV ** elems = AvARRAY(av);
                    for(int i=0; i<=n; ++i)
                        len += CONCAT(estimate_, NAME)(elems[i]);
                    --visited_p;
                    return len;
                }
                case SVt_PVHV: {
                    HV * hv = (HV*) rvs;

                    STRLEN len = 1;
                    hv_iterinit(hv);
                    for(HE * entry = hv_iternext(hv); entry; entry = hv_iternext(hv)){
                        len += 2; // : ,

                        I32 keylen;
                        char * key = hv_iterkey(entry, &keylen);
                        len += estimate_str((unsigned char*)key, (STRLEN) keylen);

                        SV * val = hv_iterval(hv, entry);
                        len += CONCAT(estimate_, NAME)(val);
                    }
                    if( len==1 )
                        ++len;
                    --visited_p;
                    return len;
                }
                default:
                    --visited_p;
                    break;
            }
            if( SvTYPE(rvs) < SVt_PVAV ){
                NV nv = SvNV(rvs);
                IV iv;
                STRLEN len=0;
                if( !Perl_isnan(nv) && nv == (NV)(iv = (IV) nv) ){
                    if( iv == 0 )
                        return 1;
                    if( iv < 0 )
                        ++len;
                    while( iv ){
                        ++len;
                        iv /= 10;
                    }
                }
                else{
                    char buffer[100];
                    snprintf(buffer, 100, "%g", (double) nv);
                    while( buffer[len] )
                        ++len;
                }
                return len;
            }
        }
        if( SvOK(sv) ){
            STRLEN len;
            char * str = SvPV(sv, len);
            return estimate_str((unsigned char*)str, len);
        }
    }
    return 4;
}

unsigned char * CONCAT(encode_, NAME)(unsigned char * buffer, SV * sv){
    if( sv!=NULL ){
        if( SvROK(sv) && (!UNBLESSED || !sv_isobject(sv)) ){
            SV * rvs = SvRV(sv);
            for(int i=visited_p-1; i>=0; --i)
                if( visited[i] == rvs )
                    goto DEGENERATE;
            reserve_visited_capacity();
            visited[visited_p++] = rvs;
            switch( SvTYPE(rvs) ){
                case SVt_PVAV: {
                    *buffer++ = '[';

                    AV * av = (AV*) rvs;
                    SSize_t n = av_len(av);
                    if( n>=0 ){
                        SV ** elems = AvARRAY(av);
                        for(int i=0; i<n; ++i){
                            buffer = CONCAT(encode_, NAME)(buffer, elems[i]);
                            *buffer++ = ',';
                        }
                        buffer = CONCAT(encode_, NAME)(buffer, elems[n]);
                    }

                    *buffer++ = ']';
                    --visited_p;
                    return buffer;
                }
                case SVt_PVHV: {
                    *buffer++ = '{';
                    HV * hv = (HV*) rvs;

                    hv_iterinit(hv);
                    for(HE * entry = hv_iternext(hv); entry; entry = hv_iternext(hv)){

                        I32 keylen;
                        char * key = hv_iterkey(entry, &keylen);
                        buffer = encode_str(buffer, (unsigned char*)key, (STRLEN) keylen);

                        *buffer++ = ':';

                        SV * val = hv_iterval(hv, entry);
                        buffer = CONCAT(encode_, NAME)(buffer, val);

                        *buffer++ = ',';
                    }

                    if( *(buffer-1) == '{' )
                        *buffer++ = '}';
                    else
                        *(buffer-1) = '}';
                    --visited_p;
                    return buffer;
                }
                default:
                    --visited_p;
                    break;
            }
            if( SvTYPE(rvs) < SVt_PVAV ){
                NV nv = SvNV(rvs);
                IV iv;
                if( !Perl_isnan(nv) && nv == (NV)(iv = (IV) nv) ){
                    if( -59074 <= iv && iv <= 59074 ){
                        // (stolen from JSON::XS)
                        // optimise the "small number case"
                        // code will likely be branchless and use only a single multiplication
                        // works for numbers up to 59074
                        U32 u;
                        char digit, nz = 0;
                        if( iv < 0 ){
                            *buffer++ = '-';
                            u = -iv;
                        }
                        else
                            u = iv;
                        // convert to 4.28 fixed-point representation
                        u = u * ((0xfffffff + 10000) / 10000); // 10**5, 5 fractional digits

                        // now output digit by digit, each time masking out the integer part
                        // and multiplying by 5 while moving the decimal point one to the right,
                        // resulting in a net multiplication by 10.
                        // we always write the digit to memory but conditionally increment
                        // the pointer, to enable the use of conditional move instructions.
                        digit = u >> 28; *buffer = digit + '0'; buffer += (nz = nz || digit); u = (u & 0xfffffffUL) * 5;
                        digit = u >> 27; *buffer = digit + '0'; buffer += (nz = nz || digit); u = (u & 0x7ffffffUL) * 5;
                        digit = u >> 26; *buffer = digit + '0'; buffer += (nz = nz || digit); u = (u & 0x3ffffffUL) * 5;
                        digit = u >> 25; *buffer = digit + '0'; buffer += (nz = nz || digit); u = (u & 0x1ffffffUL) * 5;
                        digit = u >> 24; *buffer = digit + '0'; buffer += 1; // correctly generate '0'
                    }
                    else{
                        snprintf((char*)buffer, 100, "%lld", (long long)iv);
                        while( *buffer )
                            ++buffer;
                    }
                }
                else{
                    snprintf((char*)buffer, 100, "%g", (double) nv);
                    while( *buffer )
                        ++buffer;
                }
                return buffer;
            }
        }
        if( SvOK(sv) ){
            STRLEN len;
            char * str = SvPV(sv, len);
            return encode_str(buffer, (unsigned char*)str, len);
        }
    }
    DEGENERATE:
    *buffer++ = 'n';
    *buffer++ = 'u';
    *buffer++ = 'l';
    *buffer++ = 'l';
    return buffer;
}

