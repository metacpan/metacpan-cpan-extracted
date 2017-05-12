package Hobocamp::InputBox;
{
  $Hobocamp::InputBox::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: text input widget

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'init' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => ''
);

has 'is_password_field' => (
    'is'      => 'ro',
    'isa'     => 'Bool',
    'default' => 0
);

sub run {
    my ($self) = @_;

    my $retcode = Hobocamp::Dialog::dialog_inputbox($self->title, $self->prompt, $self->width, $self->height, $self->init, $self->is_password_field);

    $self->value($self->_get_user_input_result());
    $self->init($self->value);

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::InputBox - text input widget

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Single line input widget.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

