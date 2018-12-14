use strict;

package HTML::FormFu::Exception;
# ABSTRACT: Exception base class
$HTML::FormFu::Exception::VERSION = '2.07';
use Moose;

with 'HTML::FormFu::Role::Populate';

use HTML::FormFu::ObjectUtil qw( form parent );

sub BUILD { }

sub render_data {
    my $self = shift;

    my $render = $self->render_data_non_recursive( { @_ ? %{ $_[0] } : () } );

    return $render;
}

sub render_data_non_recursive {
    my ( $self, $args ) = @_;

    my %render = (
        parent => $self->parent,
        form   => $self->form,
        $args ? %$args : (),
    );

    return \%render;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Exception - Exception base class

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
