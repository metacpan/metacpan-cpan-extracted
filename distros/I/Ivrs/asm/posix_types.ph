require '_h2ph_pre.ph';

unless(defined(&__ARCH_I386_POSIX_TYPES_H)) {
    eval 'sub __ARCH_I386_POSIX_TYPES_H () {1;}' unless defined(&__ARCH_I386_POSIX_TYPES_H);
    if(defined(&__GNUC__)) {
    }
    if(defined( &__KERNEL__) || defined( &__USE_ALL)) {
    } else {
    }
    if(defined( &__KERNEL__) || !defined( &__GLIBC__) || ((defined(&__GLIBC__) ? &__GLIBC__ : 0) < 2)) {
	undef(&__FD_SET) if defined(&__FD_SET);
	eval 'sub __FD_SET {
	    local($fd,$fdsetp) = @_;
    	    eval q( &__asm__  &__volatile__(\\"btsl %1,%0\\": \\"=m\\" (* ):\\"r\\" ( ($fd))));
	}' unless defined(&__FD_SET);
	undef(&__FD_CLR) if defined(&__FD_CLR);
	eval 'sub __FD_CLR {
	    local($fd,$fdsetp) = @_;
    	    eval q( &__asm__  &__volatile__(\\"btrl %1,%0\\": \\"=m\\" (* ):\\"r\\" ( ($fd))));
	}' unless defined(&__FD_CLR);
	undef(&__FD_ISSET) if defined(&__FD_ISSET);
	eval 'sub __FD_ISSET {
	    local($fd,$fdsetp) = @_;
    	    eval q(( &__extension__ ({ \'unsigned char __result\';  &__asm__  &__volatile__(\\"btl %1,%2 ; setb %0\\" :\\"=q\\" :\\"r\\" , \\"m\\" (* ($fdsetp)));  &__result; })));
	}' unless defined(&__FD_ISSET);
	undef(&__FD_ZERO) if defined(&__FD_ZERO);
	eval 'sub __FD_ZERO {
	    local($fdsetp) = @_;
    	    eval q( &do { \'int\'  &__d0,  &__d1;  &__asm__  &__volatile__(\\"cld ; rep ; stosl\\" :\\"=m\\" (* ), \\"=&c\\" , \\"=&D\\" :\\"a\\" , \\"1\\" , \\"2\\" ( ($fdsetp)) : \\"memory\\"); }  &while (0));
	}' unless defined(&__FD_ZERO);
    }
}
1;
