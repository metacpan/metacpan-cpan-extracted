MODULE = Hyperman		PACKAGE = Hyperman

# Public C ABI entry point (hm_abi.h / hm_abi_impl.h): a DBI-style versioned
# function-pointer table for XS consumers (DBIx::Loop, ...). Resolved at
# runtime - call_pv("Hyperman::_abi_ptr"), INT2PTR, check abi_version.

IV
_abi_ptr()
    CODE:
        RETVAL = PTR2IV(&hm_abi_table);
    OUTPUT:
        RETVAL

# Resolve and exercise the whole table from C: future lifecycle (done, fail,
# on_ready, double-settle no-op), a C io watcher on a pipe, a cancelled timer,
# and a live timer, all pumped with run_until. 1 = every check passed.
IV
_abi_selftest()
    CODE:
        RETVAL = hm_abi_selftest(aTHX);
    OUTPUT:
        RETVAL

# The table's version, for tests and for a consumer that would rather ask
# than dereference the pointer itself.
IV
_abi_version()
    CODE:
        RETVAL = hm_abi_table.abi_version;
    OUTPUT:
        RETVAL

# v4 on_worker_start, for t/33-worker-start.t. Registering a C callback is not
# something Perl can do, so the test drives these two instead: install before
# run(), then have the application report the count from inside a worker.
IV
_abi_worker_hook_install()
    CODE:
        RETVAL = hm_abi_worker_hook_install(aTHX);
    OUTPUT:
        RETVAL

# How many times the hook fired IN THIS PROCESS, and whether it was handed a
# real loop every time (0 = it was not, which is a failure).
void
_abi_worker_hook_state()
    PPCODE:
        EXTEND(SP, 2);
        mPUSHi(HM_ABI_ST_WORKER_N);
        mPUSHi(HM_ABI_ST_WORKER_LOOP_OK);

# v6 stream handles, for t/41-stream-abi.t. Everything below goes through the
# function-pointer table rather than calling hm_stream.h directly - a selftest
# that skipped the table would prove the implementation and not the ABI. An
# application drives these from inside a request; the transport is whatever
# that request arrived on, and none of it is named here, which is the point.

IV
_abi_stream_open(env, status = 200, headers = NULL)
        SV *env
        int status
        SV *headers
    CODE:
        if (headers && !SvOK(headers)) headers = NULL;
        RETVAL = hm_abi_st_stream_open(aTHX_ env, status, headers);
    OUTPUT:
        RETVAL

IV
_abi_stream_write(data)
        SV *data
    CODE:
        RETVAL = hm_abi_st_stream_write(aTHX_ data);
    OUTPUT:
        RETVAL

IV
_abi_stream_close()
    CODE:
        RETVAL = hm_abi_st_stream_close(aTHX);
    OUTPUT:
        RETVAL

# v7: the other ending. Stops the body so the peer can tell it was not
# finished - RST_STREAM on h2, a connection reset on HTTP/1.1 - and releases
# the handle the same way close does.
IV
_abi_stream_abort()
    CODE:
        RETVAL = hm_abi_st_stream_do_abort(aTHX);
    OUTPUT:
        RETVAL

# v8: register the read half on the open stream handle, so bytes the peer
# sends arrive by callback instead of being buffered into psgi.input.
IV
_abi_stream_read()
    CODE:
        RETVAL = hm_abi_st_stream_read(aTHX);
    OUTPUT:
        RETVAL

# What the read half has been handed: (calls, bytes, the bytes themselves).
void
_abi_stream_rx()
    PPCODE:
        EXTEND(SP, 3);
        mPUSHi(HM_ABI_ST_SH_RXN);
        mPUSHi(HM_ABI_ST_SH_RXLEN);
        mPUSHp(HM_ABI_ST_SH_RX, (STRLEN)HM_ABI_ST_SH_RXLEN);

# Owe the open stream n chunks of 4KiB and produce them, pausing whenever the
# connection says it is full and resuming from the drain callback. The stream
# closes itself when the last chunk is out, so the caller returns immediately
# and the body finishes on the loop.
void
_abi_stream_produce(n)
        IV n
    CODE:
        hm_abi_st_stream_produce(aTHX_ n);

# open?, aborts, drains, accepted writes, times the connection said full -
# read back by a LATER request, which is the only way a Perl test can see a
# callback that fired in C.
void
_abi_stream_state()
    PPCODE:
        EXTEND(SP, 5);
        mPUSHi(HM_ABI_ST_SH ? 1 : 0);
        mPUSHi(HM_ABI_ST_SH_ABORTS);
        mPUSHi(HM_ABI_ST_SH_DRAINS);
        mPUSHi(HM_ABI_ST_SH_WRITES);
        mPUSHi(HM_ABI_ST_SH_FULLS);
