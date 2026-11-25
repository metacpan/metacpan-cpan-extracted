#include "SystemMenuNative.h"

MODULE = Developer::Dashboard    PACKAGE = Developer::Dashboard::System::Menu

PROTOTYPES: DISABLE

int
_start()
PREINIT:
#ifdef _WIN32
    SECURITY_ATTRIBUTES sa;
    HANDLE child_stdin_read = NULL;
    HANDLE parent_stdin_write = NULL;
    HANDLE parent_stdout_read = NULL;
    HANDLE child_stdout_write = NULL;
    STARTUPINFOW si;
    PROCESS_INFORMATION pi;
    wchar_t helper_path[32768];
    wchar_t command_line[32768 + 4];
    int ok = 0;
#else
    int command_pipe[2];
    int events_pipe[2];
    char helper_path[PATH_MAX];
    posix_spawn_file_actions_t actions;
    pid_t pid;
    int rc;
    int flags;
    int ok = 0;
    char *argv[2];
#endif
CODE:
    lock_helper();
    if (helper_is_running_unlocked()) {
        ok = 1;
    }
    else {
#ifdef _WIN32
        ZeroMemory(&sa, sizeof(sa));
        sa.nLength = sizeof(sa);
        sa.bInheritHandle = TRUE;

        if (!find_helper_path(helper_path, sizeof(helper_path)/sizeof(helper_path[0]))) {
            unlock_helper();
            croak("cannot locate system_menu_helper.exe next to System::Menu bundle");
        }

        if (!CreatePipe(&child_stdin_read, &parent_stdin_write, &sa, 0) ||
            !SetHandleInformation(parent_stdin_write, HANDLE_FLAG_INHERIT, 0) ||
            !CreatePipe(&parent_stdout_read, &child_stdout_write, &sa, 0) ||
            !SetHandleInformation(parent_stdout_read, HANDLE_FLAG_INHERIT, 0)) {
            if (child_stdin_read) CloseHandle(child_stdin_read);
            if (parent_stdin_write) CloseHandle(parent_stdin_write);
            if (parent_stdout_read) CloseHandle(parent_stdout_read);
            if (child_stdout_write) CloseHandle(child_stdout_write);
            unlock_helper();
            croak("CreatePipe() failed: %lu", (unsigned long)GetLastError());
        }

        ZeroMemory(&si, sizeof(si));
        ZeroMemory(&pi, sizeof(pi));
        si.cb = sizeof(si);
        si.dwFlags = STARTF_USESTDHANDLES;
        si.hStdInput = child_stdin_read;
        si.hStdOutput = child_stdout_write;
        si.hStdError = GetStdHandle(STD_ERROR_HANDLE);

        swprintf(command_line, sizeof(command_line)/sizeof(command_line[0]), L"\"%ls\"", helper_path);

        if (!CreateProcessW(
                helper_path,
                command_line,
                NULL,
                NULL,
                TRUE,
                CREATE_NO_WINDOW,
                NULL,
                NULL,
                &si,
                &pi)) {
            DWORD err = GetLastError();
            CloseHandle(child_stdin_read);
            CloseHandle(parent_stdin_write);
            CloseHandle(parent_stdout_read);
            CloseHandle(child_stdout_write);
            unlock_helper();
            croak("CreateProcessW() failed: %lu", (unsigned long)err);
        }

        CloseHandle(pi.hThread);
        CloseHandle(child_stdin_read);
        CloseHandle(child_stdout_write);
        helper_process = pi.hProcess;
        helper_write = parent_stdin_write;
        helper_read = parent_stdout_read;
        ok = 1;
#else
        if (!find_helper_path(helper_path, sizeof(helper_path))) {
            unlock_helper();
            croak("cannot locate system_menu_helper next to System::Menu bundle");
        }
        if (pipe(command_pipe) != 0) {
            unlock_helper();
            croak("command pipe() failed: %s", strerror(errno));
        }
        if (pipe(events_pipe) != 0) {
            close(command_pipe[0]); close(command_pipe[1]);
            unlock_helper();
            croak("event pipe() failed: %s", strerror(errno));
        }
        rc = posix_spawn_file_actions_init(&actions);
        if (rc != 0) {
            close(command_pipe[0]); close(command_pipe[1]);
            close(events_pipe[0]); close(events_pipe[1]);
            unlock_helper();
            croak("posix_spawn_file_actions_init() failed: %s", strerror(rc));
        }
        posix_spawn_file_actions_adddup2(&actions, command_pipe[0], STDIN_FILENO);
        posix_spawn_file_actions_adddup2(&actions, events_pipe[1], STDOUT_FILENO);
        posix_spawn_file_actions_addclose(&actions, command_pipe[0]);
        posix_spawn_file_actions_addclose(&actions, command_pipe[1]);
        posix_spawn_file_actions_addclose(&actions, events_pipe[0]);
        posix_spawn_file_actions_addclose(&actions, events_pipe[1]);
        argv[0] = helper_path;
        argv[1] = NULL;
        rc = posix_spawn(&pid, helper_path, &actions, NULL, argv, environ);
        posix_spawn_file_actions_destroy(&actions);
        close(command_pipe[0]);
        close(events_pipe[1]);
        if (rc != 0) {
            close(command_pipe[1]); close(events_pipe[0]);
            unlock_helper();
            croak("posix_spawn() failed: %s", strerror(rc));
        }
        flags = fcntl(events_pipe[0], F_GETFL, 0);
        if (flags >= 0) (void)fcntl(events_pipe[0], F_SETFL, flags | O_NONBLOCK);
        helper_fd = command_pipe[1];
        event_fd = events_pipe[0];
        helper_pid = pid;
        ok = 1;
#endif
    }
    unlock_helper();
    RETVAL = ok;
