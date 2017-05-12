use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Mail::Sender' ) || BAIL_OUT("Can't use the module.");
}

# check that we can do all static functions
can_ok('Mail::Sender',
    qw(enc_base64 enc_qp enc_plain enc_xtext),
    qw(ResetGMTdiff GuessCType getusername),
    # The various error message private functions
    qw(_HOSTNOTFOUND _CONNFAILED _SERVNOTAVAIL _COMMERROR _USERUNKNOWN),
    qw(_TRANSFAILED _TOEMPTY _NOMSG _NOFILE _FILENOTFOUND _NOTMULTIPART _SITEERROR),
    qw(_NOTCONNECTED _NOSERVER _NOFROMSPECIFIED _INVALIDAUTH _LOGINERROR _UNKNOWNAUTH),
    qw(_ALLRECIPIENTSBAD _FILECANTREAD _DEBUGFILE _STARTTLS _IO_SOCKET_SSL),
    qw(_TLS_UNSUPPORTED_BY_ME _TLS_UNSUPPORTED_BY_SERVER _UNKNOWNENCODING),
);

{
    # encoding
    isa_ok(Mail::Sender::enc_base64(), 'CODE', 'enc_base64: empty call gets subref');
    isa_ok(Mail::Sender::enc_base64("UTF-8", "foo"), 'CODE', 'enc_base64: got a sub ref back');
    isa_ok(Mail::Sender::enc_qp(), 'CODE', 'enc_base64: empty call - got a sub ref back');
    isa_ok(Mail::Sender::enc_qp("UTF-8", "foo"), 'CODE', 'enc_base64: got a sub ref back');
    isa_ok(Mail::Sender::enc_plain(), 'CODE', 'enc_base64: empty call - got a sub ref back');
    isa_ok(Mail::Sender::enc_plain("UTF-8", "foo"), 'CODE', 'enc_base64: got a sub ref back');
    is(Mail::Sender::enc_xtext("foo"), 'foo', 'enc_base64: got encoded content');
}

{
    # test username
    my $username = Mail::Sender::getusername();
    ok($username, 'getusername: found a username');
    is(Mail::Sender::getusername(), $username, 'getusername: called a second time for state');
}

{
    # test GMT offset
    my $diff = Mail::Sender::ResetGMTdiff();
    like($diff, qr/^[+-][0-9]+$/, 'ResetGMTdiff: properly set');
    is($diff, $Mail::Sender::GMTdiff, 'ResetGMTdiff: properly set');
    ok($Mail::Sender::GMTdiff, 'ResetGMTdiff: properly set');
}

{
    # GuessCType
    my $type = Mail::Sender::GuessCType();
    is($type, 'application/octet-stream', 'GuessCType: empty call');

    $type = Mail::Sender::GuessCType('');
    is($type, 'application/octet-stream', 'GuessCType: empty string');

    $type = Mail::Sender::GuessCType('foo.unknownsomething');
    is($type, 'application/octet-stream', 'GuessCType: unknown extension');

    $type = Mail::Sender::GuessCType('foo.gif');
    is($type, 'image/gif', 'GuessCType: gif lowercase extension');

    $type = Mail::Sender::GuessCType('foo.gIf');
    is($type, 'image/gif', 'GuessCType: gif multicase extension');

    $type = Mail::Sender::GuessCType('foo.GIF');
    is($type, 'image/gif', 'GuessCType: gif uppercase extension');

    # Add a type
    $Mail::Sender::CTypes{SUPERSPECIAL} = 'text/super';
    $type = Mail::Sender::GuessCType('foo.superspecial');
    is($type, 'text/super', 'GuessCType: superspecial added MIME type');
}

