#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include <linux/cdrom.h>

#include "const-c.inc"

#define WARN_OFF \
    SV *oldwarn = PL_curcop->cop_warnings; \
    PL_curcop->cop_warnings = pWARN_NONE;

#define WARN_ON \
    PL_curcop->cop_warnings = oldwarn;

#define DEVICE_CDROM_NO_ERROR           0
#define DEVICE_CDROM_NO_OPEN            1
#define DEVICE_CDROM_NO_CDROM           2
#define DEVICE_CDROM_NO_TOCHDR          3
#define DEVICE_CDROM_NO_AUDIO           4
#define DEVICE_CDROM_NO_DISC_STATUS     5
#define DEVICE_CDROM_IDX_OUT_OF_BOUNDS  6
#define DEVICE_CDROM_IOCTL_ERROR        7

typedef struct CDROM {
    int                 fd;
    char                *device;    /* need device name for reopening it */
    int                 caps;       /* capabilities as returned by CDROM_GET_CAPABILITY */
    struct cdrom_tochdr *toch;   
    int                 num_frames;
} CDROM;

typedef struct CDROM_ADDR {
    union cdrom_addr addr;
    int type;
} CDROM_ADDR;

typedef struct cdrom_subchnl CDROM_SUBCHANNEL;

typedef struct cdrom_tocentry CDROM_TOCENTRY;

/* these two are derived from the kernel's drivers/cdrom/cdrom.c */
int msf_to_lba (char m, char s, char f) {
    return (((m * CD_SECS) + s) * CD_FRAMES + f) - CD_MSF_OFFSET;
}
void lba_to_msf (int lba, char *m, char *s, char *f) {
    *f = lba % CD_FRAMES;
    lba /= CD_FRAMES;
    lba += 2;
    *s = lba % CD_SECS;
    *m = lba / CD_SECS;
}

int reopen (CDROM *self) {
    close(self->fd);
    if ((self->fd = open(self->device, O_RDONLY|O_NONBLOCK)) == -1)
        return 0;
    return 1;
}

void to_lba (CDROM_ADDR *self) {
    if (self->type == CDROM_LBA)
        return;
    self->addr.lba = msf_to_lba(self->addr.msf.minute, self->addr.msf.second, self->addr.msf.frame);
    self->type = CDROM_LBA;
}

int
num_frames (CDROM *self) {
    long num;
    if (ioctl(self->fd, CDROM_LAST_WRITTEN, &num) == -1)
        return -1;
    return (self->num_frames = num);
}

/* $Linux::CDROM::error handling */
SV *CDERR;
void reg_error (int error) {
    STRLEN n_a;
    CDERR = get_sv("Linux::CDROM::error", FALSE);
    SvIVX(CDERR) = error;
    switch (error) {
        case DEVICE_CDROM_NO_ERROR:
            sv_setpvn(CDERR, "", 0);
            break;
        case DEVICE_CDROM_NO_OPEN:
            sv_setpvn(CDERR, "Couldn't open device: ", 22);
        case DEVICE_CDROM_NO_CDROM:
            sv_setpvn(CDERR, "Device is no CDROM drive: ", 26);
        case DEVICE_CDROM_NO_TOCHDR:
            sv_setpvn(CDERR, "Couldn't read TOC header: ", 26);
        case DEVICE_CDROM_NO_AUDIO:
            sv_setpvn(CDERR, "No Audio-CD: ", 13);
        case DEVICE_CDROM_NO_DISC_STATUS:
            sv_setpvn(CDERR, "Couldn't retrieve disc-status: ", 31);
        case DEVICE_CDROM_IDX_OUT_OF_BOUNDS:
            sv_setpvn(CDERR, "Index out of bounds: ", 21);
        case DEVICE_CDROM_IOCTL_ERROR:
            sv_setpvn(CDERR, "Generic ioctl error: ", 21);
        default: 
            sv_catpv(CDERR, SvPV(get_sv("!", FALSE), n_a));
    }
}

SV *DATSIZE;

#define INC_DATSIZE(i)      SvIVX(DATSIZE) += i
#define RESET_DATSIZE       SvIVX(DATSIZE) = 0

MODULE = Linux::CDROM		PACKAGE = Linux::CDROM

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

