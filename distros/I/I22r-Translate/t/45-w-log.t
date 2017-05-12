use I22r::Translate;
use Test::More;
use lib 't';

# assert that I22r::Translate->log function is being called
# and doing what it's supposed to do

{
    package Test45::Logger;
    sub new { bless {logged=>[]}, 'Test45::Logger' }
    sub log { my ($logger,@msg) = @_; push @{$logger->{logged}}, @msg; }
    sub logged { return scalar @{$_[0]->{logged}} }
}

my $logger = Test45::Logger->new;
I22r::Translate->config(
    logger => $logger,
    'Test::Backend::Reverser' => {
	ENABLED => 1,
    }
);

my $l0 = $logger->logged;
my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'ko', text => 'some unprotected text');
ok( $r, 'translate_string: got result');
my $l1 = $logger->logged;
ok( $l1 > $l0, 'logger invoked during translation' );

done_testing();

