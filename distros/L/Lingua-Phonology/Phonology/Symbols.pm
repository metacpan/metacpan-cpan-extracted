#!/usr/bin/perl -w

package Lingua::Phonology::Symbols;

=head1 NAME

Lingua::Phonology::Symbols - a module for associating symbols with 
segment prototypes.

=head1 SYNOPSIS

	use Lingua::Phonology;
	$phono = new Lingua::Phonology;

	# Load the default features
	$phono->features->loadfile;

	# Load the default symbols
	$symbols = $phono->symbols;
	$symbols->loadfile;

	# Make a test segment
	$segment = $phono->segment;
	$segment->labial(1);
	$segment->voice(1);

	# Find the symbol matching the segment
	print $symbols->spell($segment);  # Should print 'b'

=head1 DESCRIPTION

When using Lingua::Phonology, you usually manipulate Segment objects that have
various feature values that specify the phonetic qualities of the segment.
However, it is difficult to print those feature values, and a list of feature
values can be difficult to interpret anyway. This is where Symbols comes in--it
provides a way to take a Segment object and get a phonetic symbol representing
the properties of that segment.

In Symbols, you may use L<add_symbol>() to define text symbols that correlate to
"prototypes", which are special Segment objects that represent the ideal
segment for each symbol.  After you have defined your symbols and prototypes,
you may use L<spell>() to find which prototype is the most similar to a segment
in question, and get the symbol for that prototype.

As of v0.2, Symbols also includes diacritics. A diacritic is a special symbol
that begins or ends with a '*', and which is used to modify other symbols. If
the best symbol match for a segment you are trying to spell is an imperfect
match, Symbols will then attempt to use diacritics to indicate exactly how the
segment is pronounced. For compatibility reasons, however, this feature is off
by default. It can be turned on with L<set_diacritics>.

You will probably want to read the L<add_symbol>, L<spell>, and L<loadfile>
sections, because these describe the most widely-used functions and the
algorithm used to score potential matches. If you're not getting the results
you expect, you probably need to examine the way your prototype definitions are
interacting with that algorithm.

=cut

use strict;
use warnings;
use warnings::register;
use Carp;
use Lingua::Phonology::Common;
use Lingua::Phonology::Segment;

our $VERSION = 0.3;

sub err ($) { _err($_[0]) if warnings::enabled() };

# Make subs for our flags
# flags in sub_name => 'hash_key' format
my %flags = (
    auto_reindex => 'AUTOINDEX',
    diacritics => 'USEDCR'
);
while (my ($sub, $key) = each %flags) {
    no strict 'refs';
    *$sub = sub {
        my $self = shift;
        if (@_) {
            if ($_[0]) {
                $self->{$key} = 1;
            }
            else {
                $self->{$key} = 0;
            }
        }
        return $self->{$key};
    };
    *{'set_' . $sub} = sub { $_[0]->{$key} = 1 };
    *{'no_' . $sub} = sub {$_[0]->{$key} = 0; 1; };
}

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
        FEATURES => undef,  # a Features object
        SYMBOLS => {},     	# the hash of symbol => prototype
        DIACRITS => {}, 	# hash of diacritic => prototype
        USEDCR => 0, 		# whether or not to use diacritics (off by default)
        AUTOINDEX => 1, 	# whether or not to autoindex (on by default)
        REINDEX => 0, 		# whether reindexing is currently necessary
        INDEX => {}, 		# index of symbols by feature
        VALINDEX => {}, 	# index of features by symbol
        DCRINDEX => []   	# index of diacritics by number of keys
    }; 		

	my $features = shift;
	unless (_is_features($features)) {
		carp "No feature set or bad featureset given for new Symbols object";
		return undef;
	}
	$self->{FEATURES} = $features;

	bless ($self, $class);
	return $self;
} 

# Add a new symbol (why isn't this called add_symbol? Poor planning . . .)
sub add_symbol {
	my $self = shift;
	my %hash = @_;
	my $err = 0;

	SYMBOL: for my $symbol (keys %hash) {

        $self->_check_symbol($symbol, $hash{$symbol}) or do {
            $err = 1;
            next SYMBOL;
        };

        # Drop pre-existing symbols
        $self->drop_symbol($symbol);

        # Add the new symbol
        $self->_add_symbol($symbol, $hash{$symbol});

    }

	$self->{REINDEX} = 1;

	return $err ? () : 1;
} 

# Make symbol() synonymous with add_symbol()
*symbol = \&add_symbol;

# Private: check that the symbol prototype is okay
sub _check_symbol {
    my ($self, $symbol, $ref) = @_;

    unless (_is_seg($ref)) {
        return err ("Prototype for '$symbol' is not a Lingua::Phonology::Segment");
    }

    if ($self->features ne $ref->featureset) {
        return err("Prototype for '$symbol' has wrong feature set");
    }

    # Success--spell the proto w/ this symbolset
    $ref->symbolset($self);
    return 1;
}

# Private: add the symbol to yourself
sub _add_symbol {
    my ($self, $symbol, $ref) = @_;
    
	# Diacritics
    if ($symbol =~ /(^\*\S+)|(\S+\*$)/) {
        $self->{DIACRITS}->{$symbol} = $ref;
    }

    # Regular symbols
    else {
        $self->{SYMBOLS}->{$symbol} = $ref;
    }
}

sub drop_symbol {
	my $self = shift;
	for (@_) {
		delete ($self->{SYMBOLS}->{$_}) or delete ($self->{DIACRITS}->{$_});
	}
	$self->{REINDEX} = 1;
} 

