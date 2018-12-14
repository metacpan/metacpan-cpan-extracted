use strict;

package HTML::FormFu::Exception::Validator;
# ABSTRACT: Validator exception
$HTML::FormFu::Exception::Validator::VERSION = '2.07';
use Moose;
extends 'HTML::FormFu::Exception::Input';

sub stage {
    return 'validator';
}

sub validator {
    return shift->processor(@_);
}

around render_data_non_recursive => sub {
    my ( $orig, $self, $args ) = @_;

    my $render = $self->$orig(
        {   stage     => $self->stage,
            validator => $self->validator,
            $args ? %$args : (),
        } );

    return $render;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Exception::Validator - Validator exception

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
