package Form::Factory::Interface::HTML::Widget;
$Form::Factory::Interface::HTML::Widget::VERSION = '0.022';
use Moose::Role;

requires qw( render_control consume_control );

# ABSTRACT: rendering/consuming HTML controls


has alternate_renderer => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_alternate_renderer',
);


has alternate_consumer => (
    is        => 'rw',
    isa       => 'CodeRef',
    predicate => 'has_alternate_consumer',
);


sub render {
    my $self     = shift;

    if ($self->has_alternate_renderer) {
        return $self->alternate_renderer->($self, @_);
    }
    else {
        return $self->render_control(@_);
    }
}


sub consume {
    my $self = shift;

    if ($self->has_alternate_consumer) {
        $self->alternate_consumer->($self, @_);
    }
    else {
        $self->consume_control(@_);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML::Widget - rendering/consuming HTML controls

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Widget is the low-level API for rendering and processing HTML/HTTP form elements.

=head1 ATTRIBUTES

=head2 alternate_renderer

If the renderer needs to be customized, provide a custom renderer here. This is a code reference that is passed the control and options like the usual renderer method.

=head2 alternate_consumer

If the control needes to be consumed in a custom way, you can add that here. This is a code reference that is passed the control and options like the usual consumer method.

=head1 METHODS

=head2 render

Renders the HTML required to use this method.

=head2 consume

Consumes the value from the request.

=head1 ROLE METHODS

These methods must be implemented by role implementers.

=head2 render_control

Return HTML to render the control.

=head2 consume_control

Given consumer options, process the input.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
