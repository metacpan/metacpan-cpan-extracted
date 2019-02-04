package Locale::CLDR::NumberFormatter;

use version;

our $VERSION = version->declare('v0.34.0');


use v5.10.1;
use mro 'c3';
use utf8;
use if $^V ge v5.12.0, feature => 'unicode_strings';

use Moo::Role;

sub format_number {
	my ($self, $number, $format, $currency, $for_cash) = @_;
	
	# Check if the locales numbering system is algorithmic. If so ignore the format
	my $numbering_system = $self->default_numbering_system();
	if ($self->numbering_system->{$numbering_system}{type} eq 'algorithmic') {
		$format = $self->numbering_system->{$numbering_system}{data};
		return $self->_algorithmic_number_format($number, $format);
	}
	
	$format //= '0';
	
	return $self->_format_number($number, $format, $currency, $for_cash);
}

sub format_currency {
	my ($self, $number, $for_cash) = @_;
	
	my $format = $self->currency_format;
	return $self->format_number($number, $format, undef(), $for_cash);
}

sub _format_number {
	my ($self, $number, $format, $currency, $for_cash) = @_;
	
	# First check to see if this is an algorithmic format
	my @valid_formats = $self->_get_valid_algorithmic_formats();
	
	if (grep {$_ eq $format} @valid_formats) {
		return $self->_algorithmic_number_format($number, $format);
	}
	
	# Some of these algorithmic formats are in locale/type/name format
	if (my ($locale_id, $type, $format) = $format =~ m(^(.*?)/(.*?)/(.*?)$)) {
		my $locale = Locale::CLDR->new($locale_id);
		return $locale->format_number($number, $format);
	}
	
	my $currency_data;
	
	# Check if we need a currency and have not been given one.
	# In that case we look up the default currency for the locale
	if ($format =~ tr/¤/¤/) {
	
		$for_cash //=0;
		
		$currency = $self->default_currency()
			if ! defined $currency;
		
		$currency_data = $self->_get_currency_data($currency);
		
		$currency = $self->currency_symbol($currency);
	}
	
	$format = $self->parse_number_format($format, $currency, $currency_data, $for_cash);
	
	$number = $self->get_formatted_number($number, $format, $currency_data, $for_cash);
	
	return $number;
}

sub add_currency_symbol {
	my ($self, $format, $symbol) = @_;
	
	
	$format =~ s/¤/'$symbol'/g;
	
	return $format;
}

sub _get_currency_data {
	my ($self, $currency) = @_;
	
	my $currency_data = $self->currency_fractions($currency);
	
	return $currency_data;
}

sub _get_currency_rounding {

	my ($self, $currency_data, $for_cash) = @_;
	
	my $rounder = $for_cash ? 'cashrounding' : 'rounding' ;
	
	return $currency_data->{$rounder};
}

sub _get_currency_digits {
	my ($self, $currency_data, $for_cash) = @_;
	
	my $digits = $for_cash ? 'cashdigits' : 'digits' ;
	
	return $currency_data->{$digits};
}