sub change_symbol {
	my $self = shift;
	my %hash = @_;
	my $err = 0;

	SYMBOL: for my $symbol (keys(%hash)) {
        if (not exists $self->{SYMBOLS}->{$symbol}) {
            err "No symbol $symbol defined";
            $err = 1;
            next SYMBOL;
        }

        $self->_check_symbol($symbol, $hash{$symbol}) or do {
            $err =1;
            next SYMBOL;
        };

        $self->_add_symbol($symbol, $hash{$symbol});
		
	}

	$self->{REINDEX} = 1;

	return $err ? () : 1;
}

sub reindex {
	my $self = shift;
	$self->{REINDEX} = 0;
	$self->{INDEX} = {};

    # Index symbols by feature => value
	for my $symbol (keys %{$self->{SYMBOLS}}) {
		my %feat = $self->{SYMBOLS}->{$symbol}->all_values;
		$self->{VALINDEX}->{$symbol} = \%feat;

		for (keys %feat) {
            no warnings 'uninitialized'; # Avoid the warning when $feat{$_} is undef
            push @{$self->{INDEX}->{$_}->{$feat{$_}}}, $symbol;
		}
	} 

    # Sort diacritics by number of keys.
	$self->{DCRINDEX} = [ 
        sort
        {
            my %a = $self->{DIACRITS}->{$a}->all_values;
            my %b = $self->{DIACRITS}->{$b}->all_values;
            return keys(%b) <=> keys(%a);
        } 
        keys %{$self->{DIACRITS}}
    ];

    # Also add diacritics to VALINDEX
	for (keys %{$self->{DIACRITS}}) {
		my %feats = $self->{DIACRITS}->{$_}->all_values;
		$self->{VALINDEX}->{$_} = \%feats;
	}

	return 1;
} 

sub loadfile {
	my ($self, $file) = @_;

    my $parse;
    
    # Loading default symbols
    if (not defined $file) {
        my $start = tell DATA;
        my $string = join '', <DATA>;
        eval { $parse = _parse_from_string($string, 'symbols') };
        return err $@ if $@;
        seek DATA, $start, 0;
    }

    # Loading an actual file
    else {
        eval { $parse = _parse_from_file($file, 'symbols') };
        if (!$parse) {
            return $self->old_loadfile($file);
        }
    }

    $self->_load_from_struct($parse);
}

sub old_loadfile {
    my ($self, $file) = @_;

    eval { $file = _to_handle($file, '<') };
    return err $@ if $@;
    err "Deprecated method";

	while (<$file>) {
		s/#.*$//; # Remove comments
		if (/^\s*(\S*)\t+(.*)/) { # General line format
			my $symbol = $1;
			my @desc = split(/\s+/, $2);

			my $proto = Lingua::Phonology::Segment->new( $self->features );
			for (@desc) {
				if (/(\S+)=(\S+)/) { # Feature defs like coronal=1
					$proto->value($1, $2);
				} 
				elsif (/([*+-])?(\S+)/) { # Feature defs like +feature or feature
					my $val = $1 ? $1 : 1;
					$proto->value($2, $val);
				}
			} 
			$self->symbol($symbol => $proto);
		} 
	} 

    close $file;

	$self->{REINDEX} = 1;
} 

sub _load_from_struct {
	my ($self, $parse) = @_;

	while ( my ($sym, $val) = each %$parse ) {
		my $proto = new Lingua::Phonology::Segment($self->{FEATURES},
			{ map { $_ => $val->{feature}->{$_}->{value} } keys %{$val->{feature}} } );
		$self->symbol($sym => $proto);
	}
	$self->{REINDEX} = 1;
}

sub _to_str {
	my $self = shift;

	my $href = {};
	for ($self->{SYMBOLS}, $self->{DIACRITS}) {
		for my $sym (keys %$_) {
			my %h = $_->{$sym}->all_values;
			for (keys %h) {
                $h{$_} = '*' if not defined $h{$_};
				$href->{$sym}->{feature}->{$_} = { value => $h{$_} };
			}
		}
	}

    return eval { _string_from_struct({ symbols => { symbol => $href } }) };
}

sub spell {
	my $self = shift;

	my @return = ();
	for my $comp (@_) {
		return err("Bad argument to spell()") unless _is_seg($comp);
		my $winner = $self->score($comp);
		push (@return, $winner ? $winner : '_?_');
	} 

	local $" = '';
	return wantarray ? @return : "@return";
} 
	
sub score {
	my $self = shift;
	my $comp = shift;

	# Reindex if necessary
	$self->reindex if $self->{REINDEX} and $self->{AUTOINDEX};

	# Prepare data containers
	my %comp = $comp->all_values;
	my %scores = ();
	my @scores = ();


	for my $feature (keys %{$self->{INDEX}}) {
        while (my ($val, $list) = each %{$self->{INDEX}->{$feature}}) {
            # Avoid all sorts of harmless warnings
            no warnings 'uninitialized';

            # Special case: when $val is '' (which is equiv w/ undef), check
            # that $comp->$feature actually returns undef, in case $feature is
            # a node w/ defined children
            $comp{$feature} = $comp->$feature if $val eq '';

            if ($val eq $comp{$feature}) {
                $scores{$_}++ for @$list;
            }
            else {
                $scores{$_}-- for @$list;
            }
        }
    }

    # Build @scores
    while (my ($sym, $score) = each %scores) {
        $scores[$score] = $sym if $score > 0;
    }

	# Get a diacritic spelling if wanted
	my $sub = @scores ? $#scores : 0;
	if ($self->{USEDCR}) {
		$scores[$sub] = score_diacrit($self, $scores[$sub], %comp);
	}

	return wantarray ? %scores : $scores[$sub];
} 

