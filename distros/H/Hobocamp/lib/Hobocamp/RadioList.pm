package Hobocamp::RadioList;
{
  $Hobocamp::RadioList::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Radio box widget

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

has 'list_height' => (
    'is'      => 'rw',
    'isa'     => 'Int',
    'default' => 1
);

sub run {
    my ($self) = @_;

    my ($retcode, @s) = Hobocamp::Dialog::dialog_checklist($self->title, $self->prompt, $self->height, $self->width, $self->list_height, $self->items, 0);

    my @selected;
    foreach my $i (@s) {
        push(@selected, $self->get_item($i));
    }

    if (@selected) {
        $self->value(\@selected);
    }

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::RadioList - Radio box widget

=head1 VERSION

version 0.600

=head1 DESCRIPTION

A radio list widget.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

