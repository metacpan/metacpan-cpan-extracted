#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use JSONSchema::Validator::Format qw/
    validate_uuid
    validate_date validate_time validate_date_time
    validate_email validate_hostname
    validate_idn_email
    validate_ipv4 validate_ipv6
    validate_byte
    validate_int32 validate_int64
    validate_float validate_double
    validate_regex
    validate_json_pointer validate_relative_json_pointer
    validate_uri validate_uri_reference
    validate_iri validate_iri_reference
    validate_uri_template
/;

use Test::More;

is validate_uuid('123e4567-e89b-12d3-a456-426652340001'), 1, 'uuid ok';
is validate_uuid('123e4567-e89b-a2d3-a456-426652340001'), 1, 'uuid ok version a for future use';
is validate_uuid('123e4567-e89b-72d3-a456-426652340001'), 1, 'uuid ok version 7 for future use';
is validate_uuid('123e4567-e89b-12d3-a456-426652340x01'), 0, 'wrong uuid symbols';
is validate_uuid('123e4567-e89b-12d3-3456-426652340001'), 0, 'wrong uuid variants';
is validate_uuid('123e4567-e89b-12d3-8456-4266523400011'), 0, 'wrong uuid length 1';
is validate_uuid('123e4567-e89b-12d3-8456-42665234000'), 0, 'wrong uuid length 2';

is validate_date('2020-02-20'), 1, 'date ok';
is validate_date('2020-02-30'), 0, 'wrong date';
is validate_date('2020:02-20'), 0, 'wrong date format 1';
is validate_date('20-02-2020'), 0, 'wrong date format 2';
is validate_date('2020-2-20'), 0, 'wrong date format 3';

is validate_time('00:00:00+00:00'), 1, 'time ok, 0';
is validate_time('23:59:60Z'), 1, 'time ok, timezone Z';
is validate_time('23:59:60.1234123Z'), 1, 'time ok, milliseconds';
is validate_time('23:59:59-23:30'), 1, 'time ok, timezone -';
is validate_time('01:01:01+23:59'), 1, 'time ok, timezone +';
is validate_time('01:01:01'), 1, 'time ok, without timezone';
is validate_time('1:1:1'), 0, 'wrong time format';
is validate_time('01:01:61'), 0, 'wrong time seconds';
is validate_time('01:60:58'), 0, 'wrong time minutes';
is validate_time('24:01:58'), 0, 'wrong time hours';
is validate_time('23:01:58+24:00'), 0, 'wrong time timzone (hours)';
is validate_time('23:01:58+23:60'), 0, 'wrong time timzone (minutes)';
is validate_time('23:01:58-24:00'), 0, 'wrong time timzone (hours)';
is validate_time('23:01:58-23:60'), 0, 'wrong time timzone (minutes)';

is validate_date_time('2018-11-13T20:20:39.123123'), 1, 'datetime ok with milliseconds';
is validate_date_time('2018-11-13T20:20:39.123123+23:30'), 1, 'datetime ok with + timezone';
is validate_date_time('2018-11-13T20:20:39.123123Z'), 1, 'datetime ok with timezone z';
is validate_date_time('1985-04-12T23:20:50.52Z'), 1, 'datetime ok with timezone z';
is validate_date_time('1996-12-19T16:39:57-08:00'), 1, 'datetime ok with - timezone';
is validate_date_time('1990-12-31T23:59:60Z'), 1, 'datetime ok with max time';
is validate_date_time('2018-11-13T20:20:39+24:00'), 0, 'wrong datetime timezone hours';
is validate_date_time('2018-11-13T20:20:39+23:60'), 0, 'wrong datetime timezone minutes';

is validate_ipv4('1.1.1.1'), 1, 'ipv4 ok';
is validate_ipv4('0.0.0.0'), 1, 'ipv4 ok minimum';
is validate_ipv4('255.255.255.255'), 1, 'ipv4 ok maximum';
is validate_ipv4('1.1.1.1.1'), 0, 'wrong ipv4, long length';
is validate_ipv4('1.1.1'), 0, 'wrong ipv4, short length';
is validate_ipv4('1.1.1.1.'), 0, 'wrong ipv4, format';
is validate_ipv4('1.1.256.1'), 0, 'wrong ipv4, big octet';
is validate_ipv4('1.1.a1.1'), 0, 'wrong ipv4, wrong octet';
is validate_ipv4('01.01.01.01'), 0, 'wrong ipv4 with leading zeros';