sub score_diacrit {
	my ($self, $symbol, %comp) = @_;

	# Don't try to diacriticize completely unmatched segments
	return '' if not $symbol;

	# Avoid warnings
	no warnings 'uninitialized';

	# Build hash of discrepancy
	my %disc = ();
	for (keys %comp) {
		$disc{$_} = $comp{$_} if $comp{$_} ne $self->{VALINDEX}->{$symbol}->{$_};
	}
	for (keys %{$self->{VALINDEX}->{$symbol}}) {
		$disc{$_} = $comp{$_} if $comp{$_} ne $self->{VALINDEX}->{$symbol}->{$_};
	}
		
	DIACRIT: for (@{$self->{DCRINDEX}}) {
		# Quit if there's no more discrepancy
		last if not keys %disc;

		my $dcr = $_; # No aliasing! otherwise s/// messes us up

        # Diacrits musn't disagree w/ comp segs at all
		my %proto = %{$self->{VALINDEX}->{$dcr}};
		for (keys %proto) {
            # Defined features compare normally
			if (defined $proto{$_}) {
				next DIACRIT if ($proto{$_} ne $disc{$_});
			}

            # Undefined features must be specifically mentioned in the
            # discrepancy hash (i.e. can't be simply missing keys
			else {
				next DIACRIT unless (exists $disc{$_}) and (not defined $disc{$_});
			}
		}

		# If you get here, you agree on all features, so you should be added

		# Don't allow anybody else to match your features
		delete $disc{$_} for keys %proto;

		# Add yourself to the beginning or ending, chopping the leading/trailing '*'
		if ($dcr =~ s/^\*//) {
			$symbol .= $dcr;
		}
		else {
			$dcr =~ s/\*$//;
			$symbol = $dcr . $symbol;
		}
	} 

	return $symbol;
}

sub prototype {
	my $self = shift;
	my $symbol = shift;
	my $proto;

	if ($symbol =~ /(^\*)|(\*$)/) {
		$proto = $self->{DIACRITS}->{$symbol};
	}
	else {
		$proto = $self->{SYMBOLS}->{$symbol};
	}

	return err("No such symbol '$symbol'") if (not $proto);
	$self->{REINDEX} = 1;
	return $proto;
}

sub segment {
	my $self = shift;

	# If you're not given a symbol, return a blank segment
	unless (@_) {
		my $ret = Lingua::Phonology::Segment->new( $self->features );
		$ret->symbolset($self);
		return $ret;
	}

	# Otherwise
	my @return;
	while (@_) {
		my $proto = $self->prototype( shift );
		return unless $proto;
		push @return, $proto->duplicate;
	} 
	return wantarray ? @return : $return[0];
}

sub features {
	my $self = shift;
	if (@_) {
		my $arg = shift;
		return carp "Bad argument to features()" unless _is_features($arg);
		$self->{FEATURES} = $arg;
	}
	return $self->{FEATURES};
}

1;

=head1 METHODS

=head2 new

    $symbol = Lingua::Phonology::Symbols->new($features);

Creates a new Symbols object. This method takes one argument, a Features 
object that provides the feature set for the prototypes in this object.
This will carp if you don't provide an appropriate object.

This method is called automatically when you make a C<new
Lingua::Phonology>.

=head2 add_symbol

    $symbol->add_symbol( 'b' => $b );

Adds one or more symbols to the current object. The argument to symbol must be
a hash. The keys of this hash are the text symbols that will be returned, and
the values should be Lingua::Phonology::Segment objects that act as the
prototypes for each symbol. See L<"spell"> for explanation of how these symbols
and protoypes are used.

Symbols can generally be any text string. However, strings beginning or ending
with '*' are interpreted specially, as diacritics. The position of the asterisk
indicates where the base symbol goes, and the rest is interpreted as the
diacritic. Diacritic prototypes are also treated differently from regular
prototypes--see the L<spell> section for details. For example, you could use a
tilde '~' following a symbol to indicate nasality with the following call to
symbol:

	# Assume $nasal is an appropriate prototye
	$symbols->add_symbol('*~' => $nasal);

Note that '*' by itself is still a valid, non-diacritic symbol. However, '**'
will be interpreted as a diacritic consisting of a symbol followed by a single
asterisk.

If you attempt to pass in a Lingua::Phonology::Segment object associated with a
feature set other than the one defined for the current object, C<add_symbol()>
will skip to the next symbol and emit a warning.

This method returns true if all of the attempted symbol additions succeeded,
and false otherwise.

=head2 symbol (deprecated)

Synonymous with C<add_symbol()>. This method is deprecated, and only exists
because of a poor naming choice in earlier versions of the module.

=head2 drop_symbol

    $symbols->drop_symbol('x');

Deletes a symbol from the current object. Nothing happens if you try to 
delete a symbol which doesn't currently exist.

=head2 change_symbol

    $symbols->change_symbol( 'b' => $b );

Acts exactly the same as C<add_symbol()>, but first checks to make sure that 
there already exists a symbol with the key given. Otherwise, it brings 
up an error.

The method C<add_symbol()> can also be used to redefine existing symbols, but
it first drops any existing symbol. In the present implementation this makes no
difference, so this method really only exists to aid readability and allow for
future expansion.

