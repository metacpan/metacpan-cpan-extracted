use strict;

package HTML::FormFu::Transformer::Callback;
$HTML::FormFu::Transformer::Callback::VERSION = '2.07';
# ABSTRACT: Callback transformer

use Moose;
use MooseX::Attribute::Chained;
extends 'HTML::FormFu::Transformer';

has callback => ( is => 'rw', traits => ['Chained'] );

sub transformer {
    my ( $self, $value, $params ) = @_;

    my $callback = $self->callback || sub {1};

    ## no critic (ProhibitNoStrict);
    no strict 'refs';

    my $return = $callback->( $value, $params );

    return $return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Transformer::Callback - Callback transformer

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    $field->transformer('Callback')->callback( \&my_transformer );

    ---
    elements:
      - type: Text
        name: foo
        transformers:
          - type: Callback
            callback: "main::my_transformer"

=head1 DESCRIPTION

The first argument passed to the callback is the submitted value for the
associated field. The second argument passed to the callback is a hashref of
name/value pairs for all input fields.

=head1 METHODS

=head2 callback

Arguments: \&code-reference

Arguments: "subroutine-name"

=head1 SEE ALSO

Is a sub-class of, and inherits methods from L<HTML::FormFu::Transformer>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
