#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ptrace.h>
#include <unistd.h>

#define die(fmt, args...)\
    fprintf(stderr, fmt "\n", ##args);\
    exit(1);

int
main(void)
{
    pid_t child;

    child = fork();

    if(child == -1) {
        die("Unable to fork: %s", strerror(errno))
    }

    if(child) {
        int status;

        waitpid(child, &status, 0);

        if(WIFEXITED(status)) {
            die("child died early");
        }

        status = ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_EXITKILL);

        if(status == -1) {
            die("ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_EXITKILL) failed: %s", strerror(errno));
        }
        ptrace(PTRACE_DETACH, child, 0, 0);

        waitpid(child, &status, 0);
    } else {
        int status;
        status = ptrace(PTRACE_TRACEME, 0, 0, 0);
        if(status == -1) {
            die("unable to set up ptrace: %s", strerror(errno));
        }
        raise(SIGTRAP);
        exit(0);
    }
    return 0;
}
