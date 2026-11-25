MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::GoRoutine

PROTOTYPES: ENABLE

# _ev_invoke_callback(callback)
# Calls a Perl callback on the main thread with exit scoped to it: an
# exit() inside the callback (or in anything it calls) is caught and
# reported as the __GOROUTINE_EXIT__ token instead of terminating the
# process. Returns undef on success, or the error (string or reference)
# the callback died with. The custom runops is installed only for the
# duration of the call and is restored as soon as the callback returns,
# before mortal cleanup, so a destructor that dies there cannot leave
# it installed.
SV *
_ev_invoke_callback(callback)
    SV *callback
  CODE:
    {
        runops_proc_t saved_runops = PL_runops;
        SV *err = NULL;
        PL_runops = go_ev_runops;
        {
            dSP;
            ENTER;
            SAVETMPS;
            PUSHMARK(SP);
            PUTBACK;
            /* Clear $@ first, then read it back after the call. A
               successful G_EVAL call leaves $@ as "" (defined but
               empty) in this Perl, so definedness alone is not a die:
               the error is real only when $@ is non-empty (a reference
               is caught by SvTRUE; a false die value such as "" or 0
               still produces a non-empty message because Perl appends
               " at FILE line LINE" to it). Testing truth alone would
               miss a callback that dies with a false value and silently
               mark the routine done instead of failed. */
            sv_setsv(ERRSV, &PL_sv_undef);
            call_sv(callback, G_VOID | G_DISCARD | G_EVAL);
            /* Restore before the mortal cleanup below: FREETMPS and LEAVE
               can run destructors, and a destructor that dies would croak
               out of this frame and leave the custom runops installed. */
            PL_runops = saved_runops;
            SPAGAIN;
            if (SvOK(ERRSV) && (SvTRUE(ERRSV) || SvCUR(ERRSV) > 0)) {
                err = newSVsv(ERRSV);
                sv_setsv(ERRSV, &PL_sv_undef);
            }
            PUTBACK;
            FREETMPS;
            LEAVE;
        }
        /* Undef on success: the Perl caller tests !defined $err, so a
           defined value here (even 0) would be read as a failure. */
        RETVAL = err ? err : &PL_sv_undef;
    }
  OUTPUT:
    RETVAL

# _ev_now()
# Monotonic clock in seconds, for scheduling timers on the event loop.
# Input: none. Output: seconds since an arbitrary fixed point.
NV
_ev_now()
  CODE:
    RETVAL = go_ev_now();
  OUTPUT:
    RETVAL

# _ev_add_timer(id, when, interval, kind)
# Registers a timer trigger for a routine id. when is an absolute
# monotonic time (see _ev_now); interval 0 is one-shot, > 0 repeats;
# kind 0 fires the callback, 1 is a timeout (the Perl side cancels the
# routine with status timed_out). Input: routine id, times, kind.
void
_ev_add_timer(id, when, interval, kind)
    IV id
    NV when
    NV interval
    IV kind
  CODE:
    go_ev_add_timer((int)id, when, interval, (int)kind);

# _ev_add_io(id, fd, want_read, want_write, repeat)
# Registers an IO-readiness trigger for a routine id. fd is a Perl file
# descriptor (fileno() on a filehandle, as passed by GoRoutine.pm).
# repeat 1 keeps the trigger registered after it fires; 0 removes it.
# On Windows the descriptor is a CRT fd, and it stays one: Perl's
# headers redirect select() to win32_select(), which works on CRT fds
# through Perl's fd_set, so translating it to a SOCKET with
# _get_osfhandle would store a large SOCKET value that FD_SET writes
# past the end of the fd_set. The hang this once caused was the nfds
# argument, not the fd value: win32_select only scans fds below nfds,
# so GoRoutineEvent.h passes max_fd + 1 (see go_ev_wait).
void
_ev_add_io(id, fd, want_read, want_write, repeat)
    IV id
    IV fd
    IV want_read
    IV want_write
    IV repeat
  CODE:
#ifdef _WIN32
    go_ev_add_io((int)id, (SOCKET)fd, (int)want_read, (int)want_write, (int)repeat);
#else
    go_ev_add_io((int)id, (int)fd, (int)want_read, (int)want_write, (int)repeat);
#endif

# _ev_add_pid(id, pid)
# Registers a process-exit trigger for a routine id. The pid is checked
# without reaping it (the caller still collects it with wait_process).
void
_ev_add_pid(id, pid)
    IV id
    IV pid
  CODE:
    go_ev_add_pid((int)id, (long)pid);

# _ev_cancel(id)
# Removes every trigger registered for a routine id (timers, IO, pids).
void
_ev_cancel(id)
    IV id
  CODE:
    go_ev_cancel((int)id);

# _ev_wait(timeout_ms)
# Waits for the next trigger and returns the due routine id as a flat
# list (at most one). A positive id means run the callback; a negative
# id means a timeout fired for that routine (id is the absolute value).
# Only one id per call: a callback may block (a channel send waits for
# its receiver), and a batch collected up front cannot be reached by
# the nested wait inside that callback, so due ids are dispatched one
# at a time. timeout_ms >= 0 bounds the wait; < 0 waits until the next
# trigger, or returns at once when nothing is registered.
void
_ev_wait(timeout_ms)
    IV timeout_ms
  PPCODE:
    {
        int due[1];
        long timeout = (long)timeout_ms;
        int n = go_ev_wait(timeout, due, 1);
        if (n > 0)
            XPUSHs(sv_2mortal(newSViv(due[0])));
    }

# _ev_fail_malloc_once()
# Test-only fault injection: makes the next go_ev_wait call treat its
# pollfd malloc as failed, so the engine takes the sleep branch instead
# of busy-looping. On Windows the select path allocates nothing, so this
# is a no-op there. Production never calls it; the flag is consumed on
# use, so a single call affects exactly one wait.
void
_ev_fail_malloc_once()
  CODE:
    go_ev_fail_malloc_once();
