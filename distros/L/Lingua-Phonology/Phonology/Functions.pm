#!/usr/bin/perl

package Lingua::Phonology::Functions;

=head1 NAME

Lingua::Phonology::Functions

=head1 SYNOPSIS

	use Lingua::Phonology;
	use Lingua::Phonology::Functions qw/:all/;

=head1 DESCRIPTION

Lingua::Phonology::Functions contains a suite of functions that can be
exported to make it easier to write linguistic rules. I hope to have a
function here for each broad, sufficiently common linguistic process. So if
there are any missing here that you think should be included, feel free to
contact the author.

=cut

use strict;
use warnings;
use Carp;
use warnings::register;
use Lingua::Phonology::Common;

require Exporter;
our @ISA = qw/Exporter/;

our @EXPORT_OK = qw(
	assimilate
	flat_assimilate
	adjoin
	flat_adjoin
	copy
	flat_copy
	dissimilate
	change
	metathesize
	metathesize_feature
	delete_seg
	insert_after
	insert_before
);
our %EXPORT_TAGS = (all => \@EXPORT_OK);

our $VERSION = 0.21;

sub err ($) { _err($_[0]) if warnings::enabled() };

# Join two segments for a feature
sub assimilate {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;
	$seg2->delink($feature);
	$seg2->$feature( $seg1->value_ref($feature) );
}

# Synonym
*adjoin = \&assimilate;

# Copy vals but not references
sub copy {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;
	$seg2->delink($feature);
	$seg2->$feature( $seg1->$feature );
}

# Assimilate only the top value of a feature
sub flat_assimilate {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;
	my @rv = $seg1->value_ref($feature);
	$seg2->value_ref($feature, $rv[0]);
}
*flat_adjoin = \&flat_assimilate;

# Same, but copy
sub flat_copy {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;
	my @rv = $seg1->$feature;
	$seg2->$feature($rv[0]);
}
		
# Make two segs disagree
sub dissimilate {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;
	$seg1->$feature ? $seg2->$feature(\0) : $seg2->$feature(\1);
	return $seg2->$feature;
}

# Change a segment into a symbol
sub change {
	my ($seg, $sym) = @_;
	return unless _is_seg $seg;
	$seg->delink($_) for keys %{$seg->all_values};
	my %new_vals = $seg->symbolset->prototype($sym)->all_values;
	$seg->$_($new_vals{$_}) for (keys %new_vals);
	return 1;
}

# Switch the position of two segments
sub metathesize {
	my ($seg1, $seg2) = @_;
    # This will ensure that we get the right kind of segs
	return unless _is_ruleseg $seg1 && _is_ruleseg $seg2;

    # Decide which direction we're going
    if ($seg1->_RULE->{direction} eq 'rightward') {
        $seg1->INSERT_LEFT($seg2->duplicate);
        $seg2->clear;
    } 
    elsif ($seg1->_RULE->{direction} eq 'leftward') {
        $seg2->INSERT_RIGHT($seg1->duplicate);
        $seg1->clear;
    } 
	return 1;
}

# Switch the feature of two segments
sub metathesize_feature {
	my ($feature, $seg1, $seg2) = @_;
	return unless _is_seg $seg1 && _is_seg $seg2;

    # Capture existing vals
	my @temp1 = $seg1->$feature;
	my @temp2 = $seg2->$feature;
    $seg1->delink($feature);
    $seg2->delink($feature);

    # Switcheroo
	$seg1->$feature(@temp2);
	$seg2->$feature(@temp1);
}

# Delete a seg
sub delete_seg {
	return unless _is_seg $_[0];
	$_[0]->clear;
}

# Insert a seg after a seg
sub insert_after {
	my ($seg1, $seg2) = @_;
	return unless _is_ruleseg $seg1 && _is_seg $seg2;
	$seg1->INSERT_RIGHT($seg2);
}

# Insert a seg before a seg
sub insert_before {
	my ($seg1, $seg2) = @_;
	return unless _is_ruleseg $seg1 && _is_seg $seg2;
	$seg1->INSERT_LEFT($seg2);
}

__END__

=head1 FUNCTIONS

Lingua::Phonology::Functions does not provide an object-oriented interface
to its functions. You may either call them with their package name
(C<Lingua::Phonology::Functions::assimilate()>), or you may import the
functions you wish to use by providing their names as arguments to C<use>.
You may import all functions with the argument ':all' (as per the Exporter standard).

	Lingua::Phonology::Functions::assimilate();        # If you haven't imported anything
	use Lingua::Phonology::Functions qw(assimilate);   # Import just assimilate()
	use Lingua::Phonology::Functions qw(:all);          # Import all functions

I have tried to keep the order of arguments consistent between all of the
functions. In general, the following hold:

=over 4

=item *

If a feature name is needed for a function, that is the I<first> argument.

=item *