{
    # test error functions
    my ($num, $err);

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_HOSTNOTFOUND();
    is($num, -1, '_HOSTNOTFOUND: proper number');
    is($err, 'The SMTP server  was not found', '_HOSTNOTFOUND: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_HOSTNOTFOUND('crappola');
    is($num, -1, '_HOSTNOTFOUND: proper number');
    is($err, 'The SMTP server crappola was not found', '_HOSTNOTFOUND: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_CONNFAILED('');
    is($num, -3, '_CONNFAILED: proper number');
    like($err, qr/^connect\(\) failed: /, '_CONNFAILED: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_SERVNOTAVAIL('');
    is($num, -4, '_SERVNOTAVAIL: proper number');
    is($err, 'Service not available. Server closed the connection unexpectedly', '_SERVNOTAVAIL: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_SERVNOTAVAIL('crappola');
    is($num, -4, '_SERVNOTAVAIL: proper number');
    is($err, 'Service not available. Reply: crappola', '_SERVNOTAVAIL: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_COMMERROR('');
    is($num, -5, '_COMMERROR: proper number');
    is($err, 'No response from server', '_COMMERROR: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_COMMERROR('crappola');
    is($num, -5, '_COMMERROR: proper number');
    is($err, 'Server error: crappola', '_COMMERROR: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_USERUNKNOWN();
    is($num, -6, '_USERUNKNOWN: proper number');
    is($err, 'Local user "" unknown on host ""', '_USERUNKNOWN: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_USERUNKNOWN('crappola','crappola');
    is($num, -6, '_USERUNKNOWN: proper number');
    is($err, 'Local user "crappola" unknown on host "crappola"', '_USERUNKNOWN: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_USERUNKNOWN('crappola','crappola', 'Local user');
    is($num, -6, '_USERUNKNOWN: proper number');
    is($err, 'Local user "crappola" unknown on host "crappola"', '_USERUNKNOWN: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_USERUNKNOWN('crappola','crappola', 'crappola');
    is($num, -6, '_USERUNKNOWN: proper number');
    is($err, 'crappola for "crappola" on host "crappola"', '_USERUNKNOWN: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_USERUNKNOWN('crappola','crappola', '123 ');
    is($num, -6, '_USERUNKNOWN: proper number');
    is($err, 'Error for "crappola" on host "crappola"', '_USERUNKNOWN: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TRANSFAILED();
    is($num, -7, '_TRANSFAILED: proper number');
    is($err, 'Transmission of message failed ()', '_TRANSFAILED: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TRANSFAILED('crappola');
    is($num, -7, '_TRANSFAILED: proper number');
    is($err, 'Transmission of message failed (crappola)', '_TRANSFAILED: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TOEMPTY();
    is($num, -8, '_TOEMPTY: proper number');
    is($err, 'Argument $to empty', '_TOEMPTY: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOMSG();
    is($num, -9, '_NOMSG: proper number');
    is($err, 'No message specified', '_NOMSG: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOFILE();
    is($num, -10, '_NOFILE: proper number');
    is($err, 'No file name specified', '_NOFILE: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_FILENOTFOUND();
    is($num, -11, '_FILENOTFOUND: proper number');
    is($err, 'File "" not found', '_FILENOTFOUND: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_FILENOTFOUND('crappola');
    is($num, -11, '_FILENOTFOUND: proper number');
    is($err, 'File "crappola" not found', '_FILENOTFOUND: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOTMULTIPART();
    is($num, -12, '_NOTMULTIPART: proper number');
    is($err, ' not available in singlepart mode', '_NOTMULTIPART: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOTMULTIPART('crappola');
    is($num, -12, '_NOTMULTIPART: proper number');
    is($err, 'crappola not available in singlepart mode', '_NOTMULTIPART: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_SITEERROR();
    is($num, -13, '_SITEERROR: proper number');
    is($err, 'Site specific error', '_SITEERROR: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOTCONNECTED();
    is($num, -14, '_NOTCONNECTED: proper number');
    is($err, 'Connection not established', '_NOTCONNECTED: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOSERVER();
    is($num, -15, '_NOSERVER: proper number');
    is($err, 'No SMTP server specified', '_NOSERVER: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_NOFROMSPECIFIED();
    is($num, -16, '_NOFROMSPECIFIED: proper number');
    is($err, 'No From: address specified', '_NOFROMSPECIFIED: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_INVALIDAUTH();
    is($num, -17, '_INVALIDAUTH: proper number');
    is($err, 'Authentication protocol  is not accepted by the server', '_INVALIDAUTH: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_INVALIDAUTH('crappola');
    is($num, -17, '_INVALIDAUTH: proper number');
    is($err, 'Authentication protocol crappola is not accepted by the server', '_INVALIDAUTH: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_INVALIDAUTH('crappola','crappola');
    is($num, -17, '_INVALIDAUTH: proper number');
    is($err, "Authentication protocol crappola is not accepted by the server,\nresponse: crappola", '_INVALIDAUTH: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_LOGINERROR();
    is($num, -18, '_LOGINERROR: proper number');
    is($err, 'Login not accepted', '_LOGINERROR: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_UNKNOWNAUTH();
    is($num, -19, '_UNKNOWNAUTH: proper number');
    is($err, 'Authentication protocol  is not implemented by Mail::Sender', '_UNKNOWNAUTH: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_UNKNOWNAUTH('crappola');
    is($num, -19, '_UNKNOWNAUTH: proper number');
    is($err, 'Authentication protocol crappola is not implemented by Mail::Sender', '_UNKNOWNAUTH: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_ALLRECIPIENTSBAD();
    is($num, -20, '_ALLRECIPIENTSBAD: proper number');
    is($err, 'All recipients are bad', '_ALLRECIPIENTSBAD: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_FILECANTREAD();
    is($num, -21, '_FILECANTREAD: proper number');
    like($err, qr/^File "" cannot be read: /, '_FILECANTREAD: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_FILECANTREAD('crappola');
    is($num, -21, '_FILECANTREAD: proper number');
    like($err, qr/^File "crappola" cannot be read: /, '_FILECANTREAD: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_DEBUGFILE();
    is($num, -22, '_DEBUGFILE: proper number');
    is($err, undef, '_DEBUGFILE: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_DEBUGFILE('crappola');
    is($num, -22, '_DEBUGFILE: proper number');
    is($err, 'crappola', '_DEBUGFILE: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_STARTTLS();
    is($num, -23, '_STARTTLS: proper number');
    is($err, 'STARTTLS failed:  ', '_STARTTLS: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_STARTTLS('crappola');
    is($num, -23, '_STARTTLS: proper number');
    is($err, 'STARTTLS failed: crappola ', '_STARTTLS: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_STARTTLS('crappola', 'crappola');
    is($num, -23, '_STARTTLS: proper number');
    is($err, 'STARTTLS failed: crappola crappola', '_STARTTLS: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_IO_SOCKET_SSL();
    is($num, -24, '_IO_SOCKET_SSL: proper number');
    is($err, 'IO::Socket::SSL->start_SSL failed: ', '_IO_SOCKET_SSL: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_IO_SOCKET_SSL('crappola');
    is($num, -24, '_IO_SOCKET_SSL: proper number');
    is($err, 'IO::Socket::SSL->start_SSL failed: crappola', '_IO_SOCKET_SSL: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TLS_UNSUPPORTED_BY_ME();
    is($num, -25, '_TLS_UNSUPPORTED_BY_ME: proper number');
    is($err, 'TLS unsupported by the script: ', '_TLS_UNSUPPORTED_BY_ME: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TLS_UNSUPPORTED_BY_ME('crappola');
    is($num, -25, '_TLS_UNSUPPORTED_BY_ME: proper number');
    is($err, 'TLS unsupported by the script: crappola', '_TLS_UNSUPPORTED_BY_ME: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_TLS_UNSUPPORTED_BY_SERVER();
    is($num, -26, '_TLS_UNSUPPORTED_BY_SERVER: proper number');
    is($err, 'TLS unsupported by server', '_TLS_UNSUPPORTED_BY_SERVER: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_UNKNOWNENCODING();
    is($num, -27, '_UNKNOWNENCODING: proper number');
    is($err, q(Unknown encoding ''), '_UNKNOWNENCODING: proper string');

    $num = undef; $err = undef;
    ($num,$err) = Mail::Sender::_UNKNOWNENCODING('crappola');
    is($num, -27, '_UNKNOWNENCODING: proper number');
    is($err, q(Unknown encoding 'crappola'), '_UNKNOWNENCODING: proper string');

}

done_testing();
