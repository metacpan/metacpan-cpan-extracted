use lib qw|./lib ./blib/lib|;
use strict;
use warnings;
use Haineko;
use Test::More;
use Plack::Test;
use HTTP::Request;

my $nekochan = Haineko->start;
my $request1 = undef;
my $response = undef;
my $callback = undef;
my $nekotest = sub {
    $callback = shift;
    $request1 = HTTP::Request->new( 'GET' => 'http://127.0.0.1:2794/dump' );
    $response = $callback->( $request1 );
    is $response->code, 200;
};
test_psgi $nekochan, $nekotest;
done_testing;
__END__
