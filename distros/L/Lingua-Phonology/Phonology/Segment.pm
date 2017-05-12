#!/usr/bin/perl -w

package Lingua::Phonology::Segment;

=head1 NAME

Lingua::Phonology::Segment - a module to represent a segment as a bundle
of feature values.

=head1 SYNOPSIS

	use Lingua::Phonology;
	$phono = new Lingua::Phonology;

	# Define a feature set
	$features = $phono->features;
	$features->loadfile;

	# Make a segment
	$segment = $phono->segment;

	# Set some values
	$segment->labial(1);
	$segment->continuant(0);
	$segment->voice(1);
    # Segment is now voiced labial stop, i.e. [b]

	# Reset the segment
	$segment->clear;

=head1 DESCRIPTION

A Lingua::Phonology::Segment object provides a programmatic representation
of a linguistic segment. Such a segment is associated with a
Lingua::Phonology::Features object that lists the available features and
the relationships between them. The segment itself is a list of the values
for those features. This module provides methods for returning and setting
these feature values. A segment may also be associated with a
Lingua::Phonology::Symbols object, which allows the segment to return the
symbol that it best matches. 

=cut

use strict;
use warnings;
use warnings::register;
use Lingua::Phonology::Common;
use Lingua::Phonology::Features;
use constant {
    REF => 0,
    NUM => 1,
    TXT => 2
};

# Magical stuff:
# Automatically spell segments in string context
use overload 
    # The fun stuff
    '""' => sub { defined $_[0]->{SYMBOLS} ? $_[0]->spell : overload::StrVal($_[0]) },
    'cmp' => sub { 
        my ($l, $r, $swap) = @_;
        if ($swap) { return "$r" cmp "$l" }
        else { return "$l" cmp "$r" } },
    
    # A rediculous hack to return the non-overloaded number value. In theory,
    # '0+' => sub { $_[0] } *should* do this, but it makes the debugger
    # segfault.  This procedure is borrowed from overload.pm itself.
    '0+' => sub { 
        my $package = ref $_[0]; 
        bless $_[0], 'my::Fake'; 
        my $rv = int $_[0]; 
        bless $_[0], $package; 
        return $rv },
    'fallback' => 1;

our $VERSION = 0.3;

sub err ($) { warnings::warnif(shift); return; }

# New segment
sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = {
		FEATURES => undef,
		SYMBOLS => undef,
		WANT => REF, #  REF, NUM, or TXT
		VALUES   => { }
	};

	my $featureset = shift; # An object in class Features
	my $values = shift; # A hashref

    # When an object method, copy feature and symbol settings
	if (ref $proto) {
		$self->{FEATURES} = $featureset || $proto->{FEATURES};
		$self->{SYMBOLS} = $proto->{SYMBOLS};
	}

    # When a class method
	else {
		$self->{FEATURES} = $featureset;
	}

	# Require a $featureset of the proper type
	return err("No featureset (or bad featureset) given for new $class") unless _is_features($self->{FEATURES});

	# Gesundheit
	bless $self, $class;

	# Set initial values
	$self->value_ref($_, $values->{$_}) for keys %$values;

	return $self;
} 

sub featureset {
	my $self = shift;
	if (@_) {
		return err("Bad feature set") unless _is_features($_[0]);
        $self->{FEATURES} = shift;
	}
	return $self->{FEATURES};
}

sub symbolset {
	my $self = shift;
	if (@_) {
		return err("Bad symbol set") unless _is_symbols($_[0]);
        $self->{SYMBOLS} = shift;
	}
	return $self->{SYMBOLS};
}

# These functions locally set WANT, so that the structure generated in
# value_ref() can be built the right way the first time

sub value {
	my $self = shift;
	local $self->{WANT} = NUM;
	$self->value_ref(@_);
}

sub value_text {
	my $self = shift;
	local $self->{WANT} = TXT;
	$self->value_ref(@_);
}

