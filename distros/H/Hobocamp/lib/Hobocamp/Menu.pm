package Hobocamp::Menu;
{
  $Hobocamp::Menu::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: select 1 item from a list

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'items' => (
    'traits'  => ['Array'],
    'is'      => 'rw',
    'isa'     => 'ArrayRef[HashRef]',
    'default' => sub { [] },
    'handles' => {
        'add_item'  => 'push',
        'all_items' => 'elements',
        'get_item'  => 'get',
    }
);

has 'menu_height' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 1
);

sub run {
    my ($self) = @_;

    my ($retcode, $selected) = Hobocamp::Dialog::dialog_menu($self->title, $self->prompt, $self->height, $self->width, $self->menu_height, $self->items);

    if ($self->get_item($selected)) {
        $self->value($self->get_item($selected));
    }

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::Menu - select 1 item from a list

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Select 1 item from a list

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

