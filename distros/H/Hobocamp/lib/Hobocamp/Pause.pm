package Hobocamp::Pause;
{
  $Hobocamp::Pause::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Timed message box widget

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'seconds' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 10
);

sub run {
    my ($self) = @_;

    $self->redraw();

    my $retcode = Hobocamp::Dialog::dialog_pause($self->title, $self->prompt, $self->height, $self->width, $self->seconds);

    $self->value(undef);

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::Pause - Timed message box widget

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Display a message box for a specified duration (defaults to 10 seconds). No user
input.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

