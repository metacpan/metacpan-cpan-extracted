#!/usr/bin/env perl

use strict;
use warnings;

use utf8;
use open qw(:std :encoding(UTF-8));	# https://github.com/nigelhorne/App-Test-Generator/issues/1

use Data::Dumper;
use Data::Random qw(:all);
use Test::Most;
use Test::Returns 0.02;
use JSON::MaybeXS;

BEGIN { use_ok('Genealogy::Obituary::Parser') }

diag("Genealogy::Obituary::Parser->parse_obituary test case created by https://github.com/nigelhorne/App-Test-Generator");

# Edge-case maps injected from config (optional)
my %edge_cases = (

);
my @edge_case_array = (

);
my %type_edge_cases = (

);
my %config = (
'dedup' => 1,
'test_nuls' => 1,
'test_undef' => 1,

);

# Seed for reproducible fuzzing (if provided)


my %input = (
	'geocoder' => { can => 'geocode', optional => 1, type => 'object' },
	'text' => { max => 10000, min => 1, type => 'string' }
);

my %output = (
	
);

# Candidates for regex comparisons
my @candidate_good = ('123', 'abc', 'A1B2', '0');
my @candidate_bad = (
	'',	# empty
	# undef,	# undefined
	# "\0",	# null byte
	"😊",	# emoji
	"１２３",	# full-width digits
	"١٢٣",	# Arabic digits
	'..',	# regex metachars
	"a\nb",	# newline in middle
	'x' x 5000,	# huge string
);

# --- Fuzzer helpers ---
sub _pick_from {
	my $arrayref = $_[0];
	return undef unless $arrayref && ref $arrayref eq 'ARRAY' && @$arrayref;
	return $arrayref->[ int(rand(scalar @$arrayref)) ];
}

sub rand_ascii_str {
	my $len = shift || int(rand(10)) + 1;
	join '', map { chr(97 + int(rand(26))) } 1..$len;
}

my @unicode_codepoints = (
    0x00A9,        # ©
    0x00AE,        # ®
    0x03A9,        # Ω
    0x20AC,        # €
    0x2013,        # – (en-dash)
    0x0301,        # combining acute accent
    0x0308,        # combining diaeresis
    0x1F600,       # 😀 (emoji)
    0x1F62E,       # 😮
    0x1F4A9,       # 💩 (yes)
);

sub rand_unicode_char {
	my $cp = $unicode_codepoints[ int(rand(@unicode_codepoints)) ];
	return chr($cp);
}

# Generate a string: mostly ASCII, sometimes unicode, sometimes nul bytes or combining marks
sub rand_str {
	my $len = shift || int(rand(10)) + 1;

	my @chars;
	for (1..$len) {
		my $r = rand();
		if ($r < 0.72) {
			push @chars, chr(97 + int(rand(26)));          # a-z
		} elsif ($r < 0.88) {
			push @chars, chr(65 + int(rand(26)));          # A-Z
		} elsif ($r < 0.95) {
			push @chars, chr(48 + int(rand(10)));          # 0-9
		} elsif ($r < 0.975) {
			push @chars, rand_unicode_char();              # occasional emoji/marks
		} elsif($config{'test_nuls'}) {
			push @chars, chr(0);                           # nul byte injection
		} else {
			push @chars, chr(97 + int(rand(26)));          # a-z
		}
	}
	# Occasionally prepend/append a combining mark to produce combining sequences
	if (rand() < 0.08) {
		unshift @chars, chr(0x0301);
	}
	if (rand() < 0.08) {
		push @chars, chr(0x0308);
	}
	return join('', @chars);
}

# Random character either upper or lower case
sub rand_char
{
	return rand_chars(set => 'all', min => 1, max => 1);

	# my $char = '';
	# my $upper_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	# my $lower_chars = 'abcdefghijklmnopqrstuvwxyz';
	# my $combined_chars = $upper_chars . $lower_chars;

	# # Generate a random index between 0 and the length of the string minus 1
	# my $rand_index = int(rand(length($combined_chars)));

	# # Get the character at that index
	# return substr($combined_chars, $rand_index, 1);
}

