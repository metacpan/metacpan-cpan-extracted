package Hobocamp::TimeBox;
{
  $Hobocamp::TimeBox::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Time widget

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'hour' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '12'
);

has 'minute' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '00'
);

has 'second' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '00'
);

sub run {
    my ($self) = @_;

    my $retcode = Hobocamp::Dialog::dialog_timebox($self->title, $self->prompt, $self->width, $self->height, $self->hour, $self->minute, $self->second);

    $self->value($self->_get_user_input_result());

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::TimeBox - Time widget

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Enter time (hours, minutes, and seconds) widget.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

