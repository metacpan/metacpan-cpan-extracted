package Facebook::Messenger::Client::Text;

use Moose;

extends 'Facebook::Messenger::Client::Model';

has 'text' => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

__PACKAGE__->meta()->make_immutable();

1;

__END__

=pod

=head1 NAME

Facebook::Messenger::Client::Text -

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
