package HTML::FormHandlerX::Widget::Field::Template;

use v5.10;

use strict;
use warnings;

our $VERSION = 'v0.1.1';

# ABSTRACT: render fields using templates


use Moose::Role;

use Types::Standard -types;

use namespace::autoclean;

has template_renderer => (
    is      => 'ro',
    isa     => CodeRef,
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        $self->form->template_renderer;
    },
);

has template_args => (
    is        => 'rw',
    predicate => 'has_template_args',
);

sub render {
    my ( $self, $result ) = @_;
    $result ||= $self->result;
    die "No result for form field '"
      . $self->full_name
      . "'. Field may be inactive."
      unless $result;

    my $form = $self->form;

    my %args;

    if ( my $method = $form->can('template_args') ) {
        $form->$method( $self, \%args );
    }

    if ( $self->has_template_args ) {
        $self->template_args->( $self, \%args );
    }

    if ( my $method = $form->can( 'template_args_' . $self->name ) ) {
        $form->$method( \%args );
    }

    return $self->template_renderer->( { %args, field => $self } );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandlerX::Widget::Field::Template - render fields using templates

=head1 VERSION

version v0.1.1

=head1 SYNOPSIS

In a form class:

  has_field foo => (
    widget        => 'Template',
    template_args => sub {
      my ($field, $args) = @_;
      ...
    },
  );

  sub template_renderer {
    my ( $self, $field ) = @_;

    return sub {
        my ($args) = @_;

        my $field = $args->{field};

        ...

    };
  }

=head1 DESCRIPTION

This is an L<HTML::FormHandler> widget that allows you to use a
template for rendering forms instead of Perl methods.

=head1 SEE ALSO

=over

=item *

L<HTML::FormHandler>

=item *

L<Template>

=back

=head1 SOURCE

The development version is on github at L<https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template>
and may be cloned from L<git://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template.git>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/robrwo/HTML-FormHandlerX-Widget-Field-Template/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library L<https://www.sciencephoto.com>.

=head1 CONTRIBUTOR

=for stopwords Mohammad S Anwar

Mohammad S Anwar <mohammad.anwar@yahoo.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by Robert Rothenberg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
