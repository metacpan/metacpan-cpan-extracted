#include <errno.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ptrace.h>
#include <sys/uio.h>
#include <unistd.h>

#define die(fmt, args...)\
    fprintf(stderr, fmt "\n", ##args);\
    exit(1);

static uint32_t known_memory[] __attribute__((aligned (sizeof(void *)))) = { 0x11112222, 0x33334444, 0x55556666 };

int
main(void)
{
    pid_t child;

    child = fork();

    if(child == -1) {
        die("Unable to fork: %s", strerror(errno))
    }

    if(child) {
        ssize_t bytes_read;
        int status;
        uint32_t buffer[sizeof(known_memory) / sizeof(uint32_t)];
        struct iovec local;
        struct iovec remote;

        local.iov_base  = buffer;
        local.iov_len   = sizeof(buffer);
        remote.iov_base = known_memory;
        remote.iov_len  = sizeof(known_memory);

        waitpid(child, &status, 0);

        if(WIFEXITED(status)) {
            die("child died early");
        }

        bytes_read = process_vm_readv(child, &local, 1, &remote, 1, 0);

        if(bytes_read == -1) {
            die("process_vm_readv failed: %s", strerror(errno));
        }
        if(memcmp(known_memory, buffer, 4) != 0) {
            die("copied memory is incorrect");
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
