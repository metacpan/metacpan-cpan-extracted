use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Greeting;
use Test::More;

my $modulename = 'Haineko::SMTPD::Greeting';
my $pkgmethods = [ 'new' ];
my $objmethods = [ 'mechs' ];
my $ehlogreets = [ <DATA> ];
my $testobject = new $modulename( @$ehlogreets );

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

INSTANCE_METHODS: {

    my $o = new $modulename( @$ehlogreets );
    my $v = undef;

    is $o->dsn, 1, '->dsn => 1';
    ok $o->size, '->size => '.$o->size;
    is $o->auth, 1, '->auth => 1';
    is ref $o->mechanism, 'ARRAY', '->mechanism => '.join( ' ', @{ $o->mechanism } );
    is ref $o->feature, 'ARRAY', '->feature => '.join( ' ', @{ $o->feature } );

    like $o->greeting, qr/kijitora/, '->greeting => '.$o->greeting;
    isnt $o->starttls, 1, '->starttls => undef';
    is $o->pipelining, 1, '->pipelining => 1';

    is $o->mechs, 0;
    is $o->mechs('NEKO'), 0;
    is $o->mechs('PLAIN'), 1;
}

done_testing;
__DATA__
250-kijitora.example.jp Hello [192.0.2.25], pleased to meet you
250-ENHANCEDSTATUSCODES
250-PIPELINING
250-8BITMIME
250-SIZE 26214400
250-DSN
250-ETRN
250-AUTH LOGIN PLAIN CRAM-MD5
250-DELIVERBY
250 HELP
