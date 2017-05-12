#include "EXTERN.h"
#include "perl.h"
#include "ppport.h"
#include "XSUB.h"

#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>
#include <fcntl.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <sys/ioctl.h>

/* must never be less than 3 */
#define BUF_SIZE 4096

static char exec_path[200];
static char command_path[200];
static char core_path_base[200];
static int skreech_to_a_halt = 0;

static void sig_core_handler(int signum);
static void extract_backtrace(int signum);
static void read_write(int rd, int ed, int wd);

#ifndef FAULT_AUTOBT_DEBUG
#define FAULT_AUTOBT_DEBUG 0
#endif

#if FAULT_AUTOBT_DEBUG
void Debug( const char * format, ...)
{
    va_list args;

    va_start(args, format);
    /* fprintf(stderr, "debug: "); */
    vfprintf(stderr, format, args);
    fflush(stderr);
    va_end(args);
}
#else
void Debug()
{
}
#endif



void
sig_int_handler(int signal)
{
    skreech_to_a_halt++;
}

#define INSTALL_SIGHANDLER(signal, signame) \
    if (sigaction(signal, &sa, NULL) < 0) { \
            Perl_croak(aTHX_ "cannot set " signame " action handler"); \
    } 

static void
set_sig_trap(pTHX)
{
    struct sigaction sa;

    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESETHAND; /* restore to the default on call */
    sa.sa_handler = sig_core_handler;

#ifdef SIGQUIT
    INSTALL_SIGHANDLER(SIGQUIT, "SIGQUIT");
#endif
    INSTALL_SIGHANDLER(SIGILL,  "SIGILL");
    INSTALL_SIGHANDLER(SIGTRAP, "SIGTRAP");
    INSTALL_SIGHANDLER(SIGABRT, "SIGABRT");
    INSTALL_SIGHANDLER(SIGFPE,  "SIGFPE");
    INSTALL_SIGHANDLER(SIGBUS,  "SIGBUS");
    INSTALL_SIGHANDLER(SIGSEGV, "SIGSEGV");
    INSTALL_SIGHANDLER(SIGSYS,  "SIGSYS");
#ifdef SIGEMT
    INSTALL_SIGHANDLER(SIGEMT,  "SIGEMT");
#endif 
    
}


static void
sig_core_handler(int signum)
{
    pid_t pid;
    
    /* immediately fork and let the child do the work */
    if((pid = fork()) == -1) {
        perror("fork");
        exit(1);
    }
    
    if (pid) {
        Debug("%d (patient): waiting for %d\n", (int)getpid(), pid);
        waitpid(pid, NULL, 0);  
        Debug("%d (patient): %d returned\n", (int)getpid(), pid);
    }
    else {
        extract_backtrace(signum);
    }
    exit(0);
}

#define CASE_SIGNAL(signal, signame) \
    case signal: \
        fprintf(stderr, "pid %d: received " signame "\n", (int)patient_pid); \
        break

static void
extract_backtrace(int signum)
{
    dTHX;
    int ifd[2], ofd[2], efd[2];
    FILE *core;
    pid_t pid, patient_pid;
    char pid_opt[20];
    char command[200];
    char core_file[200];
    const char *args[] = {
        "gdb", 
        "--batch",
        "--quiet",
        NULL,
        NULL,
        NULL,
        NULL
    };

    patient_pid = getppid();
    switch (signum) {
#ifdef SIGQUIT
        CASE_SIGNAL(SIGQUIT, "SIGQUIT");
#endif
        CASE_SIGNAL(SIGILL,  "SIGILL");
        CASE_SIGNAL(SIGTRAP, "SIGTRAP");
        CASE_SIGNAL(SIGABRT, "SIGABRT");
        CASE_SIGNAL(SIGFPE,  "SIGFPE");
        CASE_SIGNAL(SIGBUS,  "SIGBUS");
        CASE_SIGNAL(SIGSEGV, "SIGSEGV");
        CASE_SIGNAL(SIGSYS,  "SIGSYS");
#ifdef SIGEMT
        CASE_SIGNAL(SIGEMT,  "SIGEMT");
#endif
    default:
        fprintf(stderr, "pid %d: received unknown sig\n", (int)patient_pid);
    }
    fflush(stderr);
     
    /* gdb reads the command from this file */
    sprintf(command, "--command=%s", command_path);
    args[3] = command;
    args[4] = exec_path;
    /* gdb5.2+: sprintf(pid_opt, "--pid=%d", (int)getpid()); */
    sprintf(pid_opt, "%d", (int)patient_pid);
    args[5] = pid_opt;

    /* the core will be written into this file */
    sprintf(core_file, "%s%d", core_path_base, (int)patient_pid);
    
    Debug("openning core trace file: %s\n", core_file);
    if ((core = fopen(core_file, "w+")) == NULL) {
        Perl_croak(aTHX_ "failed to open %s for writing: %s ", core_file, strerror(errno));
    }
    
    if (pipe(ifd) == -1) {
        Perl_croak(aTHX_ "can't open pipe: %s", strerror(errno));
    }
    if (pipe(ofd) == -1) {
        Perl_croak(aTHX_ "can't open pipe: %s", strerror(errno));
    }
    if (pipe(efd) == -1) {
        Perl_croak(aTHX_ "can't open pipe: %s", strerror(errno));
    }

    if ((pid = fork()) == -1) {
        close(ifd[0]);
        close(ifd[1]);
        close(ofd[0]);
        close(ofd[1]);
        close(efd[0]);
        close(efd[1]);
        Perl_croak(aTHX_ "couldn't fork '%s'", strerror(errno));
    }

    if (!pid) { /* child */

        Debug("gdb's pid is: %d\n", getpid());
        
        Debug("%s %s %s %s %s %s\n", args[0], args[1], args[2],
              args[3], args[4], args[5]);

        close(ifd[1]);
        fclose(stdin);
        dup(ifd[0]);

        close(ofd[0]);
        fclose(stdout);
        dup(ofd[1]);

        close(efd[0]);
        fclose(stderr);
        dup(efd[1]);

        /* run the debugger */
        execvp(args[0], (char **)args);
        Perl_croak(aTHX_ "couldn't run '%s': %s", args[0], strerror(errno));
    }
    else { /* parent */
        fclose(stdin);

        close(ifd[0]);
        close(ofd[1]);
        close(efd[1]);

        fprintf(stderr, "writing to the core file %s\n", core_file);
        fprintf(core, "The trace:\n");
        fflush(core);

        Debug("reading results from gdb\n");
        read_write(ofd[0], efd[0], fileno(core));
        fflush(core);

        close(ifd[1]);
        close(ofd[0]);
        close(efd[0]);
        fclose(core);

        /* make sure that gdb is not hanging (for gdb < 5.2) */
        kill((int)pid, SIGKILL);
        
        waitpid(pid, NULL, 0);  
        Debug("%d: gdb has returned\n", (int)getpid());
        exit(0);
    }
}

