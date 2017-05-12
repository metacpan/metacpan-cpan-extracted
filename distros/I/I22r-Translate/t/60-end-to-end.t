use I22r::Translate;
use Test::More;
use t::Constants;


my @log_msgs;
sub my_logger {
    push @log_msgs, @_;
}

if (!$t::Constants::CONFIGURED || !$t::Constants::GOOGLE_API_KEY) {
    ok( 1, 'Google backend not configured for end-to-end test' );
    t::Constants->skip_remaining_tests;
}



I22r::Translate->config(
    filter => [ 'HTML ' ],
    log => \&my_logger,
    output => 'simple',

    'I22r::Translate::Google' => {
	ENABLED => 1,
	REFERER => 'http://test-40.test/',
	API_KEY => $t::Constants::GOOGLE_API_KEY,
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'es',
    text => 'Go to sleep' );

ok($r, 'end to end result received');



done_testing();
