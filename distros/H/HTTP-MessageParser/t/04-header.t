#!perl

use strict;
use warnings;

use Test::More;

plan tests => 2;

use_ok( 'HTTP::MessageParser' );

# Borrowed from Session Initiation Protocol Torture Test Messages
my $message = join( "\x0D\x0A", split( /\n/, <<'EOM' ), '' );
TO :
 sip:vivekg@chair-dnrc.example.com ;   tag    = 1918181833n
from   : "J Rosenberg \\\""       <sip:jdrosen@example.com>
  ;
  tag = 98asjd8
MaX-fOrWaRdS: 0068
Call-ID: wsinv.ndaksdj@192.0.2.1
Content-Length   : 150
cseq: 0009
  INVITE
Via  : SIP  /   2.0
 /UDP
    192.0.2.2;branch=390skdjuw
s :
NewFangledHeader:   newfangled value
 continued newfangled value
UnknownHeaderWithUnusualValue: ;;,,;;,;
Content-Type: application/sdp
Route:
 <sip:services.example.com;lr;unknownwith=value;unknown-no-value>
v:  SIP  / 2.0  / TCP     spindle.example.com   ;
  branch  =   z9hG4bK9ikj8  ,
 SIP  /    2.0   / UDP  192.168.255.111   ; branch=
 z9hG4bK30239
m:"Quoted string \"\"" <sip:jdrosen@example.com> ; newparam =
      newvalue ;
  secondparam ; q = 0.33
EOM

my $expected = [
    'to'                            => 'sip:vivekg@chair-dnrc.example.com ; tag = 1918181833n',
    'from'                          => '"J Rosenberg \\\\\"" <sip:jdrosen@example.com> ; tag = 98asjd8',
    'max-forwards'                  => '0068',
    'call-id'                       => 'wsinv.ndaksdj@192.0.2.1',
    'content-length'                => '150',
    'cseq'                          => '0009 INVITE',
    'via'                           => 'SIP / 2.0 /UDP 192.0.2.2;branch=390skdjuw',
    's'                             => '',
    'newfangledheader'              => 'newfangled value continued newfangled value',
    'unknownheaderwithunusualvalue' => ';;,,;;,;',
    'content-type'                  => 'application/sdp',
    'route'                         => '<sip:services.example.com;lr;unknownwith=value;unknown-no-value>',
    'v'                             => 'SIP / 2.0 / TCP spindle.example.com ; branch = z9hG4bK9ikj8 , SIP / 2.0 / UDP 192.168.255.111 ; branch= z9hG4bK30239',
    'm'                             => '"Quoted string \"\"" <sip:jdrosen@example.com> ; newparam = newvalue ; secondparam ; q = 0.33',
];

my $headers = HTTP::MessageParser->parse_headers(\$message);

is_deeply $headers, $expected, "Parsed headers";
