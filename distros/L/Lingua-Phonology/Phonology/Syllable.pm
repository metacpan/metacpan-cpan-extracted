#!/usr/bin/perl

package Lingua::Phonology::Syllable;

=head1 NAME

Lingua::Phonology::Syllable;

=head1 SYNOPSIS

    use Lingua::Phonology;
    use Lingua::Phonology::Syllable;

    my $phono = Lingua::Phonology->new();
    $phono->features->loadfile;
    $phono->symbols->loadfile;

    # Create a new Syllable object
    my $syll = new Lingua::Phonology::Syllable;

    # Create an input word
    my @word = $phono->symbols->segment('t','a','k','r','o','t');

    # Allow onset clusters and simple codas
    $syll->set_complex_onset;
    $syll->set_coda;

    # Syllabify the word
    $syll->syllabify(@word);

    my $count = $syll->count_syll;
    print "Count: $count\n"; # prints "Count: 2"

	# @word now has features set to indicate a syllabification of
	# <ta><krot>

=head1 DESCRIPTION

Syllabifies an input word of Lingua::Phonology::Segment objects according
to a set of parameters. The parameters used are well-known linguistic
parameters, so most kinds of syllabification can be handled in just a few
lines of code by setting the appropriate values.

This module uses a special set of features to indicate syllabification.  These
features are added to the feature set of the input segments. The features added
are arranged in a heirarchy as follows:

	SYLL	       scalar     Non-zero if the segment has been syllabified
	 |-onset       privative  True if the segment is part of the onset
	 |-Rime	       privative  True if the segment is part of the Rime (i.e. nucleus or coda)
	    |-nucleus  privative  True if the segment is the nucleus
	    |-coda     privative  True if the segment is part of the coda
	SON            scalar     An integer indicating the calculated sonority of the segment

The module will set these features so that subsequent processing by
Lingua::Phonology::Rules will correctly split the word up into domains or tiers
on these features.

The algorithm and parameters used to syllabify an input word are described
in the L<"ALGORITHM"> and L<"PARAMETERS"> sections.

=cut

use strict;
use warnings;
use warnings::register;
use Carp;
use Lingua::Phonology::Common;
use Lingua::Phonology::Rules;
use Lingua::Phonology::Functions qw/adjoin flat_adjoin/;

our $VERSION = 0.3;

sub err ($) { _err($_[0]) if warnings::enabled() };

# Build accessors for our properties. Hashes in name => default format
our %bool = ( 
    onset => 1,
    complex_onset => 0,
    coda => 0,
	complex_coda => 0
);
for my $name (keys %bool) {
    no strict 'refs';
    *$name = sub {
        my $self = shift;
        if (@_) {
            if ($_[0]) { $self->{ATTR}->{$name} = 1; }
            else { $self->{ATTR}->{$name} = 0; }
        }
        return $self->{ATTR}->{$name};
    };
    *{"set_$name"} = sub { (shift)->$name(1) };
    *{"no_$name"} = sub { (shift)->$name(0) };
}

our %int = ( 
	min_coda_son => 0,
	onset_son_dist => 1,
	coda_son_dist => 1,
	max_edge_son => 100,
	min_nucl_son => 3
);
for my $name (keys %int) {
    no strict 'refs';
    *$name = sub {
        my $self = shift;
        if (@_) {
            $self->{ATTR}->{$name} = int shift;
        }
        return $self->{ATTR}->{$name};
    };
}

our %hash = (
	sonorous => { sonorant => 1,
				  approximant => 1,
				  aperture => 1,
				  vocoid => 1 }
);
for my $name (keys %hash) {
    no strict 'refs';
    *$name = sub {
        my $self = shift;
        if (@_) {
            my $href = shift;
            return err "Argument to $name() must be a hash reference" unless _is($href, 'HASH');
            $self->{ATTR}->{$name} = $href;
        }
        return $self->{ATTR}->{$name};
    };
}

