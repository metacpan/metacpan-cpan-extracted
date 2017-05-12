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
    $request1 = HTTP::Request->new( 'GET' => 'http://127.0.0.1:2794/sample/mail' );
    $response = $callback->( $request1 );
    $contents = JSON::Syck::Load( $response->content );

    is $response->code, 200;
    isa_ok $contents, 'ARRAY';

    for my $e ( @$contents ) {
        my $h = $e->{'header'};

        isa_ok( $e, 'HASH' );
        isa_ok( $e->{'rcpt'} || $e->{'to'}, 'ARRAY' );
        isa_ok( $e->{'header'}, 'HASH' );

        ok $e->{'body'};
        ok( $e->{'ehlo'} || $e->{'helo'} );
        ok( $e->{'mail'} || $e->{'from'} );

        ok $h->{'subject'};
        ok $h->{'from'};
        ok( $h->{'replyto'} || $h->{'charset'} );
    }
};
test_psgi $nekochan, $nekotest;
done_testing;
__END__

