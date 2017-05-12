use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Relay;
use Test::More;

my $modulename = 'Haineko::SMTPD::Relay';
my $pkgmethods = [ 'new', 'defaulthub' ];
my $objmethods = [ 'sendmail', 'getbounce' ];
my $methodargv = {
    'mail' => 'kijitora@example.jp',
    'rcpt' => 'mikeneko@example.org',
    'head' => { 
        'From', 'Kijitora <kijitora@example.jp>',
        'To', 'Mikechan <mikenkeko@example.org>',
        'Subject', 'Nyaa--',
    },
    'body' => 'Nyaaaaaaaaaaaaa',
    'host' => '127.0.0.1',
    'port' => 25,
    'attr' => {},
};
my $testobject = $modulename->new();
my $properties = [ qw/
    time mail rcpt head body host port attr 
    auth timeout username password
/ ];

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

for my $e ( @$properties ) {
    is $testobject->$e, undef, '->'.$e.' => undef';
}

my $o = $modulename->new( %$methodargv );
my $h = $modulename->defaulthub;

is $o->mail, $methodargv->{'mail'}, '->mail => '.$o->mail;
is $o->rcpt, $methodargv->{'rcpt'}, '->rcpt => '.$o->rcpt;
is $o->host, $methodargv->{'host'}, '->host => '.$o->host;
is $o->port, $methodargv->{'port'}, '->port => '.$o->port;
is $o->body, $methodargv->{'body'}, '->body => '.$o->body;

is ref $o->attr, 'HASH';
is $o->auth, undef, '->auth => undef';
is $o->timeout, undef, '->timeout => undef';
is $o->username, undef, '->username => undef';
is $o->password, undef, '->password => undef';
is $o->response, undef, '->response => undef';
is $o->starttls, undef, '->starttls => undef';
is $o->sendmail, 0, '->sendmail => 0';
is $o->getbounce, 0, '->getbounce => 0';

is $h->{'host'}, '127.0.0.1', '->defaulthub->host => 127.0.0.1';
is $h->{'port'}, 25, '->defaulthub->port => 25';
is $h->{'auth'}, 0, '->defaulthub->auth => 0';
is $h->{'mailer'}, 'ESMTP', '->defaulthub->mailer => ESMTP';

done_testing;
__END__