is validate_ipv6('FEDC:BA98:7654:3210:FEDC:BA98:7654:3210'), 1, 'ipv6 ok';
is validate_ipv6('1080:0:0:0:8:800:200C:417A'), 1, 'ipv6 ok';
is validate_ipv6('0:0:0:0:0:0:0:1'), 1, 'ipv6 ok, loopback';
is validate_ipv6('0:0:0:0:0:0:0:0'), 1, 'ipv6 ok, zeros';
is validate_ipv6('1080::8:800:200C:417A'), 1, 'ipv6 ok, group of zeros';
is validate_ipv6('FF01::101'), 1, 'ipv6 ok, group of zeros 2';
is validate_ipv6('::1'), 1, 'ipv6 ok, group of zeros, loopback';
is validate_ipv6('::'), 1, 'ipv6 ok, group of zeros, zeros';
is validate_ipv6('0:0:0:0:0:0:13.1.68.3'), 1, 'ipv6 ok, ipv4';
is validate_ipv6('0:0:0:0:0:FFFF:129.144.52.38'), 1, 'ipv6 ok, ipv4 2';
is validate_ipv6('::13.1.68.3'), 1, 'ipv6 ok, group of zeros, ipv4';
is validate_ipv6('::FFFF:129.144.52.38'), 1, 'ipv6 ok, group of zeros, ipv4 2';
is validate_ipv6('FF01::101::1'), 0, 'wrong ipv6, many group of zeros';
is validate_ipv6('::101::1'), 0, 'wrong ipv6, many group of zeros 2';
is validate_ipv6('FF0G::101'), 0, 'wrong ipv6, wrong symbol g';
is validate_ipv6('FF01:::101'), 0, 'wrong ipv6 format';
is validate_ipv6('FF01F::101'), 0, 'wrong ipv6 length of 16 bit part';
is validate_ipv6('FEDC:BA98:7654:3210:FEDC:BA98:7654:0:3210'), 0, 'wrong ipv6 number of parts';
is validate_ipv6('FEDC:BA98:7654:3210:FEDC:BA98:7654:1.1.1.1'), 0, 'wrong ipv6 number of parts';
is validate_ipv6('FEDC:BA98:7654:3210:FEDC:BA98:1.1.256.1'), 0, 'wrong ipv6, ipv4 part is wrong';
is validate_ipv6('::BA98::7654:1.1.255.1'), 0, 'wrong ipv6, ipv6 part is wrong';
is validate_ipv6('BA98::BA98::7654:1.1.255.1'), 0, 'wrong ipv6, ipv6 part is wrong2';
is validate_ipv6('1'), 0, 'wrong ipv6';

is validate_hostname('www.example.com'), 1, 'hostname ok';
is validate_hostname('www.example.com.'), 1, 'hostname ok with root empty label';
is validate_hostname('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.com'), 1, 'hostname contain max label length';
is validate_hostname('-a-host-name-that-starts-with--'), 0, 'hostname wrong, start with -';
is validate_hostname('not_a_valid_host_name'), 0, 'hostname wrong, contain _';
is validate_hostname('a-vvvvvvvvvvvvvvvveeeeeeeeeeeeeeeerrrrrrrrrrrrrrrryyyyyyyyyyyyyy'), 0, 'hostname wrong, contain label greater than 63';
is validate_hostname('hostname-'), 0, 'hostname wrong, - at the end';
my $label = 'x' x 52;
my $domain = ($label . '.') x 5;
is validate_hostname($domain), 0, 'hostname has length > 255';

