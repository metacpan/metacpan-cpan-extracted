use strict;
use warnings;
use Test::Base;
use HTTP::MobileAttribute plugins => [qw/
    Encoding
/];

plan tests => 1*blocks;

filters {
    input => [qw/filt/],
    expected => [qw/yaml/],
};

run_is_deeply input => 'expected';

sub filt {
    my $ua = shift;

    my $agent = HTTP::MobileAttribute->new($ua);
    +{
        can_display_utf8 => $agent->can_display_utf8 ? 'utf8' : 'no utf8',
        encoding         => $agent->encoding,
    };
}

__END__

=== PC
--- input: Mozilla/5.0 (Macintosh; U; Intel Mac OS X; en-US; rv:1.8.1.8) Gecko/20071019 Firefox/2.0.0.8
--- expected
can_display_utf8: utf8
encoding: utf-8

=== docomo foma
--- input: DoCoMo/2.0 N905iBiz(c100;TJ)
--- expected
can_display_utf8: utf8
encoding: x-utf8-docomo

=== docomo mova
--- input: DoCoMo/1.0/D501i
--- expected
can_display_utf8: no utf8
encoding: x-sjis-docomo

=== vodafone utf8
--- input: Vodafone/1.0/V802SE/SEJ001/SNXXXXXXXXX Browser/SEMC-Browser/4.1 Profile/MIDP-2.0 Configuration/CLDC-1.10
--- expected
can_display_utf8: utf8
encoding: x-utf8-vodafone

=== vodafone sjis
--- input: J-PHONE/2.0/J-DN02
--- expected
can_display_utf8: no utf8
encoding: x-sjis-vodafone

=== willcom
--- input: Mozilla/3.0(DDIPOCKET;JRC/AH-J3001V,AH-J3002V/1.0/0100/c50)CNF/2.0
--- expected
can_display_utf8: no utf8
encoding: x-sjis-airh

=== ez sjis
--- input: UP.Browser/3.01-HI01 UP.Link/3.4.5.2
--- expected
can_display_utf8: no utf8
encoding: x-sjis-ezweb-auto

=== ez utf8
--- input: KDDI-TS21 UP.Browser/6.0.2.276 (GUI) MMP/1.1
--- expected
can_display_utf8: no utf8
encoding: x-sjis-ezweb-auto

