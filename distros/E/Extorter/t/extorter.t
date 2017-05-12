use Test::More;

use Extorter qw(
    *utf8
    *strict
    *warnings

    Carp::croak
    Carp::confess
);

use Extorter qw(
    Encode^encode_utf8
    Encode^decode_utf8
);

use Extorter qw(
    Scalar::Util::blessed
    Scalar::Util::refaddr
    Scalar::Util::reftype
    Scalar::Util::weaken
);

use Extorter qw(
    Data::Dumper::Dumper=dumper
    Getopt::Long::GetOptions=options
);

can_ok main => qw(
    confess
    croak
);

can_ok main => qw(
    encode_utf8
    decode_utf8
);

can_ok main => qw(
    blessed
    refaddr
    reftype
    weaken
);

can_ok main => qw(
    dumper
    options
);

done_testing;