As with C<add_symbol()>, this method returns true if all of the attempted
changes succeeded, otherwise false.

=head2 features

    $features = $symbols->features();

Returns the Features object associated with the current object, or sets the
object if provided with a Lingua::Phonology::Features object as an argument.

=head2 prototype

    $proto = $symbols->prototype('b');

Takes one argument, a text string indicating a symbol in the current set.
Returns the prototype associated with that symbol, or carps if no 
such symbol is defined. You can then make changes to the prototype object,
which will be reflected in subsequent calls to spell().

=head2 segment

    # Get one segment
    $b = $symbols->segment('b');
    
	# Get several segments
	@word = $symbols->segment('b', 'a', 'n');

Takes one or more argument, a symbol, and return a new Segment object with the
feature values of the prototype for that symbol. Unlike L<prototype>, which
return the prototype itself, this method returns a completely new object which
can be modified without affecting the values of the prototype. If you supply a
list of symbols, you'll get back a list of segments in the same order. This is
generally the easiest way to make new segments with some features already set.
Example:

The segments returned from this method will be associated with the
Lingua::Phonology::Features object defined by C<features()> and the current
Lingua::Phonology::Symbols object.

=head2 reindex

    $symbols->reindex();

This function recompiles the internal index that Lingua::Phonology::Symbols
uses to speed up C<spell>ing. It should generally be unnecessary to call this
function, as Lingua::Phonology::Symbols does its best to figure out when
reindexing is necessary without any user input. You may call this function by
hand to ensure reindexing at a particular time, or if auto reindexing is off.

=head2 auto_reindex

    # Get the current state of auto-reindexing
    $auto_reindex = $symbols->auto_reindex();

    # Set the auto-reindexing flag
    $symbols->auto_reindex(0);

Returns true if automatic reindexing is currently turned on, false otherwise.
If called with an argument, sets auto reindexing to the truth or falsehood of
that argument. Auto reindexing is on by default.

=head2 set_auto_reindex

    $symbols->set_auto_reindex();

Turns automatic reindexing (back) on. Same as C<auto_reindex(1)>. Auto
reindexing is on by default, so this is only necessary after a call to
C<no_auto_reindex>. See L<"INDEXING">.

=head2 no_auto_reindex

    $symbols->no_auto_reindex();

Turns automatic reindexing off. Same as C<< auto_reindex(0) >>. See
L<"INDEXING">.

=head2 diacritics

    # Get the current diacritic flag
    $symbols->diacritics();

    # Set the diacritics flag
    $symbols->diacritics(1);

Returns true if diacritics are currently on, otherwise false. You may also pass
this method an argument to turn diacritics on or off, e.g. C<<
$symbols->diacritics(1) >>. Diacritics are off by default.

=head2 set_diacritics

    $symbols->set_diacritics();

Turns diacritics on. Same as C<< diacritics(1) >>.

=head2 no_diacritics

    $symbols->no_diacritics();

Turns diacritics off. Same as C<< diacritics(0) >>.

=head2 spell

    print $symbols->spell($seg);

Takes any number of Lingua::Phonology::Segment objects as arguments. For each
object, returns a text string indicating the best match of prototype with the
Segment given.  In a scalar context, returns a string consisting of a
concatencation of all of the symbols.

The Symbol object given will be compared against every prototype currently
defined, and scored according to the following algorithm:

=over 4

=item *

Score one point for every feature whose value is the same for both the
prototype and the comparison segments, whether that value is defined or not.

=item *

Lose one point for every feature that is defined for the prototype segment and
which the comparison segment disagrees with. 

=item *

Score zero points for each feature defined on the comparison segment but not
defined for the prototype.

=back

Comparison segments may always be more defined than the prototypes, so 
there is no consequence if the comparison segment is defined for features
that the prototype isn't defined for.

Note that this algorithm is slightly different from the one used in previous
versions. In my informal tests, about 95% of the segments come out the same,
but there is some discrepancy. My subjective impression is that the results
given by the new algorithm are better (more inuitive) than those from the
previous algorithm.

The 'winning' prototype is the one that scores the highest by the preceding
algorithm. If more than one prototype scores the same, it's unpredictable which
symbol will be returned, since it will depend on the order in which the
prototypes came out of the internal hash.

If C<diacritics> is on, diacritic formation happens after the best-matching
symbol is chosen. A list of the features for which the comparison segment and
symbol prototypes do not agree is compiled, and diacritics are selected that
match against those features. If there are diacritics that specify more than
one feature, or multiple diacritics specifying the same feature, then this
method will attempt to minimize the number of diacritics used. The diacritic
symbols will be concatenated with the base symbol, the base symbol taking the
place of the asterisk in the symbol definition. For example, if a segment
matched the base symbol 'a' and the diacritic '*~', the resulting symbol would
be 'a~'. If multiple diacritics are matched, there is no way to predict the
order in which they will be added, except that diacritics specifying multiple
features will appear closer to the base.

If no prototype scores at least 1 point by this algorithm, the string '_?_'
will be returned. This indicates that no suitable matches were found. No
diacritic matching is done in this case.

Beware of testing a Segment object that is associated with a different feature
set than the ones used by the prototypes. This will almost certainly cause
errors and bizarre results.

=head2 score

    %score = $symbols->score($seg);

