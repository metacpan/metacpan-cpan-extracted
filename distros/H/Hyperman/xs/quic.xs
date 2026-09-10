MODULE = Hyperman		PACKAGE = Hyperman

# QUIC internals, for t/44-quic-cid.t. Author-facing and not documented: they
# exist because the two structures they drive cannot be reached any other way
# from Perl, and both are things a black-box test against a real client would
# not catch.

# The Destination Connection ID map. A bug here misroutes one client's
# packets into another client's connection - a data disclosure - so this
# inserts many CIDs across many connections, looks every one up, retires a
# connection and a single CID, and asserts nothing else moved. 1 = every
# check passed.
IV
_quic_cid_selftest()
    CODE:
        RETVAL = hm_quic_cid_selftest();
    OUTPUT:
        RETVAL

# The expiry min-heap. A broken sift is either a connection that never times
# out or one that PTOs itself to death, and neither is visible from outside.
# Pushes in random order, moves deadlines both earlier and later, removes
# from the middle, and asserts the drain is monotonic and every cached
# heap_idx still agrees with the slot holding it.
IV
_quic_heap_selftest()
    CODE:
        RETVAL = hm_quic_heap_selftest();
    OUTPUT:
        RETVAL

# Address-validation tokens: Retry, NEW_TOKEN and stateless reset. Asserts the
# property that matters - a token verifies for the address, connection id and
# secret it was minted for, and for nothing else.
IV
_quic_token_selftest()
    CODE:
        RETVAL = hm_quic_token_selftest();
    OUTPUT:
        RETVAL

# ngtcp2_pkt_decode_version_cid over bytes from Perl: the first thing that
# touches an attacker-controlled datagram. Returns (rv, version, dcidlen,
# scidlen); rv 0 is decoded, -235 is NGTCP2_ERR_VERSION_NEGOTIATION, and
# anything else is a refusal.
void
_quic_decode_selftest(pkt)
        SV *pkt
    PREINIT:
        STRLEN len;
        const unsigned char *p;
        int rv = -1;
        uint32_t ver = 0;
        size_t dlen = 0, slen = 0;
    PPCODE:
        p = (const unsigned char *)SvPV(pkt, len);
        hm_quic_decode_probe(p, (size_t)len, &rv, &ver, &dlen, &slen);
        EXTEND(SP, 4);
        mPUSHi(rv);
        mPUSHu(ver);
        mPUSHu((UV)dlen);
        mPUSHu((UV)slen);
