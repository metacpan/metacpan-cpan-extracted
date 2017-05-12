use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Relay::Mandrill;
use Test::More;

my $modulename = 'Haineko::SMTPD::Relay::Mandrill';
my $pkgmethods = [ 'new' ];
my $objmethods = [ 'sendmail', 'getbounce' ];
my $methodargv = {
    'ehlo' => 'Haineko/make-test',
    'mail' => 'kijitora@example.jp',
    'rcpt' => 'mikeneko@example.org',
    'head' => { 
        'From' => 'Kijitora <kijitora@example.jp>',
        'To' => 'Mikechan <mikenkeko@example.org>',
        'Subject' => 'Nyaa--',
        'Message-Id' => 'r65FwCI022420EbogAmI9iOM.2242.1373007492.043@haineko.example.jp',
    },
    'body' => \'Nyaaaaaaaaaaaaa',
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

    for my $e ( qw/mail rcpt head body host port attr auth username password/ ) {
        is $testobject->$e, undef, '->'.$e.' => undef';
    }

    my $o = $modulename->new( %$methodargv );
    my $r = undef;
    my $m = undef;

    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    $methodargv->{'time'} = Time::Piece->new;
    $o = $modulename->new( %$methodargv );
    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    is $o->queueid, undef, '->queueid => undef';

    is $o->mail, $methodargv->{'mail'}, '->mail => '.$o->mail;
    is $o->rcpt, $methodargv->{'rcpt'}, '->rcpt => '.$o->rcpt;
    is $o->body, $methodargv->{'body'}, '->body => '.$o->body;

    is ref $o->attr, 'HASH';
    is $o->timeout, 2, '->timeout => 2';
    is $o->username, undef, '->username => undef';
    is $o->password, undef, '->password => undef';
    is $o->retry, 0, '->retry => 0';
    is $o->sleep, 1, '->sleep => 1';
    is $o->sendmail, 0, '->sendmail => 0';
    is $o->getbounce, 0, '->getbounce => 0';
    ok $o->time, '->time => '.$o->time->epoch;

    $r = $o->response;
    $m = shift @{ $o->response->message };

    is $r->dsn, undef, '->response->dsn => undef';
    is $r->code, 400, '->response->code => 400';
    is $r->error, 1, '->response->error => 1';
    is $r->host, 'mandrillapp.com', '->response->host => '.$r->host;
    is $r->port, 443, '->response->port => 443';
    is $r->rcpt, $methodargv->{'rcpt'}, '->response->rcpt => '.$r->rcpt;
    is $r->command, 'POST', '->response->command => POST';
    like $m, qr/Empty API-KEY/, '->response->message => '.$m;
}

done_testing;
__END__
