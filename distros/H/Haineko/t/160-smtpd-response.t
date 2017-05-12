use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko::SMTPD::Response;
use Test::More;

my $modulename = 'Haineko::SMTPD::Response';
my $pkgmethods = [ 'new', 'r', 'p' ];
my $objmethods = [ 'damn' ];
my $testobject = $modulename->new();

isa_ok $testobject, $modulename;
can_ok $modulename, @$pkgmethods;
can_ok $testobject, @$objmethods;

CLASS_METHODS: {
    my $o = undef;
    my $r = undef;

    $o = $modulename->new;
    is $o->dsn, undef, '->dsn => undef';
    is $o->code, undef, '->code => undef';
    is $o->error, undef, '->error => undef';
    is $o->message, undef, '->message => undef';
    is $o->command, undef, '->command => undef';

    $o = $modulename->new( 'message' => 1 );
    is $o->message, 1, '->message => 1';

    $o = $modulename->new( 'message' => [] );
    isa_ok $o->message, 'ARRAY', '->message => []';

    $r = {
        'conn' => [ qw/ok cannot-connect/ ],
        'http' => [ qw/
                    method-not-supported malformed-json not-found server-error
                    forbidden
        / ],
        'conf' => [ qw/not-looks-like-number/ ],
        'ehlo' => [ qw/invalid-domain require-domain helo-first/ ],
        'auth' => [ qw/
                    no-checkrelay access-denied cannot-decode auth-failed 
                    unavailable-mech no-auth-mech
        / ],
        'mail' => [ qw/
            ok sender-specified domain-required syntax-error
            domain-does-not-exist need-mail non-ascii
        / ],
        'rcpt' => [ qw/
            ok syntax-error address-required too-many-recipients
            is-not-emailaddress need-rcpt rejected
        / ],
        'data' => [ qw/ok enter-mail empty-body empty-subject mesg-too-big/ ],
        'rset' => [ qw/ok/ ],
        'vrfy' => [ qw/cannot-vrfy/ ],
        'verb' => [ qw/verb-unavailable/ ],
        'noop' => [ qw/ok/ ],
        'quit' => [ qw/ok/ ],
    };

    is $modulename->r, undef;
    is $modulename->r('EHLO'), undef;
    is $modulename->r('NEKO'), undef;
    is $modulename->r('EHLO','unknown-response'), undef;

    for my $e ( keys %$r ) {

        for my $f ( @{ $r->{ $e } } ) {

            $o = $modulename->r( $e, $f );
            isa_ok $o, $modulename, '->r';
            ok $o->dsn, sprintf( "->dsn(%s) => %s", uc $e, $o->dsn ) if defined $o->dsn;
            ok $o->code, sprintf( "->code(%s) => %d", uc $e, $o->code );
            is $o->error, 1, sprintf( "->error(%s) => 1", uc $e ) if $o->code =~ m/\A[45]/;
            ok $o->message->[0], sprintf( "->message(%s) => %s", uc $e, $o->message->[0] );
        }
    }

    $r = { 'code' => '550', 'message' => [ '550 5.0.0 Cannot find a cat' ], 'command' => 'RCPT' };
    $o = $modulename->p( %$r );

    isa_ok $o, $modulename, '->p';
    is $o->dsn, '5.0.0', '->dsn => '.$o->dsn;
    is $o->host, undef, '->host => undef';
    is $o->port, undef, '->port => under';
    is $o->code, 550, '->code => '.$o->code;
    is $o->error, 1, '->error => 1';
    is $o->command, 'RCPT', '->command => RCPT';
    like $o->message->[0], qr/Cannot find a cat/, '->message => '.$o->message->[0];

    $r = $o->damn;
    is ref $r, 'HASH', '->damn';
    is $r->{'dsn'}, '5.0.0', '->dsn => '.$r->{'dsn'};
    is $r->{'host'}, undef, '->host = undef';
    is $r->{'port'}, undef, '->port = undef';
    is $r->{'code'}, 550, '->code => '.$r->{'code'};
    is $r->{'error'}, 1, '->error => 1';
    is $r->{'command'}, 'RCPT', '->command => RCPT';
    like $r->{'message'}->[0], qr/Cannot find a cat/, '->message => '.$r->{'message'}->[0];

    isa_ok $o->mesg, $modulename;
    isa_ok $o->mesg('neko'), $modulename;
}

done_testing;
__END__