BOOT:
{
    CDERR = get_sv("Linux::CDROM::error", TRUE);
    SvUPGRADE(CDERR, SVt_PVIV);
    reg_error(DEVICE_CDROM_NO_ERROR);
    SvIOK_on(CDERR);
    DATSIZE = NEWSV(0,0);
    SvUPGRADE(DATSIZE, SVt_IV);
    SvIOK_on(DATSIZE);
    SvREADONLY_on(DATSIZE);

    /* overload stuff */
    PL_amagic_generation++;
    newXS("Linux::CDROM::Addr::()", XS_Linux__CDROM__Addr_noop, file);
    newXS("Linux::CDROM::Addr::(+", XS_Linux__CDROM__Addr_add, file);
    newXS("Linux::CDROM::Addr::(-", XS_Linux__CDROM__Addr_sub, file);
}

void
reset_datasize (...) 
    CODE:
    {
        RESET_DATSIZE;
    }

int
get_datasize (...)
    CODE:
    {
        RETVAL = SvIVX(DATSIZE);
    }
    OUTPUT:
        RETVAL

CDROM*
new (CLASS, device)
        char *CLASS;
        char *device;
    PREINIT:
        CDROM *cdrom;
        int fd;
        int caps;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
        if ((fd = open(device, O_RDONLY|O_NONBLOCK)) == -1) {
            reg_error(DEVICE_CDROM_NO_OPEN);
            XSRETURN_UNDEF;
        }
        if ((caps = ioctl(fd, CDROM_GET_CAPABILITY)) == -1) {
            reg_error(DEVICE_CDROM_NO_CDROM);
            close(fd);
            XSRETURN_UNDEF;
        } 
            
        New(0, cdrom, 1, CDROM);
        cdrom->fd = fd;
        cdrom->device = savepv(device);
        cdrom->caps = caps;
        cdrom->toch = NULL;
        cdrom->num_frames = -1;
        RETVAL = cdrom;
    }
    OUTPUT:
        RETVAL

void
fh (self)
        CDROM *self;
    PREINIT:
        char mode[8];
        GV *gv;
        STRLEN modlen;
    CODE:
    {
        modlen = sprintf(mode, "<&%i", self->fd);
        gv = newGVgen("main");
        sv_dump((SV*)gv);
        do_openn(gv, mode, modlen, FALSE, O_RDONLY|O_NONBLOCK, 0, Nullfp, (SV**)NULL, 0);
        sv_setsv(ST(0), sv_2mortal(newRV_noinc((SV*)gv)));
        XSRETURN(1);
    }

void
close (self)
        CDROM *self;
    CODE:
    {
        if (close(self->fd) == -1)
            XSRETURN_UNDEF;
        self->fd = -1;
        XSRETURN_YES;
    }
       
void
reopen (self)
        CDROM *self;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
        if (reopen(self)) 
            XSRETURN_YES;
        reg_error(DEVICE_CDROM_NO_OPEN);
        XSRETURN_UNDEF;
    }

int
capabilities (self)
        CDROM *self;
    CODE:
    {
        if (self->caps == -2) {
            self->caps = ioctl(self->fd, CDROM_GET_CAPABILITY);
            if (self->caps == -1)
                XSRETURN_UNDEF;
        }
        RETVAL = self->caps;
    }
    OUTPUT:
        RETVAL

int
drive_status (self)
        CDROM *self;
    PREINIT:
        int status;
    CODE:
    {
        if ((status = ioctl(self->fd, CDROM_DRIVE_STATUS)) == -1)
            XSRETURN_UNDEF;
        RETVAL = status;
    }
    OUTPUT:
        RETVAL
      
UV
disc_status (self)
        CDROM *self;
    PREINIT:
        int status;
    CODE:
    {
        if ((status = ioctl(self->fd, CDROM_DISC_STATUS)) == -1)
            XSRETURN_UNDEF;
        RETVAL = status;
    }
    OUTPUT:
        RETVAL

NV
num_frames (self)
        CDROM *self;
    PREINIT:
        long last;
    CODE:
    {
        if (self->num_frames == -1)
            if (ioctl(self->fd, CDROM_LAST_WRITTEN, &last) == -1)
                XSRETURN_UNDEF;
        RETVAL = last;
    }
    OUTPUT:
        RETVAL

