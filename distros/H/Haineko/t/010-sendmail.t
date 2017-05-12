use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko;
use Test::More;
use JSON::Syck;
use Plack::Test;
use HTTP::Request;

my $nekochan = Haineko->start;
my $request1 = undef;
my $response = undef;
my $contents = undef;
my $esmtpres = undef;
my $callback = undef;

my $errorset = [
    { 'path' => 'submit', 'status' => 405, 'code' => 421, 'message' => 'GET method not supported' },
    { 'path' => 'nyaaaa', 'status' => 404, 'code' => 421, 'message' => 'Not found' },
];
my $errindex = 0;

my $nekotest = sub {
    $callback = shift;

    my $v = $errorset->[ $errindex ]->{'path'};
    $request1 = HTTP::Request->new( 'GET' => 'http://127.0.0.1:2794/'.$v );
    $response = $callback->( $request1 );
    $contents = JSON::Syck::Load( $response->content );
    $esmtpres = $contents->{'response'};

    isa_ok $request1, 'HTTP::Request';
    isa_ok $response, 'HTTP::Response';
    isa_ok $contents, 'HASH';
    isa_ok $esmtpres, 'ARRAY';

    is $response->code, $errorset->[ $errindex ]->{'status'}, 'HTTP Status = '.$response->code;

    for my $e ( @$esmtpres ) {
        isa_ok $e, 'HASH';
        is $e->{'dsn'}, undef, 'dsn = undef';
        is $e->{'host'}, undef, 'host = undef';
        is $e->{'port'}, undef, 'port = undef';
        is $e->{'code'}, $errorset->[ $errindex ]->{'code'}, 'SMTP code = '.$e->{'code'};
        is $e->{'error'}, 1;
        is $e->{'mailer'}, undef;
        is $e->{'message'}->[0], $errorset->[ $errindex ]->{'message'}, $e->{'message'}->[0];
        is $e->{'command'}, 'HTTP';
    }
};
for( my $i = 0; $i < scalar @$errorset; $i++ ) {
    $errindex = $i;
    test_psgi $nekochan, $nekotest;
}

my $hostname = qx|hostname|; chomp $hostname;
my $jsondata = {
    'JSON00' => {
        'json' => '{ neko', 'data' => '', 
        'code' => 421, 'dsn' => undef, 'status' => 400, 'command' => 'HTTP',
        'mailer' => undef, 'message' => 'Malformed JSON string',
    },
    'EHLO00' => {
        'json' => q(), 'data' => { 'ehlo' => q() },
        'code' => 501, 'dsn' => '5.0.0', 'status' => 400, 'command' => 'EHLO',
        'message' => 'EHLO requires domain address',
    },
    'EHLO01' => {
        'json' => q(), 'data' => { 'ehlo' => 0 },
        'code' => 501, 'dsn' => '5.0.0', 'status' => 400, 'command' => 'EHLO',
        'message' => 'Invalid domain name',
    },
    'MAIL00' => {
        'json' => q(), 'data' => { 'ehlo' => 'example.jp' },
        'code' => 501, 'dsn' => '5.5.2', 'status' => 400, 'command' => 'MAIL',
        'message' => 'Syntax error in parameters scanning "FROM"',
    },
    'MAIL01' => {
        'json' => q(), 
        'data' => { 'ehlo' => 'example.jp', 'mail' => 'kijitora' },
        'code' => 553, 'dsn' => '5.5.4', 'status' => 400, 'command' => 'MAIL',
        'message' => 'Domain name required for sender address',
    },
    'RCPT00' => {
        'json' => q(), 
        'data' => { 'ehlo' => 'example.jp', 'mail' => 'kijitora@example.jp' },
        'code' => 553, 'dsn' => '5.0.0', 'status' => 400, 'command' => 'RCPT',
        'message' => 'User address required',
    },
    'RCPT01' => {
        'json' => q(), 
        'data' => { 
            'ehlo' => 'example.jp', 
            'mail' => 'kijitora@example.jp',
            'rcpt' => [ 'kijitora' ],
        },
        'code' => 553, 'dsn' => '5.1.5', 'status' => 400, 'command' => 'RCPT',
        'message' => 'Recipient address is invalid',
    },
    'RCPT02' => {
        'json' => q(), 
        'data' => { 
            'ehlo' => 'example.jp', 
            'mail' => 'kijitora@example.jp',
            'rcpt' => [ 'キジトラ@example.org' ],
        },
        'code' => 553, 'dsn' => '5.1.5', 'status' => 400, 'command' => 'RCPT',
        'message' => 'Recipient address is invalid',
    },
    'RCPT03' => {
        'json' => q(), 
        'data' => { 
            'ehlo' => 'example.jp', 
            'mail' => 'kijitora@example.jp',
            'rcpt' => [
                '0@'.$hostname, '1@'.$hostname, '2@'.$hostname, '3@'.$hostname, '4@'.$hostname,
                '5@'.$hostname, '6@'.$hostname, '7@'.$hostname, '8@'.$hostname, '9@'.$hostname,
            ],
        },
        'code' => 452, 'dsn' => '4.5.3', 'status' => 403, 'command' => 'RCPT',
        'message' => 'Too many recipients',
    },
    'DATA01' => {
        'json' => q(), 
        'data' => { 
            'ehlo' => 'example.jp', 
            'mail' => 'kijitora@example.jp',
            'rcpt' => [
                'haineko@'.$hostname,
            ],
            'header' => { 'subject' => 'make test' },
        },
        'code' => 500, 'dsn' => '5.6.0', 'status' => 400, 'command' => 'DATA',
        'message' => 'Message body is empty',
    },
    'DATA02' => {
        'json' => q(), 
        'data' => { 
            'ehlo' => 'example.jp', 
            'mail' => 'kijitora@example.jp',
            'rcpt' => [
                'haineko@'.$hostname,
            ],
            'body' => '猫が出た',
            'header' => { 'subject' => '' },
        },
        'code' => 500, 'dsn' => '5.6.0', 'status' => 400, 'command' => 'DATA',
        'message' => 'Subject header is empty',
    },
};