is validate_email('joe.bloggs@example.com'), 1, 'email ok';
is validate_email('2962'), 0, 'wrong email numbers';
is validate_email('te~st@example.com'), 1, 'email ok with ~';
is validate_email('~test@example.com'), 1, 'email ok with begin ~';
is validate_email('test~@example.com'), 1, 'email ok with end ~';
is validate_email('.test@example.com'), 0, 'wrong email dot begin';
is validate_email('test.@example.com'), 0, 'wrong email dot end';
is validate_email('te.s.t@example.com'), 1, 'email ok dot';
is validate_email('te..st@example.com'), 0, 'wrong email two dots';
is validate_email('!#$%&`*+/=?^`{|}~@iana.org'), 1, 'email ok atext';
is validate_email('test\\@test@iana.org'), 0, 'wrong email, with @ and \\';
is validate_email('123@iana.org'), 1, 'email ok, local part is number';
is validate_email('test@123.com'), 1, 'email ok, domain part is number';
is validate_email('test@iana.123'), 1, 'email ok, domain part (tld) is number';
is validate_email('test@255.255.255.255'), 1, 'email ok, ipv4';
is validate_email('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklmn@iana.org'), 1, 'email ok, long local part';
is validate_email('test@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm.com'), 1, 'email ok, long domain part';
is validate_email('test@-iana.org'), 1, 'email ok, domain hyphen start';
is validate_email('test@c--n.com'), 1, 'email ok, domain hyphen in the middle';
is validate_email('test@.iana.org'), 0, 'wrong email, dot in begin of domain';
is validate_email('test@iana.org.'), 0, 'wrong email, dot in end of domain';
is validate_email('test@iana..com'), 0, 'wrong email, consecutive dots';
is validate_email('a@a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v.w.x.y.z.a.b.c.d.e.f.g.h.i.j.k.l.m.n.o.p.q.r.s.t.u.v'), 1, 'email ok, many subdomains';
is validate_email('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghij'), 1, 'email ok, long parts of local and domain';
is validate_email('"test"@iana.org'), 1, 'email ok, quoted string';
is validate_email('""@iana.org'), 1, 'email ok, empty quoted string';
is validate_email('"""@iana.org'), 0, 'wrong email, wrong quoted string';
is validate_email('"\\a"@iana.org'), 1, 'email ok, quoted string with \\';
is validate_email('"\\""@iana.org'), 1, 'email ok, quoted string with escape "';
is validate_email('"\\"@iana.org'), 0, 'wrong email, quoted string with only \\';
is validate_email('"\\\\"@iana.org'), 1, 'email ok, quoted string with \\\\';
is validate_email('test"@iana.org'), 0, 'wrong email, omitted quotation mark at the end';
is validate_email('"test@iana.org'), 0, 'wrong email, omitted quotation mark at the beginning';
is validate_email('"test"test@iana.org'), 0, 'wrong email, atext after quoted string';
is validate_email('test"text"@iana.org'), 0, 'wrong email, atext before quoted string';
is validate_email('"test""test"@iana.org'), 0, 'wrong email, two quoted string';
is validate_email('"test\\ test"@iana.org'), 1, 'email ok, quoted string with \\';
is validate_email('"abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefg\\h"@iana.org'), 1, 'email ok, long quoted string';
is validate_email('test@[255.255.255.255]'), 1, 'email ok, ipv4';
is validate_email('test@[255.255.255]'), 1, 'email ok, wrong ipv4';
is validate_email('test@[1111:2222:3333:4444:5555:6666:7777:8888]'), 1, 'email ok, ipv6';
is validate_email('test@[IPv6:1111:2222:3333:4444:5555:6666:7777]'), 1, 'email ok, wrong ipv6 1';
is validate_email('test@[IPv6:1111:2222:3333:4444:5555:6666:7777:888G]'), 1, 'email ok, wrong ipv6 2';
is validate_email('test@[IPv6:1111::4444:5555::8888]'), 1, 'email ok, wrong ipv6 3';
is validate_email('test@[IPv6:::]'), 1, 'email ok, ipv6';
is validate_email('test@[IPv6::255.255.255.255]'), 1, 'email ok, wrong ipv6 as ipv4';
is validate_email('test@ iana .com'), 1, 'email ok, space in domain1';
is validate_email('test . test@iana.org'), 1, 'email ok, space in local part';
is validate_email('(comment)test@iana.org'), 1, 'email ok, simple comment';
is validate_email('((comment)test@iana.org'), 0, 'wrong email, closed parenthesis is omitted';
is validate_email('test@(comment)iana.org'), 1, 'email ok, comment in domain part';
is validate_email('test(comment)test@iana.org'), 0, 'wrong email, atext after CFWS';
is validate_email('test@(comment)[255.255.255.255]'), 1, 'email ok, CFWS at begin of domain part';
is validate_email('(comment)test@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghik.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghik.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijk.abcdefghijklmnopqrstuvwxyzabcdefghijk.abcdefghijklmnopqrstu'), 1, 'email ok, long email with CFWS';
is validate_email("\r\n test\@iana.org"), 1, 'email ok, FWS before atext';
is validate_email(" \r\n \r\n test\@iana.org"), 1, 'email ok, two FWS before atext';
is validate_email('(comment(comment))(comment2)test@iana.org'), 1, 'email ok, complex comment';
is validate_email('test@xn--hxajbheg2az3al.xn--jxalpdlp'), 1, 'email ok, utf8 domain';
is validate_email('(comment\\)test@iana.or'), 0, 'email wrong, unclosed comment';
is validate_email('test@[RFC-5322-domain-literal]'), 1, 'email ok, domain literal';

