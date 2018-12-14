use strict;

package HTML::FormFu::Role::Element::ProcessOptionsFromModel;
# ABSTRACT: process_options_from_model role
$HTML::FormFu::Role::Element::ProcessOptionsFromModel::VERSION = '2.07';
use Moose::Role;

sub _process_options_from_model {
    my ($self) = @_;

    my $args = $self->model_config;

    return if !$args || !keys %$args;

    return if @{ $self->options };

    # don't run if {options_from_model} is set and is 0

    my $option_flag
        = exists $args->{options_from_model}
        ? $args->{options_from_model}
        : 1;

    return if !$option_flag;

    $self->options(
        [ $self->form->model->options_from_model( $self, $args ) ] );

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::Element::ProcessOptionsFromModel - process_options_from_model role

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
