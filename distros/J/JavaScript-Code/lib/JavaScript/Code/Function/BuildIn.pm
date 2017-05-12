package JavaScript::Code::Function::BuildIn;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Function ];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Function::BuildIn - JavaScript Build-In Functions

=head1 METHODS

=cut

=head2 is_buildin

=cut

sub is_buildin { return 1; }

=head2 return

The return function.

=cut

sub return {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    return $class->new( name => 'return' );
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

1;
