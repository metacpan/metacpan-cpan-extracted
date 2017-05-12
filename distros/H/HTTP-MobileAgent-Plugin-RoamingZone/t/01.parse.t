use strict;
use Test::Base;

use HTTP::MobileAgent::Plugin::RoamingZone;

plan tests => 3 * blocks;

filters {
    input    => [qw/chomp/],
    expected => [qw/chomp/],
};

run {
    local %ENV;

    my $block = shift;
    my ($ua,$data)          = map { $_ eq 'UNDEF' ? undef : $_ eq 'NULL' ? '' : $_ } split(/\n/,$block->input);
    my ($code,$name,$is_os) = map { $_ eq 'UNDEF' ? undef : $_ eq 'NULL' ? '' : $_ } split(/\n/,$block->expected);
 
    $ENV{'HTTP_USER_AGENT'} = $ua;
    my $key                 = $ua =~ /^DoCoMo/   ? 'HTTP_X_DCMROAMING' :
                              $ua =~ /^SoftBank/ ? 'HTTP_X_JPHONE_REGION' :
                                                   'HTTP_X_UP_DEVCAP_ZONE';
    $ENV{$key}              = $data;

    my $ma = HTTP::MobileAgent->new;

    is ( $ma->zone_code,  $code  );
    is ( $ma->zone_name,  $name  );
    is ( $ma->is_oversea, $is_os );
};


__END__
=== DoCoMo No Data
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
UNDEF
--- expected
440
Japan
0

=== DoCoMo No Data
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
NULL
--- expected
440
Japan
0

=== DoCoMo Greece
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
 202
--- expected
202
Greece
1

=== DoCoMo Haiti
--- input
DoCoMo/2.0 P903i(c100;TB;W24H12)
 372
--- expected
372
Haiti (Republic of)
1

=== SoftBank No Data
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
UNDEF
--- expected
440
Japan
0

=== SoftBank No Data
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
NULL
--- expected
440
Japan
0

=== SoftBank Japan
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
44020
--- expected
44020
Japan
0

=== SoftBank Oversea
--- input
SoftBank/1.0/910T/TJ001/SN351774012575317 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
fffff
--- expected
fffff
Unknown
1

=== EZWEB No Data
--- input
KDDI-SA3D UP.Browser/6.2_7.2.7.1.K.1.5.123 (GUI) MMP/2.0
NULL
--- expected
12304
Japan
0

=== EZWEB No Data
--- input
KDDI-SA3D UP.Browser/6.2_7.2.7.1.K.1.5.123 (GUI) MMP/2.0
UNDEF
--- expected
12304
Japan
0

=== EZWEB Japan? (Need more information)
--- input
KDDI-SA3D UP.Browser/6.2_7.2.7.1.K.1.5.123 (GUI) MMP/2.0
12304
--- expected
12304
Japan
0

=== EZWEB Other case? (Need more information)
--- input
KDDI-SA3D UP.Browser/6.2_7.2.7.1.K.1.5.123 (GUI) MMP/2.0
12345
--- expected
12345
Japan
0

