package Hobocamp::EditBox;
{
  $Hobocamp::EditBox::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Widget to edit text in a file

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'file' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => ''
);

sub run {
    my ($self) = @_;

    my $retcode = Hobocamp::Dialog::dialog_editbox($self->title, $self->file, $self->height, $self->width);

    $self->value($self->_get_user_input_result());

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::EditBox - Widget to edit text in a file

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Use this widget to edit text in a file.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