our %code = (
	clear_seg => sub {1},
	begin_adjoin => sub {0},
	end_adjoin => sub {0}
);
for my $name (keys %code) {
    no strict 'refs';
    *$name = sub {
        my $self = shift;
        if (@_) {
            my $cref = shift;
            return err "Argument to $name must be a code reference" unless _is($cref, 'CODE');
            $self->{ATTR}->{$name} = $cref;
        }
        return $self->{ATTR}->{$name};
    };
}
    
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = bless { RULES => new Lingua::Phonology::Rules, ATTR => {} }, $class;
	
	# Initialize $self w/ defaults
	$self->$_($bool{$_}) for keys(%bool);
	$self->$_($int{$_}) for keys(%int);
	$self->$_($hash{$_}) for keys(%hash);
	$self->$_($code{$_}) for keys(%code);
	
	# Prepare the rules. This is the most important part
    no warnings 'uninitialized';
	$self->{RULES}->add_rule(
        # Calculate all sonorities
		CalcSon => {
			do => sub { $_[0]->SON($self->sonority($_[0])) }
		},

        # Clear old syllabification
		Clear => {
			where => sub { $self->clear_seg->(@_) },
			do => sub {
				$_[0]->delink('SYLL', 'onset', 'Rime', 'nucleus', 'coda');
			}
		},

        # Make CV syllables
		CoreSyll => {
			where => sub {
				my $son = $_[0]->SON;
				return 0 if defined $_[0]->SYLL;
				return (
					($son > $self->max_edge_son) ||  # Can't be an edge OR
					(
						($son >= $self->min_nucl_son) && # Is allowed to be a nucleus AND
						($son >= $_[-1]->SON && $son >= $_[1]->SON) # Is a local sonority peak
					)
				);
			},
			do => sub {
				$_[0]->nucleus(1); $_[0]->Rime(1); $_[0]->SYLL(1); # Make yourself a nucleus
				# Make preceding C an onset if . . . 
				if (   $self->onset # onsets allowed
                    && $_[-1]->SON <= $_[0]->SON # less sonorous than you AND
				    && $_[-1]->SON <= $self->max_edge_son # allowed to be non-nucleus AND
			        && not $_[-1]->SYLL # not already syllabified
				) {
					$_[-1]->onset(1); flat_adjoin('SYLL', $_[0], $_[-1]);
				}
			}
		},

		ComplexOnset => {
			direction => 'leftward',
			where => sub {
				   (not $_[0]->SYLL) # not yet syllabified
				&& $_[1]->onset # following seg is an onset
				&& $_[0]->SON <= $self->max_edge_son # this can be an onset
				&& (($_[1]->SON - $_[0]->SON) >= $self->min_son_dist) # sonority distance respected
			},
			do => sub { adjoin('onset', $_[1], $_[0]); flat_adjoin('SYLL', $_[1], $_[0]); }
		},

		Coda => {
			where => sub {  
                   (not $_[0]->onset) # not an onset 
                && $_[-1]->nucleus # follows a nucleus
                && $_[0]->SON <= $self->max_edge_son # allowed to be an edge
                && $_[0]->SON >= $self->min_coda_son # allowed to be a coda
            },
			do => sub { 
                $_[0]->coda(1);
                $_[0]->delink('nucleus');
                flat_adjoin('Rime', $_[-1], $_[0]);
                flat_adjoin('SYLL', $_[-1], $_[0]);
            }
		},

		ComplexCoda => {
			direction => 'rightward',
			where => sub {    
                   (not $_[0]->SYLL)
                && $_[-1]->coda
                && $_[0]->SON <= $self->max_edge_son
                && $_[0]->SON >= $self->min_coda_son 
                && (($_[-1]->SON - $_[0]->SON) >= $self->min_son_dist)
            },
			do => sub { 
                adjoin('coda', $_[-1], $_[0]);
                flat_adjoin('Rime', $_[-1], $_[0]);
                flat_adjoin('SYLL', $_[-1], $_[0])
            }
		},

		BeginAdjoin => {
			direction => 'leftward',
			where => sub {
				my $cond1 = 1 if ((not $_[0]->SYLL) && $_[1]->onset && $self->begin_adjoin->(@_));
				my $cond2 = 1;
				my $i = -1;
				while ($cond2 && not $_[$i]->BOUNDARY) {
					$cond2 = 0 if ($_[$i]->SYLL);
					$i--;
				}
				return ($cond1 && $cond2);
			},
			do => sub { 
                adjoin('onset', $_[1], $_[0]); 
                flat_adjoin('SYLL', $_[1], $_[0]);
            }
		},

		EndAdjoin => {
			direction => 'rightward',
			where => sub {
				my $cond1 = 1 if ((not $_[0]->SYLL) && $_[-1]->coda && $self->end_adjoin->(@_));
				my $cond2 = 1;
				my $i = 1;
				while ($cond2 && not $_[$i]->BOUNDARY) {
					$cond2 = 0 if ($_[$i]->SYLL);
					$i++;
				}
				return ($cond1 && $cond2);
			},
			do => sub { 
                adjoin('coda', $_[-1], $_[0]);
                flat_adjoin('Rime', $_[-1], $_[0]);
                flat_adjoin('SYLL', $_[-1], $_[0]) 
            }
		},

		# This rule exists purely for data-collection purposes (see count_unparsed)
		Unparsed => {
			where => sub { not $_[0]->SYLL },
		}

	);

	# Be blessed
	return $self;	
} 