# Integer generator: mix typical small ints with large limits
sub rand_int {
	my $r = rand();
	if ($r < 0.75) {
		return int(rand(200)) - 100;	# -100 .. 100 (usual)
	} elsif ($r < 0.9) {
		return int(rand(2**31)) - 2**30;	# 32-bit-ish
	} elsif ($r < 0.98) {
		return (int(rand(2**63)) - 2**62);	# 64-bit-ish
	} else {
		# very large/suspicious values
		return 2**63 - 1;
	}
}
sub rand_bool { rand() > 0.5 ? 1 : 0 }

# Number generator (floating), includes tiny/huge floats
sub rand_num {
	my $r = rand();
	if ($r < 0.7) {
		return (rand() * 200 - 100);	# -100 .. 100
	} elsif ($r < 0.9) {
		return (rand() * 1e12) - 5e11;             # large-ish
	} elsif ($r < 0.98) {
		return (rand() * 1e308) - 5e307;      # very large floats
	} else {
		return 1e-308 * (rand() * 1000);	# tiny float, subnormal-like
	}
}

sub rand_arrayref {
	my $len = shift || int(rand(3)) + 1; # small arrays
	[ map { rand_str() } 1..$len ];
}

sub rand_hashref {
	my $len = shift || int(rand(3)) + 1; # small hashes
	my %h;
	for (1..$len) {
		$h{rand_str(3)} = rand_str(5);
	}
	return \%h;
}

