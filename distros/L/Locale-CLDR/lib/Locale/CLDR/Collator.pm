package Locale::CLDR::Collator;

use version;
our $VERSION = version->declare('v0.32.0');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Unicode::Normalize('NFD');
use Unicode::UCD qw( charinfo );
use List::MoreUtils qw(pairwise);
use Moo;
use Types::Standard qw(Str Int Maybe ArrayRef InstanceOf);
with 'Locale::CLDR::CollatorBase';

my $NUMBER_SORT_TOP = "\x{FD00}\x{0034}";
my $LEVEL_SEPARATOR = "\x{0001}";
my $FIELD_SEPARATOR = "\x{0002}";

has 'type' => (
	is => 'ro',
	isa => Str,
	default => 'standard',
);

has 'locale' => (
	is => 'ro',
	isa => Maybe[InstanceOf['Locale::CLDR']],
	default => undef,
	predicate => 'has_locale',
);

has 'alternate' => (
	is => 'ro',
	isa => Str,
	default => 'noignore'
);

has 'backwards' => (
	is => 'ro',
	isa => Str,
	default => 'false',
);

has 'case_level' => (
	is => 'ro',
	isa => Str,
	default => 'false',
);

has 'case_ordering' => (
	is => 'ro',
	isa => Str,
	default => 'false',
);

has 'normalization' => (
	is => 'ro',
	isa => Str,
	default => 'false',
);

has 'numeric' => (
	is => 'ro',
	isa => Str,
	default => 'false',
);

has 'reorder' => (
	is => 'ro',
	isa => ArrayRef,
	default => sub { [] },
);

has 'strength' => (
	is => 'ro',
	isa => Int,
	default => 3,
);

has 'max_variable' => (
	is => 'ro',
	isa => Str,
	default => 'punct',
);

# Set up the locale overrides
sub BUILD {
	my $self = shift;
	
	my $overrides = [];
	if ($self->has_locale) {
		$overrides = $self->locale->_collation_overrides($self->type);
	}
	
	foreach my $override (@$overrides) {
		$self->_set_ce(@$override);
	}
}

sub _get_sort_digraphs_rx {
	my $self = shift;
	
	my $digraphs = $self->_digraphs();
	
	my $rx = join '|', @$digraphs, '.';
	
	# Fix numeric sorting here
	if ($self->numeric eq 'true') {
		$rx = "\\p{Nd}+|$rx";
	}
	
	return qr/$rx/;
}


# Get the collation element at the current strength
sub get_collation_element {
	my ($self, $grapheme) = @_;
	my $ce;
	if ($self->numeric && $grapheme =~/^\p{Nd}/) {
		my $numeric_top = $self->collation_elements()->{$NUMBER_SORT_TOP};
		my @numbers = $self->_convert_digits_to_numbers($grapheme);
		$ce = join '', map { "$numeric_top${LEVEL_SEPARATOR}№$_" } @numbers;
	}
	else {
		$ce = $self->collation_elements()->{$grapheme};
	}

	my $strength = $self->strength;
	my @elements = split /$LEVEL_SEPARATOR/, $ce;
	foreach my $element (@elements) {
		my @parts = split /$FIELD_SEPARATOR/, $element;
		if (@parts > $strength) {
			@parts = @parts[0 .. $strength - 1];
		}
		$element = join $FIELD_SEPARATOR, @parts;
	}
	
	return @elements;
}

# Converts $string into a string of Collation Elements
sub getSortKey {
	my ($self, $string) = @_;

	$string = NFD($string) if $self->normalization eq 'true';
	
	my $entity_rx = $self->_get_sort_digraphs_rx();

	my @ce;
	while (my ($grapheme) = $string =~ /($entity_rx)/g ) {
		push @ce, $self->get_collation_element($grapheme)
	}

	return \@ce;
}

sub generate_ce {
	my ($self, $character) = @_;
	
	my $base;
	
	if ($character =~ /\p{Unified_Ideograph}/) {
		if ($character =~ /\p{Block=CJK_Unified_Ideographs}/ || $character =~ /\p{Block=CJK_Compatibility_Ideographs}/) {
			$base = 0xFB40;
		}
		else {
			$base = 0xFB80;
		}
	}
	else {
		$base = 0xFBC0;
	}
	
	my $aaaa = $base + unpack( 'L', (pack ('L', ord($character)) >> 15));
	my $bbbb = unpack('L', (pack('L', ord($character)) & 0x7FFF) | 0x8000);
	
	return join '', map {chr($_)} $aaaa, 0x0020, 0x0002,0, $bbbb,0,0,0;
}

# sorts a list according to the locales collation rules
sub sort {
	my $self = shift;
	
	return map { $_->[0]}
		sort { $a->[1] cmp $b->[1] }
		map { [$_, $self->getSortKey($_)] }
		@_;
}

sub cmp {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) cmp $self->getSortKey($b);
}

sub eq {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) eq $self->getSortKey($b);
}

sub ne {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) ne $self->getSortKey($b);
}

sub lt {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) lt $self->getSortKey($b);
}

sub le {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) le $self->getSortKey($b);
}
sub gt {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) gt $self->getSortKey($b);
}

sub ge {
	my ($self, $a, $b) = @_;
	
	return $self->getSortKey($a) ge $self->getSortKey($b);
}

# Get Human readable sort key
sub viewSortKey {
	my ($self, $sort_key) = @_;
	
	my @levels = split/\x0/, $sort_key;
	
	foreach my $level (@levels) {
		$level = join ' ',  map { sprintf '%0.4X', ord } split //, $level;
	}
	
	return '[ ' . join (' | ', @levels) . ' ]';
}

sub _convert_digits_to_numbers {
	my ($self, $digits) = @_;
	my @numbers = ();
	my $script = '';
	foreach my $number (split //, $digits) {
		my $char_info = charinfo(ord($number));
		my ($decimal, $chr_script) = @{$char_info}{qw( decimal script )};
		if ($chr_script eq $script) {
			$numbers[-1] *= 10;
			$numbers[-1] += $decimal;
		}
		else {
			push @numbers, $decimal;
			$script = $chr_script;
		}
	}
	return @numbers;
}

no Moo;

1;

# vim: tabstop=4

