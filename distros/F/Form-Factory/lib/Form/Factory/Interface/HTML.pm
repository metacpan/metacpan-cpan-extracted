package Form::Factory::Interface::HTML;
$Form::Factory::Interface::HTML::VERSION = '0.022';
use Moose;

with qw( Form::Factory::Interface );

use Carp ();
use Scalar::Util qw( blessed );

use Form::Factory::Interface::HTML::Widget::Div;
use Form::Factory::Interface::HTML::Widget::Input;
use Form::Factory::Interface::HTML::Widget::Label;
use Form::Factory::Interface::HTML::Widget::List;
use Form::Factory::Interface::HTML::Widget::ListItem;
use Form::Factory::Interface::HTML::Widget::Select;
use Form::Factory::Interface::HTML::Widget::Span;
use Form::Factory::Interface::HTML::Widget::Textarea;

# ABSTRACT: Simple HTML form interface


has renderer => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { sub { print @_ } },
);


has consumer => (
    is        => 'ro',
    isa       => 'CodeRef',
    required  => 1,
    default   => sub { sub { $_[0] } },
);


sub new_widget_for_control {
    my $self    = shift;
    my $control = shift;
    my $results = shift;

    my $control_type = blessed $control;
    my ($name) = $control_type =~ /^Form::Factory::Control::(\w+)$/;
    return unless $name;
    $name = lc $name;

    my @alerts;
    @alerts = _alerts_for_control($control->name, $name, $results)
        if $results;

    my $method = 'new_widget_for_' . $name;
    return $self->$method($control, @alerts) if $self->can($method);
    return;
}

sub _wrapper($$@) {
    my ($name, $type, @widgets) = @_;

    return Form::Factory::Interface::HTML::Widget::Div->new(
        id      => $name . '-wrapper',
        classes => [ qw( widget wrapper ), $type ],
        widgets => \@widgets,
    );
}

sub _label($$$;$) {
    my ($name, $type, $label, $is_required) = @_;

    return Form::Factory::Interface::HTML::Widget::Label->new(
        id      => $name . '-label',
        classes => [ qw( widget label ), $type ],
        for     => $name,
        content => $label . _required_marker($is_required),
    );
}

sub _required_marker($) {
    my ($is_required) = @_;
    
    if ($is_required) {
        return Form::Factory::Interface::HTML::Widget::Span->new(
            classes => [ qw( required ) ],
            content => '*',
        )->render;
    }
    else {
        return '';
    }
}

sub _input($$$;$%) {
    my ($name, $type, $input_type, $value, %args) = @_;

    return Form::Factory::Interface::HTML::Widget::Input->new(
        id      => $name,
        name    => $name,
        type    => $input_type,
        classes => [ qw( widget field ), $type ],
        value   => $value || '',
        %args,
    );
}

sub _alerts($$@) {
    my ($name, $type, @items) = @_;

    return Form::Factory::Interface::HTML::Widget::List->new(
        id      => $name . '-alerts',
        classes => [ qw( widget alerts ), $type ],
        items   => \@items,
    );
}

sub _alerts_for_control {
    my ($name, $type, $results) = @_;
    my @items;

    my $count = 0;
    my @messages = $results->field_messages($name);
    for my $message (@messages) {
        push @items, Form::Factory::Interface::HTML::Widget::ListItem->new(
            id      => $name . '-message-' . ++$count,
            classes => [ qw( widget message ), $type, $message->type ],
            content => $message->english_message,
        );
    }

    return @items;
}


sub new_widget_for_button {
    my ($self, $control) = @_;

    return _input($control->name, 'button', 'submit', $control->label);
}


sub new_widget_for_checkbox {
    my ($self, $control, @alerts) = @_;

    return _wrapper($control->name, 'checkbox', 
        _input($control->name, 'checkbox', 'checkbox', $control->true_value, 
            checked => $control->is_true || ''),
        _label($control->name, 'checkbox', $control->label),
        _alerts($control->name, 'checkbox', @alerts),
    );
}


sub new_widget_for_fulltext {
    my ($self, $control, @alerts) = @_;

    return _wrapper($control->name, 'full-text',
        _label($control->name, 'full-text', $control->label, 
            $control->has_feature('required')),
        Form::Factory::Interface::HTML::Widget::Textarea->new(
            id      => $control->name,
            name    => $control->name,
            classes => [ qw( widget field full-text ) ],
            content => $control->current_value,
        ),
        _alerts($control->name, 'full-text', @alerts),
    );
}


sub new_widget_for_password {
    my ($self, $control, @alerts) = @_;

    return _wrapper($control->name, 'password',
        _label($control->name, 'password', $control->label,
            $control->has_feature('required')),
        _input($control->name, 'password', 'password', $control->current_value),
        _alerts($control->name, 'password', @alerts),
    );
}


