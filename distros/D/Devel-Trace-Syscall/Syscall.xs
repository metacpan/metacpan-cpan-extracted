#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <asm/unistd.h>
#include <sys/ptrace.h>
#include <sys/types.h>
#include <sys/uio.h>
#include <sys/user.h>
#include <sys/wait.h>
#include <unistd.h>

#include "syscall-lookup.h"
#include "syscall-info.h"
#include "config.h"

#define OK         0
#define FATAL      -1
#define PIPE_FULL  -2
#define PIPE_EMPTY -3

#define WORD_SIZE (sizeof(void *))
#define WORD_ALIGNED(p)\
    ((void *) (((unsigned long long)p) & (0xFFFFFFFFFFFFFFFF & ~(WORD_SIZE - 1))))

#ifdef __NR_mmap2
# define SYSCALL_IS_MMAP(value) ((value) == __NR_mmap || (value) == __NR_mmap2)
#else
# define SYSCALL_IS_MMAP(value) ((value) == __NR_mmap)
#endif

// a flag that indicates in the child process whether or not a system call
// that we care about has occurred.  The parent sets this via ptrace
static volatile int syscall_occurred __attribute__((aligned (WORD_SIZE))) = 0;

// a flag that indicates that the pipe has overflowed; too many events were generated
// at one time for the parent to send all of the data
static volatile int overflow_occurred __attribute__((aligned (WORD_SIZE))) = 0;

// a flag that indicates whether or not the child is flushing its event
// stream.  This is used so that system calls related to the behavior
// of this module don't pollute the event stream
static int is_flushing __attribute__((aligned (WORD_SIZE))) = 0;

// a pair of pipe file descriptors.  channel[0] corresponds to the read
// end (belonging to the child), channel[1] corresponds to the write end
// (belonging to the parent).  The parent sends information about the
// system calls invoked to the child via this pipe
static int channel[2];

// a lookup table indicating whether or not we care about a particular
// system call.
static int watching_syscall[MAX_SYSCALL_NO + 1];

extern const char *SYSCALL_ARGS[];

// this routine should only be called after calling a system call that
// can fail; other calls should assume that the callee has already called report_fatal_error
#define report_fatal_error() _report_fatal_error(__FILE__, __LINE__)
static int
_report_fatal_error(const char *filename, int line_no)
{
    if(errno == EPIPE) {
        warn("%s:%d: We can no longer communicate with the child; bailing!", filename, line_no);
    } else {
        warn("%s:%d: A logic error occurred in Devel::Trace::Syscall: %s", filename, line_no, strerror(errno));
    }
    return FATAL;
}

static void
flip_overflow(pid_t child)
{
    // ignoring any errors, because we can't really do anything about it
    // and the overflow stuff is for show
    ptrace(PTRACE_POKEDATA, child, (void *) &overflow_occurred, 1);
}

// writes count bytes of buffer or dies trying.  Handles short writes
// and EINTR, exiting if any other type of error occurs
static int
stubborn_write(int fd, const void *buffer, size_t count)
{
    size_t total_written = 0;
    ssize_t bytes_written;
    size_t offset = 0;

    while(total_written < count) {
        bytes_written = write(fd, buffer + offset, count - total_written);

        if(bytes_written < 0) {
            if(errno != EINTR) {
                return -1;
            }
        } else {
            offset        += bytes_written;
            total_written += bytes_written;
        }
    }
    return count;
}

// reads count bytes from fp into buffer or dies trying.  See stubborn_write
static int
stubborn_fread(void *buffer, size_t count, FILE *fp)
{
    size_t total_read = 0;
    size_t offset     = 0;

    while(total_read < count) {
        size_t bytes_read = fread(buffer + offset, 1, count - total_read, fp);

        total_read += bytes_read;
        offset     += bytes_read;

        if(bytes_read < (count - total_read)) {
            if(!ferror(fp) || errno != EINTR) {
                return -1;
            }
        }
    }
    return count;
}

static char
stubborn_fgetc(FILE *fp)
{
    char c;
    int status;

    status = stubborn_fread(&c, 1, fp);

    if(status == -1) {
        return EOF;
    }

    return c;
}

