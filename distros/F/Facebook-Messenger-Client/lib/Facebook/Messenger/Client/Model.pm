package Facebook::Messenger::Client::Model;

use Moose;

use MooseX::Storage;

with Storage();

around 'pack' => sub {
	my $orig = shift();
	my $self = shift();

	my $result = $self->$orig( @_ );
	delete( $result->{__CLASS__} );

	return $result;
};

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Facebook::Messenger::Client::Model -

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

Tudor Marghidanu <tudor@marghidanu.com>

=head1 SEE ALSO

=over 4

=item *

L<Moose>

=item *

L<Mojolicious>

=back

=head1 LICENSE

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
