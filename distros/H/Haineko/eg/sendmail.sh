#!/bin/sh
#
PATH='/usr/local/bin:/usr/bin:/bin'
LANG='C'
CURL='/usr/bin/curl -XPOST'
NEKO='http://127.0.0.1:2794/submit'
AUTH='haineko:kijitora'
EHLO=`hostname`

if [ -n "$HAINEKO_AUTH" -o -n "$1" ]; then
    CURL="$CURL -u$AUTH"
fi

cat << EOM | $CURL -d'@-' "$NEKO"
{
    'ehlo': "$EHLO",
    'mail': 'envelope-sender@example.jp',
    'rcpt': [ 'envelope-recipient@example.org' ],
    'header': {
        'subject': 'テストメール',
        'from': 'キジトラ <envelope-sender@example.jp>',
        'replyto': 'neko@example.jp'
    },
    'body': 'テストメールです'
}
EOM