Takes a Segment argument and compares it against the defined symbols, just like
symbol(). It normally returns a hash with the available symbols as the keys and
the score for each symbol as the value. In a scalar context, returns the
winning symbol just like spell(). Useful for debugging and determining why the
program thinks that [a] is better described as [d] (as happened to the author
during testing). Unfortunately, score() can only be used to test one segment at
a time, rather than a list of segments.

=head2 loadfile

    # Load symbol definitions from a file
    $symbols->loadfile('phono.xml');

    # Load default symbols
    $symbols->loadfile();

Takes one argument, a file name, and loads prototype segment definitions
from that file. If no file name is given, loads the default symbol set.

Files should be in the XML format described in
L<Lingua::Phonology::FileFormatPOD>. If the filename given does not parse
correctly, this method will fall back on C<old_loadfile()>, just in case this
is an old script using the deprecated custom file format. In this case, you
will get a warning. To avoid the warning, change the method call, or better yet
change your file over to the XML format.

=head2 old_loadfile (deprecated)

    # Load a file
    $symbols->old_loadfile('symbols.txt');

This method is deprecated. Use C<loadfile()> instead.

Takes one argument, a file name. Reads that file according to the format
described below and adds the symbols defined there to the current symbols
object. This method does NOT load default features when called without any
arguments.

Lines in the file should match the regular expression /^\s*(\S+)\t+(.*)/.
The first parenthesized sub-expression will be taken as the symbol, and the
second sub-expression as the feature definitions for the prototype. Feature
definitions are separated by spaces, and should be in one of three formats:

=over 4

=item *

B<feature>: The preferred way to set a privative value is simply to write the
name of the feature unadorned. Since privatives are either true or undef, this
is sufficient to declare the existence of a privative. E.g., since both
[labial] and [voice] are privatives in the default feature set, the following
line suffices to define the symbol 'b' (though you may want more specificity):

	b		labial voice

=item *

B<[+-*]feature>: The characters before the feature correspond to setting the
value to true, false, and undef, respectively. This is the preferred way to set
binary features, and the only way to assert that a feature of any type must be
undef. For example, the symbol 'd`' for a voiced retroflex stop can be defined
with the following line:

	d`		-anterior -distributed voice

=item *

B<feature=value>: Whatever precedes the equals sign is the feature name;
whatever follows is the value. This is the preferred way to set scalar values,
and the only way to set scalar values to anything other than undef, 0, or 1.

=back

Feature definitions may work if you use them other than as recommended, 
but the recommended forms are provided for maximum readability. To be 
exact, however, the following are synonymous:

	# Synonymous one way
	labial
	+labial
	labial=1

	# Synonymous in a different way
	-labial # only if 'labial' is binary
	labial=0

Since this behavior is partly dependent on the implementation of text and
number forms in the Features module, the synonymity of these forms is not
guaranteed to remain constant in the future. However, every effort will be
made the guarantee that the I<recommended> forms won't change their
behavior.

You may begin comments with '#'--anything between the first '#' on a line and
the end of that line will be ignored. Consequently, '#' cannot be used as a
symbol in a loaded file (though it is a valid symbol elsewhere, and can be
assigned via C<add_symbol()>).

As with C<add_symbol()>, symbol definitions beginning or ending with '*' will be
interpreted as diacritics. Diacritic symbols may be defined in exactly the same
way as regular symbols. Thus, to define a tilde as a diacritic for nasality,
you might use the following simple line:

	*~		nasal

You should only define terminal (non-node) features in your segment 
definitions. The loadfile method is unable to deal with features that
are nodes, and will generate errors if you try to assign to a node.

If you don't give a file name, then the default symbol set is loaded. This
is described in L<"THE DEFAULT SYMBOL SET">.

=head1 INDEXING

This section endeavors to explain the purpose of indexing in
Lingua::Phonology::Symbols, and how you can control it.

As of v0.2, this module uses an efficient hash comparison algorithm that
greatly speeds up calls to C<spell> and C<score>. This algorithm works by
compiling an index of the features and values that prototype segments have,
then only comparing against those prototypes that have some chance of winning.
Indexing itself is a somewhat costly procedure, but fortunately, it only needs
to be done once. Unfortunately, it needs to be done again any time that the
list of symbols or the prototypes for those symbols is changed.

Fortunately again, Lingua::Phonology::Symbols will take care of this for you.
Whenever a method is called that might require reindexing, an internal flag on
the object is set. The next time that you ask this module to C<spell>
something, it will first reindex, then proceed to spelling. The methods that
will trigger reindexing are C<add_symbol, drop_symbol, change_symbol, loadfile,
prototype>. This reindexing is done "just in time", and isn't done more than is
necessary.

Unfortunately, not all calls to those methods actually warrant reindexing, so
if you call those methods a lot, you might want to have manual control over
when the hash is reindexed. To do this, you can use the method
C<no_auto_reindex>, which will disable automatic reindexing. You then will have
to call C<reindex> yourself whenever it's warranted. If you get tired of this
and want reindexing back, you can call C<set_auto_reindex>.

The author of this module has never felt the need to work with auto reindexing
off, for what it's worth.

=head1 THE DEFAULT SYMBOL SET

Currently, Lingua::Phonology::Symbols comes with a set of symbols that can
be loaded by calling loadfile with no arguments, like so:

	$symbols->loadfile;

The symbol set thus loaded is based on the X-SAMPA system for encoding the IPA
into ASCII. You can read more about X-SAMPA at
L<http://www.phon.ucl.ac.uk/home/sampa/x-sampa.htm>. The default does not
contain all of the symbols in X-SAMPA, but it does contain a lot of them, plus
a few extra symbols for IPA characters not covered in X-SAMPA. These symbols are:

    # Consonants
    # Labials
    p   voiceless labial stop
    b   voiced labial stop
    f   voiceless labiodental fricative
    v   voiced labiodental fricative
    m   labial nasal

    # Dentals
    t   voiceless dental stop
    d   voiced dental stop
    T   voiceless dental fricative
    D   voiced dental fricative
    s   voiceless alveolar fricative
    z   voiced alveolar fricative
    n   alveolar nasal
    l   alveolar lateral
    r   alveolar rhotic

    # Postalveolars
    tS  voiceless postalveolar stop
    dZ  voiced postalveolar stop
    S   voiceless postalveolar fricative
    Z   voiced postalveolar fricative

    # Retroflex
    t`  voiceless retroflex stop
    d`  voiced retroflex stop
    s`  voiceless retroflex fricative
    z`  voiced retroflex fricative
    n`  retroflex nasal
    l`  retroflex lateral
    r`  retroflex rhotic

    # Palatal
    c   voiceless palatal stop
    d\  voiced palatal stop
    C   voiceless palatal fricative
    j\  voiced palatal fricative
    J   palatal nasal
    L   palatal lateral

    # Velar
    k   voiceless velar stop
    g   voiced velar stop
    x   voiceless velar fricative
    G   voiced velar fricative
    N   velar nasal

    # Uvular
    q   voiceless uvular stop
    G\  voiced uvular stop
    X   voiceless uvular fricative
    R   voiced uvular fricative
    N\  uvular nasal
    R\  uvular rhotic

    # Pharyngeal
    q\  voiceless pharyngeal stop
    X\  voiceless pharyngeal fricative
    ?\  voiced pharyngeal fricative

    # Glottal
    ?   voiceless glottal stop
    h   voicelesss glottal fricative
    h\  voiced glottal fricative

    # Vowels
    # High Front Vowels
    i   high front tense
    I   high front
    y   high front rounded tense
    Y   high front rounded
    j   high front semivowels
    H   high front rounded semivowel

    # High Back Vowels
    u   high back rounded tense
    U   high back rounded
    M   high back unrounded
    w   high back rounded semivowel

    # High Central Vowels
    1   high central
    }   high central rounded

    # Mid Front Vowels
    e   mid front tense
    E   mid front
    2   mid front rounded tense
    9   mid front rounded

    # Mid Back Vowels
    o   mid back rounded tense
    O   mid back rounded
    W   mid back unrounded tense
    V   mid back unrounded

    # Mid Central Vowels
    @   mid central
    8   mid central rounded

    # Low Vowels
    a   low
    Q   low rounded

    # Diacritics
    ~   nasal
    _l  lateral
    _v  voiced
    _0  voiceless
    _h  aspirated (spread)
    _~  creaky voice (constricted)
    _w  labialized
    _d  laminalized
    _G  velarized
    _?  pharyngealized

