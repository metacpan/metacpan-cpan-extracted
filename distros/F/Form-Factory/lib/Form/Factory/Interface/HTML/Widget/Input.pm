package Form::Factory::Interface::HTML::Widget::Input;
$Form::Factory::Interface::HTML::Widget::Input::VERSION = '0.022';
use Moose;

extends qw( Form::Factory::Interface::HTML::Widget::Element );

# ABSTRACT: HTML interface widget helper


has '+tag_name' => (
    default => 'input',
);

has type => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => 'text',
);

has name => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
);

has value => (
    is        => 'ro',
    isa       => 'Str',
    required  => 1,
    default   => '',
);

has size => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_size',
);

has maxlength => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_maxlength',
);

has disabled => (
    is        => 'ro',
    isa       => 'Bool',
);

has readonly => (
    is        => 'ro',
    isa       => 'Bool',
);

has tabindex => (
    is        => 'ro',
    isa       => 'Int',
    predicate => 'has_tabindex',
);

has alt => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_alt',
);

has checked => (
    is        => 'ro',
    isa       => 'Bool',
);

sub consume_control {
    my ($self, %options) = @_;
    my $params = $options{params};
    my $name   = $self->name;

    return { $name => $params->{ $name } };
}

override more_attributes => sub {
    my $self = shift;

    my %attributes = (
        type  => $self->type,
        name  => $self->name,
        value => $self->value,
    );

    $attributes{size}      = $self->size      if $self->has_size;
    $attributes{maxlength} = $self->maxlength if $self->has_maxlength;
    $attributes{disabled}  = 'disabled'       if $self->disabled;
    $attributes{readonly}  = 'readonly'       if $self->readonly;
    $attributes{tabindex}  = $self->tabindex  if $self->has_tabindex;
    $attributes{alt}       = $self->alt       if $self->has_alt;
    $attributes{checked}   = 'checked'        if $self->checked;

    return \%attributes;
};


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Form::Factory::Interface::HTML::Widget::Input - HTML interface widget helper

=head1 VERSION

version 0.022

=head1 DESCRIPTION

Move along. Nothing to see here.

=for Pod::Coverage   .*

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
