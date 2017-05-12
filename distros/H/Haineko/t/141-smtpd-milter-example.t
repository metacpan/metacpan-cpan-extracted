use lib qw(./t/lib ./dist/lib ./lib);
use strict;
use warnings;
use Haineko::SMTPD::Milter;
use Haineko::SMTPD::Response;
use Test::More;

my $modulename = 'Haineko::SMTPD::Milter';
my $miltername = 'Example';
my $pkgmethods = [ 'conn', 'ehlo', 'mail', 'rcpt', 'head', 'body' ];
my $loadedlist = Haineko::SMTPD::Milter->import( [ $miltername ] );

is( $loadedlist->[0], 'Haineko::SMTPD::Milter::Example', '->import( [ Example ] )' );
can_ok( $loadedlist->[0], @$pkgmethods );

METHODS: {
    my $r = undef;
    my $v = 0;
    my $m = $loadedlist->[0];
    my $x = [];
    my $y = {};

    CONN: {
        is $m->conn, 1;

        $r = Haineko::SMTPD::Response->new();
        $v = $m->conn( $r, 'localhost', '127.0.0.1' );
        is( $v, 1, '->conn( $r, localhost, 127.0.0.1 ) => 1' );

        $v = $m->conn( $r, 'localhost.localdomain' );
        is( $v, 0, '->conn( $r, localhost.localdomain ) => 0' );

        $v = $m->conn( $r, 'localhost', '255.255.255.255' );
        is( $v, 0, '->conn( $r, localhost, 255.255.255.255 ) => 0' );
        is( $r->error, 1, 'r->error = 1' );
        is( $r->message->[0], 'Broadcast address', 'r->message = Broadcast address' );
    }

    EHLO: {
        is $m->ehlo, 1;

        $r = Haineko::SMTPD::Response->new();
        $v = $m->ehlo( $r, 'neko.example.jp' );
        is( $v, 1, '->ehlo( $r, neko.example.jp ) => 1' );

        $v = $m->ehlo( $r, 'neko.local' );
        is( $v, 0, '->ehlo( $r, neko.local ) => 0' );
        is( $r->code, 521, 'r->code = 521' );
        is( $r->error, 1, 'r->error = 1' );
        like( $r->message->[0], qr/Invalid domain/, 'r->message = Invalid domain' );
    }

    MAIL: {
        is $m->mail, 1;

        $r = Haineko::SMTPD::Response->new();
        $v = $m->mail( $r, 'cat@neko.example.jp' );
        is( $v, 1, '->mail( $r, cat@neko.example.jp ) => 1' );

        $v = $m->mail( $r, 'spammer@example.com' );
        is( $v, 0, '->mail( $r, spammer@example.com ) => 0' );
        is( $r->error, 1, 'r->error = 1' );
        like( $r->message->[0], qr/spammer is not allowed/, 'r->message = spammer is not...' );
    }

    RCPT: {
        is $m->rcpt, 1;

        $r = Haineko::SMTPD::Response->new();
        $x = [ 'kijitora@example.jp' ];
        $v = $m->rcpt( $r, $x );
        is( $v, 1, '->rcpt( $r, [ kijitora@example.jp ] ) => 1' );
        is( $r->error, undef, 'r->error => undef' );
        is( $x->[0], 'kijitora@example.jp', '[ kijitora@example.jp ]' );
        is( $x->[1], 'always-bcc@example.jp', '[ kijitora@.., always-bcc@... ]' );
    }

    HEAD: {
        is $m->head, 1;

        $r = Haineko::SMTPD::Response->new();
        $y = { 'subject' => 'spam spam spam', 'from' => 'kijitora@example.org' };
        $v = $m->head( $r, $y );
        is( $v, 0, '->head( $r, { subject => "spam" } )' );
        is( $r->dsn, '5.7.1', 'r->dsn => 5.7.1' );
        is( $r->error, 1, 'r->error = 1' );
        like( $r->message->[0], qr/DO NOT SEND/, 'r->message = DO NOT SEND' );
    }

    BODY: {
        is $m->body, 1;

        $r = Haineko::SMTPD::Response->new();
        $v = $m->body( $r, \'URL is http://nekochan.example.com/?neko=kijitora' );
        is( $v, 0, '->body( $r, \"URL is http://..." )' );
        is( $r->error, 1, 'r->error = 1' );
        like( $r->message->[0], qr/Not allowed to send/, 'r->message = Not allowed to send...' );
    }
}

done_testing;