sub fuzz_inputs {
	my @cases;

	# Are any options manadatory?
	my $all_optional = 1;
	my %mandatory_strings;	# List of mandatory strings to be added to all tests, always put at start so it can be overwritten
	my %mandatory_objects = ();
	my $class_simple_loaded;
	foreach my $field (keys %input) {
		my $spec = $input{$field} || {};
		if((ref($spec) eq 'HASH') && (!$spec->{optional})) {
			$all_optional = 0;
			if($spec->{'type'} eq 'string') {
				local $config{'test_undef'} = 0;
				local $config{'test_nuls'} = 0;
				$mandatory_strings{$field} = rand_str();
				$mandatory_strings{$field} = rand_ascii_str();
			} elsif($spec->{'type'} eq 'object') {
				my $method = $spec->{'can'};
				if(!$class_simple_loaded) {
					require_ok('Class::Simple');
					eval {
						Class::Simple->import();
						$class_simple_loaded = 1;
					};
				}
				my $obj = new_ok('Class::Simple');
				$obj->$method(1);
				$mandatory_objects{$field} = $obj;
				$config{'dedup'} = 0;	# FIXME:  Can't yet dedup with class method calls
			} else {
				die 'TODO: type = ', $spec->{'type'};
			}
		}
	}

	if(($all_optional) || ((scalar keys %input) > 1)) {
		# Basic test cases
		if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
			# our %input = ( type => 'string' );
			my $type = $input{'type'};
			if ($type eq 'string') {
				# Is hello allowed?
				if(!defined($input{'memberof'}) || (grep { $_ eq 'hello' } @{$input{'memberof'}})) {
					push @cases, { _input => 'hello' };
				} elsif(defined($input{'memberof'}) && !defined($input{'max'})) {
					# Data::Random
					push @cases, { _input => rand_set(set => $input{'memberof'}, size => 1) }
				} else {
					if((!defined($input{'min'})) || ($input{'min'} >= 1)) {
						push @cases, { _input => '0' } if(!defined($input{'memberof'}));
					}
					push @cases, { _input => 'hello', _STATUS => 'DIES' };
				}
				push @cases, { _input => '' } if((!exists($input{'min'})) || ($input{'min'} == 0));
				# push @cases, { $field => "emoji \x{1F600}" };
				push @cases, { _input => "\0null" } if($config{'test_nuls'});
			} else {
				die 'TODO';
			}
		} else {
			# our %input = ( str => { type => 'string' } );
			foreach my $field (keys %input) {
				my $spec = $input{$field} || {};
				my $type = lc((!ref($spec)) ? $spec : $spec->{type}) || 'string';

				# --- Type-based seeds ---
				if ($type eq 'number') {
					push @cases, { $field => 0 };
					push @cases, { $field => 1.23 };
					push @cases, { $field => -42 };
					push @cases, { $field => 'abc', _STATUS => 'DIES' };
				}
				elsif ($type eq 'integer') {
					push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 42 ) };
					if((!defined $spec->{min}) || ($spec->{min} <= -1)) {
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => -1, _LINE => __LINE__ ) };
					}
					push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 3.14, _STATUS => 'DIES' ) };
					push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'xyz', _STATUS => 'DIES' ) };
					# --- min/max numeric boundaries ---
					# Probably duplicated below, but here as well just in case
					if (defined $spec->{min}) {
						my $min = $spec->{min};
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $min - 1, _STATUS => 'DIES' ) };
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $min ) };
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $min + 1 ) };
					}
					if (defined $spec->{max}) {
						my $max = $spec->{max};
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $max - 1 ) };
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $max ) };
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $max + 1, _STATUS => 'DIES' ) };
					}

				} elsif ($type eq 'string') {
					# Is hello allowed?
					if(my $re = $spec->{matches}) {
						if(ref($re) ne 'Regexp') {
							$re = qr/$re/;
						}
						if('hello' =~ $re) {
							if(!defined($spec->{'memberof'}) || (grep { $_ eq 'hello' } @{$spec->{'memberof'}})) {
								push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'hello' ) };
							} elsif(defined($spec->{'memberof'}) && !defined($spec->{'max'})) {
								# Data::Random
								push @cases, { %mandatory_strings, %mandatory_objects, ( _input => rand_set(set => $spec->{'memberof'}, size => 1) ) }
							} else {
								push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'hello', _STATUS => 'DIES' ) };
							}
						} else {
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'hello', _STATUS => 'DIES' ) };
						}
					} else {
						if(!defined($spec->{'memberof'}) || (grep { $_ eq 'hello' } @{$spec->{'memberof'}})) {
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'hello' ) };
						} else {
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'hello', _LINE => __LINE__, _STATUS => 'DIES' ) };
						}
					}
					if((!exists($spec->{min})) || ($spec->{min} == 0)) {
						# '' should die unless it's in the memberof list
						if(defined($spec->{'memberof'}) && (!grep { $_ eq '' } @{$spec->{'memberof'}})) {
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => '', _name => $field, _STATUS => 'DIES' ) }
						} elsif(defined($spec->{'memberof'}) && !defined($spec->{'max'})) {
							# Data::Random
							push @cases, { %mandatory_strings, %mandatory_objects, _input => rand_set(set => $spec->{'memberof'}, size => 1) }
						} else {
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => '', _name => $field ) } if((!exists($spec->{min})) || ($spec->{min} == 0));
						}
					}
					# push @cases, { $field => "emoji \x{1F600}" };
					push @cases, { %mandatory_strings, %mandatory_objects, ( $field => "\0null" ) } if($config{'test_nuls'} && (!(defined $spec->{memberof})) && !defined($spec->{matches}));

					unless(defined($spec->{memberof}) || defined($spec->{matches})) {
						# --- min/max string/array boundaries ---
						if (defined $spec->{min}) {
							my $len = $spec->{min};
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x ($len - 1), _STATUS => 'DIES' ) } if($len > 0);
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x $len ) };
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x ($len + 1) ) };
						}
						if (defined $spec->{max}) {
							my $len = $spec->{max};
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x ($len - 1) ) };
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x $len ) };
							push @cases, { %mandatory_strings, %mandatory_objects, ( $field => 'a' x ($len + 1), _STATUS => 'DIES' ) };
						}
					}
				}
				elsif ($type eq 'boolean') {
					push @cases, { %mandatory_objects, ( $field => 0 ) };
					push @cases, { %mandatory_objects, ( $field => 1 ) };
					push @cases, { %mandatory_objects, ( $field => 'true' ) };
					push @cases, { %mandatory_objects, ( $field => 'false' ) };
					push @cases, { %mandatory_objects, ( $field => 'off' ) };
					push @cases, { %mandatory_objects, ( $field => 'on' ) };
					push @cases, { %mandatory_objects, ( $field => 'bletch', _STATUS => 'DIES' ) };
				}
				elsif ($type eq 'hashref') {
					push @cases, { $field => { a => 1 } };
					push @cases, { $field => [], _STATUS => 'DIES' };
				}
				elsif ($type eq 'arrayref') {
					push @cases, { $field => [1,2] };
					push @cases, { $field => { a => 1 }, _STATUS => 'DIES' };
				}

				# --- matches (regex) ---
				if (defined $spec->{matches}) {
					my $regex = $spec->{matches};
					push @cases, { $field => 'match123' } if 'match123' =~ $regex;
					push @cases, { $field => 'nope', _STATUS => 'DIES' } unless 'nope' =~ $regex;
				}

				# --- nomatch (regex) ---
				if (defined $spec->{nomatch}) {
					my $regex = $spec->{nomatch};
					push @cases, { $field => 'match123' } if "match123" !~ $regex;
					push @cases, { $field => 'nope', _STATUS => 'DIES' } unless 'nope' !~ $regex;
				}

				# --- memberof ---
				if (defined $spec->{memberof}) {
					my @set = @{ $spec->{memberof} };
					push @cases, { %mandatory_strings, ( $field => $set[0] ) } if @set;
					push @cases, { %mandatory_strings, ( $field => 'not_in_set', _STATUS => 'DIES' ) };
				}
			}
		}
	}

	# Optional deduplication
	# my %seen;
	# @cases = grep { !$seen{join '|', %$_}++ } @cases;

	# Random data test cases
	if(scalar keys %input) {
		if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
			# our %input = ( type => 'string' );
			my $type = $input{'type'};
			for (1..50) {
				my $case_input;
				if (@edge_case_array && rand() < 0.4) {
					# Sometimes pick a field-specific edge-case
					$case_input = _pick_from(\@edge_case_array);
				} elsif(exists $type_edge_cases{$type} && rand() < 0.3) {
					# Sometimes pick a type-level edge-case
					$case_input = _pick_from($type_edge_cases{$type});
				} elsif($type eq 'string') {
					unless($input{matches}) {	# TODO: Make a random string to match a regex
						$case_input = rand_str();
					}
				} elsif($type eq 'integer') {
					$case_input = rand_int() + $input{'min'};
				} elsif(($type eq 'number') || ($type eq 'float')) {
					$case_input = rand_num();
				} elsif($type eq 'boolean') {
					$case_input = rand_bool();
				} else {
					die 'TODO';
				}
				push @cases, { _input => $case_input, status => 'OK' } if($case_input);
			}
		} else {
			# our %input = ( str => { type => 'string' } );
			for (1..50) {
				my %case_input = (%mandatory_strings, %mandatory_objects);
				foreach my $field (keys %input) {
					my $spec = $input{$field} || {};
					next if $spec->{'memberof'};	# Memberof data is created below
					my $type = $spec->{type} || 'string';

					# 1) Sometimes pick a field-specific edge-case
					if (exists $edge_cases{$field} && rand() < 0.4) {
						$case_input{$field} = _pick_from($edge_cases{$field});
						next;
					}

					# 2) Sometimes pick a type-level edge-case
					if (exists $type_edge_cases{$type} && rand() < 0.3) {
						$case_input{$field} = _pick_from($type_edge_cases{$type});
						next;
					}

					# 3) Sormal random generation by type
					if ($type eq 'string') {
						unless($spec->{matches}) {	# TODO: Make a random string to match a regex
							if(my $min = $spec->{min}) {
								$case_input{$field} = rand_str($min);
							} else {
								$case_input{$field} = rand_str();
							}
						}
					} elsif ($type eq 'integer') {
						if(my $min = $spec->{min}) {
							if(my $max = $spec->{'max'}) {
								$case_input{$field} = int(rand($max - $min + 1)) + $min;
							} else {
								$case_input{$field} = rand_int() + $min;
							}
						} elsif(exists($spec->{min})) {
							# min == 0
							if(my $max = $spec->{'max'}) {
								$case_input{$field} = int(rand($max + 1));
							} else {
								$case_input{$field} = abs(rand_int());
							}
						} else {
							$case_input{$field} = rand_int();
						}
					}
					elsif ($type eq 'boolean') {
						$case_input{$field} = rand_bool();
					}
					elsif ($type eq 'number') {
						if(my $min = $spec->{min}) {
							$case_input{$field} = rand_num() + $min;
						} else {
							$case_input{$field} = rand_num();
						}
					}
					elsif ($type eq 'arrayref') {
						$case_input{$field} = rand_arrayref();
					}
					elsif ($type eq 'hashref') {
						$case_input{$field} = rand_hashref();
					} elsif($config{'test_undef'}) {
						$case_input{$field} = undef;
					}

					# 4) occasionally drop optional fields
					if ($spec->{optional} && rand() < 0.25) {
						delete $case_input{$field};
					}
				}
				push @cases, { _input => \%case_input, status => 'OK' } if(keys %case_input);
			}
		}
	}

	# edge-cases
	if($all_optional) {
		push @cases, {} if($config{'test_undef'});
	} else {
		# Note that this is set on the input rather than output
		push @cases, { '_STATUS' => 'DIES' };	# At least one argument is needed
	}

	if(scalar keys %input) {
		push @cases, { '_STATUS' => 'DIES', map { $_ => undef } keys %input } if($config{'test_undef'});
	} else {
		push @cases, { };	# Takes no input
	}

	# If it's not in mandatory_strings it sets to 'undef' which is the idea, to test { value => undef } in the args
	push @cases, { map { $_ => $mandatory_strings{$_} } keys %input, %mandatory_objects } if($config{'test_undef'});

	# generate numeric, string, hashref and arrayref min/max edge cases
	# TODO: For hashref and arrayref, if there's a $spec->{schema} field, use that for the data that's being generated
	if(((scalar keys %input) == 1) && exists($input{'type'}) && !ref($input{'type'})) {
		# our %input = ( type => 'string' );
		my $type = $input{type};
		if (exists $input{memberof} && ref $input{memberof} eq 'ARRAY' && @{$input{memberof}}) {
			# Generate edge cases for memberof inside values
			foreach my $val (@{$input{memberof}}) {
				push @cases, { _input => $val };
			}
			# outside value
			my $outside;
			if(($type eq 'integer') || ($type eq 'number') || ($type eq 'float')) {
				$outside = (sort { $a <=> $b } @{$input{memberof}})[-1] + 1;
			} else {
				$outside = 'INVALID_MEMBEROF';
			}
			push @cases, { _input => $outside, _STATUS => 'DIES' };
		} else {
			# Generate edge cases for min/max
			if ($type eq 'number' || $type eq 'integer') {
				if (defined $input{min}) {
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{min} + 1 ) };	# just inside
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{min} ) };	# border
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{min} - 1, _STATUS => 'DIES' ) }; # outside
				} else {
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => 0, _LINE => __LINE__ ) };	# No min, so 0 should be allowable
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => -1, _LINE => __LINE__ ) };	# No min, so -1 should be allowable
				}
				if (defined $input{max}) {
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{max} - 1 ) };	# just inside
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{max} ) };	# border
					push @cases, { %mandatory_strings, %mandatory_objects, ( _input => $input{max} + 1, _STATUS => 'DIES' ) }; # outside
				}
			} elsif ($type eq 'string') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => 'a' x ($len + 1) };	# just inside
					if($len == 0) {
						push @cases, { _input => '' }
					} else {
						# outside
						push @cases, { _input => 'a' x $len };	# border
						push @cases, { _input => 'a' x ($len - 1), _STATUS => 'DIES' };
					}
					if($len >= 1) {
						# Test checking of 'defined'/'exists' rather than if($string)
						push @cases, { %mandatory_strings, ( _input => '0', _LINE => __LINE__ ) };
					} else {
						push @cases, { _input => '0', _STATUS => 'DIES' }
					}
				} else {
					push @cases, { _input => '' };	# No min, empty string should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { %mandatory_strings, ( _input => 'a' x ($len - 1) ) };	# just inside
					push @cases, { %mandatory_strings, ( _input => 'a' x $len ) };	# border
					push @cases, { %mandatory_strings, ( _input => 'a' x ($len + 1), _STATUS => 'DIES' ) }; # outside
				}
				if(defined $input{matches}) {
					my $re = $input{matches};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val =~ $re) {
							push @cases, { %mandatory_strings, ( _input => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if ($val !~ $re) {
							push @cases, { _input => $val, _STATUS => 'DIES' };
						}
					}
					push @cases, { _input => undef, _STATUS => 'DIES' } if($config{'test_undef'});
					push @cases, { _input => "\0", _STATUS => 'DIES' } if($config{'test_nuls'});
				}
				if(defined $input{nomatch}) {
					my $re = $input{nomatch};

					# --- Positive controls ---
					foreach my $val (@candidate_good) {
						if ($val !~ $re) {
							push @cases, { %mandatory_strings, ( _input => $val ) };
							last; # one good match is enough
						}
					}

					# --- Negative controls ---
					foreach my $val (@candidate_bad) {
						if ($val =~ $re) {
							push @cases, { _input => $val, _STATUS => 'DIES' };
						}
					}
				}
			} elsif ($type eq 'arrayref') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => [ (1) x ($len + 1) ] };	# just inside
					push @cases, { _input => [ (1) x $len ] };	# border
					push @cases, { _input => [ (1) x ($len - 1) ], _STATUS => 'DIES' } if $len > 0; # outside
				} else {
					push @cases, { _input => [] };	# No min, empty array should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { _input => [ (1) x ($len - 1) ] };	# just inside
					push @cases, { _input => [ (1) x $len ] };	# border
					push @cases, { _input => [ (1) x ($len + 1) ], _STATUS => 'DIES' }; # outside
				}
			} elsif ($type eq 'hashref') {
				if (defined $input{min}) {
					my $len = $input{min};
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len + 1) } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len - 1) }, _STATUS => 'DIES' } if $len > 0;
				} else {
					push @cases, { _input => {} };	# No min, empty hash should be allowable
				}
				if (defined $input{max}) {
					my $len = $input{max};
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len - 1) } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. $len } };
					push @cases, { _input => { map { "k$_" => 1 }, 1 .. ($len + 1) }, _STATUS => 'DIES' };
				}
			} elsif ($type eq 'boolean') {
				if (exists $input{memberof} && ref $input{memberof} eq 'ARRAY') {
					# memberof already defines allowed booleans
					foreach my $val (@{$input{memberof}}) {
						push @cases, { _input => $val };
					}
				} else {
					# basic boolean edge cases
					push @cases, { _input => 0 };
					push @cases, { _input => 1 };
					push @cases, { _input => 'off' };
					push @cases, { _input => 'on' };
					push @cases, { _input => 'false' };
					push @cases, { _input => 'true' };
					push @cases, { _input => undef, _STATUS => 'DIES' } if($config{'test_undef'});
					push @cases, { _input => 2, _STATUS => 'DIES' };	# invalid boolean
					push @cases, { _input => 'plugh', _STATUS => 'DIES' };	# invalid boolean
				}
			}
		}
	} else {
		# our %input = ( str => { type => 'string' } );
		foreach my $field (keys %input) {
			my $spec = $input{$field} || {};
			my $type = $spec->{type} || 'string';

			if (exists $spec->{memberof} && ref $spec->{memberof} eq 'ARRAY' && @{$spec->{memberof}}) {
				# Generate edge cases for memberof
				# inside values
				foreach my $val (@{$spec->{memberof}}) {
					push @cases, { %mandatory_strings, ( $field => $val ) };
				}
				# outside value
				my $outside;
				if ($type eq 'integer' || $type eq 'number') {
					$outside = (sort { $a <=> $b } @{$spec->{memberof}})[-1] + 1;
				} else {
					$outside = 'INVALID_MEMBEROF';
				}
				push @cases, { %mandatory_strings, ( $field => $outside, _STATUS => 'DIES' ) };
			} else {
				# Generate edge cases for min/max
				if ($type eq 'number' || $type eq 'integer') {
					if (defined $spec->{min}) {
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{min} + 1 ) };	# just inside
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{min} ) };	# border
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{min} - 1, _STATUS => 'DIES' ) }; # outside
					} else {
						push @cases, { $field => 0 };	# No min, so 0 should be allowable
						push @cases, { $field => -1 };	# No min, so -1 should be allowable
					}
					if (defined $spec->{max}) {
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{max} - 1, _LINE => __LINE__ ) };	# just inside
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{max}, _LINE => __LINE__ ) };	# border
						push @cases, { %mandatory_strings, %mandatory_objects, ( $field => $spec->{max} + 1, _STATUS => 'DIES', _LINE => __LINE__ ) }; # outside
					}
				} elsif($type eq 'string') {
					if (defined $spec->{min}) {
						my $len = $spec->{min};
						if(my $re = $spec->{matches}) {
							for my $count ($len + 1, $len, $len - 1) {
								next if ($count < 0);
								my $str = rand_char() x $count;
								if($str =~ $re) {
									push @cases, { %mandatory_strings, ( $field => $str ) };
								} else {
									push @cases, { %mandatory_strings, ( $field => $str, _STATUS => 'DIES' ) };
								}
							}
						} else {
							push @cases, { %mandatory_strings, ( $field => 'a' x ($len + 1) ) };	# just inside
							push @cases, { %mandatory_strings, ( $field => 'a' x $len ) };	# border
							if($len > 0) {
								push @cases, (
									# outside
									{ %mandatory_strings, ( $field => 'a' x ($len - 1), _STATUS => 'DIES' ) },
									# Test checking of 'defined'/'exists' rather than if($string)
									{ %mandatory_strings, ( $field => '0' ) }
								);
							} else {
								push @cases, { %mandatory_strings, ( $field => '' ) };	# min == 0, empty string should be allowable
								# Don't confuse if() with if(defined())
								push @cases, { %mandatory_strings, ( $field => '0' , _STATUS => 'DIES' ) };
							}
						}
					} else {
						push @cases, { %mandatory_strings, ( $field => '' ) };	# No min, empty string should be allowable
					}
					if (defined $spec->{max}) {
						my $len = $spec->{max};
						if((!defined($spec->{min})) || ($spec->{min} != $len)) {
							if(my $re = $spec->{matches}) {
								for my $count ($len - 1, $len, $len + 1) {
									my $str = rand_char() x $count;
									if($str =~ $re) {
										if($count > $len) {
											push @cases, { %mandatory_strings, ( $field => $str, _LINE => __LINE__, _STATUS => 'DIES' ) };
										} else {
											push @cases, { %mandatory_strings, ( $field => $str, _LINE => __LINE__ ) };
										}
									} else {
										push @cases, { %mandatory_strings, ( $field => $str, _STATUS => 'DIES', _LINE => __LINE__ ) };
									}
								}
							} else {
								push @cases, { %mandatory_strings, ( $field => 'a' x ($len - 1), _LINE => __LINE__ ) };	# just inside
								push @cases, { %mandatory_strings, ( $field => 'a' x $len, _LINE => __LINE__ ) };	# border
								push @cases, { %mandatory_strings, ( $field => 'a' x ($len + 1), _LINE => __LINE__, _STATUS => 'DIES' ) }; # outside
							}
						}
					}
					if(defined $spec->{matches}) {
						my $re = $spec->{matches};

						# --- Positive controls ---
						foreach my $val (@candidate_good) {
							if ($val =~ $re) {
								push @cases, { %mandatory_strings, ( $field => $val ) };
								last; # one good match is enough
							}
						}

						# --- Negative controls ---
						foreach my $val (@candidate_bad) {
							if ($val !~ $re) {
								push @cases, { $field => $val, _LINE => __LINE__, _STATUS => 'DIES' };
							}
						}
						push @cases, { $field => undef, _STATUS => 'DIES' } if($config{'test_undef'});
						push @cases, { $field => "\0", _STATUS => 'DIES' } if($config{'test_nuls'});
					}
					if(defined $spec->{nomatch}) {
						my $re = $spec->{nomatch};

						# --- Positive controls ---
						foreach my $val (@candidate_good) {
							if ($val !~ $re) {
								push @cases, { %mandatory_strings, ( $field => $val ) };
								last; # one good match is enough
							}
						}

						# --- Negative controls ---
						foreach my $val (@candidate_bad) {
							if ($val =~ $re) {
								push @cases, { $field => $val, _STATUS => 'DIES' };
							}
						}
					}
				} elsif ($type eq 'arrayref') {
					if (defined $spec->{min}) {
						my $len = $spec->{min};
						push @cases, { $field => [ (1) x ($len + 1) ] };	# just inside
						push @cases, { $field => [ (1) x $len ] };	# border
						push @cases, { $field => [ (1) x ($len - 1) ], _STATUS => 'DIES' } if $len > 0; # outside
					} else {
						push @cases, { $field => [] };	# No min, empty array should be allowable
					}
					if (defined $spec->{max}) {
						my $len = $spec->{max};
						push @cases, { $field => [ (1) x ($len - 1) ] };	# just inside
						push @cases, { $field => [ (1) x $len ] };	# border
						push @cases, { $field => [ (1) x ($len + 1) ], _STATUS => 'DIES' }; # outside
					}
				} elsif ($type eq 'hashref') {
					if (defined $spec->{min}) {
						my $len = $spec->{min};
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len + 1) } };
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. $len } };
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len - 1) }, _STATUS => 'DIES' } if $len > 0;
					} else {
						push @cases, { $field => {} };	# No min, empty hash should be allowable
					}
					if (defined $spec->{max}) {
						my $len = $spec->{max};
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len - 1) } };
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. $len } };
						push @cases, { $field => { map { "k$_" => 1 }, 1 .. ($len + 1) }, _STATUS => 'DIES' };
					}
				} elsif ($type eq 'boolean') {
					if (exists $spec->{memberof} && ref $spec->{memberof} eq 'ARRAY') {
						# memberof already defines allowed booleans
						foreach my $val (@{$spec->{memberof}}) {
							push @cases, { %mandatory_objects, ( $field => $val ) };
						}
					} else {
						# basic boolean edge cases
						push @cases, { %mandatory_objects, ( $field => 0 ) };
						push @cases, { %mandatory_objects, ( $field => 1 ) };
						push @cases, { %mandatory_objects, ( $field => 'false' ) };
						push @cases, { %mandatory_objects, ( $field => 'true' ) };
						push @cases, { %mandatory_objects, ( $field => 'off' ) };
						push @cases, { %mandatory_objects, ( $field => 'on' ) };
						push @cases, { %mandatory_objects, ( $field => undef, _STATUS => 'DIES' ) } if($config{'test_undef'});
						push @cases, { %mandatory_objects, ( $field => 2, _STATUS => 'DIES' ) };	# invalid boolean
						push @cases, { %mandatory_objects, ( $field => 'xyzzy', _STATUS => 'DIES' ) };	# invalid boolean
					}
				}
			}
		}
	}

	# FIXME: I don't thing this catches them all
	# FIXME: Handle cases with Class::Simple calls
	if($config{'dedup'}) {
		# dedup, fuzzing can easily generate repeats
		my %seen;
		@cases = grep {
			my $dump = encode_json($_);
			!$seen{$dump}++
		} @cases;
	}

	# use Data::Dumper;
	# die(Dumper(@cases));

	return \@cases;
}