sub syllabify {
	my $self = shift;

	# Check for valid input
	for (@_) {
		return err("Bad input to syllabify()") unless _is_seg($_);
	}

	# Add the necessary features
	$_[0]->featureset->add_feature(
		SYLL => { type => 'scalar' },
		onset => { type => 'privative' },
		Rime => { type => 'privative' },
		nucleus => { type => 'privative' },
		coda => { type => 'privative' },
		SON => { type => 'scalar' },
	);
    $_[0]->featureset->add_child('SYLL', 'onset', 'Rime');
    $_[0]->featureset->add_child('Rime', 'nucleus', 'coda');

	# Optimize the rule order
	my @order = ('Clear', 'CalcSon', 'CoreSyll');
	push(@order, 'ComplexOnset') if $self->complex_onset;
	push(@order, 'Coda') if $self->coda;
	push(@order, 'ComplexCoda') if $self->complex_coda;
	push(@order, 'BeginAdjoin') if $self->begin_adjoin != $code{begin_adjoin};
	push(@order, 'EndAdjoin') if $self->end_adjoin != $code{end_adjoin};
	push(@order, 'Unparsed');
	$self->{RULES}->order(@order);

	# Are we in a rule (are these really RuleSegments)?
	if (_is_ruleseg $_[0]) {
		# Rewind the word (it fucks us up to start in the middle)
		unshift(@_, pop(@_)) while not $_[-1]->BOUNDARY;
		# Get rid of boundary segments
		pop @_ while $_[-1]->BOUNDARY;
	}

	# Apply all rules
	$self->{RULES}->apply_all(\@_);
} 

sub count_syll {
	my $self = shift;
	$self->{RULES}->count->{CoreSyll};
}

sub count_unparsed {
	my $self = shift;
	$self->{RULES}->count->{Unparsed};
}

# Calculate a segment's sonority
sub sonority {
	my $self = shift;
	my $seg = shift;
	my $son = 0;
	for (keys(%{$self->sonorous})) {
		$son += $self->{ATTR}->{sonorous}->{$_} if $seg->$_;
	}
	return $son;
} 

# min_son_dist sets both coda_son and onset_son
sub min_son_dist {
	my $self = shift;

	if (@_) {
		my $val = shift;
		$self->coda_son_dist($val);
		$self->onset_son_dist($val);
	}
	return $self->onset_son_dist;

}