OUTPUT:
    RETVAL

int
_running()
PREINIT:
    int running;
CODE:
    lock_helper();
    running = helper_is_running_unlocked();
    unlock_helper();
    RETVAL = running;
OUTPUT:
    RETVAL

int
_command_json(value)
    const char *value
PREINIT:
    size_t len;
    int ok = 0;
CODE:
    lock_helper();
    if (helper_is_running_unlocked()) {
        len = strlen(value);
#ifdef _WIN32
        ok = write_all_win(helper_write, value, len) && write_all_win(helper_write, "\n", 1);
#else
        ok = write_all_posix(helper_fd, value, len) && write_all_posix(helper_fd, "\n", 1);
#endif
        if (!ok) close_helper_state_unlocked();
    }
    unlock_helper();
    if (!ok) croak("System::Menu helper is not running or command write failed");
    RETVAL = 1;
OUTPUT:
    RETVAL

SV *
_read_events()
PREINIT:
    char buf[8192];
    SV *out;
#ifdef _WIN32
    DWORD available = 0;
    DWORD n = 0;
#else
    ssize_t n;
#endif
CODE:
    out = newSVpvn("", 0);
    lock_helper();
#ifdef _WIN32
    if (helper_read) {
        while (PeekNamedPipe(helper_read, NULL, 0, NULL, &available, NULL) && available > 0) {
            DWORD want = available < sizeof(buf) ? available : (DWORD)sizeof(buf);
            if (!ReadFile(helper_read, buf, want, &n, NULL) || n == 0) break;
            sv_catpvn(out, buf, (STRLEN)n);
        }
    }
#else
    if (event_fd >= 0) {
        while (1) {
            n = read(event_fd, buf, sizeof(buf));
            if (n > 0) { sv_catpvn(out, buf, (STRLEN)n); continue; }
            if (n < 0 && errno == EINTR) continue;
            if (n < 0 && (errno == EAGAIN || errno == EWOULDBLOCK)) break;
            if (n == 0) { close(event_fd); event_fd = -1; break; }
            break;
        }
    }
#endif
    unlock_helper();
    RETVAL = out;
OUTPUT:
    RETVAL

int
_stop()
PREINIT:
    const char *json = "{\"op\":\"stop\"}\n";
#ifdef _WIN32
    HANDLE process = NULL;
#else
    pid_t pid = -1;
#endif
CODE:
    lock_helper();
    if (helper_is_running_unlocked()) {
#ifdef _WIN32
        process = helper_process;
        (void)write_all_win(helper_write, json, strlen(json));
        if (helper_write) { CloseHandle(helper_write); helper_write = NULL; }
        if (helper_read) { CloseHandle(helper_read); helper_read = NULL; }
        helper_process = NULL;
#else
        pid = helper_pid;
        (void)write_all_posix(helper_fd, json, strlen(json));
        if (helper_fd >= 0) { close(helper_fd); helper_fd = -1; }
        if (event_fd >= 0) { close(event_fd); event_fd = -1; }
        helper_pid = -1;
#endif
    }
    else {
        close_helper_state_unlocked();
    }
    unlock_helper();
#ifdef _WIN32
    if (process) {
        DWORD rc = WaitForSingleObject(process, 5000);
        if (rc == WAIT_TIMEOUT) TerminateProcess(process, 0);
        CloseHandle(process);
    }
#else
    if (pid > 0) {
        while (waitpid(pid, NULL, 0) < 0 && errno == EINTR) { }
    }
#endif
    RETVAL = 1;
OUTPUT:
    RETVAL