sub value_ref {
	my ($self, $feature, $val, $hash) = @_;
	return unless $self->{FEATURES}->feature($feature);

	# Assign primary values, checking the size of @_ because $val could be
	# undef. Skip this part if $val is undef and we have 4 args
	if (@_ > 2 and not (@_ > 3 and not defined $val)) {

		# If given a plain scalar ref, replace the old ref
		if (ref($val) eq 'SCALAR') {
            # This errs if $$val is not an lvalue
            eval {
                $$val = $self->{FEATURES}->number_form($feature, $$val);
            };

            # ...in which case we work around
            if ($@) {
                my $nval = $self->{FEATURES}->number_form($feature, $$val);
                $self->{VALUES}->{$feature} = \$nval;
            }
            else {
                $self->{VALUES}->{$feature} = $val;
            }
		} 

		# Otherwise, change the val via the current ref
		else {
			$val = $self->{FEATURES}->number_form($feature, $val);

			# If this feature is already defined, assign via existing ref
			if (my $ref = $self->{VALUES}->{$feature}) {
				$$ref = $val;
			} 
			
			# If it's not defined, assign as a ref
			else {
				$self->{VALUES}->{$feature} = \$val;
			} 

		} 
	}

	# Assign child values
	HASH: if (@_ > 3 && defined $hash) {
		unless (_is($hash, 'HASH')) {
			err("Third argument to value() must be a hash reference");
			last HASH;
		}

        # Get children that are also in our hash (implicitly ignoring bad children in $hash)
		for (grep { exists $hash->{$_} } $self->{FEATURES}->children($feature)) {
			# For pairs like $feature => [ $val, { child vals } ]
			if (_is($hash->{$_}, 'ARRAY')) {
				$self->value_ref($_, @{$hash->{$_}});
			}

			# For pairs like $feature => $val
			else {
				$self->value_ref($_, $hash->{$_});
			}
		}
	}

	# Quit in void context
	return if not defined wantarray;

	# Find the return value or a ref to undef
	my $retval = $self->{VALUES}->{$feature} || \undef;
	{
		# Less strictness here for when $retval is undef
		#no strict 'refs';
		#no warnings 'uninitialized';

		if ($self->{WANT} == TXT) {
			$retval = $self->{FEATURES}->text_form($feature, $$retval);
		}
		elsif ($self->{WANT} == NUM) {
			$retval = $$retval;
		}
	}

    # Return these in scalar context
	if (not wantarray) {
        # Return the actual value if the feature is defined
		return $retval if exists $self->{VALUES}->{$feature} && defined ${$self->{VALUES}->{$feature}};

        # Otherwise return the child hashref
		return $self->_children($feature);
	}

	# Get the hashref to return if we want an array
    my $rethash = $self->_children($feature);
    return $retval => $rethash; # if (defined $rethash || defined $retval);

    # When everything's undef
	return;
}

# Build a hashref of child values, or undef if you're childless
sub _children {
	my ($self, $feature) = @_;
	my $rethash = {};

    # Nodes w/ children
	if (my @kids = $self->{FEATURES}->children($feature)) {
		for (@kids) {
			my ($val, $kids) = $self->value_ref($_);
			if (defined $val || defined $kids) {
				$rethash->{$_} = [ $val, $kids ];
			}
		}
	}

    # Terminal nodes
	else {
		return;
	}

    # Nodes with no defined children
	return if not keys %$rethash;

    # Normal case
	return $rethash;
}

sub delink {
	my $self = shift;
	my @return = ();
	for (@_) {
		push @return, delete($self->{VALUES}->{$_});
		push @return, $self->delink($self->{FEATURES}->children($_));
	}
	return @return;
} 

sub all_values {
	my $self = shift;

	# Get the real values for each feature
    my %h = map { $_ => ${$self->{VALUES}->{$_}} } keys %{$self->{VALUES}};
    return wantarray ? %h : \%h;
} 

sub spell {
	my ($self) = @_;

	return err "No symbol set defined for spell()" if not $self->{SYMBOLS};
    return $self->{SYMBOLS}->spell($self);
}

sub duplicate {
	my $self = shift;
	return $self->new(undef, { $self->all_values });
} 

sub clear {
	my $self = shift;
	$self->{VALUES} = {};
	return 1;
} 