foreach my $case (@{fuzz_inputs()}) {
	# my %params;
	# lives_ok { %params = get_params(\%input, %$case) } 'Params::Get input check';
	# lives_ok { validate_strict(\%input, %params) } 'Params::Validate::Strict input check';

	my $input;
	my $name = delete $case->{'_name'};
	if((ref($case) eq 'HASH') && exists($case->{'_input'})) {
		$input = $case->{'_input'};
	} else {
		$input = $case;
	}

	if(my $line = (delete $case->{'_LINE'} || delete $input{'_LINE'})) {
		diag("Test case from line number $line") if($ENV{'TEST_VERBOSE'});
	}

	# if($ENV{'TEST_VERBOSE'}) {
		# ::diag('input: ', Dumper($input));
	# }

	my $result;
	my $mess;
	if(defined($input) && !ref($input)) {
		if($name) {
			$mess = "parse_obituary($name = '$input') %s";
		} else {
			$mess = "parse_obituary('$input') %s";
		}
	} elsif(defined($input)) {
		my @alist;
		foreach my $key (sort keys %{$input}) {
			if($key ne '_STATUS') {
				if(defined($input->{$key})) {
					push @alist, "'$key' => '$input->{$key}'";
				} else {
					push @alist, "'$key' => undef";
				}
			}
		}
		my $args = join(', ', @alist);
		$mess = "parse_obituary($args) %s";
	} else {
		$mess = "parse_obituary %s";
	}

	if(my $status = (delete $case->{'_STATUS'} || delete $output{'_STATUS'})) {
		if($status eq 'DIES') {
			dies_ok { $result = Genealogy::Obituary::Parser->parse_obituary($input); } sprintf($mess, 'dies');
		} elsif($status eq 'WARNS') {
			warnings_exist { $result = Genealogy::Obituary::Parser->parse_obituary($input); } qr/./, sprintf($mess, 'warns');
		} else {
			lives_ok { $result = Genealogy::Obituary::Parser->parse_obituary($input); } sprintf($mess, 'survives');
		}
	} else {
		lives_ok { $result = Genealogy::Obituary::Parser->parse_obituary($input); } sprintf($mess, 'survives');
	}

	if(scalar keys %output) {
		if($ENV{'TEST_VERBOSE'}) {
			::diag('result: ', Dumper($result));
		}
		returns_ok($result, \%output, 'output validates');
	}
}



done_testing();
