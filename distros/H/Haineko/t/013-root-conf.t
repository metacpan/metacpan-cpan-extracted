use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko;
use JSON::Syck;
use Test::More;
use Plack::Test;
use HTTP::Request;

my $nekochan = Haineko->start;
my $request1 = undef;
my $response = undef;
my $contents = undef;
my $callback = undef;
my $nekotest = sub {
    $callback = shift;
    $request1 = HTTP::Request->new( 'GET' => 'http://127.0.0.1:2794/conf' );
    $response = $callback->( $request1 );
    $contents = JSON::Syck::Load( $response->content );

    is $response->code, 200;

    isa_ok $contents, 'HASH';
    isa_ok $contents->{'haineko.cf'}, 'HASH';
    isa_ok $contents->{'haineko.cf'}->{'data'}, 'HASH';
    isa_ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}, 'HASH';
    isa_ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'mailer'}, 'HASH';
    isa_ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'access'}, 'HASH';
    isa_ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'milter'}, 'HASH';

    is $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'system'}, 'Haineko';
    ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'version'};
    ok $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'hostname'};
    is $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'max_message_size'}, 4194304;
    is $contents->{'haineko.cf'}->{'data'}->{'smtpd'}->{'max_rcpts_per_message'}, 4;

    for my $e ( 'sendermt', 'authinfo', 'relayhosts', 'recipients', 'mailertable' ) {
        isa_ok $contents->{ $e }, 'HASH';
    }

    if( defined $ENV{'HAINEKO_AUTH'} && -r -f -s $ENV{'HAINEKO_AUTH'} ) {
        isa_ok $contents->{'password'}, 'HASH';
    }
};
test_psgi $nekochan, $nekotest;
done_testing;
__END__
