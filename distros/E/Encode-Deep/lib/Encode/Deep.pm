package Encode::Deep;

use 5.006;
use strict;
use warnings;

=head1 NAME

Encode::Deep - Encode or decode each element of a reference and it's sub-references.

=head1 VERSION

Version 0.01

=cut

use Carp qw(croak);
use Encode ();
use base 'Exporter';

our $VERSION = '0.01';
our %EXPORT_TAGS = (
	all => [qw(encode decode encode_inplace decode_inplace)],
);
our @EXPORT_OK = (map {@$_} values %EXPORT_TAGS);

=pod

=head1 SYNOPSIS

Apply any encoding on a reference and all references within the parent.

Supports hash, array and scalar reference but no blessed references (objects),
croaks on unknown refrences.

Perhaps a little code snippet.

    use Encode::Deep;

    Encode::Deep::encode($encoding, $reference);

    Encode::Deep::decode($encoding, $reference);

=head1 OTHER CHOICES

L<Deep::Encode> is also on CPAN but can't handle circular references while this module
recreates them as copies to new circular references. L<Deep::Encode> does it's changes
in-place modifying the original reference which might be what you want or not.

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 encode

    $copy_ref = Encode::Deep::encode($encoding, $ref);

Walks through the given $ref and runs Encode::encode($encoding, $value) for every
non-reference value.

See L<Encode::encode> for more information about the encode call being used for recoding.

Returns a deep copy of the original reference meaning that every value and reference
will be copied.

=cut

sub encode {
	my $encoding = shift;
	my $ref = shift;

	return _walk(
		$ref,
		sub { return Encode::encode($encoding, shift); },
		{},
	);
}

=pod

=head2 decode

    $copy_ref = Encode::Deep::decode($encoding, $ref);

Walks through the given $ref and runs Encode::decode($encoding, $value) for every
non-reference value.

See L<Encode::decode> for more information about the decode call being used for recoding.

Returns a deep copy of the original reference meaning that every value and reference
will be copied.

=cut

sub decode {
	my $encoding = shift;
	my $ref = shift;

	return _walk(
		$ref,
		sub { return Encode::decode($encoding, shift); },
		{},
	);
}

### INTERNAL FUNCTIONS

sub _walk {
	my $ref = shift;
	my ($sub, $ref_map) = @_;

	# Convert values
	return &$sub($ref) unless ref($ref);

	# Handle circular references
	return $ref_map->{$ref} if $ref_map->{$ref};

	if (ref($ref) eq 'SCALAR') {
		my $new_value; # create new SCALAR
		$ref_map->{$ref} = \$new_value; # Add to list of known references
		$new_value = _walk($$ref, @_);
		return \$new_value;
	}

	if (ref($ref) eq 'ARRAY') {
		my @new_array; # create new ARRAY
		$ref_map->{$ref} = \@new_array; # Add to list of known references
		@new_array = map { _walk($_, @_); } @$ref;
		return \@new_array;
	}

	if (ref($ref) eq 'HASH') {
		my %new_hash; # create new HASH
		$ref_map->{$ref} = \%new_hash; # Add to list of known references
		# Convert hash keys directly because hash keys can't contain working references
		%new_hash = map { &$sub($_) => _walk($ref->{$_}, @_); } keys %$ref;
		return \%new_hash;
	}

	croak('Unknown refernce '.$ref.' of type '.ref($ref));
}

=pod

=head1 AUTHOR

Sebastian Willing, C<< <sewi at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-encode-deep at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Encode-Deep>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Encode::Deep


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Encode-Deep>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Sebastian Willing, eGENTIC Systems L<http://egentic-systems.com/karriere/>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Encode::Deep
