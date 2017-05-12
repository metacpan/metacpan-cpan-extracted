#!/usr/bin/perl -w
use strict;
use Test::More tests => 5;

sub read_file { local $/; local *FH; open FH, shift or die $!; return <FH> }
use_ok("Email::MIME");
use_ok("Email::MIME::XMTP");
# Very basic functionality test
my $mail_text = read_file("t/test-mails/josey-nofold");
my $mail = Email::MIME->new($mail_text);
isa_ok($mail, "Email::MIME");

$mail->set_namespace( 'foo', 'http://foo.com/' );
$mail->header_set( 'X-XMTP-foo-BAR', "VALUE");

my $xml = $mail->as_XML;

#print $xml."\n";exit;
#open(FF,">foo");
#binmode(FF);
#print FF $xml;
#close(FF);

my $mail_XML_text = read_file("t/test-mails/josey-nofold.xml");
ok( $mail_XML_text eq $xml );

$mail_text = read_file("t/test-mails/mail-2");
$mail = Email::MIME->new($mail_text);
isa_ok($mail, "Email::MIME");

$xml = $mail->as_XML;
#print $xml."\n";exit;
