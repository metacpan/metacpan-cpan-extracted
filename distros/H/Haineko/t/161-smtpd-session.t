use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Session;
use Haineko::SMTPD::Response;
use Test::More;

my $modulename = 'Haineko::SMTPD::Session';
my $pkgmethods = [ 'new', 'make_queueid', 'done' ];
my $objmethods = [ 'ehlo', 'auth', 'mail', 'rcpt', 'data', 'rset', 'quit', 'damn' ];
my $testobject = $modulename->new();

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

METHODS: {
    my $x = { 
        'useragent'  => 'CLI', 
        'remoteaddr' => '127.0.0.1',
        'addresser'  => 'kijitora@example.jp',
        'recipient'  => [ 'mi-chan@example.org' ],
        'response'   => Haineko::SMTPD::Response->new,
    };
    my $y = undef;
    my $z = undef;
    my $o = $modulename->new( %$x );

    NEW: {
        isa_ok $o, $modulename, '->new';
        isa_ok $o->started, 'Time::Piece', '->started => Time::Piece';
        ok $o->started->epoch, '->started->epoch => '.$o->started->epoch;
        is $o->stage, 0, '->stage => 0';
        isa_ok $o->response, 'ARRAY', '->response => ARRAY';
        for my $e ( @{ $o->response } ) {
            isa_ok $e, 'Haineko::SMTPD::Response', '->response->[n] => Haineko::SMTPD::Response';
            is $e->dsn, undef, '->response->[n]->dsn => undef';
        }

        isa_ok $o->addresser, 'Haineko::SMTPD::Address', '->addresser => Haineko::SMTPD::Address';
        is $o->addresser->user, 'kijitora', '->addresser->user => kijitora';
        is $o->addresser->host, 'example.jp', '->addresser->host => example.jp';
        is $o->addresser->address, 'kijitora@example.jp', '->addresser->address => kijitora@example.jp';

        isa_ok $o->recipient->[0], 'Haineko::SMTPD::Address', '->recipient->[0] => Haineko::SMTPD::Address';
        is $o->recipient->[0]->user, 'mi-chan', '->recipient->[0]->user => mi-chan';
        is $o->recipient->[0]->host, 'example.org', '->recipient->[0]->host => example.org';
        is $o->recipient->[0]->address, 'mi-chan@example.org', '->recipient->[0]->address => mi-chan@example.org';

        ok $o->queueid, '->queueid => '.$o->queueid;
        is $o->useragent, 'CLI', '->useragent => CLI';
        is $o->remoteaddr, '127.0.0.1', '->remoteaddr => 127.0.0.1';
        is $o->remoteport, undef, '->remoteport => undef';
        is $o->referer, undef, '->referer => undef';
    }

    MAKE_QUEUEID: {
        $y = $modulename->make_queueid;
        ok $y, '->queueid => '.$y;
    }

    DONE: {
        is $modulename->done('ehlo'), ( 1 << 0 ), '->done(ehlo) => '.( 1 << 0 );
        is $modulename->done('auth'), ( 1 << 1 ), '->done(auth) => '.( 1 << 1 );
        is $modulename->done('mail'), ( 1 << 2 ), '->done(mail) => '.( 1 << 2 );
        is $modulename->done('rcpt'), ( 1 << 3 ), '->done(rcpt) => '.( 1 << 3 );
        is $modulename->done('data'), ( 1 << 4 ), '->done(data) => '.( 1 << 4 );
        is $modulename->done('quit'), ( 1 << 5 ), '->done(quit) => '.( 1 << 5 );
    }

    COMMAND: {
        $o->ehlo(1); is $o->stage, 1, '->stage => '.$o->stage;
        $o->auth(1); is $o->stage, 3, '->stage => '.$o->stage;
        $o->mail(1); is $o->stage, 7, '->stage => '.$o->stage;
        $o->rcpt(1); is $o->stage, 15, '->stage => '.$o->stage;
        $o->data(1); is $o->stage, 31, '->stage => '.$o->stage;
        $o->rset(1); is $o->stage, 1, '->stage => '.$o->stage;
        $o->quit(1); is $o->stage, 0, '->stage => '.$o->stage;
    }
}

done_testing;
__END__
