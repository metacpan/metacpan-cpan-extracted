require '_h2ph_pre.ph';

unless(defined(&_I386_TERMIOS_H)) {
    eval 'sub _I386_TERMIOS_H () {1;}' unless defined(&_I386_TERMIOS_H);
    require 'asm/termbits.ph';
    require 'asm/ioctls.ph';
    eval 'sub NCC () {8;}' unless defined(&NCC);
    eval 'sub TIOCM_LE () {0x001;}' unless defined(&TIOCM_LE);
    eval 'sub TIOCM_DTR () {0x002;}' unless defined(&TIOCM_DTR);
    eval 'sub TIOCM_RTS () {0x004;}' unless defined(&TIOCM_RTS);
    eval 'sub TIOCM_ST () {0x008;}' unless defined(&TIOCM_ST);
    eval 'sub TIOCM_SR () {0x010;}' unless defined(&TIOCM_SR);
    eval 'sub TIOCM_CTS () {0x020;}' unless defined(&TIOCM_CTS);
    eval 'sub TIOCM_CAR () {0x040;}' unless defined(&TIOCM_CAR);
    eval 'sub TIOCM_RNG () {0x080;}' unless defined(&TIOCM_RNG);
    eval 'sub TIOCM_DSR () {0x100;}' unless defined(&TIOCM_DSR);
    eval 'sub TIOCM_CD () { &TIOCM_CAR;}' unless defined(&TIOCM_CD);
    eval 'sub TIOCM_RI () { &TIOCM_RNG;}' unless defined(&TIOCM_RI);
    eval 'sub TIOCM_OUT1 () {0x2000;}' unless defined(&TIOCM_OUT1);
    eval 'sub TIOCM_OUT2 () {0x4000;}' unless defined(&TIOCM_OUT2);
    eval 'sub TIOCM_LOOP () {0x8000;}' unless defined(&TIOCM_LOOP);
    eval 'sub N_TTY () {0;}' unless defined(&N_TTY);
    eval 'sub N_SLIP () {1;}' unless defined(&N_SLIP);
    eval 'sub N_MOUSE () {2;}' unless defined(&N_MOUSE);
    eval 'sub N_PPP () {3;}' unless defined(&N_PPP);
    eval 'sub N_STRIP () {4;}' unless defined(&N_STRIP);
    eval 'sub N_AX25 () {5;}' unless defined(&N_AX25);
    eval 'sub N_X25 () {6;}' unless defined(&N_X25);
    eval 'sub N_6PACK () {7;}' unless defined(&N_6PACK);
    eval 'sub N_MASC () {8;}' unless defined(&N_MASC);
    eval 'sub N_R3964 () {9;}' unless defined(&N_R3964);
    eval 'sub N_PROFIBUS_FDL () {10;}' unless defined(&N_PROFIBUS_FDL);
    eval 'sub N_IRDA () {11;}' unless defined(&N_IRDA);
    eval 'sub N_SMSBLOCK () {12;}' unless defined(&N_SMSBLOCK);
    eval 'sub N_HDLC () {13;}' unless defined(&N_HDLC);
    eval 'sub N_SYNC_PPP () {14;}' unless defined(&N_SYNC_PPP);
    eval 'sub N_HCI () {15;}' unless defined(&N_HCI);
    if(defined(&__KERNEL__)) {
	eval 'sub INIT_C_CC () {"\\003\\034\\177\\025\\004\\0\\1\\0\\021\\023\\032\\0\\022\\017\\027\\026\\0";}' unless defined(&INIT_C_CC);
	eval 'sub SET_LOW_TERMIOS_BITS {
	    local($termios, $termio, $x) = @_;
    	    eval q({ \'unsigned short __tmp\';  &get_user( &__tmp,($termio)->$x); * ($termios)->$x =  &__tmp; });
	}' unless defined(&SET_LOW_TERMIOS_BITS);
	eval 'sub user_termio_to_kernel_termios {
	    local($termios, $termio) = @_;
    	    eval q(({  &SET_LOW_TERMIOS_BITS($termios, $termio,  &c_iflag);  &SET_LOW_TERMIOS_BITS($termios, $termio,  &c_oflag);  &SET_LOW_TERMIOS_BITS($termios, $termio,  &c_cflag);  &SET_LOW_TERMIOS_BITS($termios, $termio,  &c_lflag);  &copy_from_user(($termios)-> &c_cc, ($termio)-> &c_cc,  &NCC); }));
	}' unless defined(&user_termio_to_kernel_termios);
	eval 'sub kernel_termios_to_user_termio {
	    local($termio, $termios) = @_;
    	    eval q(({  &put_user(($termios)-> &c_iflag, ($termio)-> &c_iflag);  &put_user(($termios)-> &c_oflag, ($termio)-> &c_oflag);  &put_user(($termios)-> &c_cflag, ($termio)-> &c_cflag);  &put_user(($termios)-> &c_lflag, ($termio)-> &c_lflag);  &put_user(($termios)-> &c_line, ($termio)-> &c_line);  &copy_to_user(($termio)-> &c_cc, ($termios)-> &c_cc,  &NCC); }));
	}' unless defined(&kernel_termios_to_user_termio);
	eval 'sub user_termios_to_kernel_termios {
	    local($k, $u) = @_;
    	    eval q( &copy_from_user($k, $u, $sizeof{1;
	}' unless defined(&user_termios_to_kernel_termios);
	eval 'sub kernel_termios_to_user_termios {
	    local($u, $k) = @_;
    	    eval q( &copy_to_user($u, $k, $sizeof{1;
	}' unless defined(&kernel_termios_to_user_termios);
    }
}
1;
