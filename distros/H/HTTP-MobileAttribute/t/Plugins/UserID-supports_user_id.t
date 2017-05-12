use strict;
use warnings;
use Test::Base;

use HTTP::MobileAttribute plugins => [
    qw/UserID/
];

plan tests => 1*blocks;

filters {
    input => [qw/supports_user_id/],
};

run_is 'input' => 'expected';

sub supports_user_id {
    my $ua = shift;
    HTTP::MobileAttribute->new( $ua )->supports_user_id ? 'supported' : 'not supported';
}

__END__

===
--- input: DoCoMo/1.0/NM502i
--- expected: supported

===
--- input: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
--- expected: supported

===
--- input: Mozilla/2.0 (compatible; Ask Jeeves)
--- expected: not supported

=== airhphone
--- input: Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0
--- expected: not supported

=== ThirdForce type C
--- input: J-PHONE/2.0/J-DN02
--- expected: not supported

===
--- input: MOT-V980/80.2F.2E. MIB/2.2.1 Profile/MIDP-2.0 Configuration/CLDC-1.1,V702MO
--- expected: supported

