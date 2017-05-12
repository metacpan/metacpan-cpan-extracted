use Test::More;
use utf8;
use Data::Dumper;
use I22r::Translate;
use t::Constants;
use strict;
use warnings;

# exercise translator with some non-latin inputs.
# Expect input and output to use unicode code points.

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';
if (defined $DB::OUT) {
    # if Perl debugger is running
    binmode $DB::OUT, ':encoding(UTF-8)';
}

ok(1, 'starting test');
t::Constants::skip_remaining_tests() unless $t::Constants::CONFIGURED;

t::Constants::basic_config();

my %INPUT = (abc => '以此我相信和平是必要的，合理的结果。',
	     def => '我们的问题是人为的，因此它们都可以被人解决的。 任何人可以想他们一样大。'
    );
my $src = 'zh';

for my $dest ('en','ja','th') {

    my $time1 = time;
    my %R = I22r::Translate->translate_hash(
	src => $src, dest => $dest, text => \%INPUT,
	return_type => 'hash');

    ok(defined $R{'abc'} && defined $R{'def'},
       "results provided");

    ok($R{'abc'}{ID} eq 'abc' && $R{'def'}{ID} eq 'def',
       "results have ID");

    ok($R{'abc'}{OTEXT} eq $INPUT{'abc'} && $R{'def'}{OTEXT} eq $INPUT{'def'},
       "results have OTEXT");

    ok($R{'abc'}{OLANG} eq $src && $R{'def'}{OLANG} eq $src,
       "results have OLANG");

    if ($dest eq 'th') {
	ok( is_thai( $R{'abc'}{TEXT} ), 'translated text is Thai' );
	ok( is_thai( $R{'def'}{TEXT} ), 'translated text is Thai' );
    } elsif ($dest eq 'en') {
	ok( is_english( $R{'abc'}{TEXT} ), 'translated text is English' );
	ok( is_english( $R{'def'}{TEXT} ), 'translated text is English' )
	    or diag Dumper \%R;
    } else {
	ok( is_chinese( $R{'abc'}{OTEXT} ),
	    'original text is Chinese' );
    }

    ok($R{'abc'}{LANG} eq $dest && $R{'def'}{LANG} eq $dest,
       "results have LANG");
    
#ok($R{'abc'}{TEXT} =~ /taco/ && $R{'def'}{TEXT} =~ /taco/,
#   "results have TEXT, text looks reasonable");

    ok( !$R{'abc'}{RTEXT}, 'results do not have RTEXT element' );

    ok($R{'abc'}{OTEXT} ne $R{'abc'}{TEXT} &&
       $R{'def'}{OTEXT} ne $R{'def'}{TEXT},
       "OTEXT is not the same as TEXT")
    or diag($R{abc}{OTEXT}," ne? ", $R{abc}{TEXT},
	    "  &&  ", $R{def}{OTEXT}, " ne? ", $R{def}{TEXT});

    ok(join ("\n",map { $INPUT{$_} } sort keys %INPUT) eq
       join ("\n",map { $R{$_}{OTEXT} } sort keys %R),
       "original text is maintained");
    
    my $time2 = time;

    ok(defined $R{'abc'}{TIME} && defined $R{'def'}{TIME}
       && $R{'abc'}{TIME} >= $time1 && $R{'abc'}{TIME} <= $time2
       && $R{'def'}{TIME} >= $time1 && $R{'def'}{TIME} <= $time2,
       "results have TIME, looks reasonable");

    ok(defined $R{'abc'}{SOURCE} && defined $R{'def'}{SOURCE}
       && $R{'abc'}{SOURCE} eq $R{'def'}{SOURCE},
       "results have SOURCE");
}

done_testing();

sub is_chinese {
    my $text = shift;
    my ($in,$chars);
    foreach my $char (map{ord} split //, $text) {
	$chars++;
	$in++ if $char >= 0x4E00 && $char <= 0x9FFFF;
    }
    $in > $chars * 0.8;
}

sub is_thai {
    my $text = shift;
    my ($in,$chars);
    foreach my $char (map{ord} split //, $text) {
	$chars++;
	$in++ if $char >= 0x0E01 && $char <= 0x0E5F;
    }
    $in >= $chars * 0.8;
}

sub is_english {
    my $text = shift;
    my ($in,$chars);
    foreach my $char (map{ord} split //, $text) {
	$chars++;
	$in++ if $char >= 32 && $char <= 127;
    }
    $in > 0.8 * $chars;
}