The symbols are defined with the following XML structure, which you can use as
a model if you need to write your own symbols definition:

    <phonology>
      <symbols>
        
        <!-- Consonants -->

        <!-- Labials -->
        <symbol label="p">
          <feature value="0" name="continuant" />
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="b">
          <feature value="1" name="voice" />
          <feature value="0" name="continuant" />
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="f">
          <feature value="1" name="continuant" />
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="v">
          <feature value="1" name="voice" />
          <feature value="1" name="continuant" />
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="m">
          <feature value="1" name="sonorant" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
          <feature value="1" name="labial" />
        </symbol>

        <!-- Dentals and alveolars -->
        <symbol label="t">
          <feature value="1" name="anterior" />
          <feature value="0" name="continuant" />
        </symbol>
        <symbol label="d">
          <feature value="1" name="voice" />
          <feature value="1" name="anterior" />
          <feature value="0" name="continuant" />
        </symbol>
        <symbol label="T">
          <feature value="1" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>
        <symbol label="D">
          <feature value="1" name="voice" />
          <feature value="1" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>
        <symbol label="s">
          <feature value="1" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="z">
          <feature value="1" name="voice" />
          <feature value="1" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="n">
          <feature value="1" name="sonorant" />
          <feature value="1" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
        </symbol>
        <symbol label="l">
          <feature value="1" name="lateral" />
          <feature value="1" name="sonorant" />
          <feature value="1" name="anterior" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="r">
          <feature value="1" name="sonorant" />
          <feature value="1" name="anterior" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Postalveolar -->
        <symbol label="tS">
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>
        <symbol label="dZ">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>
        <symbol label="S">
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>
        <symbol label="Z">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="distributed" />
        </symbol>

        <!-- Retroflex -->
        <symbol label="t`">
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="d`">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="s`">
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="z`">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="n`">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
          <feature value="0" name="distributed" />
        </symbol>
        <symbol label="l`">
          <feature value="1" name="lateral" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="0" name="distributed" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="r`">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="0" name="distributed" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Palatal -->
        <symbol label="c">
          <feature value="0" name="continuant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="d\">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="C">
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="j\">
          <feature value="1" name="voice" />
          <feature value="0" name="anterior" />
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="J">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="L">
          <feature value="1" name="lateral" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="approximant" />
          <feature value="1" name="dorsal" />
        </symbol>

        <!-- Velar -->
        <symbol label="k">
          <feature value="0" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="g">
          <feature value="1" name="voice" />
          <feature value="0" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="x">
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="G">
          <feature value="1" name="voice" />
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="N">
          <feature value="1" name="sonorant" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
          <feature value="1" name="dorsal" />
        </symbol>

        <!-- Uvular -->
        <symbol label="q">
          <feature value="1" name="pharyngeal" />
          <feature value="0" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="G\">
          <feature value="1" name="voice" />
          <feature value="1" name="pharyngeal" />
          <feature value="0" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="X">
          <feature value="1" name="pharyngeal" />
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="R">
          <feature value="1" name="voice" />
          <feature value="1" name="pharyngeal" />
          <feature value="1" name="continuant" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="N\">
          <feature value="1" name="sonorant" />
          <feature value="1" name="pharyngeal" />
          <feature value="0" name="continuant" />
          <feature value="1" name="nasal" />
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="R\">
          <feature value="1" name="sonorant" />
          <feature value="1" name="pharyngeal" />
          <feature value="1" name="approximant" />
          <feature value="1" name="dorsal" />
        </symbol>

        <!-- Pharyngeal -->
        <symbol label="q\">
          <feature value="1" name="pharyngeal" />
          <feature value="0" name="continuant" />
        </symbol>
        <symbol label="X\">
          <feature value="1" name="pharyngeal" />
          <feature value="1" name="continuant" />
        </symbol>
        <symbol label="?\">
          <feature value="1" name="voice" />
          <feature value="1" name="pharyngeal" />
          <feature value="1" name="continuant" />
        </symbol>

        <!-- Glottal -->
        <symbol label="?">
          <feature value="*" name="Place" />
          <feature value="0" name="continuant" />
        </symbol>
        <symbol label="h">
          <feature value="*" name="Place" />
          <feature value="1" name="continuant" />
        </symbol>
        <symbol label="h\">
          <feature value="*" name="Place" />
          <feature value="1" name="voice" />
          <feature value="1" name="continuant" />
        </symbol>


        <!-- Vowels -->
        <!-- High Front Vowels -->
        <symbol label="i">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="I">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="y">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="Y">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="j">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="*" name="nucleus" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="H">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="*" name="nucleus" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
          <feature value="1" name="labial" />
        </symbol>

        <!-- High Back Vowels -->
        <symbol label="u">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="U">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="M">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="w">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="*" name="nucleus" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="labial" />
        </symbol>

        <!-- High Central Vowels -->
        <symbol label="1">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="}">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="0" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Mid Front Vowels -->
        <symbol label="e">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="E">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="2">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="approximant" />
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="9">
          <feature value="1" name="sonorant" />
          <feature value="0" name="anterior" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="approximant" />
          <feature value="1" name="labial" />
        </symbol>

        <!-- Mid Back Vowels -->
        <symbol label="o">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="O">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="W">
          <feature value="1" name="tense" />
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="V">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="dorsal" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Mid Central Vowels -->
        <symbol label="@">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="8">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="1" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Low Vowels -->
        <symbol label="a">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="2" name="aperture" />
          <feature value="1" name="approximant" />
        </symbol>
        <symbol label="Q">
          <feature value="1" name="sonorant" />
          <feature value="1" name="vocoid" />
          <feature value="2" name="aperture" />
          <feature value="1" name="labial" />
          <feature value="1" name="approximant" />
        </symbol>

        <!-- Diacritics -->
        <symbol label="*~">
          <feature value="1" name="nasal" />
        </symbol>
        <symbol label="*_?\">
          <feature value="1" name="pharyngeal" />
        </symbol>
        <symbol label="*_v">
          <feature value="1" name="voice" />
        </symbol>
        <symbol label="*_h">
          <feature value="1" name="spread" />
        </symbol>
        <symbol label="*_w">
          <feature value="1" name="labial" />
        </symbol>
        <symbol label="*_l">
          <feature value="1" name="lateral" />
        </symbol>
        <symbol label="*_~">
          <feature value="1" name="constricted" />
        </symbol>
        <symbol label="*_G">
          <feature value="1" name="dorsal" />
        </symbol>
        <symbol label="*_0">
          <feature value="*" name="voice" />
        </symbol>
        <symbol label="*_d">
          <feature value="1" name="distributed" />
        </symbol>

      </symbols>
    </phonology>


