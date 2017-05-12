#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifndef PERL_UNUSED_ARG
# define PERL_UNUSED_ARG(x) ((void)x)
#endif

static int signals[] = {
    SIGILL,
    SIGFPE,
    SIGBUS,
    SIGSEGV,
    SIGTRAP,
    SIGABRT,
    SIGQUIT
};

static char perl_path[PATH_MAX], gdb_path[PATH_MAX];

static void
register_sighandler (void (*handler)(int))
{
    unsigned int i;
    for (i = 0; i < sizeof(signals) / sizeof(signals[0]); i++) {
        signal(signals[i], handler);
    }
}

static void
stack_trace (char **args)
{
    pid_t pid;
    int in_fd[2], out_fd[2], idx, state;
    fd_set fdset;
    char buffer[4096];

    /* stop gdb from wrapping lines */
    snprintf(buffer, sizeof(buffer), "%u", (unsigned int)sizeof(buffer));
    setenv("COLUMNS", buffer, 1);

    if ((pipe(in_fd) == -1) || (pipe(out_fd) == -1)) {
        perror("unable to open pipe");
        _exit(0);
    }

    pid = fork();
    if (pid == 0) {
        /* double fork+_exit so we can properly detach from the parent
           process. this is important because some platforms (only OpenBSD for
           now) don't allow ptrace()ing their parent processes, which is what we
           need to be able to do to have a working gdb. */
        pid = fork();
        if (pid == 0) {
            char buf[16];
            /* just to be sure the kernel doesn't recognize us as an inferiour
               process */
            if (setsid() == (pid_t)-1) {
                perror("setsid failed");
                _exit(0);
            }

            close(0); dup(in_fd[0]);
            close(1); dup(out_fd[1]);
            close(2); dup(out_fd[1]);

            snprintf(buf, sizeof(buf), "%u\n", getpid());
            write(1, buf, strlen(buf));

            execvp(args[0], args);
            perror("exec failed");
            _exit(0);
        }
        else if (pid == (pid_t)-1) {
            perror("unable to fork");
            _exit(0);
        }
        else {
            _exit(0);
        }
    }
    else if (pid == (pid_t)-1) {
        perror("unable to fork");
        _exit(0);
    }

    FD_ZERO(&fdset);
    FD_SET(out_fd[0], &fdset);

    write(in_fd[1], "thread apply all backtrace\n", 27);
    write(in_fd[1], "quit\n", 5);

    idx = 0;
    state = 0;

    while (1) {
        pid_t gdb_pid;
        struct timeval tv;
        int sel;

        tv.tv_sec = 1;
        tv.tv_usec = 0;

        sel = select(FD_SETSIZE, &fdset, NULL, NULL, &tv);
        if (sel == -1)
            break;

        if ((sel > 0) && (FD_ISSET(out_fd[0], &fdset))) {
            char c;
            if (read(out_fd[0], &c, 1) > 0) {
                switch (state) {
                case 0:
                    state = 1;
                    idx = 0;
                    buffer[idx++] = c;
                    break;
                case 1:
                    buffer[idx++] = c;
                    if ((c == '\n') || (c == '\r')) {
                        buffer[idx] = 0;
                        gdb_pid = (pid_t)strtol(buffer, (char **)NULL, 10);
                        state = 2;
                        idx = 0;
                    }
                    break;
                case 2:
                    if (c == '#') {
                        state = 3;
                        idx = 0;
                        buffer[idx++] = c;
                    }
                    break;
                case 3:
                    buffer[idx++] = c;
                    if ((c == '\n') || (c == '\r')) {
                        buffer[idx] = 0;
                        write(1, buffer, strlen(buffer));
                        state = 2;
                        idx = 0;
                    }
                    break;
                default:
                    break;
                }
            }
        }
        else if (kill(gdb_pid, 0) < 0) {
            break;
        }
    }

    close(in_fd[0]);
    close(in_fd[1]);
    close(out_fd[0]);
    close(out_fd[1]);
    _exit(0);
}

static void
backtrace ()
{
    pid_t pid;
    char buf[16], *args[4];
    int status;

    snprintf(buf, sizeof(buf), "%u", (unsigned int)getpid());

    args[0] = gdb_path;
    args[1] = perl_path;
    args[2] = buf;
    args[3] = NULL;

    pid = fork();
    if (pid == 0) {
        stack_trace(args);
        _exit(0);
    }
    else if (pid == (pid_t)-1) {
        perror("unable to fork");
        return;
    }

    waitpid(pid, &status, 0);
}

static void
signal_handler (int sig) {
    PERL_UNUSED_ARG(sig);
    register_sighandler(SIG_DFL);
    backtrace();
    abort();
}

static void
register_segv_handler (char *gdb, char *perl)
{
    strncpy(gdb_path, gdb, sizeof(gdb_path));
    strncpy(perl_path, perl, sizeof(perl_path));
    register_sighandler(signal_handler);
}

MODULE = Devel::bt  PACKAGE = Devel::bt

PROTOTYPES: DISABLE

void
register_segv_handler (gdb, perl)
        char *gdb
        char *perl