#if HAS_PROCESS_VM_READV
static int
pmemcpy(void *dst, size_t size, pid_t child, void *addr)
{
    struct iovec local;
    struct iovec remote;

    local.iov_base = dst;
    local.iov_len  = size;

    remote.iov_base = addr;
    remote.iov_len  = size;

    return (int) process_vm_readv(child,
        &local, 1,
        &remote, 1,
        0);
}
#else
static int
pmemcpy(void *dst, size_t size, pid_t child, void *addr)
{
    union {
        long l;
        char c[WORD_SIZE];
    } u;
    size_t offset       = addr - WORD_ALIGNED(addr);
    size_t bytes_copied = 0;
    addr -= offset;

    while(bytes_copied < size) {
        errno = 0;
        u.l   = ptrace(PTRACE_PEEKDATA, child, addr, 0);
        if(u.l == -1 && errno) {
            return -1;
        }
        if(size < WORD_SIZE) {
            memcpy(dst, u.c + offset, size - offset);
        } else {
            memcpy(dst, u.c + offset, WORD_SIZE - offset);
        }
        offset = 0;

        dst          += WORD_SIZE;
        addr         += WORD_SIZE;
        bytes_copied += WORD_SIZE;
    }

    return 0;
}
#endif

static void
handle_sigpipe(int signum)
{
    (void) signum;
}

static int
send_args(pid_t child, int fd, struct syscall_info *info)
{
    const char *arg = SYSCALL_ARGS[info->syscall_no];
    int arg_idx = 0;
    int status;

    if(! arg) {
        return OK;
    }

    while(*arg) {
        switch(*arg) {
            case 'z': // zero (NUL) terminated string
                {
                    char *child_p = (char *) info->args[arg_idx++];
                    char buffer[64];

                    while(1) {
                        char *end_p;

                        status = pmemcpy(buffer, 64, child, child_p);

                        if(status < 0) {
                            if(errno == EFAULT || errno == EIO) {
                                // this memory is inaccessible, so let's feed the
                                // child something digestable
                                strcpy(buffer, "<unable to access>");
                            } else {
                                return report_fatal_error();
                            }
                        }

                        end_p = memchr(buffer, 0, 64);

                        if(end_p) {
                            status = stubborn_write(fd, buffer, (end_p - buffer) + 1);
                        } else {
                            status = stubborn_write(fd, buffer, 64);
                            child_p += 64;
                        }
                        if(status < 0) {
                            if(errno == EAGAIN) {
                                flip_overflow(child);
                                return PIPE_FULL;
                            } else {
                                return report_fatal_error();
                            }
                        }

                        if(end_p) {
                            break;
                        }
                    }
                }
                break;
            case 'i': // signed int
            case 'u': // unsigned int
            case 'p': // pointer
            case 'o': // unsigned int (formatted in octal)
            case 'x': // unsigned int (formatted in hex)
                status = stubborn_write(fd, &info->args[arg_idx++], sizeof(info->args[0]));
                if(status < 0) {
                    if(errno == EAGAIN) {
                        flip_overflow(child);
                        return PIPE_FULL;
                    } else if(errno != EINTR) {
                        return report_fatal_error();
                    }
                }
                break;
        }
        arg++;
    }
    return OK;
}

static int
handle_syscall_enter(pid_t child)
{
    struct user userdata;
    struct syscall_info info;
    int status;

#if __sparc__
    status = ptrace(PTRACE_GETREGS, child, &userdata, 0);
#else
    status = ptrace(PTRACE_GETREGS, child, 0, &userdata);
#endif
    if(status == -1) {
        return report_fatal_error();
    }
    syscall_info_from_user(&userdata, &info);

    if(watching_syscall[info.syscall_no]) {
        if(info.syscall_no == __NR_write) {
            long child_is_flushing = ptrace(PTRACE_PEEKDATA, child, (void *) &is_flushing, 0);

            if(child_is_flushing == -1) {
                return report_fatal_error();
            }

            if(child_is_flushing) {
                return OK;
            }
        } else if(info.syscall_no == __NR_read && info.args[0] == channel[0]) {
            return OK;
        } else if(SYSCALL_IS_MMAP(info.syscall_no)) {
            if( ((int) info.args[4]) == -1) {
                return OK;
            }
        }

        status = stubborn_write(channel[1], &info.syscall_no, sizeof(uint16_t));

        if(status < 0) {
            if(errno == EAGAIN) {
                flip_overflow(child);

                return 1;
            } else if(errno != EINTR) {
                return report_fatal_error();
            }
        }

        status = ptrace(PTRACE_POKEDATA, child, (void *) &syscall_occurred, 1);
        if(status == -1) {
            return report_fatal_error();
        }

        status = send_args(child, channel[1], &info);
        if(status != OK && status != PIPE_FULL) {
            return status;
        }
        return 1;
    }
    return OK;
}

