use v5.30;
use warnings;

package Mac::Finder::Tags::Tag;
# ABSTRACT: Representation of a single tag
$Mac::Finder::Tags::Tag::VERSION = '0.02';

use Carp 'carp';
our @CARP_NOT = qw( Mac::Finder::Tags );
use Mac::PropertyList 'parse_plist';
use Object::Pad 0.60;
use Path::Tiny;


# color names and legacy Finder labels
my @LABELS = ('', qw[ Gray Green Purple Blue Yellow Red Orange ]);
my @COLORS = map {lc} @LABELS;
eval {
	my $LABELS_PATH = '~/Library/Preferences/com.apple.Labels.plist';
	my $labels = parse_plist( path($LABELS_PATH)->slurp )->as_perl;
	for (1..7) {
		my $key = "Label_Name_$_";
		next unless defined $labels->{$key};
		$LABELS[$_] = $labels->{$key};
	}
};
my %LABELS = map {( $LABELS[$_] => $_ )} 1..7;
my %FLAGS  = map {( $COLORS[$_] => $_ )} 1..7;

# Some of these were introduced in Unicode 12.0,
# for which support was added in Perl 5.30.
my @EMOJI  = (
	"\N{MEDIUM WHITE CIRCLE}\N{VARIATION SELECTOR-16}",
	"\N{MEDIUM BLACK CIRCLE}\N{VARIATION SELECTOR-16}",
	"\N{LARGE GREEN CIRCLE}",
	"\N{LARGE PURPLE CIRCLE}",
	"\N{LARGE BLUE CIRCLE}",
	"\N{LARGE YELLOW CIRCLE}",
	"\N{LARGE RED CIRCLE}",
	"\N{LARGE ORANGE CIRCLE}",
);


class Mac::Finder::Tags::Tag :strict(params) {
	
	field $name  :reader :param;
	field $color :reader :param = undef;
	field $flags :reader;
	
	field $legacy_label  :reader :param = !!0;
	field $color_guessed :reader :param = !!0;
	
	
	ADJUST {
		$self->_adjust_color_flags();
	}
	
	method _adjust_color_flags () {
		if ($legacy_label) {
			$name = $LABELS[$color];
		}
		elsif ($color_guessed) {
			$color = $LABELS{$name};
		}
		
		return unless defined $color;
		if ($color =~ m/^[0-7]$/) {
			$flags = 0 + $color;
			$color = $COLORS[$flags];
		}
		elsif (exists $FLAGS{$color}) {
			$flags = $FLAGS{$color};
		}
		else {
			$flags = 0;
			carp "Unkown color '$color'" if $color;
		}
	}
	
	method emoji () {
		defined $flags ? $EMOJI[$flags] : '';
	}
	
}


1;
