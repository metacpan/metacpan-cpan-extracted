package Linux::Perl::Base::BitsTest;

use strict;
use warnings;

use constant _PERL_CAN_64BIT => !!do { local $@; eval { pack 'Q' } };

sub _PACK_u64 {
    return 'Q' if  _PERL_CAN_64BIT();

    require Linux::Perl::Endian;
    return Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN() ? 'xxxxL!' : 'L!xxxx';
}

sub _PACK_i64 {
    return 'q' if  _PERL_CAN_64BIT();

    require Linux::Perl::Endian;
    return Linux::Perl::Endian::SYSTEM_IS_BIG_ENDIAN() ? 'xxxxl!' : 'l!xxxx';
}

1;
