/*******************************************************************
 * Torture Half-Duplex on Microsoft Platforms
 *
 * This program is designed to drive the 150 known combinations of
 * input method, output method, and execution subsystem supported
 * on DOS/Windows.  It is intendend to cause problems for anyone
 * attempting a IO::Pty::HalfDuplex port.
 *
 * Subsystem is a compiler option, and must also be communicated:
 *  -DREALMODE   Raw DOS, 8088 style
 *  -DDPMI_16    16-bit DOS extenders running in a DOS box
 *  -DDPMI_32    ditto
 *  -DWIN16      Windows 3.x compatibility mode
 *  -DWIN32
 *  -DWIN64
 *
 * Input and output modes are specified on the command line, and
 * can be:
 *
 * hardware: direct port banging
 * bios: ROM interrupt calls
 * dos: DOS calls
 * unistd: POSIX calls (read/write)
 * stdio: C calls (getchar/putchar)
 * winfile: NT KERNEL32, WriteFile/ReadFile
 * consolea: NT console, WriteConsoleA/ReadConsoleA
 * consolew: NT console, WriteConsoleW/ReadConsoleW
 */

#include <stdio.h>

#if (defined(REALMODE) || defined(DPMI_16) || defined(DPMI_32)) \
    && defined(__WATCOMC__)

/* have I mentioned recently how awful the AT keyboard controller
   interface is? */

static int hw_setup_in(void) {
}

static void hw_teardown_in(void) {
}

static int hw_getc(void) {
}

static int curx, cury;

static int hw_setup_out(void) {
    /* fetch cursor position from VGA registers */
}

static void hw_teardown_out(void) {
}

static char[80][2] far *framebuffer;

static void hw_putc(int ch) {
    
}

/**/

#else

#define hw_setup_in 0
#define hw_setup_out 0
#define hw_teardown_in 0
#define hw_teardown_out 0
#define hw_getc 0
#define hw_putc 0

#define bios_getc 0
#define bios_putc 0

#define dos_getc 0
#define dos_putc 0

#endif

static void stdio_putc(int ch) {
    putchar(ch);
    fflush(stdout);
}

static int stdio_getc() {
    return getchar();
}

static void unistd_putc(int ch) {
    char ch2 = ch;
    write(1, &ch2, 1);
}

static int unistd_getc() {
    char buf;
    read(0, &buf, 1);
    return buf;
}

#if defined(WIN16) || defined(WIN32) || defined(WIN64)

#endif

struct method {
    const char *name;
    int (*setup_in)(void);
    void (*teardown_in)(void);
    int (*setup_out)(void);
    void (*teardown_out)(void);
    int (*getc)(void);
    void (*putc)(int);
} methods[] = {
    { "hardware", hw_setup_in, hw_teardown_in, hw_setup_out,
        hw_teardown_out, hw_getc, hw_putc },
    { "bios", 0, 0, 0, 0, bios_getc, bios_putc },
    { "dos", 0, 0, 0, 0, dos_getc, dos_putc },
    { "unistd", 0, 0, 0, 0, unistd_getc, unistd_putc },
    { "stdio", 0, 0, 0, 0, stdio_getc, stdio_putc },
    { "winfile", 0, 0, 0, 0, winfile_getc, winfile_putc },
    { "ntcona", 0, 0, 0, 0, ntcona_getc, ntcona_putc },
    { "ntconw", 0, 0, 0, 0, ntconw_getc, ntconw_putc },
    { 0, 0, 0, 0, 0, 0, 0 }
};

struct method *lookmethod(char *name) {
    struct method *p;

    for (p = methods; p->name; p++) {
        if (stricmp(name, p->name))
            continue;

        if (! p->getc) {
            printf("'%s' doesn't work on this platform.\n", p->name);
            exit(1);
        }

        return p;
    }

    printf("'%s' is unrecognized.\n", name);
    exit(1);
}

void foomain(char *in, char *out) {
    struct method *min = lookmethod(in);
    struct method *mout = lookmethod(out);

    if (min->setup_in && !(min->setup_in)()) {
        printf("'%s' (input) doesn't seem to be supported here.\n",
                min->name);
        exit(1);
    }

    if (mout->setup_out && !(mout->setup_out)()) {
        min->teardown_in();
        printf("'%s' (output) doesn't seem to be supported here.\n",
                mout->name);
        exit(1);
    }

    /* do something here */

    (min->teardown_in)();
    (min->teardown_out)();
}