my $nekopost = sub {
    $callback = shift;

    for my $e ( keys %$jsondata ) {
        $request1 = HTTP::Request->new( 'POST' => 'http://127.0.0.1:2794/submit' );
        $request1->header( 'Content-Type' => 'application/json' );

        my $d = $jsondata->{ $e };
        my $j = $d->{'json'} || JSON::Syck::Dump( $d->{'data'} );

        $request1->content( $j );
        $response = $callback->( $request1 );
        $contents = JSON::Syck::Load( $response->content );
        $esmtpres = $contents->{'response'};

        isa_ok $request1, 'HTTP::Request';
        isa_ok $response, 'HTTP::Response';
        isa_ok $contents, 'HASH';
        isa_ok $esmtpres, 'ARRAY';

        ok $response->is_error;
        is $response->header('Content-Type'), 'application/json';
        is $response->code, $d->{'status'}, sprintf( "[%s] HTTP Status = %s", $e, $d->{'status'} );

        for my $v ( qw|remoteport remoteaddr queueid| ) {
            ok $contents->{ $v }, sprintf( "[%s] %s = %s", $e, $v, $contents->{ $v } );
        }
        isa_ok $contents->{'timestamp'}, 'HASH';
        ok $contents->{'timestamp'}->{'unixtime'};
        ok $contents->{'timestamp'}->{'datetime'};

        for my $p ( @$esmtpres ) {
            isa_ok $p, 'HASH';
            ok $p->{'rcpt'}, sprintf( "[%s] rcpt = %s", $e, $p->{'rcpt'} ) if defined $p->{'rcpt'};
            is $p->{'host'}, undef, sprintf( "[%s] host = undef", $e );
            is $p->{'port'}, undef, sprintf( "[%s] port = undef", $e );
            is $p->{'error'}, 1, sprintf( "[%s] error = 1", $e );

            if( scalar @$esmtpres > 1 ) {

                for my $r ( keys %$d ) {
                    next if $r =~ m/(?:status|json|data|message)/;
                    ok $p->{ $r }, sprintf( "[%s] SMTP %s = %s", $e, $r, ( $p->{ $r } || q() ) );
                }

                for my $v ( @{ $p->{'message'} } ) {
                    ok $v, sprintf( "[%s] SMTP message = %s", $e, $v );
                }
                ok( $p->{'code'} );

            } else {

                for my $r ( keys %$d ) {
                    next if $r =~ m/(?:status|json|data|message)/;
                    is $p->{ $r }, $d->{ $r }, sprintf( "[%s] SMTP %s = %s", $e, $r, ( $d->{ $r } || q() ) );
                }

                is $p->{'message'}->[0], $d->{'message'}, sprintf( "[%s] SMTP message = %s", $e, $d->{'message'} );
                is substr( $p->{'code'}, 0, 1 ), substr( $p->{'dsn'}, 0, 1 ) if $p->{'dsn'};
            }
        }
    }
};
test_psgi $nekochan, $nekopost;
done_testing();
__END__