# Allows you to call changes to feature settings directly
# with syntax like $segment->feature_name($value)
our $AUTOLOAD;
sub AUTOLOAD {
	my $feature = $AUTOLOAD;
	$feature =~ s/.*:://;
    my $self = shift;

    no strict 'refs';
    *$feature = sub {
        my $self = splice @_, 0, 1, $feature;
        $self->value(@_);
    };

	$self->$feature(@_);
} 

sub DESTROY {}

1;

__END__

=head1 OVERLOADING

As of Lingua::Phonology v0.32 (Lingua::Phonology::Segment v0.4), string
conversion of segments is overloaded. When you use a Lingua::Phonology::Segment
in string context, the C<spell()> method is automatically called, and the
representation of the segment from the current symbolset is returned. String
comparison operators (C<cmp eq ne lt le gt ge>) are also overloaded. Therefore,
the following work correctly, assuming that you have a Lingua::Phonology object
correctly set up in C<$phono>.

    my ($b, $k) = $phono->symbols->segment('b', 'k');

    print "Segments: $b, $k\n";                  # Prints "Segments: b, k";
    print "$b is greater than $k\n" if $b gt $k; # Won't print
    print "$b is less than $k\n" if $b lt $k;    # Prints 'b is less than k';
    print "$b is equal to $k\n" if $b eq $k;     # Won't print

    my $b2 = $b->duplicate;
    print "$b is equal to $b2\n" if $b eq $b2    # Prints 'b is equal to b';

Note that stringification is not overloaded if the C<symbolset> is not properly
set. However, it turns on as soon as a symbolset is available:

    my $b = Lingua::Phonology::Segment->new($features);
    $b->voice(1);
    $b->labial(1);

    print "$b\n";             # Prints 'Lingua::Phonology::Segment=HASH(0x88af598)'
                              # or something similar, because there is no symbolset
                              # defined for spelling the segment.

    $b->symbolset($symbols);
    print "$b\n";             # Prints 'b'

Number conversion is not overloaded.

=head1 METHODS

=head2 new

	my $seg = Lingua::Phonology::Segment->new($features);
	my $new_seg = $seg->new();

When called as a class method, this method takes one argument, a
Lingua::Phonology::Features object. The Features object provides the list of
available features. If no such object is provided, this method will carp and
return undefined. When called as an object method, the featureset may be
omitted, in which case the feature set from the calling object will be
provided. When called as an object method, C<new()> does not copy the features
values of the calling object, only the feature set. To create a complete
duplicate of the calling object, use L<"duplicate">.

In either case, a second argument may be provided, which must be a hash
reference. If this argument exists, it must contain C<< feature => value >>
pairs used to initialize the segment. If you call this as an object method and
do not wish to provide a Features object, you need to include an C<undef> as a
place-holder. For example:

	my $seg = Lingua::Phonology::Segment->new($features, { foo => 1, bar => 0 });
	my $new_seg = $seg->new(undef, { foo => 1, bar => 0 });

=head2 featureset

    $features = $seg->featureset();
    $seg->featureset($new_features);

Returns the Lingua::Phonology::Features object currently associated with the
segment. May be called with one argument, a Lingua::Phonology::Features object,
in which case the current feature set is set to the object provided.

=head2 symbolset

    $symbols = $seg->symbolset();
    $seg->symbolset($new_symbols);

Returns a Lingua::Phonology::Symbols object currently associated with the
segment. You may call this method with one argument, in which case the symbol
set is set to that argument.

=head2 value

Takes one, two, or three arguments. The first argument must be the name of a
feature, the second argument, if any, is the value to set the feature to, and
the third argument is a hash reference naming values to pass on to children of
the feature.

Most of the time you will only use the first two arguments. This can usually be
as simple as the following:

	# Retrieve this segment's value for $feature
	$val = $seg->value($feature);

	# Set this segment's value for $feature to $val
	$seg->value($feature, $val);

Note that the second argument passed to value() is passed through the
number_form() method in Lingua::Phonology::Features before it is assigned. This
has the effect of taking whatever number or text value you passed in and
changing it into a numeric representation appropriate for the type of the
feature you are assigning to. Read the L<Lingua::Phonology::Features>
documentation for details on this transformation.