is validate_byte(''), 1, 'base64 empty';
is validate_byte('Zg=='), 1, 'base64 1 symbol';
is validate_byte('Zm8='), 1, 'base64 2 symbols';
is validate_byte('Zm8='), 1, 'base64 3 symbols';
is validate_byte('Zm9vYg=='), 1, 'base64 4 symbols';
is validate_byte('Zm9vYmE='), 1, 'base64 5 symbols';
is validate_byte('Zm9vYmFy'), 1, 'base64 6 symbols';
is validate_byte('01Zz+/=='), 1, 'base64 any';
is validate_byte('Z'), 0, 'base64 wrong length 1';
is validate_byte('Zz'), 0, 'base64 wrong length 2';
is validate_byte('Zzz'), 0, 'base64 wrong length 3';
is validate_byte('Zzzzz'), 0, 'base64 wrong length 5';
is validate_byte('Zzzzz='), 0, 'base64 wrong length 6';
is validate_byte('Zzzzz=='), 0, 'base64 wrong length 7';
is validate_byte('$zzz'), 0, 'base64 wrong symbol';
is validate_byte('=zzz'), 0, 'base64 wrong sequence, = at begin';
is validate_byte('z=zz'), 0, 'base64 wrong sequence, = in the middle';

is validate_int32(123), 1, 'int32 ok';
is validate_int32(1), 1, 'int32 1';
is validate_int32(-1), 1, 'int32 -1';
is validate_int32(0), 1, 'int32 0';
is validate_int32('-0'), 1, 'int32 -0';
is validate_int32('1'), 1, 'int32 1 string';
is validate_int32('-1'), 1, 'int32 -1 string';
is validate_int32('+1'), 1, 'int32 +1 string';
is validate_int32('0012'), 1, 'int32 leading zeros';
is validate_int32(2147483647), 1, 'int32 max int';
is validate_int32(-2147483648), 1, 'int32 min int';
is validate_int32('+002147483647'), 1, 'int32 max int leading zeros';
is validate_int32('-002147483648'), 1, 'int32 min int leading zeros';
is validate_int32('002147483648'), 0, 'int32 greater than max int';
is validate_int32('0021474836460'), 0, 'int32 greater than max int 2';
is validate_int32('-002147483649'), 0, 'int32 less than min int';
is validate_int32('-0021474836470'), 0, 'int32 less than min int 2';
is validate_int32('-1.1'), 0, 'int32 float';
is validate_int32(' -11'), 0, 'int32 sign with space';
is validate_int32(' 11'), 0, 'int32 space at begin';
is validate_int32('11 '), 0, 'int32 space at end';
is validate_int32('1$1'), 0, 'int32 non-digit in the middle';

