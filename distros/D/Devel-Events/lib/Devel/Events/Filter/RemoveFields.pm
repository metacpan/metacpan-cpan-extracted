package Devel::Events::Filter::RemoveFields;
# vim: set ts=2 sw=2 noet nolist :
# ABSTRACT: Remove certain fields from events
our $VERSION = '0.10';
use Moose;

with qw/Devel::Events::Filter/;

has fields => (
	isa => "ArrayRef",
	is  => "ro",
	required   => 1,
	auto_deref => 1,
);

has _fields_hash => (
	isa  => "HashRef",
	is   => "ro",
	lazy => 1,
	default => sub {
		my $self = shift;
		return { map { $_ => undef } $self->fields };
	}
);

sub filter_event {
	my ( $self, $type, @data ) = @_;

	my $fields = $self->_fields_hash;
	
	my @ret;
	while ( @data ) {
		my ( $key, $value ) = splice( @data, 0, 2 );
		push @ret, $key, $value unless exists $fields->{$key};
	}

	return ( $type, @ret );
}


__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Events::Filter::RemoveFields - Remove certain fields from events

=head1 VERSION

version 0.10

=head1 SYNOPSIS

	use Devel::Events::Filter::RemoveFields;

	my $f = Devel::Events::Filter::RemoveFields->new(
		fields => [qw/generator/],
		handler => $h,
	);

	# all events delivered to $f will be proxied to $h without any 'generator'
	# field.

	# field order and multiple instances of a field won't be affected

=head1 DESCRIPTION

This simple filter will remove all instances of a certain field in an event.

=head1 ATTRIBUTES

=over 4

=item fields

An array reference.

Tbe list of fields to remove from the event data.

=back

=head1 METHODS

=over 4

=item filter_event @event

Removes the fields specified in C<fields> from the event data.

=back

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Events>
(or L<bug-Devel-Events@rt.cpan.org|mailto:bug-Devel-Events@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
