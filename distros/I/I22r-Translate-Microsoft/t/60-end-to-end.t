use I22r::Translate;
use Test::More;
use t::Constants;


my @log_msgs;
sub my_logger {
    push @log_msgs, @_;
}

if (!$t::Constants::CONFIGURED || !$t::Constants::BING_SECRET) {
    ok( 1, 'Microsoft backend not configured for end-to-end test' );
    t::Constants->skip_remaining_tests;
}



I22r::Translate->config(
    filter => [ 'HTML ' ],
    log => \&my_logger,
    output => 'simple',

    'I22r::Translate::Microsoft' => {
	ENABLED => 1,
	REFERER => 'http://test-60.test/',
	CLIENT_ID => $t::Constants::BING_CLIENT_ID,
	SECRET => $t::Constants::BING_SECRET,
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'es',
    text => 'Go to sleep' );

diag $r;

ok($r, 'end to end result received');



done_testing();