If you give a scalar reference as the second argument, then additional magic
happens. This is discussed below in L<"value_ref">;

Everything beyond this point is probably not necessary for you, and potentially
very confusing. You have been warned.

With the third value, things get more complex. The third argument must be a
hash reference. In its simplest form, you may simply specify C<< feature =>
value >> pairs for the children you wish to assign to.  For example, the
following sets [Coronal] itself to 1, and sets the child features [anterior] to
1 and [distributed] to 0:

	$seg->value('Coronal', 1, { anterior => 1, distributed => 0 });

However, if you also want to assign to children of those children
(grandchildren), then the values of the feature => value pairs must be array
references. The first element in the array reference is the value assigned, and
the second element must be a hash reference containing feature => value pairs
just like those above. (This is identical to the arguments to value() itself,
but with the final two arguments turned into an array reference.) For example,
the following sets Lingual to 1, [labial] to 1, and Coronal and its
children to the same values as shown in the previous example:

	$seg->value('Lingual', 1, { labial => 1,
	                                Coronal => [ 1 , { anterior => 1, distributed => 0 } ]
								  }
	);

This gets awkward pretty quickly, and we don't imagine you'll do it much. The
three-argument form of value() exists mostly so that the following always works
correctly and makes $seg1 and $seg2 equal for [feature] and all children of
[feature]:

    $seg1->value('feature', $seg2->value('feature'));

There is a special exception made for when you call value() with three
arguments, the second of which is undefined. Normally if the second argument to
value() is undefined, the value for the feature is explicitly set to undef, and
a key representing this fact will appear in subsequent calls to all_values().
However, in cases like the one just illustrated, it is often necessary to add
C<undef> as a placeholder, so in this situation the value() method assumes that
this is the case and doesn't attempt to assign C<undef> as a value. (This is an
exception, but it's almost always what you want).

The return value of value() in scalar context is the value of the feature
itself, UNLESS that value is undefined, in which case a hash reference with
feature => value pairs conforming to the description above is returned. If no
children of the feature in question are defined either, this also returns undef
(rather than returning an empty hash reference). 

In list context, two values are returned: the value of the feature, and a hash
reference containing feature => value pairs as described above. If there would
be no keys in the hash or if all children of the feature are undefined, undef
is returned instead. In the case of a feature that is undefined and has no
defined children, a list of two undefs is returned. This behavior is designed
so that the return value of any call to value() can be the argument to another
call and have the effect of setting the features in question to be identical.
Like so:

	$seg1->value('feature', $seg2->value('feature'));

This makes $seg1 and $seg2 identical for 'feature' and its descendants. This
behavior also mimics the default behavior of nodes from previous versions, so
that backwards compatibility is disrupted as little as possible.

=head2 value_text

    $text = $seg->value_text('feature');

This method is equivalent to C<value()>, and takes the same arguments.
However, the return from value() is first passed through the C<text_form()>
function of Lingua::Phonology::Features and then returned. For details on this
conversion see L<Lingua::Phonology::Features>.

=head2 value_ref

    $ref = $seg->value_ref('feature');

This method is identical in arguments to value(), taking a feature name as the
first argument and a value as the optional second argument. However, it returns
a scalar reference rather than a real value. Why? Read on:

Internally, all of the values for a Segment object are stored as scalar
references rather than direct values. When you call value(), all of the
referencing and dereferencing is done for you, so you never have to think about
this. However, at times it may be useful to cause two or more Segments to have
references to the same value, in which case you may use the value_ref() method
to return the reference from one of the objects.  If the value that you give to
value(), value_text(), or value_ref() is a scalar reference, then rather than
setting the value that the current reference points to, the current reference
will be replaced by the reference you provided. This can cause two segments to
"share" a feature, so that changes made to one segment automatically appear on
the other. This example should make things clearer:

	# Assume you have a Lingua::Phonology::Features object called $features with the default feature set
	$seg1 = Lingua::Phonology::Segment->new($features);
	$seg2 = Lingua::Phonology::Segment->new($features);

	# If we assign direct values, the segments can vary independently
	$seg1->value('voice', 1); 
	$seg2->value('voice', $seg1->value('voice'));	  # $seg2->value('voice') also returns 1
	$seg1->value('voice', 0);                         
    # Now $seg1 return 0 for [voice], but $seg2 still returns 1

	# If we assign references, then the segments are linked to each other for that value
	$seg1->value('voice', 1');
	$seg2->value('voice', $seg1->value_ref('voice')); # $seg2 now returns 1 for voice
	$seg1->value('voice', 0);
    # Now both $seg1 and $seg2 return 0 for voice, because they both internally
    # reference the same value

    # To break the connection between segments, pass one of them a new
    # reference.
    $seg1->value('voice', \1);
    # Now $seg1 returns 1, and $seg2 returns 0

As this example illustrates, any of the value_*() functions can be passed
any kind of argument (numeric, textual, or reference). The functions only
differ in what their return value is.

=head2 Calling feature names as methods

You can also return and set values to a segment by using the name of a feature
as a method. This is usually easier and more readable than using value(). The
following are exactly synonymous:

	$seg1->value('voice', 1);
	$seg1->voice(1);

Calling a feature-name method like this is always equivalent to calling
C<value()>, and never equivalent to calling C<value_text()> or C<value_ref()>.

WARNING: If you use a feature name that is the same as a reserved word
(function or operator) in Perl, you can cause a non-terminating loop, due to
the implementation of autoloaded functions. Use the longer form with value()
instead.

=head2 delink

Takes a list of arguments, which are names of feature, and removes the
values for those features from the segment. The values for those features
will subsequently be undefined. This method does not affect the value that
the internal reference points to, so other segments that may be pointing to
the same value are unaffected. For example:

	$seg1->voice('1);
	$seg2->voice($seg1->value_ref('voice')); # $seg1 and $seg2 refer to the same value

	$seg2->voice(undef);                     # now both $seg1 and $seg2 will return 'undef' for voice

	$seg1->voice(1);                         # both will now return 1
	$seg2->delink('voice');                  # now $seg2 returns 'undef', but $seg1 returns 1

As an additional effect, the hash returned from L<"all_values"> will
include a key-value pair like C<< feature => undef >> if you assign an undef to
a value, as in line 4 above, while if you use delink(), no key for the 
deleted feature will appear at all.

Calling delink() on a feature with children causes all children of the feature
to be delinked recursively. This is the only way to reliably undefine a feature
and all of its children.

In scalar context, this method returns the number of items that were delinked.
In list context, it returns a list of the former values of the features that
were delinked. If you are delinking a feature with children you will get a list
of the values of the children of that feature, in a consistent but not
predictable order.

=head2 all_values

    %values = $seg->all_values();
    $values = $seg->all_values();

Takes no arguments. In list context, returns a hash with feature names as its
keys and feature values as its values. In scalar context returns similar hash
reference. The feature names present in the hash or hash reference will be
those that have defined values for the segment, or those features that were
explicitly set to be undef (as opposed to being C<delink>ed).

=head2 spell

    print $seg->spell();

Takes no arguments. Returns a text string indicating the symbol that the
current segment best matches if a Lingua::Phonology::Symbols object has been
defined via C<symbolset()>. Returns undef and prints an error if C<symbolset()>
has not been set.

=head2 duplicate

    $seg2 = $seg->duplicate();

Takes no arguments. Returns a new Lingua::Phonology::Segment object that is an
identical deep copy of the current object. The new segment will have all of the
same feature values as the original segment, but does NOT share any
references--the two segments will be able to diverge completely independently.

=head2 clear

    $seg->clear();

Takes no arguments. Clears all values from the segment. Calling
L<"all_values">() after calling clear() will return an empty hash.

=head1 BUGS

A bug in the implementation of overloading can cause infinite loops and
segmentation faults when using the debugger with Lingua::Phonology::Segment.

=head1 SEE ALSO

L<Lingua::Phonology::Features>, L<Lingua::Phonology::Symbols>

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut
