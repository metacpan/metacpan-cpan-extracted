package Form::Maker;
use Form::Field;
use Form::Buttons;
use overload '""' => \&render;
Form::Field->plugins;

our $VERSION = "0.03";

=head1 NAME

Form::Maker - Framework for web forms

=head1 SYNOPSIS

  use Form::Maker;
  # Please see Form::Maker::Introduction

=head1 DESCRIPTION

=cut

use base qw(Form::Base Class::Accessor);
use UNIVERSAL::require;
use Carp;
use strict;
use warnings;

Form::Maker->mk_attributes(qw/_renderer decorators field_hash fields/);
Form::Maker->mk_accessors(qw/buttons/);
Form::Maker->add_decorators(
        qw/Form::Decorator::PredefinedFields Form::Decorator::DefaultButtons/);
Form::Maker->renderer("Form::Renderer::HTML");
Form::Maker->field_hash({});
Form::Maker->fields([]);

sub _load_and_run {
    my ($self, $class, $method, @args) = @_;
    if (!$class->require) {
        if ($method) {
            $class->can($method) or croak "Can't load class $class";
        } else {
            # Maybe it's inline?
            no strict 'refs';
            return if keys %{$class."::"};
            croak "Can't load class $class";
        }
    }
    $class->$method(@args) if $method;
}

=head1 METHODS

=head2 make

    my $form = Form::Maker->make();
    my $form = Form::Maker->make("Form::Outline::Login");

Creates a new form. If a package name is given, this is used as an
outline for the form, and any fields defined in the outline are added to
the new form.

=cut

sub make {
    my ($class, $spec) = @_;
    my $obj = $class->new({
            fields => [], 
            field_hash => {}, 
            buttons => Form::Buttons->new()
        });
    $class->_load_and_run($spec => fill_outline => $obj) if $spec;
    return $obj;
}

=head2 add_fields

    $form->add_fields(qw/username password/);

    $form->add_fields(
            Form::Field::Text->new({ name => "username" }),
            Form::Field::Password->new({ name => "password" }),
    );

Adds fields to a form; the arguments may either be
C<Form::Field>-derived objects, or names of fields. If the argument is a
plain string, then a C<Form::Field::Text> object is created; this may
later be changed to a different kind of field by the default
C<Form::Decorator::PredefinedFields>.

=cut

sub add_fields {
    my ($self, @fields) = @_;
    for my $field (@fields) {
        if (UNIVERSAL::isa($field, "Form::Field")) {
            if ($self->field_hash->{$field->name}) {
                croak "We already have a field called ".$field->name;
            }
            $self->field_hash->{$field->name} = $field;
            $self->_add_fields($field);
            $field->_form($self);
        } else {
            $self->add_named_field($field);
        }
    }
    return $self;
}

sub add_named_field {
    my ($self, $name) = @_;
    $self->add_fields(Form::Field::Text->new({ name => $name }));
}

=head2 remove_fields

    $self->remove_fields(qw/password/);

Removes the named fields from the form.

=cut

sub remove_fields {
    my ($self, @fields) = @_;
    if (ref $self) { delete @{$self->{field_hash}}{@fields} }
    my %names = map {$_ => 1 } @fields;
    $self->fields(
        [
        grep {!exists $names{$_->name}}
        @{$self->fields}
        ]
    );
}

=head2 add_button

    $self->add_button("submit");
    $self->add_button( Form::Button->new("whatever") );

Adds a button to the form. If no buttons are explicitly added by the
time the form is rendered, the C<DefaultButtons> decorator will add a
submit and reset button.

=cut

sub add_button {
    my ($self, $button) = @_;
    return $self->add_button(Form::Button->new($button))
     unless ref $button;

    croak "We already have a field called ".$button->name
        if $self->field_hash->{$button->name};
    $self->field_hash->{$button->name} = $button;
    push @{$self->buttons}, $button;
}

=head2 add_validation

    $self->add_validation(
        username => qr/^[a-z]+$/,
        phone    => "Form::Validation::PhoneNumber",
        email    => {
            perl => qr/$RE{email}/,
            javascript => 
                '/^[\w\-\+\._]+\@[a-zA-Z0-9][-a-zA-Z0-9\.]*\.[a-zA-Z]+$/'
        }
    );

Sets the validation method for a given field; the value for each field
can be a regular expression, to be used for all validation contexts, a
hash mapping validation contexts to regular expressions, or the name of
a class which will provide such a hash.

=cut

sub add_validation {
    my $self = shift;
    while (my ($fieldname, $validation) = splice @_, 0, 2) {
        my $field = $self->field_hash->{$fieldname};
        croak "Can't add validation to non-existant field $fieldname" unless $field;
        $field->add_validation($validation);
    }
    $self;
}

=head2 renderer

    $form->renderer("Form::Renderer::TT");

Gets or sets the form's renderer

=cut

sub renderer {
    my ($self, $renderer) = @_;
    if ($renderer) {
        $self->_load_and_run($renderer);
        $self->_renderer($renderer);
    }
    $self->_renderer;
}

=head2 render

    print $form->render;
    print $form;

This uses the form's renderer to turn the form into a string; this
stringification is also done automatically when the form object is used
in a string context.

=cut


sub render {
    my $self = shift;
    $self->decorate;
    $self->renderer->render($self);
}

sub decorate {
    my $self = shift;
    return if $self->{decorated}++;
    for my $decorator (@{$self->decorators}) {
        $self->_load_and_run($decorator);
        $decorator->decorate($self);
    }
}

sub add_decorator { goto &add_decorators }

=head1 Form elements

These methods return rendered parts of the form

=head2 start

=head2 end

Return the surrounding tags of the form, as plain text.

=head2 fieldset_start

=head2 fieldset_end

Return the surrounding tags of the field section of the form, as plain
text.

=cut

for my $method (qw(start end fieldset_start fieldset_end)) {
    no strict 'refs';
    *$method = sub {
        my $self = shift; $self->decorate; $self->renderer->$method;
    };
}

=head2 fieldset

Returns the rendered fieldset portion of the form.

=cut

sub fieldset {
    my $self = shift;
    $self->decorate;
    join ("", $self->fieldset_start, @{$self->fields}, $self->fieldset_end);
}

=head2 fields

Returns the individual fields as C<Form::Field> elements.

=cut

sub fields {
    my $self = shift;
    if (ref $self) { 
        $self->decorate
    }
    $self->_att_fields(@_);
}

1;

=head1 AUTHOR

Programmed by Simon Cozens, from a specification by Tony Bowden
(C<tony-form@kasei.com>) and Marty Pauley, and with the generous support
of Kasei.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Simon Cozens and Kasei.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
