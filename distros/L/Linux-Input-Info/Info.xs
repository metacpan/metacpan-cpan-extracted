#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "Info.h"

MODULE = Linux::Input::Info               PACKAGE = Linux::Input::Info

int
device_open(num)
        INPUT:
                int num;
        CODE:
                char filename[32];
                int fd, version;
                RETVAL = 0;
                snprintf(filename,sizeof(filename), "/dev/input/event%d",num);
                fd = open(filename,O_RDONLY);
                if (-1 == fd) {
			XSRETURN_UNDEF;
                }

                if (-1 == ioctl(fd,EVIOCGVERSION,&version)) {
                        perror("ioctl EVIOCGVERSION");
                        close(fd);
			XSRETURN_UNDEF;
                }
                if (EV_VERSION != version) {
                        fprintf(stderr, "protocol version mismatch (expected %d, got %d)\n",
                                EV_VERSION, version);
                        close(fd);
			XSRETURN_UNDEF;
                }
	        RETVAL = fd;
        OUTPUT:
                RETVAL




HV *
device_info(fd)
        int fd;
        CODE:
                struct input_id id;
                BITFIELD bits[32];
                char buf[32], name[32];
                int rc, bit;    

		/* create the new hash */
                RETVAL = (HV *) sv_2mortal((SV*)newHV());

		rc = ioctl(fd,EVIOCGID,&id);
		if (rc >= 0) {
			hv_store(RETVAL, "bustype",  7, newSVpv(BUS_NAME[id.bustype],strlen(BUS_NAME[id.bustype])), 0);
			hv_store(RETVAL, "vendor",   6, newSVnv(id.vendor), 0);
			hv_store(RETVAL, "product",  7, newSVnv(id.product), 0);
			hv_store(RETVAL, "version",  7, newSVnv(id.version), 0);
			
		}
                
                /* name */
		rc = ioctl(fd,EVIOCGNAME(sizeof(buf)),buf);
                if (rc >= 0) {
                         hv_store(RETVAL, "name", 4, newSVpv(buf,rc), 0);
                }

		/* physical */
		rc = ioctl(fd,EVIOCGPHYS(sizeof(buf)),buf);
                if (rc >= 0) {
			hv_store(RETVAL, "phys", 4, newSVpv(buf,rc), 0);

		}
		
		/* uniq */
		rc = ioctl(fd,EVIOCGUNIQ(sizeof(buf)),buf);
		if (rc >= 0) {
			hv_store(RETVAL, "uniq", 4, newSVpv(buf,rc), 0);
		}

		/* bits */ 
		rc = ioctl(fd,EVIOCGBIT(0,sizeof(bits)),bits);
		if (rc >= 0) {
			AV * returnbits = (AV *) sv_2mortal((SV*)newAV());
			for (bit = 0; bit < rc*8 && bit < EV_MAX; bit++) {
			if (test_bit(bit,bits))
				av_push((AV *)returnbits, newSVnv(bit));
			}
			hv_store(RETVAL, "bits", 4, (SV *) newRV_inc((SV *)returnbits), 0); 
		}
                
        OUTPUT:
                RETVAL