sub parse_number_format {
	my ($self, $format, $currency, $currency_data, $for_cash) = @_;

	use feature 'state';
	
	state %cache;
	
	return $cache{$format} if exists $cache{$format};
	
	$format = $self->add_currency_symbol($format, $currency)
		if defined $currency;
	
	my ($positive, $negative) = $format =~ /^( (?: (?: ' [^']* ' )*+ | [^';]+ )+ ) (?: ; (.+) )? $/x;
	
	$negative //= "-$positive";
	
	my $type = 'positive';
	foreach my $to_parse ( $positive, $negative ) {
		my ($prefix, $suffix);
		if (($prefix) = $to_parse =~ /^ ( (?: [^0-9@#.,E'*] | (?: ' [^']* ' )++ )+ ) /x) {
			$to_parse =~ s/^ ( (?: [^0-9@#.,E'*] | (?: ' [^']* ' )++ )+ ) //x;
		}
		if( ($suffix) = $to_parse =~ / ( (?: [^0-9@#.,E'] | (?: ' [^']* ' )++ )+ ) $ /x) {
			$to_parse =~ s/( (?:[^0-9@#.,E'] | (?: ' [^']* ' )++ )+ ) $//x;
		}
		
		# Fix escaped ', - and +
		foreach my $str ($prefix, $suffix) {
			$str //= '';
			$str =~ s/(?: ' (?: (?: '' )++ | [^']+ ) ' )*? \K ( [-+\\] ) /\\$1/gx;
			$str =~ s/ ' ( (?: '' )++ | [^']++ ) ' /$1/gx;
			$str =~ s/''/'/g;
		}
		
		# Look for padding
		my ($pad_character, $pad_location);
		if (($pad_character) = $prefix =~ /^\*(\p{Any})/ ) {
			$prefix =~ s/^\*(\p{Any})//;
			$pad_location = 'before prefix';
		}
		elsif ( ($pad_character) = $prefix =~ /\*(\p{Any})$/ ) {
			$prefix =~ s/\*(\p{Any})$//;
			$pad_location = 'after prefix';
		}
		elsif (($pad_character) = $suffix =~ /^\*(\p{Any})/ ) {
			$suffix =~ s/^\*(\p{Any})//;
			$pad_location = 'before suffix';
		}
		elsif (($pad_character) = $suffix =~ /\*(\p{Any})$/ ) {
			$suffix =~ s/\*(\p{Any})$//;
			$pad_location = 'after suffix';
		}
		
		my $pad_length = defined $pad_character 
			? length($prefix) + length($to_parse) + length($suffix) + 2
			: 0;
		
		# Check for a multiplier
		my $multiplier = 1;
		$multiplier = 100  if $prefix =~ tr/%/%/ || $suffix =~ tr/%/%/;
		$multiplier = 1000 if $prefix =~ tr/‰/‰/ || $suffix =~ tr/‰/‰/;
		
		my $rounding = $to_parse =~ / ( [1-9] [0-9]* (?: \. [0-9]+ )? ) /x;
		$rounding ||= 0;
		
		$rounding = $self->_get_currency_rounding($currency_data, $for_cash)
			if defined $currency;
		
		my ($integer, $decimal) = split /\./, $to_parse;
		
		my ($minimum_significant_digits, $maximum_significant_digits, $minimum_digits);
		if (my ($digits) = $to_parse =~ /(\@+)/) { 
			$minimum_significant_digits = length $digits;
			($digits ) = $to_parse =~ /\@(#+)/;
			$maximum_significant_digits = $minimum_significant_digits + length ($digits // '');
		}
		else {
			$minimum_digits = $integer =~ tr/0-9/0-9/;
		}
		
		# Check for exponent
		my $exponent_digits = 0;
		my $need_plus = 0;
		my $exponent;
		my $major_group;
		my $minor_group;
		if ($to_parse =~ tr/E/E/) {
			($need_plus, $exponent) = $to_parse  =~ m/ E ( \+? ) ( [0-9]+ ) /x;
			$exponent_digits = length $exponent;
		}
		else {
			# Check for grouping
			my ($grouping) = split /\./, $to_parse;
			my @groups = split /,/, $grouping;
			shift @groups;
			($major_group, $minor_group) = map {length} @groups;
			$minor_group //= $major_group;
		}
		
		$cache{$format}{$type} = {
			prefix 						=> $prefix // '',
			suffix 						=> $suffix // '',
			pad_character 				=> $pad_character,
			pad_location				=> $pad_location // 'none',
			pad_length					=> $pad_length,
			multiplier					=> $multiplier,
			rounding					=> $rounding,
			minimum_significant_digits	=> $minimum_significant_digits, 
			maximum_significant_digits	=> $maximum_significant_digits,
			minimum_digits				=> $minimum_digits // 0,
			exponent_digits				=> $exponent_digits,
			exponent_needs_plus			=> $need_plus,
			major_group					=> $major_group,
			minor_group					=> $minor_group,
		};
		
		$type = 'negative';
	}
	
	return $cache{$format};
}

# Rounding function
sub round {
	my ($self, $number, $increment, $decimal_digits) = @_;

	if ($increment ) {
		$number /= $increment;
		$number = int ($number + .5 );
		$number *= $increment;
	}
	
	if ( $decimal_digits ) {
		$number *= 10 ** $decimal_digits;
		$number = int $number;
		$number /= 10 ** $decimal_digits;
		
		my ($decimal) = $number =~ /(\..*)/; 
		$decimal //= '.'; # No fraction so add a decimal point
		
		$number = int ($number) . $decimal . ('0' x ( $decimal_digits - length( $decimal ) +1 ));
	}
	else {
		# No decimal digits wanted
		$number = int $number;
	}
	
	return $number;
}

sub get_formatted_number {
	my ($self, $number, $format, $currency_data, $for_cash) = @_;
	
	my @digits = $self->get_digits;
	my @number_symbols_bundles = reverse $self->_find_bundle('number_symbols');
	my %symbols;
	foreach my $bundle (@number_symbols_bundles) {
		my $current_symbols = $bundle->number_symbols;
		foreach my $type (keys %$current_symbols) {
			foreach my $symbol (keys %{$current_symbols->{$type}}) {
				$symbols{$type}{$symbol} = $current_symbols->{$type}{$symbol};
			}
		}
	}
	
	my $symbols_type = $self->default_numbering_system;
	
	$symbols_type = $symbols{$symbols_type}{alias} if exists $symbols{$symbols_type}{alias};
	
	my $type = $number=~ s/^-// ? 'negative' : 'positive';
	
	$number *= $format->{$type}{multiplier};
	
	if ($format->{rounding} || defined $for_cash) {
		my $decimal_digits = 0;
		
		if (defined $for_cash) {
			$decimal_digits = $self->_get_currency_digits($currency_data, $for_cash)
		}
		
		$number = $self->round($number, $format->{$type}{rounding}, $decimal_digits);
	}
	
	my $pad_zero = $format->{$type}{minimum_digits} - length "$number";
	if ($pad_zero > 0) {
		$number = ('0' x $pad_zero) . $number;
	}
	
	# Handle grouping
	my ($integer, $decimal) = split /\./, $number;

	my $minimum_grouping_digits = $self->_find_bundle('minimum_grouping_digits');
	$minimum_grouping_digits = $minimum_grouping_digits
		? $minimum_grouping_digits->minimum_grouping_digits()
		: 0;
	
	my ($separator, $decimal_point) = ($symbols{$symbols_type}{group}, $symbols{$symbols_type}{decimal});
	if (($minimum_grouping_digits && length $integer >= $minimum_grouping_digits) || ! $minimum_grouping_digits) {
		my ($minor_group, $major_group) = ($format->{$type}{minor_group}, $format->{$type}{major_group});
	
		if (defined $minor_group && $separator) {
			# Fast commify using unpack
			my $pattern = "(A$minor_group)(A$major_group)*";
			$number = reverse join $separator, grep {length} unpack $pattern, reverse $integer;
		}
		else {
			$number = $integer;
		}
	}
	else {
		$number = $integer;
	}
	
	$number.= "$decimal_point$decimal" if defined $decimal;
	
	# Fix digits
	$number =~ s/([0-9])/$digits[$1]/eg;
		
	my ($prefix, $suffix) = ( $format->{$type}{prefix}, $format->{$type}{suffix});
	
	# This needs fixing for escaped symbols
	foreach my $string ($prefix, $suffix) {
		$string =~ s/%/$symbols{$symbols_type}{percentSign}/;
		$string =~ s/‰/$symbols{$symbols_type}{perMille}/;
		if ($type eq 'negative') {
			$string =~ s/(?: \\ \\ )*+ \K \\ - /$symbols{$symbols_type}{minusSign}/x;
			$string =~ s/(?: \\ \\)*+ \K \\ + /$symbols{$symbols_type}{minusSign}/x;
		}
		else {
			$string =~ s/(?: \\ \\ )*+ \K \\ - //x;
			$string =~ s/(?: \\ \\ )*+ \K \\ + /$symbols{$symbols_type}{plusSign}/x;
		}
		$string =~ s/ \\ \\ /\\/gx;
	}
	
	$number = $prefix . $number . $suffix;
	
	return $number;
}

# Get the digits for the locale. Assumes a numeric numbering system
sub get_digits {
	my $self = shift;
	
	my $numbering_system = $self->default_numbering_system();
	
	$numbering_system = 'latn' unless  $self->numbering_system->{$numbering_system}{type} eq 'numeric'; # Fall back to latn if the numbering system is not numeric
	
	my $digits = $self->numbering_system->{$numbering_system}{data};
	
	return @$digits;
}

# RBNF
# Note that there are a couple of assumptions with the way
# I handle Rule Base Number Formats.
# 1) The number is treated as a string for as long as possible
#	This allows things like -0.0 to be correctly formatted
# 2) There is no fall back. All the rule sets are self contained
#	in a bundle. Fall back is used to find a bundle but once a 
#	bundle is found no further processing of the bundle chain
#	is done. This was found by trial and error when attempting 
#	to process -0.0 correctly into English.
sub _get_valid_algorithmic_formats {
	my $self = shift;
	
	my @formats = map { @{$_->valid_algorithmic_formats()} } $self->_find_bundle('valid_algorithmic_formats');
	
	my %seen;
	return sort grep { ! $seen{$_}++ } @formats;
}

# Main entry point to RBNF
sub _algorithmic_number_format {
	my ($self, $number, $format_name, $type) = @_;
	
	my $format_data = $self->_get_algorithmic_number_format_data_by_name($format_name, $type);
	
	return $number unless $format_data;
	
	return $self->_process_algorithmic_number_data($number, $format_data);
}

sub _get_algorithmic_number_format_data_by_name {
	my ($self, $format_name, $type) = @_;
	
	# Some of these algorithmic formats are in locale/type/name format
	if (my ($locale_id, undef, $format) = $format_name =~ m(^(.*?)/(.*?)/(.*?)$)) {
		my $locale = Locale::CLDR->new($locale_id);
		return $locale->_get_algorithmic_number_format_data_by_name($format, $type)
			if $locale;

		return undef;
	}
	
	$type //= 'public';
	
	my %data = ();
	
	my @data_bundles = $self->_find_bundle('algorithmic_number_format_data');
	foreach my $data_bundle (@data_bundles) {
		my $data = $data_bundle->algorithmic_number_format_data();
		next unless $data->{$format_name};
		next unless $data->{$format_name}{$type};
		
		foreach my $rule (keys %{$data->{$format_name}{$type}}) {
			$data{$rule} = $data->{$format_name}{$type}{$rule};
		}
		
		last;
	}
	
	return keys %data ? \%data : undef;
}

sub _get_plural_form {
	my ($self, $plural, $from) = @_;
	
	my ($result) = $from =~ /$plural\{(.+?)\}/;
	($result) = $from =~ /other\{(.+?)\}/ unless defined $result;
	
	return $result;
}

sub _process_algorithmic_number_data {
	my ($self, $number, $format_data, $plural, $in_fraction_rule_set) = @_;
	
	$in_fraction_rule_set //= 0;
	
	my $format = $self->_get_algorithmic_number_format($number, $format_data);
	
	my $format_rule = $format->{rule};
	if (! $plural && $format_rule =~ /(cardinal|ordinal)/) {
		my $type = $1;
		$plural = $self->plural($number, $type);
		$plural = [$type, $plural];
	}
	
	# Sort out plural forms
	if ($plural) {
		$format_rule =~ s/\$\($plural->[0],(.+)\)\$/$self->_get_plural_form($plural->[1],$1)/eg;
	}
	
	my $divisor = $format->{divisor};
	my $base_value = $format->{base_value} // '';
	
	# Negative numbers
	if ($number =~ /^-/) {
		my $positive_number = $number;
		$positive_number =~ s/^-//;
		
		if ($format_rule =~ /→→/) {
			$format_rule =~ s/→→/$self->_process_algorithmic_number_data($positive_number, $format_data, $plural)/e;
		}
		elsif((my $rule_name) = $format_rule =~ /→(.+)→/) {
			my $type = 'public';
			if ($rule_name =~ s/^%%/%/) {
				$type = 'private';
			}
			my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
			if($format_data) {
				# was a valid name
				$format_rule =~ s/→(.+)→/$self->_process_algorithmic_number_data($positive_number, $format_data, $plural)/e;
			}
			else {
				# Assume a format
				$format_rule =~ s/→(.+)→/$self->_format_number($positive_number, $1)/e;
			}
		}
		elsif($format_rule =~ /=%%.*=/) {
			$format_rule =~ s/=%%(.*?)=/$self->_algorithmic_number_format($number, $1, 'private')/eg;
		}
		elsif($format_rule =~ /=%.*=/) {
			$format_rule =~ s/=%(.*?)=/$self->_algorithmic_number_format($number, $1, 'public')/eg;
		}
		elsif($format_rule =~ /=.*=/) {
			$format_rule =~ s/=(.*?)=/$self->_format_number($number, $1)/eg;
		}
	}
	# Fractions
	elsif( $number =~ /\./ ) {
		my $in_fraction_rule_set = 1;
		my ($integer, $fraction) = $number =~ /^([^.]*)\.(.*)$/;
		
		if ($number >= 0 && $number < 1) {
			$format_rule =~ s/\[.*\]//;
		}
		else {
			$format_rule =~ s/[\[\]]//g;
		}
		
		if ($format_rule =~ /→→/) {
			$format_rule =~ s/→→/$self->_process_algorithmic_number_data_fractions($fraction, $format_data, $plural)/e;
		}
		elsif((my $rule_name) = $format_rule =~ /→(.*)→/) {
			my $type = 'public';
			if ($rule_name =~ s/^%%/%/) {
				$type = 'private';
			}
			my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
			if ($format_data) {
				$format_rule =~ s/→(.*)→/$self->_process_algorithmic_number_data_fractions($fraction, $format_data, $plural)/e;
			}
			else {
				$format_rule =~ s/→(.*)→/$self->_format_number($fraction, $1)/e;
			}
		}
		
		if ($format_rule =~ /←←/) {
			$format_rule =~ s/←←/$self->_process_algorithmic_number_data($integer, $format_data, $plural, $in_fraction_rule_set)/e;
		}
		elsif((my $rule_name) = $format_rule =~ /←(.+)←/) {
			my $type = 'public';
			if ($rule_name =~ s/^%%/%/) {
				$type = 'private';
			}
			my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
			if ($format_data) {
				$format_rule =~ s/←(.*)←/$self->_process_algorithmic_number_data($integer, $format_data, $plural, $in_fraction_rule_set)/e;
			}
			else {
				$format_rule =~ s/←(.*)←/$self->_format_number($integer, $1)/e;
			}
		}
		
		if($format_rule =~ /=.*=/) {
			if($format_rule =~ /=%%.*=/) {
				$format_rule =~ s/=%%(.*?)=/$self->_algorithmic_number_format($number, $1, 'private')/eg;
			}
			elsif($format_rule =~ /=%.*=/) {
				$format_rule =~ s/=%(.*?)=/$self->_algorithmic_number_format($number, $1, 'public')/eg;
			}
			else {
				$format_rule =~ s/=(.*?)=/$self->_format_number($integer, $1)/eg;
			}
		}
	}
	
	# Everything else
	else {
		# At this stage we have a non negative integer
		if ($format_rule =~ /\[.*\]/) {
			if ($in_fraction_rule_set && $number * $base_value == 1) {
				$format_rule =~ s/\[.*\]//;
			}
			# Not fractional rule set      Number is a multiple of $divisor and the multiple is even
			elsif (! $in_fraction_rule_set && ! ($number % $divisor) ) {
				$format_rule =~ s/\[.*\]//;
			}
			else {
				$format_rule =~ s/[\[\]]//g;
			}
		}
		
		if ($in_fraction_rule_set) {
			if (my ($rule_name) = $format_rule =~ /←(.*)←/) {
				if (length $rule_name) {
					my $type = 'public';
					if ($rule_name =~ s/^%%/%/) {
						$type = 'private';
					}
					my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
					if ($format_data) {
						$format_rule =~ s/←(.*)←/$self->_process_algorithmic_number_data($number * $base_value, $format_data, $plural, $in_fraction_rule_set)/e;
					}
					else {
						$format_rule =~ s/←(.*)←/$self->_format_number($number * $base_value, $1)/e;
					}
				}
				else {
					$format_rule =~ s/←←/$self->_process_algorithmic_number_data($number * $base_value, $format_data, $plural, $in_fraction_rule_set)/e;
				}
			}
			elsif($format_rule =~ /=.*=/) {
				$format_rule =~ s/=(.*?)=/$self->_format_number($number, $1)/eg;
			}
		}
		else {
			if (my ($rule_name) = $format_rule =~ /→(.*)→/) {
				if (length $rule_name) {
					my $type = 'public';
					if ($rule_name =~ s/^%%/%/) {
						$type = 'private';
					}
					my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
					if ($format_data) {
						$format_rule =~ s/→(.+)→/$self->_process_algorithmic_number_data($number % $divisor, $format_data, $plural)/e;
					}
					else {
						$format_rule =~ s/→(.*)→/$self->_format_number($number % $divisor, $1)/e;
					}
				}
				else {
					$format_rule =~ s/→→/$self->_process_algorithmic_number_data($number % $divisor, $format_data, $plural)/e;
				}
			}
			
			if (my ($rule_name) = $format_rule =~ /←(.*)←/) {
				if (length $rule_name) {
					my $type = 'public';
					if ($rule_name =~ s/^%%/%/) {
						$type = 'private';
					}
					my $format_data = $self->_get_algorithmic_number_format_data_by_name($rule_name, $type);
					if ($format_data) {
						$format_rule =~ s|←(.*)←|$self->_process_algorithmic_number_data(int ($number / $divisor), $format_data, $plural)|e;
					}
					else {
						$format_rule =~ s|←(.*)←|$self->_format_number(int($number / $divisor), $1)|e;
					}
				}
				else {
					$format_rule =~ s|←←|$self->_process_algorithmic_number_data(int($number / $divisor), $format_data, $plural)|e;
				}
			}
			
			if($format_rule =~ /=.*=/) {
				if($format_rule =~ /=%%.*=/) {
					$format_rule =~ s/=%%(.*?)=/$self->_algorithmic_number_format($number, $1, 'private')/eg;
				}
				elsif($format_rule =~ /=%.*=/) {
					$format_rule =~ s/=%(.*?)=/$self->_algorithmic_number_format($number, $1, 'public')/eg;
				}
				else {
					$format_rule =~ s/=(.*?)=/$self->_format_number($number, $1)/eg;
				}
			}
		}
	}	
	
	return $format_rule;
}

sub _process_algorithmic_number_data_fractions {
	my ($self, $fraction, $format_data, $plural) = @_;
	
	my $result = '';
	foreach my $digit (split //, $fraction) {
		$result .= $self->_process_algorithmic_number_data($digit, $format_data, $plural, 1);
	}
	
	return $result;
}

sub _get_algorithmic_number_format {
	my ($self, $number, $format_data) = @_;
	
	use bignum;
	return $format_data->{'-x'} if $number =~ /^-/ && exists $format_data->{'-x'};
	return $format_data->{'x.x'} if $number =~ /\./ && exists $format_data->{'x.x'};
	return $format_data->{0} if $number == 0 || $number =~ /^-/;
	return $format_data->{max} if $number >= $format_data->{max}{base_value};
	
	my $previous = 0;
	foreach my $key (sort { $a <=> $b } grep /^[0-9]+$/, keys %$format_data) {
		next if $key == 0;
		return $format_data->{$key} if $number == $key;
		return $format_data->{$previous} if $number < $key;
		$previous = $key;
	}
}

no Moo::Role;

1;

# vim: tabstop=4
