use Test::More;
use utf8;
use Data::Dumper;
use I22r::Translate;
use t::Constants;
use strict;
use warnings;

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
if (defined $DB::OUT) {
    # if Perl debugger is running
    binmode $DB::OUT, ':encoding(UTF-8)';
}

ok(1, 'starting test');
t::Constants::skip_remaining_tests() unless $t::Constants::CONFIGURED;

my $src = 'en';
my $dest = $ARGV[0] || 'es';

t::Constants::basic_config();

# expect output with some diacritical marks

my %INPUT = (
    "youtoo" => "And you too?",   # expect  tambie'n
    "iknow"  => "I know.",        # expect  Se'.
    "Spanish" => "Spanish",       # expect  n~
    );

my %R = I22r::Translate->translate_hash(
    src => $src, dest => $dest, text => \%INPUT,
    return_type => 'hash' );

ok($R{"youtoo"}{TEXT} =~ /é/, 'result with acute e ok')
    or diag("result '",$R{youtoo}{TEXT},"': ",
	    map{" ".ord}split //, $R{"youtoo"}{TEXT});

ok($R{"iknow"}{TEXT} =~ /é/, 'result with acute e ok')
    or diag("result: ", map{" ".ord}split //, $R{"iknow"}{TEXT});

ok($R{"Spanish"}{TEXT} =~ /ñ/, 'result with tilde n ok')
    or diag("result: ", map{" ".ord}split(//, $R{"Spanish"}{TEXT}));


# use (English) input with diacritical marks

%INPUT = (Beyonce => "vis-à-vis Beyoncé's naïve papier-mâché résumé");
%R = I22r::Translate->translate_hash(
    src => 'en', dest => 'fr', text => \%INPUT,
    return_type => 'object');

ok( keys %R == keys %INPUT , 'output length equals input length' );
ok( $R{"Beyonce"} && $R{"Beyonce"}->otext =~ /vis-à-vis/,
    'original text preserved' )
    or diag(Dumper(\%R));

done_testing();
