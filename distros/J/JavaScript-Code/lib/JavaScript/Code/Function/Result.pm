package JavaScript::Code::Function::Result;

use strict;
use vars qw[ $VERSION ];
use base qw[
  JavaScript::Code::Accessor
  JavaScript::Code::Value
];
use JavaScript::Code::Function::Result::Element ();

use overload
  '""' => sub { shift->output };

__PACKAGE__->mk_accessors(qw[ value ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Function::Result - A JavaScript Function Result

=head1 METHODS

=head2 $self->output( )

=cut

sub output {
    return shift->value;
}

=head2 $self->as_element( )

Returns a the result as a L<JavaScript::Code::Function::Result::Element> object.

=cut

sub as_element {
    my $self = shift;

    my $retval = JavaScript::Code::Function::Result::Element->new();
    $retval->value( $self );

    return $retval;
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
