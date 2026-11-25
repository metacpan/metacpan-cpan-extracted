MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::GoRoutine

PROTOTYPES: ENABLE

UV
spawn(argv_array, options)
    AV *argv_array
    HV *options
  CODE:
    RETVAL = dd_spawn_process(aTHX_ argv_array, options);
  OUTPUT:
    RETVAL

int
process_running(pid)
    UV pid
  CODE:
#ifdef _WIN32
    {
        HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, (DWORD)pid);
        if (process == NULL) RETVAL = 0;
        else {
            DWORD result = WaitForSingleObject(process, 0);
            CloseHandle(process);
            if (result == WAIT_FAILED)
                croak("unable to inspect GoRoutine child process (Windows error %lu)",
                      (unsigned long)GetLastError());
            RETVAL = result == WAIT_TIMEOUT ? 1 : 0;
        }
    }
#else
    if (pid == 0 || pid > (UV)INT_MAX) RETVAL = 0;
    else if (kill((pid_t)pid, 0) == 0 || errno == EPERM) RETVAL = 1;
    else if (errno == ESRCH) RETVAL = 0;
    else croak("unable to inspect GoRoutine child process: %s", strerror(errno));
#endif
  OUTPUT:
    RETVAL

int
process_exited(pid)
    UV pid
  CODE:
    if (pid == 0)
        croak("invalid GoRoutine child process identifier");
#ifdef _WIN32
    if (pid > (UV)0xFFFFFFFFUL)
        croak("invalid GoRoutine child process identifier");
    {
        HANDLE process = OpenProcess(SYNCHRONIZE, FALSE, (DWORD)pid);
        if (process == NULL) {
            DWORD error = GetLastError();
            if (error == ERROR_INVALID_PARAMETER) RETVAL = 1;
            else croak("unable to inspect GoRoutine child process (Windows error %lu)",
                       (unsigned long)error);
        }
        else {
            DWORD result = WaitForSingleObject(process, 0);
            DWORD error = result == WAIT_FAILED ? GetLastError() : ERROR_SUCCESS;
            CloseHandle(process);
            if (result == WAIT_FAILED)
                croak("unable to inspect GoRoutine child process (Windows error %lu)",
                      (unsigned long)error);
            RETVAL = result == WAIT_OBJECT_0 ? 1 : 0;
        }
    }
#else
    {
        siginfo_t info;
        int result;
        if (pid == 0 || pid > (UV)INT_MAX)
            croak("invalid GoRoutine child process identifier");
        memset(&info, 0, sizeof(info));
        do { result = waitid(P_PID, (id_t)pid, &info, WEXITED | WNOHANG | WNOWAIT); }
        while (result < 0 && errno == EINTR);
        if (result < 0 && errno == ECHILD) {
            if (kill((pid_t)pid, 0) == 0 || errno == EPERM) RETVAL = 0;
            else if (errno == ESRCH) RETVAL = 1;
            else croak("unable to inspect GoRoutine process: %s", strerror(errno));
        }
        else if (result < 0)
            croak("unable to inspect GoRoutine child process: %s", strerror(errno));
        else RETVAL = info.si_pid != 0 ? 1 : 0;
    }
#endif
  OUTPUT:
    RETVAL

int
wait_process(pid)
    UV pid
  CODE:
    if (pid == 0)
        croak("invalid GoRoutine child process identifier");
#ifdef _WIN32
    {
        if (pid > (UV)0xFFFFFFFFUL)
            croak("invalid GoRoutine child process identifier");
        HANDLE process = OpenProcess(SYNCHRONIZE | PROCESS_QUERY_LIMITED_INFORMATION,
                                     FALSE, (DWORD)pid);
        DWORD wait_result, exit_code = 0;
        if (process == NULL) {
            DWORD error = GetLastError();
            if (error == ERROR_INVALID_PARAMETER) {
                /* The child has already exited and been reaped: the spawn
                   layer closes its own process handle at spawn time, so no
                   process object remains to open. Treat the child as exited.
                   No exit code survives to report, so return the
                   unknown-status code the POSIX branch uses when the wait
                   status cannot be determined. */
                RETVAL = 255;
            }
            else
                croak("unable to open GoRoutine child process (Windows error %lu)",
                      (unsigned long)error);
        }
        else {
            wait_result = WaitForSingleObject(process, INFINITE);
            if (wait_result != WAIT_OBJECT_0 || !GetExitCodeProcess(process, &exit_code)) {
                DWORD error = GetLastError();
                CloseHandle(process);
                croak("unable to wait for GoRoutine child process (Windows error %lu)",
                      (unsigned long)error);
            }
            CloseHandle(process);
            RETVAL = (int)exit_code;
        }
    }
#else
    {
        int status = 0;
        pid_t result;
        if (pid == 0 || pid > (UV)INT_MAX)
            croak("invalid GoRoutine child process identifier");
        do { result = waitpid((pid_t)pid, &status, 0); } while (result < 0 && errno == EINTR);
        if (result < 0)
            croak("unable to wait for GoRoutine child process: %s", strerror(errno));
        if (WIFEXITED(status)) RETVAL = WEXITSTATUS(status);
        else if (WIFSIGNALED(status)) RETVAL = 128 + WTERMSIG(status);
        else RETVAL = 255;
    }
#endif
  OUTPUT:
    RETVAL

int
terminate_process(pid, signal_name="TERM")
    UV pid
    const char *signal_name
  CODE:
#ifdef _WIN32
    {
        HANDLE process;
        DWORD code;
        if (strEQ(signal_name, "KILL")) code = 137;
        else if (strEQ(signal_name, "TERM")) code = 143;
        else croak("unsupported GoRoutine termination signal '%s'", signal_name);
        process = OpenProcess(PROCESS_TERMINATE, FALSE, (DWORD)pid);
        if (process == NULL) RETVAL = 0;
        else {
            RETVAL = TerminateProcess(process, code) ? 1 : 0;
            CloseHandle(process);
        }
    }
#else
    {
        int signal_number;
        if (strEQ(signal_name, "TERM")) signal_number = SIGTERM;
        else if (strEQ(signal_name, "KILL")) signal_number = SIGKILL;
        else if (strEQ(signal_name, "HUP")) signal_number = SIGHUP;
        else if (strEQ(signal_name, "INT")) signal_number = SIGINT;
        else croak("unsupported GoRoutine termination signal '%s'", signal_name);
        if (pid == 0 || pid > (UV)INT_MAX)
            croak("invalid GoRoutine child process identifier");
        RETVAL = kill((pid_t)pid, signal_number) == 0 ? 1 : 0;
        if (!RETVAL && errno != ESRCH)
            croak("unable to terminate GoRoutine child process: %s", strerror(errno));
    }
#endif
  OUTPUT:
    RETVAL
