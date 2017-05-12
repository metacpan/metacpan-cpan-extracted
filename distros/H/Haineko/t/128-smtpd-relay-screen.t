use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Relay::Screen;
use Test::More;

my $modulename = 'Haineko::SMTPD::Relay::Screen';
my $pkgmethods = [ 'new' ];
my $objmethods = [ 'sendmail' ];
my $methodargv = {
    'mail' => 'kijitora@example.jp',
    'rcpt' => 'mikeneko@example.org',
    'head' => { 
        'From', 'Kijitora <kijitora@example.jp>',
        'To', 'Mikechan <mikenkeko@example.org>',
        'Subject', 'Nyaa--',
    },
    'body' => \'Nyaaaaaaaaaaaaa',
    'attr' => {},
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

    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    $methodargv->{'time'} = Time::Piece->new;
    $o = $modulename->new( %$methodargv );
    isa_ok $o->time, 'Time::Piece';
    ok $o->time, '->time => '.$o->time->epoch;

    is $o->mail, $methodargv->{'mail'}, '->mail => '.$o->mail;
    is $o->rcpt, $methodargv->{'rcpt'}, '->rcpt => '.$o->rcpt;
    is $o->host, undef, '->host => undef';
    is $o->port, undef, '->port => undef';
    is $o->body, $methodargv->{'body'}, '->body => '.$o->body;

    is ref $o->attr, 'HASH';
    is $o->timeout, 0, '->timeout => 0';
    is $o->retry, 0, '->retry => 0';
    is $o->sleep, 0, '->sleep => 0';
    is $o->sendmail, 1, '->sendmail => 1';

    $r = $o->response;
    $m = shift @{ $o->response->message };

    is $r->dsn, undef, '->response->dsn => undef';
    is $r->code, 200, '->response->code => 200';
    is $r->host, undef, '->response->host => undef';
    is $r->port, undef, '->response->port => undef';
    is $r->rcpt, $methodargv->{'rcpt'}, '->response->rcpt => '.$r->rcpt;
    is $r->error, 0, '->response->error=> 0';
    is $r->command, 'DATA', '->response->command => DATA';
    is $m, 'OK', '->response->message => '.$m;
}

done_testing;
__END__