# Sets the direction
sub direction {
	my ($self, $val) = @_;
	if (defined($val)) {
		$self->{RULES}->direction('CoreSyll', $val);
		$self->{RULES}->direction('Coda', $val);
	} 
	return $self->{ATTR}->{direction} = $self->{RULES}->direction('CoreSyll');
}

sub loadfile {
	my ($self, $file) = @_;

    # Load defaults, but defaults are loaded with new()
    return 1 if not defined $file;

    my $parse;
	eval { $parse = _parse_from_file($file, 'syllable') };
    return err $@ if $@;

    $self->_load_from_struct($parse);
}

sub _load_from_struct {
    my ($self, $struct) = @_;

    for (keys %$struct) {
        # Accomodate set_ and no_ entries
        my $bool = 1;
        $bool = 1 if s/^set_//;
        $bool = 0 if s/^no_//;
		if (exists $bool{$_}) {
			$self->$_($bool);
		}
		elsif (exists $hash{$_}) {
			my $l = $_;
			$self->$_( {map { $_ => $struct->{$l}->{feature}->{$_}->{score} } keys %{$struct->{$l}->{feature}}} );
		}
		elsif (exists $code{$_}) {
            my $c = _parse_ext $struct->{$_};

			if ($@) {
				err("Errors processing $_ : $@");
			}
			else {
				$self->$_($c);
			}
		}
        # Most general, applicable for integers, direction, min_son_dist, etc.
        else {
            $self->$_($struct->{$_}->{value});
        }
	}
    1;
}
    

sub _to_str {
	my ($self, $file) = @_;

    require B::Deparse;

	my $href = {};
	for (keys %{$self->{ATTR}}) {
		if (exists $bool{$_}) {
            if ($self->$_) {
                $href->{"set_$_"} = {};
            }
            else {
                $href->{"no_$_"} = {};
            }
		}
		elsif (exists $hash{$_}) {
			my $l = $_;
			$href->{$l}->{feature} = {};
			for (keys %{$self->{ATTR}->{$l}}) {
				$href->{$l}->{feature}->{$_} = { score => $self->{ATTR}->{$l}->{$_} };
			}
		}
		elsif (exists $code{$_}) {
			my $d = B::Deparse->new('-x7', '-p', '-si4');
			$d->ambient_pragmas(strict => 'all', warnings => 'all');
			my $code = _deparse_ext $self->{ATTR}->{$_}, $d or err $@;

			$href->{$_} = [ $code . '  ' ]; # Extra whitespace for helping indent
		}
        # Takes car of %int and others
        else {
            $href->{$_} = { value => $self->$_ };
        }
	}

	_string_from_struct({ syllable => $href });
}

1;

__END__


=head1 METHODS

This section lists the methods not associated with any particular parameter.
The items in the L<"PARAMETERS"> section also have methods associated with
them.

=head2 new

    $syll = Lingua::Phonology::Syllable->new();

Returns a new Lingua::Phonology::Syllable object. Takes no arguments.

=head2 syllabify

    $syll->syllabify(@word);

Syllabifies an input word. The arguments to syllabify() should be a list of
Lingua::Phonology::Segment objects. Those segments will be set to have the
feature values named above (SYLL, Rime, onset, nucleus, coda), according to
the current syllabification parameters.

Note that if you're using this method as part of a Lingua::Phonology::Rules
rule, then the following is almost certainly wrong:

	# Assume that we have a Rules object $rules and Syllable object $syll already
	$rules->add_rule(
		Syllabify => {
			do => sub { $syll->syllabify(@_) }
		}
	);

The preceding rule will needlessly resyllabify the word once for every
segment in the input word. This can be avoided with a simple addition.

	$rules->add_rule(
		Syllabify => {
			direction => 'rightward',
			where => sub { $_[-1]->BOUNDARY },
			do => sub { $syll->syllabify(@_) }
		}
	);