sub new_widget_for_selectmany {
    my ($self, $control, @alerts) = @_;

    my @checkboxes;
    for my $choice (@{ $control->available_choices }) {
        push @checkboxes, _input(
            $control->name, 'select-many choice', 'checkbox', 
            $choice->value, checked => $control->is_choice_selected($choice),
        );
    }

    return _wrapper($control->name, 'select-many',
        _label($control->name, 'select-many', $control->label,
            $control->has_feature('required')),
        Form::Factory::Interface::HTML::Widget::Div->new(
            id      => $control->name . '-list',
            classes => [ qw( widget list select-many ) ],
            widgets => \@checkboxes,
        ),
        _alerts($control->name, 'select-many', @alerts),
    );
}


sub new_widget_for_selectone {
    my ($self, $control, @alerts) = @_;

    return _wrapper($control->name, 'select-one',
        _label($control->name, 'select-one', $control->label,
            $control->has_feature('required')),
        Form::Factory::Interface::HTML::Widget::Select->new(
            id       => $control->name,
            name     => $control->name,
            classes  => [ qw( widget field select-one ) ],
            size     => 1,
            available_choices => $control->available_choices,
            selected_choices  => [ $control->current_value ],
        ),
        _alerts($control->name, 'select-one', @alerts),
    );
}


sub new_widget_for_text {
    my ($self, $control, @alerts) = @_;

    return _wrapper($control->name, 'text',
        _label($control->name, 'text', $control->label,
            $control->has_feature('required')),
        _input($control->name, 'text', 'text', $control->current_value),
        _alerts($control->name, 'text', @alerts),
    );
}


sub new_widget_for_value {
    my ($self, $control, @alerts) = @_;

    if ($control->is_visible) {
        return _wrapper($control->name, 'value',
            _label($control->name, 'value', $control->label),
            Form::Factory::Interface::HTML::Widget::Span->new(
                id      => $control->name,
                content => $control->value,
                classes => [ qw( widget field value ) ],
            ),
            _alerts($control->name, 'text', @alerts),
        );
    }

    return;
}


sub render_control {
    my ($self, $control, %options) = @_;

    my $widget = $self->new_widget_for_control($control, $options{results});
    return unless $widget;
    $self->renderer->($widget->render);
}


sub consume_control {
    my ($self, $control, %options) = @_;

    Carp::croak("no request option passed") unless defined $options{request};

    my $widget = $self->new_widget_for_control($control);
    return unless defined $widget;

    my $params = $widget->consume( params => $self->consumer->($options{request}) );

    return unless defined $params->{ $control->name };

    $control->current_value( $params->{ $control->name } );
}



__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML - Simple HTML form interface

=head1 VERSION

version 0.022

=head1 SYNOPSIS

  use Form::Factory;

  my $q = CGI->new;
  my $html = '<form>';

  my $form = Form::Factory->new(HTML => {
      renderer => sub { $html .= join('', @_) },
      consumer => sub { shift->Vars },
  });

  my $action = $form->new_action('MyApp::Action::Foo');
  $action->consume_and_clean_and_check_and_process( request => $q );
  $action->render;

  $html .= '</form>';

  print $q->header('text/html');
  print $html;

=head1 DESCRIPTION

This renders plain HTML forms and consumes value from a hash.

=head1 ATTRIBUTES

=head2 renderer

This is a code reference responsible for printing the HTML elements. The HTML for the controls is passed to this subroutine as a string. The default implementation just prints to the screen.

  sub { print @_ }

=head2 consumer

This is a code reference responsible for taking the request object and turning it into a hash reference of values passed in from the HTTP request. The value passed in is the value passed as the C<request> parameter to L<Form::Factory::Action/consume>.

=head1 METHODS

=head2 new_widget_for_control

Returns a L<Form::Factory::Interface::HTML::Widget> implementation for the given control.

=head2 new_widget_for_button

Returns a widget for a L<Form::Factory::Control::Button>.

=head2 new_widget_for_checkbox

Returns a widget for a L<Form::Factory::Control::Checkbox>.

=head2 new_widget_for_fulltext

Returns a widget for a L<Form::Factory::Control::FullText>.

=head2 new_widget_for_password

Returns a widget for a L<Form::Factory::Control::Password>.

=head2 new_widget_for_selectmany

Returns a widget for a L<Form::Factory::Control::SelectMany>.

=head2 new_widget_for_selectone

Returns a widget for a L<Form::Factory::Control::SelectOne>.

=head2 new_widget_for_text

Returns a widget for a L<Form::Factory::Control::Text>.

=head2 new_widget_for_value

Returns a widget for a L<Form::Factory::Control::Value>.

=head2 render_control

Renders the widget for the given control.

=head2 consume_control

Consumes values using the widget for the given control.

=head1 CAVEATS

When I initially implemented this, using the widget classes made sense. However, the API has changed in some subtle ways since then. Originally, widgets were a required piece of the factory API, but they are not anymore. As such, they don't make nearly as much sense as they once did.

They will probably be removed in a future release.

=head1 SEE ALSO

L<Form::Factory::Interface>

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
