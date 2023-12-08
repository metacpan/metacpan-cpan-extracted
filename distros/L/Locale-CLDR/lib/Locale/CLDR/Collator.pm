package Locale::CLDR::Collator;

use version;
our $VERSION = version->declare('v0.34.4');

use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

#line 6538
use Unicode::Normalize('NFD');
use Unicode::UCD qw( charinfo );
use List::MoreUtils qw(pairwise);
use Moo;
use Types::Standard qw(Str Int Maybe ArrayRef InstanceOf RegexpRef Bool);
with 'Locale::CLDR::CollatorBase';

my $NUMBER_SORT_TOP = "\x{FD00}\x{0034}";
my $LEVEL_SEPARATOR = "\x{0001}";

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

# Note that backwards is only at level 2
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
	default => 'true',
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
	default => chr(0x0397),
);

has _character_rx => (
	is => 'ro',
	isa => RegexpRef,
	lazy => 1,
	init_arg => undef,
	default => sub {
		my $self = shift;
		my $list = join '|', @{$self->multi_rx()}, '.';
		return qr/\G($list)/s;
	},
);

has _in_variable_weigting => (
	is => 'rw',
	isa => Bool,
	init_arg => undef,
	default => 0,
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

# Get the collation element at the current strength
sub get_collation_elements {
	my ($self, $string) = @_;
	my @ce;
	if ($self->numeric eq 'true' && $string =~/^\p{Nd}^/) {
		my $numeric_top = $self->collation_elements()->{$NUMBER_SORT_TOP};
		my @numbers = $self->_convert_digits_to_numbers($string);
		@ce = map { "$numeric_top${LEVEL_SEPARATOR}№$_" } @numbers;
	}
	else {
		my $rx = $self->_character_rx;
		my @characters = $string =~ /$rx/g;
			
		foreach my $character (@characters) {
			my @current_ce;
			if (length $character > 1) {
				# We have a collation element that dependeds on two or more codepoints
				# Remove the code points that the collation element depends on and if 
				# there are still codepoints get the collation elements for them
				my @multi_rx = @{$self->multi_rx};
				my $multi;
				for (my $count = 0; $count < @multi_rx; $count++) {
					if ($character =~ /$multi_rx[$count]/) {
						$multi = $self->multi_class()->[$count];
						last;
					}
				}
				
				my $match = $character;  
				eval "\$match =~ tr/$multi//cd;";
				push @current_ce, $self->collation_elements()->{$match};
				$character =~ s/$multi//g;
				if (length $character) {
					foreach my $codepoint (split //, $character) {
						push @current_ce,
							$self->collation_elements()->{$codepoint}
							// $self->generate_ce($codepoint);
					}
				}
			}
			else {
				my $ce = $self->collation_elements()->{$character};
				$ce //= $self->generate_ce($character);
				push @current_ce, $ce;
			}
			push @ce, $self->_process_variable_weightings(@current_ce);
		}
	}
	return @ce;
}

sub _process_variable_weightings {
	my ($self, @ce) = @_;
	return @ce if $self->alternate() eq 'noignore';
	
	foreach my $ce (@ce) {
		if ($ce->[0] le $self->max_variable) {
			# Variable waighted codepoint
			if ($self->alternate eq 'blanked') {
				@$ce = map { chr() } qw(0 0 0);
				
			}
			if ($self->alternate eq 'shifted') {
				my $l4;
				if ($ce->[0] eq "\0" && $ce->[1] eq "\0" && $ce->[2] eq "\0") {
					$ce->[3] = "\0";
				}
				else {
					$ce->[3] = $ce->[1]; 
				}
				@$ce[0 .. 2] = map { chr() } qw (0 0 0);
			}
			$self->_in_variable_weigting(1);
		}
		else {
			if ($self->_in_variable_weigting()) {
				if( $ce->[0] eq "\0" && $self->alternate eq 'shifted' ) {
					$ce->[3] = "\0";
				}
				elsif($ce->[0] ne "\0") {
					$self->_in_variable_weigting(0);
					if ( $self->alternate eq 'shifted' ) {
						$ce->[3] = chr(0xFFFF)
					}
				}
			}
		}
	}
}

# Converts $string into a sort key. Two sort keys can be correctly sorted by cmp
sub getSortKey {
	my ($self, $string) = @_;

	$string = NFD($string) if $self->normalization eq 'true';

	my @sort_key;
	
	my @ce = $self->get_collation_elements($string);

	for (my $count = 0; $count < $self->strength(); $count++ ) {
		foreach my $ce (@ce) {
			$ce = [ split //, $ce] unless ref $ce;
			if (defined $ce->[$count] && $ce->[$count] ne "\0") {
				push @sort_key, $ce->[$count];
			}
		}
	}
	
	return join "\0", @sort_key;
}

sub generate_ce {
	my ($self, $character) = @_;
	
	my $aaaa;
	my $bbbb;
	
	if ($^V ge v5.26 && eval q($character =~ /(?!\p{Cn})(?:\p{Block=Tangut}|\p{Block=Tangut_Components})/)) {
		$aaaa = 0xFB00;
		$bbbb = (ord($character) - 0x17000) | 0x8000;
	}
	# Block Nushu was added in Perl 5.28
	elsif ($^V ge v5.28 && eval q($character =~ /(?!\p{Cn})\p{Block=Nushu}/)) {
		$aaaa = 0xFB01;
		$bbbb = (ord($character) - 0x1B170) | 0x8000;
	}
	elsif ($character =~ /(?=\p{Unified_Ideograph=True})(?:\p{Block=CJK_Unified_Ideographs}|\p{Block=CJK_Compatibility_Ideographs})/) {
		$aaaa = 0xFB40 + (ord($character) >> 15);
		$bbbb = (ord($character) & 0x7FFFF) | 0x8000;
	}
	elsif ($character =~ /(?=\p{Unified_Ideograph=True})(?!\p{Block=CJK_Unified_Ideographs})(?!\p{Block=CJK_Compatibility_Ideographs})/) {
		$aaaa = 0xFB80 + (ord($character) >> 15);
		$bbbb = (ord($character) & 0x7FFFF) | 0x8000;
	}
	else {
		$aaaa = 0xFBC0 + (ord($character) >> 15);
		$bbbb = (ord($character) & 0x7FFFF) | 0x8000;
	}
	return join '', map {chr($_)} $aaaa, 0x0020, 0x0002, ord($LEVEL_SEPARATOR), $bbbb, 0, 0;
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