NV
next_writable (self)
        CDROM *self;
    PREINIT:
        long next;
    CODE:
    {
        if (ioctl(self->fd, CDROM_NEXT_WRITABLE, &next) == -1)
            XSRETURN_UNDEF;
        RETVAL = next;
    }
    OUTPUT:
        RETVAL

int
get_spindown (self)
        CDROM *self;
    PREINIT:
        int sd;
    CODE:
    {
        if (ioctl(self->fd, CDROMGETSPINDOWN, &sd) == -1)
            XSRETURN_UNDEF;
        RETVAL = (char)sd;
    }
    OUTPUT:
        RETVAL

void
set_spindown (self, sd)
        CDROM *self;
        int sd;
    CODE:
    {
        if (ioctl(self->fd, CDROMSETSPINDOWN, (void*)&sd) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
reset (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMRESET) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }
    
void
eject (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMEJECT) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void 
auto_eject (self, val)
        CDROM *self;
        int val;
    CODE:
    {
        if (ioctl(self->fd, CDROMEJECT_SW, val) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void 
close_tray (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMCLOSETRAY, 0) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
lock_door (self, val)
        CDROM *self;
        int val;
    CODE:
    {
        if (ioctl(self->fd, CDROM_LOCKDOOR, val) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
media_changed (self)
        CDROM *self;
    PREINIT:
        int changed;
    CODE:
    {
        if ((changed = ioctl(self->fd, CDROM_MEDIA_CHANGED)) == -1)
            XSRETURN_UNDEF;
        if (changed)
            XSRETURN_YES;
        else
            XSRETURN_NO;
    }

void
mcn (self)
        CDROM *self;
    PREINIT:
        struct cdrom_mcn mcn;
    CODE:
    {
        if (ioctl(self->fd, CDROM_GET_MCN, &mcn) == -1)
            XSRETURN_UNDEF;
        ST(0) = sv_2mortal(newSVpvn(mcn.medium_catalog_number, 13));
        XSRETURN(1);
    }


void
get_vol (self)
        CDROM *self;
    PREINIT:
        struct cdrom_volctrl vol;
    CODE:
    {
        if (ioctl(self->fd, CDROMVOLREAD, &vol) == -1)
            XSRETURN_UNDEF;
        EXTEND(SP, 4);
        ST(0) = sv_2mortal(newSVuv(vol.channel0));
        ST(1) = sv_2mortal(newSVuv(vol.channel1));
        ST(2) = sv_2mortal(newSVuv(vol.channel2));
        ST(3) = sv_2mortal(newSVuv(vol.channel3));
        XSRETURN(4);
    }
  
void 
set_vol (self, v0, v1, v2, v3)
        CDROM *self;
        unsigned int v0; 
        unsigned int v1; 
        unsigned int v2;
        unsigned int v3;
    PREINIT:
        struct cdrom_volctrl vol;
    CODE:
    {
        vol.channel0 = v0;
        vol.channel1 = v1;
        vol.channel2 = v2;
        vol.channel3 = v3;
        if (ioctl(self->fd, CDROMVOLCTRL, &vol) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
play_msf (self, from, to) 
        CDROM *self;
        CDROM_ADDR *from;
        CDROM_ADDR *to;
    PREINIT:
        struct cdrom_msf msf;
        int status;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
        
        if ((status = ioctl(self->fd, CDROM_DISC_STATUS)) == -1) {
            reg_error(DEVICE_CDROM_NO_DISC_STATUS);
            XSRETURN_UNDEF;
        }

        if (! status & CDS_AUDIO) {
            reg_error(DEVICE_CDROM_NO_AUDIO);
            XSRETURN_UNDEF;
        }
        
        lba_to_msf(from->addr.lba, &msf.cdmsf_min0, &msf.cdmsf_sec0, &msf.cdmsf_frame0);
        lba_to_msf(to->addr.lba, &msf.cdmsf_min1, &msf.cdmsf_sec1, &msf.cdmsf_frame1);
        if (ioctl(self->fd, CDROMPLAYMSF, &msf) == -1) {
            reg_error(DEVICE_CDROM_IOCTL_ERROR);
            XSRETURN_UNDEF;
        }
        XSRETURN_YES;
    }
   
void
play_ti (self, ...)
        CDROM *self;
    PREINIT:
        register int i;
        int fromtr  = 0;
        int fromidx = 0;
        int totr    = 0;
        int toidx   = 0;
        struct cdrom_ti ti;
        int dotochdr = 2;
        int status;
        STRLEN n_a;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
       
        if ((status = ioctl(self->fd, CDROM_DISC_STATUS)) == -1) {
            reg_error(DEVICE_CDROM_NO_DISC_STATUS);
            XSRETURN_UNDEF;
        }

        if (! status & CDS_AUDIO) {
            reg_error(DEVICE_CDROM_NO_AUDIO);
            XSRETURN_UNDEF;
        }
            
        /* temporarily shut up warnings */
        WARN_OFF;
        for (i = 1; i+1 < items; i++) {
            if (strEQ(SvPV(ST(i), n_a), "-from")) {
                i++;
                fromtr = SvIV(ST(i));
                dotochdr--;
                continue;
            } 
            if (strEQ(SvPV(ST(i), n_a), "-to")) {
                i++;
                totr = SvIV(ST(i));
                dotochdr--;
                continue;
            }
            if (strEQ(SvPV(ST(i), n_a),  "-fromidx")) {
                i++;
                fromidx = SvIV(ST(i));
                continue;
            }
            if (strEQ(SvPV(ST(i), n_a), "-toidx")) {
                i++;
                toidx = SvIV(ST(i));
                continue;
            }
        }
        /* warning-prone code done so restore old
         * warnings bit-mask */
        WARN_ON;
        
        if (dotochdr) {
            if (!self->toch) {
                New(0, self->toch, 1, struct cdrom_tochdr);
                if (ioctl(self->fd, CDROMREADTOCHDR, self->toch) == -1) {
                    reg_error(DEVICE_CDROM_NO_TOCHDR);
                    XSRETURN_UNDEF;
                }
                else {
                    fromtr = 1;
                    totr = self->toch->cdth_trk1;
                }
            }
        }
        
        ti.cdti_trk0 = (__u8)fromtr;
        ti.cdti_ind0 = (__u8)fromidx;
        ti.cdti_trk1 = (__u8)totr;
        ti.cdti_ind1 = (__u8)toidx;

        if (ioctl(self->fd, CDROMPLAYTRKIND, &ti) == -1) {
            reg_error(DEVICE_CDROM_IOCTL_ERROR);
            XSRETURN_UNDEF;
        }
        XSRETURN_YES;
    }
      
void
pause (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMPAUSE) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
resume (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMRESUME) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
start (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMSTART) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void 
stop (self)
        CDROM *self;
    CODE:
    {
        if (ioctl(self->fd, CDROMSTOP) == -1)
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
read1 (self, addr)
        CDROM *self;
        CDROM_ADDR *addr;
    PREINIT:
        struct cdrom_msf *data;
    CODE:
    {
        New(0, data, CD_FRAMESIZE, char);

        lba_to_msf(addr->addr.lba, &data->cdmsf_min0, &data->cdmsf_sec0, &data->cdmsf_frame0);

        if (ioctl(self->fd, CDROMREADMODE1, data) == -1) {
            Safefree(data);
            XSRETURN_UNDEF;
        }
        
        ST(0) = sv_newmortal();
        sv_usepvn(ST(0), (char*)data, CD_FRAMESIZE);
        XSRETURN(1);
    }

void
read2 (self, addr)
        CDROM *self;
        CDROM_ADDR *addr;
    PREINIT:
        struct cdrom_msf *data;
    CODE:
    {
        New(0, data, CD_FRAMESIZE_RAW0, char);

        lba_to_msf(addr->addr.lba, &data->cdmsf_min0, &data->cdmsf_sec0, &data->cdmsf_frame0);

        if (ioctl(self->fd, CDROMREADMODE2, data) == -1) {
            Safefree(data);
            XSRETURN_UNDEF;
        }
      
        ST(0) = sv_newmortal();
        sv_usepvn(ST(0), (char*)data, CD_FRAMESIZE_RAW0);
        XSRETURN(1);
    }
    
void
read_audio (self, addr, nframes)
        CDROM *self;
        CDROM_ADDR *addr;
        int nframes;
    PREINIT:
        struct cdrom_read_audio audio;
        int ret;
        int status;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
       
        /* bound checking stuff */
        
        if (self->num_frames == -1)
            status = num_frames(self);

        if (status >= 0) {
            if (addr->addr.lba >= self->num_frames) {
                reg_error(DEVICE_CDROM_IDX_OUT_OF_BOUNDS);
                XSRETURN_UNDEF;
            }
            /* detect reading-beyond-last-frame case and correct
             * the number of frames */
            if (addr->addr.lba + nframes - 1 >= self->num_frames)
                nframes = self->num_frames - addr->addr.lba;
        }
        
        Newz(0, audio.buf, nframes * CD_FRAMESIZE_RAW, __u8);
        audio.addr = addr->addr;
        audio.addr_format = addr->type;
        audio.nframes = nframes;
        if ((ret = ioctl(self->fd, CDROMREADAUDIO, &audio)) == -1) {
            Safefree(audio.buf);
            XSRETURN_UNDEF;
        }

        INC_DATSIZE(CD_FRAMESIZE_RAW * nframes);
        ST(0) = sv_newmortal();
        sv_usepvn(ST(0), audio.buf, nframes*CD_FRAMESIZE_RAW);
        XSRETURN(1);
    }

#if 0
void
read_cooked (self, lba)
        CDROM *self;
        int lba;
    PREINIT:
        struct cdrom_msf *data;
    CODE:
    {
        New(0, (char*)data, CD_FRAMESIZE, char);

        lba_to_msf(lba, &data->cdmsf_min0, &data->cdmsf_sec0, &data->cdmsf_frame0);

        if (ioctl(self->fd, CDROMREADCOOKED, data) == -1) {
            Safefree(data);
            XSRETURN_UNDEF;
        }
      
        ST(0) = sv_newmortal();
        sv_usepvn(ST(0), (char*)data, CD_FRAMESIZE);
        XSRETURN(1);
    }

#endif

void
read_raw (self, addr)
        CDROM *self;
        CDROM_ADDR *addr;
    PREINIT:
        struct cdrom_msf *data;
    CODE:
    {
        New(0, data, CD_FRAMESIZE_RAW, char);

        lba_to_msf(addr->addr.lba, &data->cdmsf_min0, &data->cdmsf_sec0, &data->cdmsf_frame0);

        if (ioctl(self->fd, CDROMREADRAW, data) == -1) {
            Safefree(data);
            XSRETURN_UNDEF;
        }
      
        ST(0) = sv_newmortal();
        sv_usepvn(ST(0), (char*)data, CD_FRAMESIZE_RAW);
        XSRETURN(1);
    }

CDROM_SUBCHANNEL*
poll (self)
        CDROM *self;
    PREINIT:
        CDROM_SUBCHANNEL *subch;
    CODE:
    {
        New(0, subch, 1, CDROM_SUBCHANNEL);
        subch->cdsc_format = CDROM_LBA;
        if (ioctl(self->fd, CDROMSUBCHNL, subch) == -1) {
            Safefree(subch);
            XSRETURN_UNDEF;
        }
        RETVAL = subch;
    }
    OUTPUT:
        RETVAL
   
void
toc (self)
        CDROM *self;
    CODE:
    {
        if (!self->toch) {
            New(0, self->toch, 1, struct cdrom_tochdr);
            if (ioctl(self->fd, CDROMREADTOCHDR, self->toch) == -1) {
                Safefree(self->toch);
                XSRETURN_UNDEF;
            }
        }
        EXTEND(SP, 2);
        ST(0) = sv_2mortal(newSVuv(self->toch->cdth_trk0));
        ST(1) = sv_2mortal(newSVuv(self->toch->cdth_trk1));
        XSRETURN(2);
    }

CDROM_TOCENTRY*
toc_entry (self, idx)
        CDROM *self;
        int idx;
    PREINIT:
        CDROM_TOCENTRY *entry;
    CODE:
    {
        reg_error(DEVICE_CDROM_NO_ERROR);
        if (!self->toch) {
            New(0, self->toch, 1, struct cdrom_tochdr);
            if (ioctl(self->fd, CDROMREADTOCHDR, self->toch) == -1) {
                reg_error(DEVICE_CDROM_NO_TOCHDR);
                Safefree(self->toch);
                XSRETURN_UNDEF;
            }
        }
        
        if (idx < self->toch->cdth_trk0 || idx > self->toch->cdth_trk1 && idx != CDROM_LEADOUT) {
            reg_error(DEVICE_CDROM_IDX_OUT_OF_BOUNDS);
            XSRETURN_UNDEF;
        }

        New(0, entry, 1, CDROM_TOCENTRY);
        entry->cdte_track  = (__u8)idx;
        entry->cdte_format = CDROM_LBA;
        if (ioctl(self->fd, CDROMREADTOCENTRY, entry) == -1) {
            reg_error(DEVICE_CDROM_IOCTL_ERROR);
            Safefree(entry);
            XSRETURN_UNDEF;
        }
        RETVAL = entry;
    }
    OUTPUT:
        RETVAL

void
is_multisession (self)
        CDROM *self;
    PREINIT:
        struct cdrom_multisession ms;
    CODE:
    {
        ms.addr_format = CDROM_LBA;
        if (ioctl(self->fd, CDROMMULTISESSION, &ms) == -1)
            XSRETURN_UNDEF;
        if (ms.xa_flag) 
            XSRETURN_YES;
        else
            XSRETURN_NO;
    }
    
void
ioctl (self, func, arg) 
        CDROM *self;
        int func;
        SV *arg;
    PREINIT:
        unsigned char *data;
        STRLEN dlen, need;
    CODE:
    {
        /* this is derived from Perl's pp_sys.c:pp_ioctl */
        WARN_OFF;
        data = SvPV_force(arg, dlen);
        need = IOCPARM_LEN(func);
        if (dlen < need) {
            data = SvGROW(arg, need+1);
            SvCUR_set(arg, need);
        }
        WARN_ON;
        if (ioctl(self->fd, func, data) == -1) 
            XSRETURN_UNDEF;
        XSRETURN_YES;
    }

void
DESTROY (self)
        CDROM *self;
    CODE:
    {
        close(self->fd);
        Safefree(self);
    }

MODULE = Linux::CDROM      PACKAGE = Linux::CDROM::Addr

void
noop (...)
    CODE:
    {
        croak("This should never happen");
    }

CDROM_ADDR*
add (addr1, addr2, ...)
        CDROM_ADDR *addr1;
        SV *addr2;
    PREINIT:
        CDROM_ADDR *delta;
        int lba1, lba2;
    CODE:
    {
        lba1 = addr1->addr.lba;
        
        /* second argument could be object or an integer */
        if (!sv_isobject(addr2))
            lba2 = SvIV(addr2);
        else {
            CDROM_ADDR *a = (CDROM_ADDR*) SvIV( (SV*)SvRV(addr2) );
            lba2 = a->addr.lba;
        }
           
        New(0, delta, 1, CDROM_ADDR);
        delta->type = CDROM_LBA;
        delta->addr.lba = lba1 + lba2;
        RETVAL = delta;
    }
    OUTPUT:
        RETVAL

CDROM_ADDR*
sub (addr1, addr2, swap)
        CDROM_ADDR *addr1;
        SV *addr2;
        IV swap;
    PREINIT:
        CDROM_ADDR *delta;
        int lba1, lba2;
    CODE:
    {
        lba1 = addr1->addr.lba;

        /* second argument could be object or an integer */
        if (!sv_isobject(addr2))
            lba2 = SvIV(addr2);
        else {
            CDROM_ADDR *a = (CDROM_ADDR*) SvIV( (SV*)SvRV(addr2) );
            lba2 = a->addr.lba;
        }
        
        New(0, delta, 1, CDROM_ADDR);
        delta->type = CDROM_LBA;
        delta->addr.lba = swap ? lba2 - lba1 : lba1 - lba2;
        RETVAL = delta;
    }
    OUTPUT:
        RETVAL


CDROM_ADDR*
new (CLASS, type, ...)
        char *CLASS;
        int type;
    PREINIT:
        CDROM_ADDR *addr;
    CODE:
    {
        if (type == CDROM_LBA) { 
            if (items != 3)
                croak("Usage: Linux::CDROM::Addr->new(CDROM_LBA, $frame)");
            else {
                New(0, addr, 1, CDROM_ADDR);
                addr->addr.lba = POPi;
            }
        } 
        else if (type == CDROM_MSF) {
            if (items != 5)
                croak("Usage: Linux::CDROM::Addr->new(CDROM_MSF, $min, $sec, $frame)");
            else {
                New(0, addr, 1, CDROM_ADDR);
                addr->addr.msf.minute   = (__u8)SvIV(ST(2));
                addr->addr.msf.second   = (__u8)SvIV(ST(3));
                addr->addr.msf.frame    = (__u8)SvIV(ST(4));
            }
        }
        else 
            croak("First argument to Linux::CDROM::Addr->new() must be either CDROM_LBA or CDROM_MSF");

        addr->type = type;
        to_lba(addr);
        RETVAL = addr;
    }
    OUTPUT:
        RETVAL

int
frame (self)
        CDROM_ADDR *self;
    PREINIT:
        int lba;
        char min, sec, frame;
    CODE:
    {
        lba = self->addr.lba;
        lba_to_msf(lba, &min, &sec, &frame);
        RETVAL = frame;
    }
    OUTPUT:
        RETVAL

int
second (self)
        CDROM_ADDR *self;
    PREINIT:
        int lba;
        char min, sec, frame;
    CODE:
    {
        lba = self->addr.lba;
        lba_to_msf(lba, &min, &sec, &frame);
        RETVAL = sec;
    }
    OUTPUT:
        RETVAL

int
minute (self)
        CDROM_ADDR *self;
    PREINIT:
        int lba;
        char min, sec, frame;
    CODE:
    {
        lba = self->addr.lba;
        lba_to_msf(lba, &min, &sec, &frame);
        RETVAL = min;
    }
    OUTPUT:
        RETVAL

int
as_lba (self)
        CDROM_ADDR *self;
    CODE:
    {
        RETVAL = self->addr.lba;
    }
    OUTPUT:
        RETVAL
        
void
as_msf (self)
        CDROM_ADDR *self;
    PREINIT:
        int lba;
        char min, sec, frame;
    CODE:
    {
        lba = self->addr.lba;
        lba_to_msf(lba, &min, &sec, &frame);
        ST(0) = sv_2mortal(newSVuv(min));
        ST(1) = sv_2mortal(newSVuv(sec));
        ST(2) = sv_2mortal(newSVuv(frame));
        XSRETURN(3);
    }
        
void
DESTROY (self)
        CDROM_ADDR *self;
    CODE:
    {
        Safefree(self);
    }

MODULE = Linux::CDROM      PACKAGE = Linux::CDROM::Subchannel

int
status (self) 
        CDROM_SUBCHANNEL *self;
    CODE:
    {
        RETVAL = self->cdsc_audiostatus;
    }
    OUTPUT:
        RETVAL

CDROM_ADDR*
abs_addr (self)
        CDROM_SUBCHANNEL *self;
    PREINIT:
        CDROM_ADDR *addr;
    CODE:
    {
        New(0, addr, 1, CDROM_ADDR);
        addr->type = CDROM_LBA;
        addr->addr = self->cdsc_absaddr;
        RETVAL = addr;
    }
    OUTPUT:
        RETVAL
        
CDROM_ADDR*
rel_addr (self)
        CDROM_SUBCHANNEL *self;
    PREINIT:
        CDROM_ADDR *addr;
    CODE:
    {
        New(0, addr, 1, CDROM_ADDR);
        addr->type = CDROM_LBA;
        addr->addr = self->cdsc_reladdr;
        RETVAL = addr;
    }
    OUTPUT:
        RETVAL

int
track (self)
        CDROM_SUBCHANNEL *self;
    CODE:
    {
        RETVAL = self->cdsc_trk;
    }
    OUTPUT:
        RETVAL

int
index (self)
        CDROM_SUBCHANNEL *self;
    CODE:
    {
        RETVAL = self->cdsc_ind;
    }
    OUTPUT:
        RETVAL

void
DESTROY (self)
        CDROM_SUBCHANNEL *self;
    CODE:
    {
        Safefree(self);
    }

MODULE = Linux::CDROM      PACKAGE = Linux::CDROM::TocEntry

CDROM_ADDR*
addr (self)
        CDROM_TOCENTRY *self;
    PREINIT:
        CDROM_ADDR *addr;
    CODE:
    {
        New(0, addr, 1, CDROM_ADDR);
        addr->type = CDROM_LBA;
        addr->addr = self->cdte_addr;
        RETVAL = addr;
    }
    OUTPUT:
        RETVAL

int
adr (self)
        CDROM_TOCENTRY *self;
    CODE:
    {
        RETVAL = self->cdte_adr;
    }
    OUTPUT:
        RETVAL

int
is_data (self)
        CDROM_TOCENTRY *self;
    CODE:
    {
        RETVAL = (self->cdte_ctrl & CDROM_DATA_TRACK) > 0;
    }
    OUTPUT:
        RETVAL

int
is_audio (self)
        CDROM_TOCENTRY *self;
    CODE:
    {
        RETVAL = (self->cdte_ctrl & CDROM_DATA_TRACK) == 0;
    }
    OUTPUT:
        RETVAL

void
DESTROY (self)
        CDROM_TOCENTRY *self;
    CODE:
    {
        Safefree(self);
    }

MODULE = Linux::CDROM      PACKAGE = Linux::CDROM::Format

void
raw2yellow1 (CLASS, data)
        char *CLASS;
        char *data;
    CODE:
    {
        EXTEND(SP, 6);
        ST(0) = sv_2mortal(newSVpvn(data, 12));         /* sync */
        ST(1) = sv_2mortal(newSVpvn(data+12, 4));       /* head */
        ST(2) = sv_2mortal(newSVpvn(data+16, 2048));    /* data */
        ST(3) = sv_2mortal(newSVpvn(data+2064, 4));     /* EDC */
        ST(4) = sv_2mortal(newSVpvn(data+2068, 8));     /* zero */
        ST(5) = sv_2mortal(newSVpvn(data+2076, 276));   /* ECC */
        XSRETURN(6);
    }

void
raw2yellow2 (CLASS, data)
        char *CLASS;
        char *data;
    CODE:
    {
        EXTEND(SP, 3);
        ST(0) = sv_2mortal(newSVpvn(data, 12));         /* sync */
        ST(1) = sv_2mortal(newSVpvn(data+12, 4));       /* head */
        ST(2) = sv_2mortal(newSVpvn(data+16, 2336));    /* data */
        XSRETURN(3);
    }

void
raw2green1 (CLASS, data)
        char *CLASS;
        char *data;
    CODE:
    {
        EXTEND(SP, 6);
        ST(0) = sv_2mortal(newSVpvn(data, 12));         /* sync */
        ST(1) = sv_2mortal(newSVpvn(data+12, 4));       /* head */
        ST(2) = sv_2mortal(newSVpvn(data+16, 8));       /* sub */
        ST(3) = sv_2mortal(newSVpvn(data+24, 2048));    /* data */
        ST(4) = sv_2mortal(newSVpvn(data+2072, 4));     /* EDC */
        ST(5) = sv_2mortal(newSVpvn(data+2076, 276));   /* ECC */
        XSRETURN(6);
    }

void
raw2green2 (CLASS, data)
        char *CLASS;
        char *data;
    CODE:
    {
        EXTEND(SP, 5);
        ST(0) = sv_2mortal(newSVpvn(data, 12));         /* sync */
        ST(1) = sv_2mortal(newSVpvn(data+12, 4));       /* head */
        ST(2) = sv_2mortal(newSVpvn(data+16, 8));       /* sub */
        ST(3) = sv_2mortal(newSVpvn(data+24, 2324));    /* data */
        ST(4) = sv_2mortal(newSVpvn(data+2348, 4));     /* EDC */
        XSRETURN(5);
    } 

void
wav_header (CLASS, bytes)
        char *CLASS;
        unsigned int bytes;
    CODE:
    {
        struct {
            char	RiffTag[4]; 	// 'RIFF'
            int32_t	FileLength;
            char	FormatTag[8];	// 'WAVEfmt '
            int32_t	FormatLength;	// 16
            int16_t	DataFormat;
            int16_t	NumChannels;
            int32_t	SampleRate;
            int32_t	BytesPerSecond;
            int16_t	BlockAlignment;
            int16_t	SampleDepth;
            char	DataTag[4];	// 'data'
            int32_t	DataLength;
        } header = {
            "RIFF", 0, "WAVEfmt ",
            16, 1, 2, 44100, 176400, 4, 16,
            "data", 0
        };
        header.FileLength = 36 + bytes;
        header.DataLength = bytes;
        ST(0) = sv_newmortal();
        sv_setpvn(ST(0), (char*) &header, sizeof(header));
        XSRETURN(1);
    }
            