These symbols depend upon the default feature set. If you aren't using the
default feature set, you're on your own. If you've modified the default
feature set, these may still work, though you'll probably have to tweak
them. YMMV.

=head1 SEE ALSO

Lingua::Phonology, Lingua::Phonology::Features

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut

__DATA__

<phonology>
  <symbols>
    
    <!-- Consonants -->

    <!-- Labials -->
    <symbol label="p">
      <feature value="0" name="continuant" />
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="b">
      <feature value="1" name="voice" />
      <feature value="0" name="continuant" />
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="f">
      <feature value="1" name="continuant" />
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="v">
      <feature value="1" name="voice" />
      <feature value="1" name="continuant" />
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="m">
      <feature value="1" name="sonorant" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
      <feature value="1" name="labial" />
    </symbol>

    <!-- Dentals and alveolars -->
    <symbol label="t">
      <feature value="1" name="anterior" />
      <feature value="0" name="continuant" />
    </symbol>
    <symbol label="d">
      <feature value="1" name="voice" />
      <feature value="1" name="anterior" />
      <feature value="0" name="continuant" />
    </symbol>
    <symbol label="T">
      <feature value="1" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>
    <symbol label="D">
      <feature value="1" name="voice" />
      <feature value="1" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>
    <symbol label="s">
      <feature value="1" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="z">
      <feature value="1" name="voice" />
      <feature value="1" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="n">
      <feature value="1" name="sonorant" />
      <feature value="1" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
    </symbol>
    <symbol label="l">
      <feature value="1" name="lateral" />
      <feature value="1" name="sonorant" />
      <feature value="1" name="anterior" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="r">
      <feature value="1" name="sonorant" />
      <feature value="1" name="anterior" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Postalveolar -->
    <symbol label="tS">
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>
    <symbol label="dZ">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>
    <symbol label="S">
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>
    <symbol label="Z">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="distributed" />
    </symbol>

    <!-- Retroflex -->
    <symbol label="t`">
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="d`">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="s`">
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="z`">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="n`">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
      <feature value="0" name="distributed" />
    </symbol>
    <symbol label="l`">
      <feature value="1" name="lateral" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="0" name="distributed" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="r`">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="0" name="distributed" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Palatal -->
    <symbol label="c">
      <feature value="0" name="continuant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="d\">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="C">
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="j\">
      <feature value="1" name="voice" />
      <feature value="0" name="anterior" />
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="J">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="L">
      <feature value="1" name="lateral" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="approximant" />
      <feature value="1" name="dorsal" />
    </symbol>

    <!-- Velar -->
    <symbol label="k">
      <feature value="0" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="g">
      <feature value="1" name="voice" />
      <feature value="0" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="x">
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="G">
      <feature value="1" name="voice" />
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="N">
      <feature value="1" name="sonorant" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
      <feature value="1" name="dorsal" />
    </symbol>

    <!-- Uvular -->
    <symbol label="q">
      <feature value="1" name="pharyngeal" />
      <feature value="0" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="G\">
      <feature value="1" name="voice" />
      <feature value="1" name="pharyngeal" />
      <feature value="0" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="X">
      <feature value="1" name="pharyngeal" />
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="R">
      <feature value="1" name="voice" />
      <feature value="1" name="pharyngeal" />
      <feature value="1" name="continuant" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="N\">
      <feature value="1" name="sonorant" />
      <feature value="1" name="pharyngeal" />
      <feature value="0" name="continuant" />
      <feature value="1" name="nasal" />
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="R\">
      <feature value="1" name="sonorant" />
      <feature value="1" name="pharyngeal" />
      <feature value="1" name="approximant" />
      <feature value="1" name="dorsal" />
    </symbol>

    <!-- Pharyngeal -->
    <symbol label="q\">
      <feature value="1" name="pharyngeal" />
      <feature value="0" name="continuant" />
    </symbol>
    <symbol label="X\">
      <feature value="1" name="pharyngeal" />
      <feature value="1" name="continuant" />
    </symbol>
    <symbol label="?\">
      <feature value="1" name="voice" />
      <feature value="1" name="pharyngeal" />
      <feature value="1" name="continuant" />
    </symbol>

    <!-- Glottal -->
    <symbol label="?">
      <feature value="*" name="Place" />
      <feature value="0" name="continuant" />
    </symbol>
    <symbol label="h">
      <feature value="*" name="Place" />
      <feature value="1" name="continuant" />
    </symbol>
    <symbol label="h\">
      <feature value="*" name="Place" />
      <feature value="1" name="voice" />
      <feature value="1" name="continuant" />
    </symbol>


    <!-- Vowels -->
    <!-- High Front Vowels -->
    <symbol label="i">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="I">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="y">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="Y">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="j">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="*" name="nucleus" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="H">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="*" name="nucleus" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
      <feature value="1" name="labial" />
    </symbol>

    <!-- High Back Vowels -->
    <symbol label="u">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="U">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="M">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="w">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="*" name="nucleus" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="labial" />
    </symbol>

    <!-- High Central Vowels -->
    <symbol label="1">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="}">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="0" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Mid Front Vowels -->
    <symbol label="e">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="E">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="2">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="approximant" />
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="9">
      <feature value="1" name="sonorant" />
      <feature value="0" name="anterior" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="approximant" />
      <feature value="1" name="labial" />
    </symbol>

    <!-- Mid Back Vowels -->
    <symbol label="o">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="O">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="W">
      <feature value="1" name="tense" />
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="V">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="dorsal" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Mid Central Vowels -->
    <symbol label="@">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="8">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="1" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Low Vowels -->
    <symbol label="a">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="2" name="aperture" />
      <feature value="1" name="approximant" />
    </symbol>
    <symbol label="Q">
      <feature value="1" name="sonorant" />
      <feature value="1" name="vocoid" />
      <feature value="2" name="aperture" />
      <feature value="1" name="labial" />
      <feature value="1" name="approximant" />
    </symbol>

    <!-- Diacritics -->
    <symbol label="*~">
      <feature value="1" name="nasal" />
    </symbol>
    <symbol label="*_?\">
      <feature value="1" name="pharyngeal" />
    </symbol>
    <symbol label="*_v">
      <feature value="1" name="voice" />
    </symbol>
    <symbol label="*_h">
      <feature value="1" name="spread" />
    </symbol>
    <symbol label="*_w">
      <feature value="1" name="labial" />
    </symbol>
    <symbol label="*_l">
      <feature value="1" name="lateral" />
    </symbol>
    <symbol label="*_~">
      <feature value="1" name="constricted" />
    </symbol>
    <symbol label="*_G">
      <feature value="1" name="dorsal" />
    </symbol>
    <symbol label="*_0">
      <feature value="*" name="voice" />
    </symbol>
    <symbol label="*_d">
      <feature value="1" name="distributed" />
    </symbol>

  </symbols>
</phonology>
