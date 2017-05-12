use I22r::Translate;
use Test::More;
use Data::Dumper;
use t::Constants;


my @log_msgs;
sub my_logger {
    push @log_msgs, @_;
}


if (!$t::Constants::CONFIGURED || !$t::Constants::BING_SECRET) {
    ok( 1, 'Microsoft backend not configured for end-to-end test' );
    t::Constants->skip_remaining_tests;
}
if (!$t::Constants::GOOGLE_API_KEY) {
   ok( 1, 'Google backend not configured for end-to-end test' );
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
    },

    'I22r::Translate::Google' => {
	ENABLED => 1,
	REFERER => 'http://test-70.test',
	API_KEY => $t::Constants::GOOGLE_API_KEY,
    }
);

my $r = I22r::Translate->translate_string(
    src => 'en', dest => 'es',
    text => 'Go to sleep' );

$ENV{DIAG} && diag $r;

ok($r, 'end to end result received');

my @r = I22r::Translate->translate_list(
    src => 'en', dest => 'de',
    return_type => 'hash',
    text => [
	"Perhaps the great Dawkins wasn't so wise.",
	"Maybe some otters do need to believe in something.",
	"Maybe just believing in God makes God exist.",
	"Kill the wise one!",
	"Who is this?",
	"Listen to me carefully.",
	"You need to be patient.",
	"You have to be patient and wait for the Nintendo Wii to come out.",
	"I'm trying to do you a favor.",
	"I'm about to come over to your house and ask you to help me freeze myself.",
	"Do not do what I tell you.",
	"Come on, we got to go.",
	"Come on, it's going to get dark.",
	"If you freeze yourself, you're going to die."
    ] );

ok($r[0]{SOURCE} eq 'Google' || $r[0]{SOURCE} eq 'Microsoft',
   'source was one of "Google" or "Microsoft"') or diag Dumper \@r;

# in principle, if you run this test several times, 
# sometimes it will use Google and sometimes it will use
# Microsoft


done_testing();