This rule does a simple check to see if it's the first segment in the word,
and then syllabifies. Syllabification only then happens once each time you
apply the rule.

=head2 count_syll

    $sylls = $syll->count_syll;

This is a simple data-collection method that takes no arguments. It returns the
number of syllables created in the most recent call to C<syllabify>.

=head2 count_unparsed

    $unparsed = $syll->count_unparsed;

This is another data-collection method that takes no arguments. It returns the
number of segments that were left unparsed in the most recent call to
C<syllabify>.

=head2 sonority

    $sonority = $syll->sonority($segment);

Takes a single Lingua::Phonology::Segment object as its argument, and
returns an integer indicating the current calcuated sonority of the
segment. The integer returned depends on the current value of the
C<sonorous> property. See L<"sonorous"> for more information.

=head1 ALGORITHM

Syllabification algorithms are well-established in linguistic literature;
this module merely implements the general view. Syllabification proceeds in
several steps, the maximum expression of which is given below.
Lingua::Phonology::Syllable may optimize away some of these steps if the
current parameter settings warrant.

=head2 Clearing and calculating sonority

At the beginning of any syllabification, the existing syllabification for a
segment is cleared if that segment meets the conditions in the C<clear_seg>
parameter. The sonority for all segments is also calculated according to
the properties of the C<sonorous> parameter.

=head2 Core syllabification

In this step, basic CV syllables are formed. Nuclei are assigned to segments
that are of equal or greater sonority than both adjacent segments, and which at
least as sonorous as the minimum nucleus sonority (C<min_nucl_son>). The
segments to the left of nuclei are assigned as onsets if onsets are allowed
(defined by C<onset>), they are not more sonorous than the maximum edge
sonority (C<max_edge_son>), and they have not already been assigned as nuclei.

=head2 Complex onset formation

Complex onsets are formed if they are allowed (defined by C<complex_onset>). As
many segments as possible are taken into the onset of the existing syllables,
provided that they do not violate the minimum sonority distance in the onset
(C<onset_son_dist>) and do not exceed the maximum edge sonority.

=head2 Coda formation

Codas are formed if they are allowed (defined by C<coda>). A segment to the
left of a nucleus will be assigned to a coda if it has not already been
syllabified as an onset, is less sonorous than the maximum edge sonority, and
is at least as sonorous as the minimum coda sonority (C<min_coda_son>).

=head2 Complex coda formation

Complex codas are formed if they are allowed (defined by C<complex_coda>).
As many segments as possible are taken into the coda, so long as they do
not violate the minimum sonority distance and meet the same conditions
imposed on regular codas.

=head2 Beginning adjunction

Segments at the very beginning of a word may be added to the initial
syllable if special conditions apply. As many segments as possible will be
added to the onset of the initial syllable if there are no syllabified
segments between them and the left edge of the word, and if they meet the
conditions imposed by the C<begin_adjoin> parameter.

=head2 End adjunction

Segments at the very end of a word may be added to the coda of a final
syllable under similar conditions. As many segments as possible will be
added to the final syllable if for each of them there are no syllabified
segments between them and the right edge of the word, and if they meet the
conditions imposed in the C<end_adjoin> parameter.

=head1 PARAMETERS

These parameters are used to determine the behavior of the syllabification
algorithm. They are all accessible with a variety of get/set methods. The
significance of the parameters and the methods used to access them are
described below.

=head2 onset

B<Boolean>, default true.

    # Return the current setting
    $syll->onset;

    # Allow onsets
    $syll->onset(1);
    $syll->set_onset;

    # Disallow onsets
    $syll->onset(0);
    $syll->no_onset;

If this parameter is true, onsets are allowed. When nuclei are formed, the
segment preceding the nucleus will be taken as the onset of the syllable if
other parameters allow. Note that pretty much all languages allow onsets.