static int
handle_syscall_exit(pid_t child, int handled_previous_enter)
{
    if(handled_previous_enter) {
        struct user userdata;
        struct syscall_info info;
        int status;

#if __sparc__
        status = ptrace(PTRACE_GETREGS, child, &userdata, 0);
#else
        status = ptrace(PTRACE_GETREGS, child, 0, &userdata);
#endif
        if(status == -1) {
            return report_fatal_error();
        }
        syscall_info_from_user(&userdata, &info);

        status = stubborn_write(channel[1], &info.return_value, sizeof(int));
        if(status < 0) {
            if(errno == EAGAIN) {
                flip_overflow(child);
                return OK;
            } else if(errno != EINTR) {
                return report_fatal_error();
            }
        }
    }
    return OK;
}

static int
run_parent(pid_t child, int *exit_code)
{
    int status = -1;
    int enter = 1;
    int handled_previous_enter;

    while(status == -1) {
        status = waitpid(child, &status, 0);

        if(status == -1 && errno != EINTR) {
            return report_fatal_error();
        }
    }

#if HAS_PTRACE_O_EXITKILL
    status = ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_EXITKILL | PTRACE_O_TRACEEXIT | PTRACE_O_TRACESYSGOOD);
#else
    status = ptrace(PTRACE_SETOPTIONS, child, 0, PTRACE_O_TRACEEXIT | PTRACE_O_TRACESYSGOOD);
#endif

    if(status == -1) {
        return report_fatal_error();
    }
    status = ptrace(PTRACE_SYSCALL, child, 0, 0);
    if(status == -1) {
        return report_fatal_error();
    }

    signal(SIGPIPE, handle_sigpipe);

    while(waitpid(child, &status, 0) >= 0) {
        if(WIFSTOPPED(status) && WSTOPSIG(status) == (SIGTRAP | 0x80)) {
            if(enter) {
                handled_previous_enter = handle_syscall_enter(child);
                if(handled_previous_enter == FATAL) {
                    return FATAL;
                }
            } else {
                status = handle_syscall_exit(child, handled_previous_enter);
                if(status == FATAL) {
                    return FATAL;
                }
            }
            enter = !enter;
        } else if((status >> 8) == (SIGTRAP | PTRACE_EVENT_EXIT << 8)) {
            ptrace(PTRACE_GETEVENTMSG, child, 0, exit_code);
            // if this fails, we just end up with a 0 exit code, which is just fine
            *exit_code = WEXITSTATUS(*exit_code);
            break;
        }
        status = ptrace(PTRACE_SYSCALL, child, 0, 0);
        if(status == -1) {
            return report_fatal_error();
        }
    }
    return OK;
}

static int
read_and_print_args(FILE *fp, uint16_t syscall_no)
{
    const char *arg = SYSCALL_ARGS[syscall_no];
    int first = 1;

    if(! arg) {
        fprintf(stderr, "...");
        return OK;
    }

    while(*arg) {
        if(first) {
            first = 0;
        } else {
            fprintf(stderr, ", ");
        }

        if(*arg == 'z') {
            char c;
            fprintf(stderr, "\"");
            while((c = stubborn_fgetc(fp)) != '\0') {
                if(c == EOF) {
                    if(errno == EAGAIN) {
                        fprintf(stderr, "...\", ...");
                        return PIPE_EMPTY;
                    } else {
                        return report_fatal_error();
                    }
                }
                fputc(c, stderr);
            }
            fprintf(stderr, "\"");
        } else {
            const char *format_string = "";

            unsigned long long arg_value;
            int status = stubborn_fread(&arg_value, WORD_SIZE, fp);
            if(status == -1) {
                if(errno == EAGAIN) {
                    fprintf(stderr, "...");
                    return PIPE_EMPTY;
                } else {
                    return report_fatal_error();
                }
            }

            switch(*arg) {
                case 'i': format_string = "%d";   break;
                case 'u': format_string = "%u";   break;
                case 'p': format_string = "%p";   break;
                case 'o': format_string = "0%o";  break;
                case 'x': format_string = "0x%x"; break;
            }
            fprintf(stderr, format_string, arg_value);
        }

        arg++;
    }
    return OK;
}

