use strict;
use warnings;
use Test::Base;

use HTTP::MobileAttribute plugins => [
    'Core',
    'DoCoMo::Browser',
];

plan tests => 1*blocks;

filters {
    input    => [qw/b_ver/],
    expected => [qw//],
};

run_is_deeply input => 'expected';

sub b_ver {
    my $ua = shift;
    my $ma = HTTP::MobileAttribute->new($ua);
    return $ma->browser_version;
}

__END__

===
--- input : DoCoMo/1.0/D501i
--- expected : 1.0

===
--- input : DoCoMo/2.0 N2001(c10)
--- expected : 1.0

===
--- input: DoCoMo/2.0 SH906iTV(c100;TB;W20H13)
--- expected : 1.0

===
--- input: DoCoMo/2.0 F06A(c100;TB;W24H12)
--- expected : 1.0

===
--- input: DoCoMo/2.0 N06A3(c500;TB;W24H16)
--- expected : 2.0

===
--- input: DoCoMo/2.0 P07A3(c500;TB;W24H15)
--- expected : 2.0

