<?php
# http://stackoverflow.com/questions/2934563/how-to-decode-unicode-escape-sequences-like-u00ed-to-proper-utf-8-encoded-cha
function replace_unicode_escape_sequence($match) {
    return mb_convert_encoding(pack('H*', $match[1]), 'UTF-8', 'UCS-2BE');
}

preg_replace_callback('/(?:\\\\u[0-9a-fA-Z]{4})+/', function ($v) {
    $v = strtr($v[0], array('\\u' => ''));
    return mb_convert_encoding(pack('H*', $v), 'UTF-8', 'UTF-16BE');
}, $string);

$credential = array(
    'username' => 'haineko', 
    'password' => 'kijitora',
);
$clientname = rtrim( shell_exec(hostname) );
$hainekourl = 'http://127.0.0.1:2794/submit';
$emaildata1 = array(
    'ehlo' => $clientname,
    'mail' => 'envelope-sender@example.jp',
    'rcpt' => array( 'envelope-recipient@example.org' ),
    'body' => 'メール本文です。',
    'header' => array(
        'from' => 'キジトラ <envelope-sender@example.jp>',
        'subject' => 'テストメール',
        'replyto' => 'neko@example.jp',
    ),
);

$htrequest1 = curl_init( $hainekourl );
$jsonstring = json_encode( $emaildata1 );
$jsonstring = preg_replace_callback('/\\\\u([0-9a-f]{4})/i', 'replace_unicode_escape_sequence', $jsonstring );

curl_setopt( $htrequest1, CURLOPT_HEADER, FALSE );
curl_setopt( $htrequest1, CURLOPT_RETURNTRANSFER, TRUE );
curl_setopt( $htrequest1, CURLOPT_POST, TRUE );
curl_setopt( $htrequest1, CURLOPT_HTTP_VERSION,CURL_HTTP_VERSION_1_1 );
curl_setopt( $htrequest1, CURLOPT_POSTFIELDS, $jsonstring );

if( $_ENV{'HAINEKO_AUTH'} || $argv[1] ) {
    $_auth = sprintf( "%s:%s", $credential['username'], $credential['password'] );
    curl_setopt( $htrequest1, CURLOPT_USERPWD, $_auth );
}
$htresponse = curl_exec( $htrequest1 );
curl_close( $htrequest1 );

print $htresponse;

?>
