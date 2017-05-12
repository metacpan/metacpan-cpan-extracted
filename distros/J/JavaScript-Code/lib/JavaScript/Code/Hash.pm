package JavaScript::Code::Hash;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Type ];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Element - A JavaScript Hash

=head1 DESCRIPTION

=head1 METHODS

=head2 new

=head2 $self->type( )

=cut

sub type {
    return "Hash";
}

=head2 $self->output( )

=cut

sub output {
    die "Not yet implemented.";
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
