package Hobocamp::FileSelect;
{
  $Hobocamp::FileSelect::VERSION = '0.600';
}

use v5.10;
use warnings;

# ABSTRACT: Widget to select a file

use Moose;

with qw(Hobocamp::Role::Widget Hobocamp::Role::Window);

use Hobocamp::Dialog;

has 'path' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => ''
);

sub run {
    my ($self) = @_;

    my $retcode = Hobocamp::Dialog::dialog_fselect($self->title, $self->path, $self->height, $self->width);

    $self->value($self->_get_user_input_result());

    return $retcode;
}

1;


__END__
=pod

=head1 NAME

Hobocamp::FileSelect - Widget to select a file

=head1 VERSION

version 0.600

=head1 DESCRIPTION

Use this widget to browse for a directory.

=head1 AUTHOR

Adam Flott <adam@npjh.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Flott <adam@npjh.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

