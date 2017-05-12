#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/user.h>
#include <string.h>

#ifdef __FreeBSD__
#define KIP kinfo_proc
#define GETKIP KERN_PROC
#else
#define KIP kinfo_proc2
#define GETKIP KERN_PROC2
#endif

int
iphd_sysctl_is_waiting(int pid)
{
    struct KIP kip;
    size_t kipsz = sizeof(kip);
    int addr[4];
    int err;

    addr[0] = CTL_KERN;
    addr[1] = GETKIP;
    addr[2] = KERN_PROC_PID;
    addr[3] = pid;

    err = sysctl(addr, 4, &kip, &kipsz, NULL, 0);

    if (err < 0) {
        /* can happen due to races, so ignore XXX */
        return 0;
    }

#ifdef __FreeBSD__
    return kip.ki_stat == SSLEEP && !strcmp(kip.ki_wmesg, "ttyin");
#else
    return kip.p_stat == SSLEEP && !strcmp(kip.p_wmesg,
#ifdef __NetBSD__
            "ttyraw"
#else
            "ttyin"
#endif
            );
#endif
}