=head2 complex_onset

B<Boolean>, default false.

	# Return the current setting
	$syll->complex_onset;

	# Allow complex onsets
	$syll->complex_onset(1);
	$syll->set_complex_onset;

	# Disallow complex onsets
	$syll->complex_onset(0);
	$syll->no_complex_onset;

If this parameter is true, then complex onsets are allowed. The
syllabification algorithm will greedily take as many segments as possible
into the onset, provided that minimum sonority distance and maximum edge
sonority are respected.

=head2 coda

B<Boolean>, default false.

	# Return the current setting
	$syll->coda;

	# Allow codas
	$syll->coda(1);
	$syll->set_coda;

	# Disallow codas
	$syll->coda(0);
	$syll->no_coda;

If this parameter is true, then a single coda consonant is allowed.

=head2 complex_coda

B<Boolean>, default false.

	# Return the current setting
	$syll->complex_coda; 

	# Allow complex codas
	$syll->complex_coda(1);
	$syll->set_complex_coda;

	# Disallow complex codas
	$syll->complex_coda(0);
	$syll->no_complex_coda;

If this parameter is true, then complex codas are allowed. Setting this
parameter has no effect unless C<coda> is also set. The algorithm will
greedily take as many consonants as possible into the coda, provided that
minimum sonority distance, maximum edge sonority, and minimum coda sonority
are respected.

=head2 min_son_dist

B<Integer>, default 1.

	# Return the current value
	$syll->min_son_dist;

	# Set the value
	$syll->min_son_dist(2);

This determines the B<min>imum B<son>ority B<dist>ance between members of a
coda or onset. Within a coda or onset, adjacent segments must differ in
sonority by at least this amount. Setting this value sets both coda_son_dist
and onset_son_dist (see below). This has no effect unless C<complex_onset> or
C<complex_coda> is set to true. The default value is 1, which means that stop +
nasal sequences like /kn/ will be valid onsets (if complex_onset is true);

=head2 coda_son_dist

B<Integer>, default 1

    # Return the current value
    $syll->coda_son_dist;

    # Set the value
    $syll->coda_son_dist(2);

This parameter allows you finer control over the minimum sonority distance by
allowing you to set the minimum sonority distance in codas separately from
onsets. This sets the minimum sonority difference between adjacent segments in
codas only.

=head2 onset_son_dist

B<Integer>, default 1

    # Return the current value
    $syll->onset_son_dist;

    # Set the value
    $syll->onset_son_dist(2);

This parameter allows you finer control over the minimum sonority distance by
allowing you to set the minimum sonority distance in codas separately from
onsets. This sets the minimum sonority difference between adjacent segments in
onsets only.

=head2 min_coda_son

B<Integer>, default 0.

	# Return the current value
	$syll->min_coda_son;

	# Set the value;
	$syll->min_coda_son(2);

This determines the B<min>imum B<coda> B<son>ority. Coda consonants must be at
least this sonorous in order to be made codas. This is an easy way to, for
example, allow only liquids and glides in codas. The default value is for
anything to be allowed in a coda if codas are allowed at all.

=head2 max_edge_son

B<Integer>, default 100

	# Return the current value
	$syll->max_edge_son;

	# Set the value;
	$syll->max_edge_son(2);

This determines the B<max>imum B<edge> B<son>ority. Segments that are more
sonorous than this value are required to be nuclei, no matter what other
factors might intervene. This is an easy way to, for example, prevent high
vowels from being made into glides. The default value (100) is simply set
to a very high number to imply no particular restriction on what may be an
onset or coda.

=head2 min_nucl_son

B<Integer>, default 3.

	# Return the current value
	$syll->min_nucl_son;

	# Set the value;
	$syll->min_nucl_son(2);

