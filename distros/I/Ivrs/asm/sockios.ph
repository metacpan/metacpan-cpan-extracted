require '_h2ph_pre.ph';

unless(defined(&__ARCH_I386_SOCKIOS__)) {
    eval 'sub __ARCH_I386_SOCKIOS__ () {1;}' unless defined(&__ARCH_I386_SOCKIOS__);
    eval 'sub FIOSETOWN () {0x8901;}' unless defined(&FIOSETOWN);
    eval 'sub SIOCSPGRP () {0x8902;}' unless defined(&SIOCSPGRP);
    eval 'sub FIOGETOWN () {0x8903;}' unless defined(&FIOGETOWN);
    eval 'sub SIOCGPGRP () {0x8904;}' unless defined(&SIOCGPGRP);
    eval 'sub SIOCATMARK () {0x8905;}' unless defined(&SIOCATMARK);
    eval 'sub SIOCGSTAMP () {0x8906;}' unless defined(&SIOCGSTAMP);
}
1;