is validate_int64(123), 1, 'int64 ok';
is validate_int64(1), 1, 'int64 1';
is validate_int64(-1), 1, 'int64 -1';
is validate_int64(0), 1, 'int64 0';
is validate_int64('-0'), 1, 'int64 -0';
is validate_int64('1'), 1, 'int64 1 string';
is validate_int64('-1'), 1, 'int64 -1 string';
is validate_int64('+1'), 1, 'int64 +1 string';
is validate_int64('0012'), 1, 'int64 leading zeros';
is validate_int64(2147483647), 1, 'int64 max int32';
is validate_int64(-2147483648), 1, 'int64 min int32';
is validate_int64('9223372036854775807'), 1, 'int64 max int64';
is validate_int64('-9223372036854775808'), 1, 'int64 min int64';
is validate_int64('+0009223372036854775807'), 1, 'int64 max int leading zeros';
is validate_int64('-0009223372036854775808'), 1, 'int64 min int leading zeros';
is validate_int64('9223372036854775808'), 0, 'int64 greater than max int';
is validate_int64('92233720368547758000'), 0, 'int64 greater than max int 2';
is validate_int64('-9223372036854775809'), 0, 'int64 less than min int';
is validate_int64('-0092233720368547758000'), 0, 'int64 less than min int 2';
is validate_int64('-1.1'), 0, 'int64 float';
is validate_int64(' -11'), 0, 'int64 sign with space';
is validate_int64(' 11'), 0, 'int64 space at begin';
is validate_int64('11 '), 0, 'int64 space at end';
is validate_int64('1$1'), 0, 'int64 non-digit in the middle';

is validate_float(12), 1, 'float int';
is validate_float(12.1), 1, 'float ok';
is validate_float(12e2), 1, 'float exp';
is validate_float('12e2'), 1, 'float exp string';
is validate_float(-12e2), 1, 'float exp negative';
is validate_float('-12e+22'), 1, 'float exp with sign +';
is validate_float('-12e-22'), 1, 'float exp with sign -';
is validate_float('0'), 1, 'float 0';
is validate_float('1'), 1, 'float 1';
is validate_float('-1'), 1, 'float -1';
is validate_float('3e38'), 1, 'float max float';
is validate_float('3e39'), 1, 'float greater than max float'; # for now is valid
is validate_float('3e400'), 1, 'float greater than max double'; # for now is valid
is validate_float('Inf'), 1, 'float infinity';
is validate_float('-Inf'), 1, 'float -infinity';
is validate_float('12#1'), 0, 'float wrong symbol';
is validate_float('12#1'), 0, 'float wrong symbol in the middle';
is validate_float('12$'), 0, 'float wrong symbol at the end';
is validate_float('$12'), 0, 'float wrong symbol at the begin';
is validate_float(' 12.1'), 0, 'float space at the begin';
is validate_float('12.1 '), 0, 'float space at the end';

is validate_double(12.03), 1, 'double ok';
is validate_double(' 12.03'), 0 , 'double wrong';

is validate_regex('^[a-z0-9]*?a{1,}(?=xx)$'), 1, 'regex ok';
is validate_regex('^[)$'), 0, 'regex wrong';
is validate_regex('asd(?{ print "message"; })'), 0, 'regex check security checks';

is validate_json_pointer(''), 1, 'json pointer root';
is validate_json_pointer('/'), 1, 'json pointer empty key';
is validate_json_pointer('/1'), 1, 'json pointer number key';
is validate_json_pointer('/string'), 1, 'json pointer string key';
is validate_json_pointer('/~1/str/1'), 1, 'json pointer escape /';
is validate_json_pointer('/~0/~0'), 1, 'json pointer escape ~';
is validate_json_pointer('/ '), 1, 'json pointer space';
is validate_json_pointer('a/asd'), 0, 'json pointer without first /';
is validate_json_pointer('/~~'), 0, 'json pointer wrong ~~';
is validate_json_pointer('/~1~'), 0, 'json pointer ~ at the end';
is validate_json_pointer('/~3/~1/~0'), 0, 'json pointer wrong ~3';

is validate_relative_json_pointer('0'), 1, 'relative json pointer 0';
is validate_relative_json_pointer('1'), 1, 'relative json pointer 1';
is validate_relative_json_pointer('100'), 1, 'relative json pointer 100';
is validate_relative_json_pointer('0/'), 1, 'relative json pointer 0/';
is validate_relative_json_pointer('1/0'), 1, 'relative json pointer 1/0';
is validate_relative_json_pointer('0/some/~1~0/path'), 1, 'relative json pointer with some pointer';
is validate_relative_json_pointer('0#'), 1, 'relative json pointer 0#';
is validate_relative_json_pointer('1#'), 1, 'relative json pointer 1#';
is validate_relative_json_pointer('00'), 0, 'relative json pointer 00';
is validate_relative_json_pointer('0#1'), 0, 'relative json pointer 0#1';
is validate_relative_json_pointer('101/a/b~~/~11'), 0, 'relative json pointer wrong json pointer';