extern void
init_syscall_args(void);

MODULE = Devel::Trace::Syscall PACKAGE = Devel::Trace::Syscall

void
import(...)
    INIT:
        int i;
        int status;
        pid_t child;
    CODE:
    {
        init_syscall_args();

        memset(watching_syscall, 0, sizeof(watching_syscall));
        for(i = 1; i < items; i++) {
            HE *entry = hv_fetch_ent(syscall_lookup, ST(i), 0, 0);

            if(entry) {
                int syscall_no = SvIVx(HeVAL(entry));
                if(syscall_no == __NR_brk) {
                    warn("*** Monitoring brk will likely result in a lot of events out of the control of your program due to memory allocation; disabling ***");
                    continue;
                } else if(SYSCALL_IS_MMAP(syscall_no)) {
                    warn("*** Monitoring mmap will *not* list mmap calls that are made purely for memory allocation, considering this is out of the control of your program ***");
                } else if(syscall_no == __NR_exit || syscall_no == __NR_exit_group) {
                    warn("*** Because of the way this module works, events for exit and exit_group will never appear. ***");
                    continue;
                }
                watching_syscall[syscall_no] = 1;
            } else {
                croak("unknown syscall '%s'", SvPVutf8_nolen(ST(i)));
            }
        }
        if(items <= 1) {
            croak("you must provide at least one system call to monitor");
        }

        status = pipe(channel);

        if(status == -1) {
            croak("failed to create pipe: %s\n", strerror(errno));
        }

        child = fork();

        if(child == -1) {
            croak("failed to fork: %s", strerror(errno));
        }

        if(child) {
            int status;
            int exit_code = 0;
            close(channel[0]);
            fcntl(channel[1], F_SETFL, O_NONBLOCK);
            status = run_parent(child, &exit_code);

            if(status < 0 && errno != EPIPE) {
                my_exit(1);
            }
            my_exit(exit_code);
        } else {
            close(channel[1]);
            fcntl(channel[0], F_SETFL, O_NONBLOCK);
            fcntl(channel[0], F_SETFD, FD_CLOEXEC);
            ptrace(PTRACE_TRACEME, 0, 0, 0);
            raise(SIGTRAP);
            XSRETURN_UNDEF;
        }
    }

void
flush_events(SV *trace)
    CODE:
        static FILE *fp = NULL; // we use stdio for buffering for the child's reads

        if(fp == NULL && channel[0] != 0) {
            fp = fdopen(channel[0], "r");
        }
        if(UNLIKELY(syscall_occurred)) {
            char *trace_chars = SvPVutf8_nolen(trace);
            uint16_t syscall_no;
            int status;

            syscall_occurred = 0;
            is_flushing      = 1;

            if(SvIV(PL_DBsingle)) {
                while(stubborn_fread(&syscall_no, sizeof(uint16_t), fp) > 0) {
                    int return_value;

                    fprintf(stderr, "%s(", syscall_names[syscall_no]);
                    status = read_and_print_args(fp, syscall_no);
                    if(status < 0) {
                        if(status == PIPE_EMPTY) {
                            clearerr(fp);
                            errno = 0;
                            fprintf(stderr, ") = ?%s", trace_chars);
                            break;
                        } else { // FATAL
                            my_exit(1);
                        }
                    }
                    status = stubborn_fread(&return_value, sizeof(int), fp);
                    if(status < 0) {
                        if(errno == EAGAIN) {
                            clearerr(fp);
                            errno = 0;
                            fprintf(stderr, ") = ?%s", trace_chars);
                            break;
                        } else { // FATAL
                            report_fatal_error();
                            my_exit(1);
                        }
                    }
                    fprintf(stderr, ") = %d%s", return_value, trace_chars);
                }

                if(ferror(fp) && errno != EAGAIN) {
                    report_fatal_error();
                }

                if(overflow_occurred) {
                    fprintf(stderr, "Overflow occurred; some events may have been lost\n");
                }
            } else {
                char buffer[1024];

                while(stubborn_fread(buffer, 1024, fp) > 0) {
                    // just discard it
                }
                if(ferror(fp) && errno != EAGAIN) {
                    report_fatal_error();
                }
            }
            overflow_occurred = 0;
            is_flushing       = 0;
        }

BOOT:
        CV *flush_events = get_cv("Devel::Trace::Syscall::flush_events", 0);
        CvNODEBUG_on(flush_events);
