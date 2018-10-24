package Form;

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler';

use Template;

has '+name' => ( default => 'b', );

has template => (
    is      => 'ro',
    lazy    => 1,
    default => sub { Template->new },
);

has_field a => (
    type          => 'Checkbox',
    default       => 2,
    widget        => 'Template',
    template_args => sub {
        my ( $field, $args ) = @_;
        $args->{field_method} = $field->name;
    }
);

sub template_args {
    my ( $self, $field, $args ) = @_;
    $args->{form_method} = $field->name;
}

sub template_args_a {
    my ( $self, $args ) = @_;
    $args->{form_method_a} = $self->name;
}

sub template_path {
    my ( $self, $field ) = @_;
    return 't/etc/' . $field->name . '.tt';
}

sub template_renderer {
    my ( $self, $field ) = @_;

    return sub {
        my ($args) = @_;
        $self->template->process( $self->template_path( $args->{field} ),
            $args, \my $output );
        return $output;
    };
}

1;