This determines the B<min> B<nucl>eus B<son>ority. Segments that are less
sonorous than this cannot be nuclei, no matter what other factors intervene.
This is useful to rule out syllabic nasals and liquids. The default value (3)
is set so that only vocoids can be nuclei. If you change which features count
towards sonority, this will of course change the significance of the sonority
value 3. Therefore, if you change sonorous(), you should consider if you need
to change this value.

=head2 direction

B<String>, default 'rightward'.

	# Return the current value
	$syll->direction;

	# Set the value
	$syll->direction('leftward');

This determines the direction in which core syllabification proceeds: L->R or
R->L. Since syllable lines are not redrawn after the core syllabification, this
can have important consequences for which segments are nuclei and which are
onsets and codas if there is some ambiguity. This chart gives some examples:

	Outcomes for various scenarios, based on direction
	  Input word          rightward          leftward
	
	No complex onsets or codas
	  /duin/               <du><i>n          d<wi>n
	
	Codas, no complex onsets
	  /duin/               <duj>n            d<win>
	
	Complex onsets and complex codas
	  /duin/               <dujn>            <dwin>

=head2 sonorous

B<Hash reference>, default:

	{
		sonorant => 1,
		approximant => 1,
		vocoid => 1,
		aperture => 1
	}

This is used to calculate the sonority of segments in the word. The value
returned or passed into this method is a hash reference. The keys of this
reference are the names of features, and the values are the amounts by
which sonority is to be increased or decreased if the segment tests true
for those features.

This method returns a hash reference containing all of the current key =>
value pairs. If you pass it a hash reference as an argument, that hash
reference will replace the current one. I often find that for modifying the
existing hash reference, it's easiest to use syntax like C<<
$syll->sonorous->{feature} >> to retrieve a the value for a single key, or
C<< $syll->sonorous->{feature} = $val >> to set a single value.

Note that the sonority() method only tests to see whether the feature values
given as keys are I<true>. There is no way to test for a particular scalar
value. If you want to increase sonority in the case that a particular feature
is false, simply set the value for that feature to be -1. E.g. if you were
using the feature [consonantal] in place of [vocoid], you would want to say C<<
$syll->sonorous->{consonantal} = -1 >>.

The default settings for sonorous(), together with the default feature set
defined in Lingua::Phonology::Features, define the following sonority
classes and values:

	0: Stops and fricatives
	1: Nasals
	2: Liquids
	3: High Vocoids
	4: Non-high vocoids

=head2 clear_seg

B<Code>, default clears all segs.

	# Return the current value
	$syll->clear_seg;

	# Set the value
	$syll->clear_seg(\&foo);

This sets the conditions under which a segment should have its
syllabification values cleared and should be re-syllabified from scratch.
The default value is for every segment to be cleared every time. The code
reference passed to C<clear_seg> should follow the same rules as one for
the C<where> property for a rule in Lingua::Phonology::Rules.

=head2 end_adjoin

B<Code>, default C<sub {0}>.

	# Return the current value
	$syll->end_adjoin;

	# Set the value
	$syll->end_adjoin(\&foo);

This sets the conditions under which a segment may be adjoined to the end
of a word. The default is for no end-adjunction at all. The code reference
passed to end_adjoin() should follow the same rules as one for the C<where>
property of a rule in Lingua::Phonology::Rules. Note that additional
constraints other than the ones present in the code reference here must be
met in order for end-adjunction to happen, as described in the
L<"ALGORITHM"> section.

=head2 begin_adjoin

B<Code>, default C<sub {0}>.

	# Return the current value
	$syll->begin_adjoin;

	# Set the value
	$syll->begin_adjoin(\&foo);

This sets the conditions under which a segment may be adjoined to the
beginning of a word. The default is for no beginning-adjunction at all. The
code reference passed to begin_adjoin() should follow the same rules as one
for the C<where> property of a rule in Lingua::Phonology::Rules. Note that
additional constraints other than the ones present in the code reference
here must be met in order for beginning-adjunction to happen, as described
in the L<"ALGORITHM"> section.

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut
