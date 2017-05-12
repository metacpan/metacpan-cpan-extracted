#!perl -w

use strict;

# init some vars
my @affs= qw (
	/usr/lib/ispell/english.aff
	/usr/lib/ispell/american.aff
	/usr/lib/ispell/british.aff
	);

my @test_words=( 'cars', 'dogs' );

my $findaffix_file='./findaffix.out';

my $loaded = 0;
my $debug = 0;

BEGIN { $| = 1; print "1..8\n"; }
END {print "not ok 1\n" unless $loaded;}

use Lingua::Spelling::Alternative;
$loaded = 1;
print "ok 1\n";

### test constructor

my $a = new Lingua::Spelling::Alternative( DEBUG => $debug ) ;

defined($a) || print 'not '; print "ok 2\n";

### test load affix

my $affix_file;
foreach (@affs) {
	if (-e $_) {
		$affix_file = $_;
		last;
	}
}

# test sub

sub test {
	my $a=shift @_;
	my $nr=shift @_;

	my @words = $a->alternatives(@test_words);
	print 'not ' if (! @words);
	print "ok ",$nr++," # - ",join(", ",@test_words)," -> alternatives: ",join(", ",@words),"\n";
	my @min_words = $a->minimal(@test_words);
	print 'not ' if (! @min_words);
	print "ok ",$nr++," # - ",join(", ",@test_words)," -> minimal: ",join(", ",@min_words),"\n";
}

# skip sub

sub skip {
	foreach (@_) {
		print "ok $_ # - Skip\n";
	}
}

if ( -e $affix_file ) {
	my $ok = $a->load_affix($affix_file);
	print 'not ' if (! $ok);
	print "ok 3\n";
	test($a,4);

} else {
	print "ok 3 # - Skip, affix file '$affix_file' not found\n";
	skip(4..5);
}

undef $a;

### test load findaffix

if ( -e $findaffix_file ) {
	my $a = new Lingua::Spelling::Alternative( DEBUG => $debug ) ;

	my $ok = $a->load_findaffix($findaffix_file);
	print 'not ' if (! $ok);
	print "ok 6\n";

	test($a,7);
} else {
	print "ok 6 # - Skip, findaffix file '$findaffix_file' not found\n";
	skip(7..8);
}

