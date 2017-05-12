package JavaScript::Code::Number;

use strict;
use vars qw[ $VERSION ];
use base
  qw[ JavaScript::Code::Type JavaScript::Code::Expression::Node::Arithmetic ];

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Number - A JavaScript Number Type

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::Code::Number;

    my $number = JavaScript::Code::String->new( value => 42 );

    print $number->output;

=head1 METHODS

See also the L<JavaScript::Code::Type> documentation.

=cut

=head2 $self->type( )

=cut

sub type {
    return "Number";
}

=head2 $self->output( )

=cut

sub output {
    my ($self) = @_;

    my $value = $self->value;
    $value += 0;    # make sure it is a number

    return "$value";
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