static void
read_write_error(int ed, int wd)
{
    char buf[BUF_SIZE];
    ssize_t readlen, writelen;
    fd_set rfds;
    struct timeval tv;
       
    Debug("reading stderr\n");
    FD_ZERO(&rfds);
    FD_SET(ed, &rfds);
    tv.tv_sec = 0;
    tv.tv_usec = 1;

    if (select(ed + 1, &rfds, NULL, NULL, &tv)) {
        readlen = read(ed, buf, BUF_SIZE);
        if (readlen == -1) {
            /* might be EAGAIN (deadlock). Try writing instead */
            if (errno != EAGAIN) {
                perror("ProcessError read");
            }
        }
        else {
            buf[readlen] = '\0';
            Debug("stderr read %d: [%s]\n", readlen, buf);
            writelen = write(wd, buf, readlen);
            if (writelen != readlen) {
                perror("write");
            }
        }
    }
    
}
/* input: - a file descriptor to read stdout from
 *        - a file descriptor to read stderr from
 *        - a file descriptor to write to the read data
 */
static void
read_write(int rd, int ed, int wd)
{
    fd_set rfds;
    struct timeval tv;
    ssize_t readlen, writelen;
    char buf[BUF_SIZE];
    int fd_flags;
    int giveup_count = 0;
    int already_read = 0;

    if ((fd_flags = fcntl(rd, F_GETFL, 0)) == -1)
        perror("Could not get flags for fd");
    if (fcntl(rd, F_SETFL, fd_flags | O_NONBLOCK) == -1)
        perror("Could not set flags for fd");

    signal(SIGINT, sig_int_handler);
    
    /* while we're connected... */
    while (!skreech_to_a_halt) {
        FD_ZERO(&rfds);
        FD_SET(rd, &rfds);

        /* older perl versions (<5.8) don't seem to close the pipe
         * properly (they don't send eof to stdout) if the 'kill'
         * command is used in the gdb-command file, before 'qt'.
         * (without this 'kill' older gdbs hang). so if we read
         * something already and don't get anything on the pipe after
         * several more tries, chances are that nothing else will come
         * in, so we simply don't expect anything else and move on
         * XXX: need to find a better solution, since on slow systems
         * this approach might fail to get the whole trace
         */
        if (giveup_count++ > 150 && already_read) {
            skreech_to_a_halt = 1;
        }

        /* for some reason, if I make usec == 0 (poll), performance sucks */
        tv.tv_sec = 0;
        tv.tv_usec = 1;
        Debug("+");
        if (select(rd + 1, &rfds, NULL, NULL, &tv)) {
            /* can read */
            Debug("stuff to read...");
            if (FD_ISSET(rd, &rfds)) {
                already_read = 1;
                giveup_count = 0;
                Debug("...reading\n");
                readlen = read(rd, buf, BUF_SIZE);
                buf[readlen] = '\0';
                Debug("read %d: [%s]\n", readlen, buf);
                if (readlen == -1) {
                    if (errno != EAGAIN) {
                        perror("read");
                    }
                    continue;
                }
                if (readlen == 0) {
                    /* all done (eof) */
                    Debug("no more data to read\n");
                    skreech_to_a_halt = 1;
                    /* fflush(NULL); eh? */
                    continue;
                }
                /* Debug(buf); */
                writelen = write(wd, buf, readlen);
                if (writelen != readlen) {
                    perror("write");
                    break;
                }
            }
        }

        /* read_write_error(ed, wd); */
    }

    read_write_error(ed, wd);

    if (skreech_to_a_halt) {
        Debug("normal read aborted\n");
        fflush(NULL);
        return;
    }
    
    fflush(NULL);
    return;

}

XS(boot_Debug__DumpCore); /* proto */

MODULE=Debug::FaultAutoBT PACKAGE=Debug::FaultAutoBT

BOOT:
# boot the second XS file
boot_Debug__DumpCore(aTHX_ cv);


MODULE=Debug::FaultAutoBT PACKAGE=Debug::FaultAutoBT PREFIX=fault_auto_bt_

void
fault_auto_bt_set_segv_action(exec_path_in, command_path_in, core_path_base_in)
    char *exec_path_in
    char *command_path_in
    char *core_path_base_in
    
    CODE:
    strcpy(exec_path, exec_path_in);
    strcpy(command_path, command_path_in);
    strcpy(core_path_base, core_path_base_in);
    set_sig_trap(aTHX);


