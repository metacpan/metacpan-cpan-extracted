#!/usr/bin/env perl -T

use strict;
use warnings;

use Test::More;
use Email::IsEmail qw/IsEmail/;


my $cDNS = 0;  # do not check DNS
my $EL = Email::IsEmail::THRESHOLD;

ok( !IsEmail( '', $cDNS, $EL ), 'empty E-mail is invalid' );
ok( Email::IsEmail::ERR_NODOMAIN == IsEmail( 'test', $cDNS, $EL ), 'test is invalid E-mail' );
ok( Email::IsEmail::ERR_NOLOCALPART == IsEmail( '@', $cDNS, $EL ), '@ is invalid E-mail' );
ok( Email::IsEmail::ERR_NODOMAIN == IsEmail( 'test@', $cDNS, $EL ), 'test@ is invalid E-mail' );
ok( Email::IsEmail::ERR_DOT_START == IsEmail( '.test@iana.org', $cDNS, $EL ), '.test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_DOT_END == IsEmail( 'test.@iana.org', $cDNS, $EL ), 'test.@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_CONSECUTIVEDOTS == IsEmail( 'test..iana.org', $cDNS, $EL ), 'test..iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_ATEXT == IsEmail( 'test\\@test@iana.org', $cDNS, $EL ), 'test\\@test@iana.org is invalid E-mail' );
ok( Email::IsEmail::RFC5322_LOCAL_TOOLONG == IsEmail( 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklmn@iana.org', $cDNS, $EL ), 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklmn@iana.org is invalid E-mail' );
ok( Email::IsEmail::RFC5322_LABEL_TOOLONG == IsEmail( 'test@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm.com', $cDNS, $EL ), 'test@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm.com is invalid E-mail' );
ok( Email::IsEmail::ERR_DOMAINHYPHENSTART == IsEmail( 'test@-iana.org', $cDNS, $EL ), 'test@-iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_DOMAINHYPHENEND == IsEmail( 'test@iana-.org', $cDNS, $EL ), 'test@iana-.org is invalid E-mail' );
ok( Email::IsEmail::ERR_DOMAINHYPHENEND == IsEmail( 'test@iana.org-', $cDNS, $EL ), 'test@iana.org- is invalid E-mail' );
ok( Email::IsEmail::ERR_DOT_START == IsEmail( 'test@.iana.org', $cDNS, $EL ), 'test@.iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_DOT_END == IsEmail( 'test@iana.org.', $cDNS, $EL ), 'test@iana.org. is invalid E-mail' );
ok( Email::IsEmail::ERR_CONSECUTIVEDOTS == IsEmail( 'test@iana..org', $cDNS, $EL ), 'test@iana..org is invalid E-mail' );
ok( Email::IsEmail::RFC5322_TOOLONG == IsEmail( 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghij', $cDNS, $EL ), 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghiklm@abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghikl.abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghij is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_ATEXT == IsEmail( '"""@iana.org', $cDNS, $EL ), '"""@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDQUOTEDSTR == IsEmail( '"\\"@iana.org', $cDNS, $EL ), '"\\"@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_ATEXT == IsEmail( 'test"@iana.org', $cDNS, $EL ), 'test"@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDQUOTEDSTR == IsEmail( '"test@iana.org', $cDNS, $EL ), '"test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_ATEXT_AFTER_QS == IsEmail( '"test"test@iana.org', $cDNS, $EL ), '"test"test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_ATEXT == IsEmail( 'test"test"@iana.org', $cDNS, $EL ), 'test"test"@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_ATEXT == IsEmail( '"test""test"@iana.org', $cDNS, $EL ), '"test""test"@iana.org is invalid E-mail' );
ok( Email::IsEmail::DEPREC_LOCALPART == IsEmail( '"test"."test"@iana.org', $cDNS, $EL ), '"test"."test"@iana.org is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_GRPCOUNT == IsEmail( 'test@[IPv6:1111:2222:3333:4444:5555:6666:7777]', $cDNS, $EL ), 'test@[IPv6:1111:2222:3333:4444:5555:6666:7777] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_BADCHAR == IsEmail( 'test@[IPv6:1111:2222:3333:4444:5555:6666:7777:888G]', $cDNS, $EL ), 'test@[IPv6:1111:2222:3333:4444:5555:6666:7777:888G] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_2X2XCOLON == IsEmail( 'test@[IPv6:1111::4444:5555::8888]', $cDNS, $EL ), 'test@[IPv6:1111::4444:5555::8888] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_GRPCOUNT == IsEmail( 'test@[IPv6:1111:2222:3333:4444:5555:255.255.255.255]', $cDNS, $EL ), 'test@[IPv6:1111:2222:3333:4444:5555:255.255.255.255] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_MAXGRPS == IsEmail( 'test@[IPv6:1111:2222:3333:4444:5555:6666::255.255.255.255]', $cDNS, $EL ), 'test@[IPv6:1111:2222:3333:4444:5555:6666::255.255.255.255] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_COLONSTRT == IsEmail( 'test@[IPv6::255.255.255.255]', $cDNS, $EL ), 'test@[IPv6::255.255.255.255] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_IPV6_COLONEND == IsEmail( 'test@[IPv6:1::2:]', $cDNS, $EL ), 'test@[IPv6:1::2:] is invalid E-mail' );
ok( Email::IsEmail::DEPREC_CFWS_NEAR_AT == IsEmail( ' test @iana.org', $cDNS, $EL ), ' test @iana.org is invalid E-mail' );
ok( Email::IsEmail::DEPREC_CFWS_NEAR_AT == IsEmail( 'test@ iana .org', $cDNS, $EL ), 'test@ iana .org is invalid E-mail' );
ok( Email::IsEmail::DEPREC_FWS == IsEmail( 'test . test@iana.org', $cDNS, $EL ), 'test . test@iana.org is invalid E-mail' );
ok( Email::IsEmail::CFWS_COMMENT == IsEmail( '(comment)test@iana.org', $cDNS, $EL ), '(comment)test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDCOMMENT == IsEmail( '((comment)test@iana.org', $cDNS, $EL ), '((comment)test@iana.org is invalid E-mail' );
ok( Email::IsEmail::DEPREC_CFWS_NEAR_AT == IsEmail( 'test@(comment)iana.org', $cDNS, $EL ), 'test@(comment)iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_ATEXT_AFTER_CFWS == IsEmail( 'test(comment)test@iana.org', $cDNS, $EL ), 'test(comment)test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDDOMLIT == IsEmail( 'test@[1.2.3.4', $cDNS, $EL ), 'test@[1.2.3.4 is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDCOMMENT == IsEmail( '(comment\\)test@iana.org', $cDNS, $EL ), '(comment\\)test@iana.org is invalid E-mail' );
ok( Email::IsEmail::ERR_BACKSLASHEND == IsEmail( 'test@iana.org(comment\\', $cDNS, $EL ), 'test@iana.org(comment\\ is invalid E-mail' );
ok( Email::IsEmail::ERR_ATEXT_AFTER_DOMLIT == IsEmail( 'test@[RFC-5322]-domain-literal]', $cDNS, $EL ), 'test@[RFC-5322]-domain-literal] is invalid E-mail' );
ok( Email::IsEmail::ERR_EXPECTING_DTEXT == IsEmail( 'test@[RFC-5322-[domain-literal]', $cDNS, $EL ), 'test@[RFC-5322-[domain-literal] is invalid E-mail' );
ok( Email::IsEmail::RFC5322_DOMLIT_OBSDTEXT == IsEmail( 'test@[RFC-5322-\\]-domain-literal]', $cDNS, $EL ), 'test@[RFC-5322-\\]-domain-literal] is invalid E-mail' );
ok( Email::IsEmail::ERR_UNCLOSEDDOMLIT == IsEmail( 'test@[RFC-5322-domain-literal\\]', $cDNS, $EL ), 'test@[RFC-5322-domain-literal\\] is invalid E-mail' );
ok( Email::IsEmail::DEPREC_QTEXT == IsEmail( '"' . chr(127) . '"@iana.org', $cDNS, $EL ), '"' . chr(127) . '"@iana.org is invalid E-mail' );
ok( Email::IsEmail::CFWS_FWS == IsEmail( ' test@iana.org', $cDNS, $EL ), ' test@iana.org is invalid E-mail' );
ok( Email::IsEmail::CFWS_FWS == IsEmail( 'test@iana.org ', $cDNS, $EL ), 'test@iana.org  is invalid E-mail' );
ok( Email::IsEmail::RFC5322_DOMAIN == IsEmail( 'test@iana/icann.org', $cDNS, $EL ), 'test@iana/icann.org is invalid E-mail' );
ok( Email::IsEmail::DEPREC_COMMENT == IsEmail( 'test.(comment)test@iana.org', $cDNS, $EL ), 'test.(comment)test@iana.org is invalid E-mail' );

done_testing();