is validate_uri('http://user:pass@www.google.com/test?a=12&b=13#fragment-id'), 1, 'uri valid';
is validate_uri('http://-.~_!$&\'()*+,;=:%40:80%2f::::::@example.com'), 1, 'uri with special chars';
is validate_uri('ldap://[2001:db8::7]/c=GB?objectClass?one'), 1, 'uri with ipv6 + double ?';
is validate_uri('http://google.com'), 1, 'uri without path';
is validate_uri('http:// google.com'), 0, 'uri with space';
is validate_uri('htt,p://google.com'), 0, 'uri with wrong scheme';
is validate_uri('http://пётр:пароль@родина.рф/путь?параметр=значение#фрагмент'), 0, 'uri invalid with utf8 symbols';

is validate_uri_reference('http://user:pass@www.google.com/test?a=12&b=13#fragment-id'), 1, 'uri-reference with absolute url';
is validate_uri_reference('//user:pass@www.google.com/test?a=12&b=13#fragment-id'), 1, 'uri-reference without scheme';
is validate_uri_reference('some_path'), 1, 'uri-reference with relative path';
is validate_uri_reference('/some_path'), 1, 'uri-reference with absolute path';
is validate_uri_reference('?a=b#fragment'), 1, 'uri-reference with query_string and fragment';
is validate_uri_reference('#fragment'), 1, 'uri-reference with fragment';
is validate_uri_reference('#frag\\ment'), 0, 'uri-reference with wrong fragment';

is validate_iri('http://user:pass@www.google.com/test?a=12&b=13#fragment-id'), 1, 'iri valid';
is validate_iri('http://пётр:пароль@родина.рф/путь?параметр=значение#фрагмент'), 1, 'iri valid with utf8 symbols';
is validate_iri('http://пётр:пар%20@родина.рф/путь?параметр=значение#фрагмент'), 1, 'iri valid with percent encoding';
is validate_iri('схема://пётр:пароль@родина.рф/путь?параметр=значение#фрагмент'), 0, 'iri scheme must have only ascii symbols';
is validate_iri('http://пётр:пар%%%@родина.рф/путь?параметр=значение#фрагмент'), 0, 'iri scheme with invalid percent encoding';

is validate_iri_reference('/путь?параметр=значение#фрагмент'), 1, 'iri reference valid';
is validate_iri_reference('#фрагмент'), 1, 'iri reference fragment valid';
is validate_iri_reference('#фрагм\\ент'), 0, 'iri reference fragment invalid';

is validate_uri_template('http://example.com/~{username}/'), 1, 'uri-tempalte level 1 valid';
is validate_uri_template('http://example.com/dictionary/{+term1}/{#term2}'), 1, 'uri-tempalte level 2 valid';
is validate_uri_template('/search/{/path,p}/label{.l1,l2}/{;p1,p2}{?q,lang}{&x,y}'), 1, 'uri-template level 3 valid';
is validate_uri_template('{/p1:10}/{+p2*}/x{.l*}{/p3*,p4:2}{;params:5}{?qparams*}{&qparams2:10}{#f*}'), 1, 'uri-template level 4 valid';
is validate_uri_template(' {value}'), 0, 'uri-template with space at begin';
is validate_uri_template('{value:*}'), 0, 'uri-template incorrect max length';
is validate_uri_template('{%value*}'), 0, 'uri-template incorrect operator';
is validate_uri_template('{value'), 0, 'uri-template omitted closing curly brace';
is validate_uri_template('value}'), 0, 'uri-template omitted opening curly brace';

is validate_idn_email('!#$%&`*+/=?^`{|}~@iana.org'), 1, 'idn-email ok atext ascii';
is validate_idn_email('василий@петька.сергеевич'), 1, 'idn-email ok atext utf8';
is validate_idn_email(' василий@петька.сергеевич'), 0, 'idn-email space at begin';

done_testing;
