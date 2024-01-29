#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 4;

use MIME::Entity;
use MIME::Parser;
use lib qw( ./t );

my $e = MIME::Entity->build(From => 'dianne@skoll.ca',
			    To   => 'dfs2@roaringpenguin.com',
			    Subject => 'End-of-line test',
			    Data => ["Line 1\n", "Line 2\n"],);

my $str = $e->as_string();
is ($str, "Content-Type: text/plain\nContent-Disposition: inline\nContent-Transfer-Encoding: binary\nMIME-Version: 1.0\nX-Mailer: MIME-tools 5.513 (Entity 5.513)\nFrom: dianne\@skoll.ca\nTo: dfs2\@roaringpenguin.com\nSubject: End-of-line test\n\nLine 1\nLine 2\n", 'Got expected line endings');

my $delim = "\r\n";
$MIME::Entity::BOUNDARY_DELIMITER = $delim;
$e = MIME::Entity->build(From => 'dianne@skoll.ca',
			    To   => 'dfs2@roaringpenguin.com',
			    Subject => 'End-of-line test',
			    Data => ["Line 1$delim", "Line 2$delim"],);

$str = $e->as_string();

is ($str, "Content-Type: text/plain${delim}Content-Disposition: inline${delim}Content-Transfer-Encoding: binary${delim}MIME-Version: 1.0${delim}X-Mailer: MIME-tools 5.513 (Entity 5.513)${delim}From: dianne\@skoll.ca${delim}To: dfs2\@roaringpenguin.com${delim}Subject: End-of-line test${delim}${delim}Line 1${delim}Line 2${delim}", 'Got expected line endings');

$e->attach(Data => ["More Text$delim"], Type => "text/plain");

$e = MIME::Entity->build(From => 'dianne@skoll.ca',
			 To   => 'dfs2@roaringpenguin.com',
			 Subject => 'End-of-line test',
			 Type => 'multipart/mixed', Boundary => 'foo');
$e->attach(Data => ["Text$delim"], Type => "text/plain");
$e->attach(Data => ["More Text$delim"], Type => "text/plain");
$str = $e->as_string();
is ($str, "Content-Type: multipart/mixed; boundary=\"foo\"${delim}Content-Transfer-Encoding: binary${delim}MIME-Version: 1.0${delim}X-Mailer: MIME-tools 5.513 (Entity 5.513)${delim}From: dianne\@skoll.ca${delim}To: dfs2\@roaringpenguin.com${delim}Subject: End-of-line test${delim}${delim}This is a multi-part message in MIME format...${delim}${delim}--foo${delim}Content-Type: text/plain${delim}Content-Disposition: inline${delim}Content-Transfer-Encoding: binary${delim}${delim}Text${delim}${delim}--foo${delim}Content-Type: text/plain${delim}Content-Disposition: inline${delim}Content-Transfer-Encoding: binary${delim}${delim}More Text${delim}${delim}--foo--${delim}", 'Got expected line endings');

$e = MIME::Entity->build(From => 'dianne@skoll.ca',
			 To   => 'dfs2@roaringpenguin.com',
			 Subject => 'End-of-line test',
			 Type => 'multipart/mixed', Boundary => 'foo');
$e->attach(Data => ["Text\n"], Type => "text/plain", Encoding => 'Base64');
$e->attach(Data => ["More Text\n", 'LongLine' x 120], Type => "text/plain", Encoding => 'Base64');
$str = $e->as_string();

is ($str, "Content-Type: multipart/mixed; boundary=\"foo\"${delim}Content-Transfer-Encoding: binary${delim}MIME-Version: 1.0${delim}X-Mailer: MIME-tools 5.513 (Entity 5.513)${delim}From: dianne\@skoll.ca${delim}To: dfs2\@roaringpenguin.com${delim}Subject: End-of-line test${delim}${delim}This is a multi-part message in MIME format...${delim}${delim}--foo${delim}Content-Type: text/plain${delim}Content-Disposition: inline${delim}Content-Transfer-Encoding: Base64${delim}${delim}VGV4dAo=${delim}${delim}--foo${delim}Content-Type: text/plain${delim}Content-Disposition: inline${delim}Content-Transfer-Encoding: Base64${delim}${delim}TW9yZSBUZXh0CkxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGlu${delim}ZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5l${delim}TG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVM${delim}b25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxv${delim}bmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9u${delim}Z0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25n${delim}TGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdM${delim}aW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xp${delim}bmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGlu${delim}ZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5l${delim}TG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVM${delim}b25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxv${delim}bmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9u${delim}Z0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25n${delim}TGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdM${delim}aW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xp${delim}bmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGluZUxvbmdMaW5lTG9uZ0xpbmVMb25nTGlu${delim}ZQ==${delim}${delim}--foo--${delim}", 'Got expected line endings for Base64 encoding');