If more than one segment is given as an argument to a function, the first
segment will act upon the second segment. That is, some feature from the
first segment will be assimilated, copied, dissimilated, etc. to the second
segment.

=back

Through these function descriptions, C<$feature> is the name of some
feature in the current Lingua::Phonology::Features object, and
C<$segment1>, C<$segment2> . . . C<$segmentN> are
Lingua::Phonology::Segment objects depending on that same Features object.

=head2 assimilate

	assimilate($feature, $segment1, $segment2);

Assimilates $segment2 to $segment1 on $feature. This does a recursive
assimilation, so that all children of $feature are also assimilated. This also
does a "deep" assimilation, copying the reference from $segment1 to $segment2
so that future modifications of this feature for either segment will be
reflected on both segments.  If you don't want this, use C<copy()> instead.

The new value of the feature is returned.

=head2 adjoin

	adjoin($feature, $segment1, $segment2);

This function is synonymous with C<assimilate()>. It is provided only to
aid readability.

=head2 copy

	copy($feature, $segment1, $segment2);

Copies the value of $feature from $segment1 to $segment2, recursively so that
all children of $feature are also copied. This does a "shallow" copy, copying
the value but not the underlying reference, so that $segment1 and $segment2 can
vary independently after the feature value is copied. Returns the new value of
the feature.

=head2 flat_assimilate

	flat_assimilate($feature, $segment1, $segment2);

Assimilates the value of $feature from $segment1 to $segment2 non-recursively.
This will cause the values for $feature to be references to the same value for
both segments, but will not affect any of children of $feature for either
segment.

=head2 flat_adjoin

	flat_adjoin($feature, $segment1, $segment2);

Identical to L<C<flat_assimilate>>. Provided only for readability.

=head2 flat_copy

	flat_copy($feature, $segment1, $segment2);

Copies the value of $feature from $segment1 to $segment2 non-recursively. This
will cause the numerical value of $feature to be the same for both segments,
but will not make them have references to the same data, nor will it affect the
children of $feature.

=head2 dissimilate

	dissimilate($feature, $segment1, $segment2);

Dissimilates $segment2 from $segment1 on $feature, or something like it.  If
$segment1->value($feature) is true, then this attempts to assign 1 to
$segment2->$feature. If $segment1->value($feature) is false, this attempts to
assign 0. The actual value that is subsequently returned will depend on the
type of $feature. The new value of $segment2->$feature will be returned.

If $segment1 and $segment2 currently have a reference to the same value for
$feature, $segment2 will be assigned a new reference, breaking the connection
between the two segments.

=head2 change

	change($segment1, $symbol);

This function changes $segment1 to $symbol, where $symbol is a text string
indicating a symbol in the symbol set associated with $segment1. If
$segment1 doesn't have a symbol set associated with it, this function will
fail.

=head2 metathesize

	metathesize($segment1, $segment2);

This function swaps the order of $segment1 and $segment2. Returns true on
success, false on failure.

$segment1 MUST be the first of the two segments, or else this function may
result in a non-terminating loop as the same two segments are swapped
repeatedly. (The exact behavior of this depends on the implementation of
Lingua::Phonology::Rules, which is not a fixed quantity. But things should be
okay if you heed this warning.)

The assumption here is that $segment1 and $segment2 are adjacent segments in
some word currently being processed by Lingua::Phonology::Rules, since the
notion of "segment order" has little meaning outside of this context. Thus,
this function assumes that the INSERT_RIGHT() and INSERT_LEFT() methods are
available (which is only true during a Lingua::Phonology::Rules evaluation),
and will raise errors if this isn't so.

Note that the segments won't actually be switched until after the current
C<do> code reference closes, so you can't make changes to the metathesized
segments immediately after changing them and have the segments be where you
expect them.

=head2 metathesize_feature

	metathesize_feature($feature, $segment1, $segment2);

This function swaps the value of $feature for $segment1 with the value of
$feature for $segment2, and returns the new value of $segment2->$feature.

=head2 delete_seg

	delete_seg($segment1);

Deletes $segment1. This is essentially a synonym for calling C<<
$segment1->clear >>.

=head2 insert_after

	insert_after($segment1, $segment2);

This function inserts $segment2 after $segment1 in the current word.  Like
L<"metathesize">, this function assumes that it is being called as part of
the C<do> property of a Lingua::Phonology::Rules rule, so any environment
other than this will probably raise errors.

=head2 insert_before

	insert_before($segment1, $segment2);

This function inserts $segment2 before $segment1, just like insert_after().
The same warnings that apply to insert_after() apply to this function.

=head1 SEE ALSO

L<Lingua::Phonology>, L<Lingua::Phonology::Rules>,
L<Lingua::Phonology::Features>, L<Lingua::Phonology::Segment>

=head1 AUTHOR

Jesse S. Bangs <F<jaspax@cpan.org>>.

=head1 LICENSE

This module is free software. You can distribute and/or modify it under the
same terms as Perl itself.

=cut
