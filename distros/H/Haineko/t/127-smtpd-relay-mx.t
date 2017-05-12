use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Relay::MX;
use Test::More;

my $modulename = 'Haineko::SMTPD::Relay::MX';
my $pkgmethods = [ 'new' ];
my $objmethods = [ 'sendmail' ];
my $methodargv = {
    'mail' => 'kijitora@example.jp',
    'rcpt' => 'mikeneko@example.co.jp',
    'head' => { 
        'From', 'Kijitora <kijitora@example.jp>',
        'To', 'Mikechan <mikenkeko@example.co.jp>',
        'Subject', 'Test mail from Haineko',
    },
    'body' => \'Test message',
    'attr' => {},
    'retry' => 0,
    'sleep' => 1,
    'timeout' => 2,
};
my $testobject = $modulename->new();

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

INSTANCE_METHODS: {

    for my $e ( qw/mail rcpt head body attr/ ) {
        is $testobject->$e, undef, '->'.$e.' => undef';
    }

    my $o = $modulename->new( %$methodargv );
    my $r = undef;
    my $m = undef;
    my $s = undef;

    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    $methodargv->{'time'} = Time::Piece->new;
    $o = $modulename->new( %$methodargv );
    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    is $o->mail, $methodargv->{'mail'}, '->mail => '.$o->mail;
    is $o->rcpt, $methodargv->{'rcpt'}, '->rcpt => '.$o->rcpt;
    is $o->host, '', '->host => ""';
    is $o->port, 25, '->port => 25';
    is $o->body, $methodargv->{'body'}, '->body => '.$o->body;

    is ref $o->attr, 'HASH';
    is $o->timeout, 2, '->timeout => 2';
    is $o->retry, 0, '->retry => 1';
    is $o->sleep, 1, '->sleep => 1';

    $s = $o->sendmail;
    $r = $o->response;
    $m = shift @{ $o->response->message };

    if( $s == 1 ) {
        is $o->sendmail, 1, '->sendmail => 1';
        is $r->error, 0, '->response->error=> 0';

        like $r->dsn, qr/\d[.]\d[.]\d/, '->response->dsn => '.$r->dsn;
        like $r->code, qr/\d{3}/, '->response->code => '.$r->code;
        like $r->command, qr/[A-Z]+/, '->response->command => '.$r->command;
        ok length( $m ), '->response->message => '.$m;

    } else {
        is $o->sendmail, 0, '->sendmail => 0';
        is $r->dsn, undef, '->response->dsn => undef';
        is $r->code, 421, '->response->code => 421';
        is $r->error, 1, '->response->error=> 1';
        is $r->command, 'CONN', '->response->command => CONN';

        like $m, qr/Cannot connect SMTP Server/, '->response->message => '.$m;
    }

    is $r->host, undef, '->response->host => undef';
    is $r->port, 25, '->response->port => 25';
    is $r->rcpt, $methodargv->{'rcpt'}, '->response->rcpt => '.$r->rcpt;
}

done_testing;
__END__
