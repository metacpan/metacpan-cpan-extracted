package Hobocamp::Calendar;
{
  $Hobocamp::Calendar::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: calendar widget

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'day' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '1'
);

has 'month' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '1'
);

has 'year' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => '1970'
);

sub run {
    my ($self) = @_;

    my $retcode = Hobocamp::Dialog::dialog_calendar($self->title, $self->prompt, $self->width, $self->height, $self->day, $self->month, $self->year);

    $self->value($self->_get_user_input_result());

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::Calendar - calendar widget

=head1 VERSION

version 0.600

=head1 DESCRIPTION

A widget to choose a date.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

