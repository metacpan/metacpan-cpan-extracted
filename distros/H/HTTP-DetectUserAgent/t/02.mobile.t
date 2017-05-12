use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (4 * blocks);

filters {
    input    => [qw(chomp)],
    expected => [qw(yaml)],
};

run {
    my $block = shift;
    my $ua = HTTP::DetectUserAgent->new($block->input);
    my $expected = $block->expected;
    is $ua->type, "Mobile";
    is $ua->name, $expected->{name};
    is $ua->version, $expected->{version};
    is $ua->vendor, $expected->{vendor};
}

__END__

=== docomo
--- input
DoCoMo/2.0 SO905i(c100;TB;W24H18)
--- expected
name: "docomo"
version: "SO905i"
vendor: "docomo"

=== au
--- input
KDDI-SN39 UP.Browser/6.2.0.11.2.1 (GUI) MMP/2.0
--- expected
name: "au"
version: "SN39"
vendor: "KDDI"

=== SoftBank
--- input
SoftBank/1.0/811SH/SHJ001/SN359798001502661 Browser/NetFront/3.3 Profile/MIDP-2.0 Configuration/CLDC-1.1
--- expected
name: "SoftBank"
version: "811SH"
vendor: "SoftBank"

=== Vodafone
--- input
Vodafone/1.0/V904T/TJ001 Browser/VF-Browser/1.0 Profile/MIDP-2.0 Configuration/CLDC-1.1 Ext-J-Profile/JSCL-1.2.2 Ext-V-Profile/VSCL-2.0.0
--- expected
name: "SoftBank"
version: "V904T"
vendor: "SoftBank"

=== J-PHONE
--- input
J-PHONE/4.3/V501SH/SNJSHN3177216 SH/0008aa Profile/MIDP-1.0 Configuration/CLDC-1.0 Ext-Profile/JSCL-1.3.2
--- expected
name: "SoftBank"
version: "V501SH"
vendor: "SoftBank"
