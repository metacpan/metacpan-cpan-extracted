use strict;
use warnings;
use Test::Base;
use HTTP::MobileAttribute plugins => [
    qw/Core GPS/
];

plan tests => 1*blocks;

filters {
    input => ['is_gps'],
};

run_is input => 'expected';

sub is_gps {
    HTTP::MobileAttribute->new(shift)->is_gps ? 'supported' : 'not supported'
}

__END__

===
--- input: DoCoMo/1.0/F661i/c10/TB
--- expected: supported

===
--- input: DoCoMo/1.0/SH505i2/c20/TB/W20H10
--- expected: not supported

