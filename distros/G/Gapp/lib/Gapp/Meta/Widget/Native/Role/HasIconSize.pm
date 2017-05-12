package Gapp::Meta::Widget::Native::Role::HasIconSize;
{
  $Gapp::Meta::Widget::Native::Role::HasIconSize::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'icon_size' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

1;


__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::HasIconSize - icon_size attribute for widgets
   
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<icon_size>

=over 4

=item is rw

=item isa Str|Undef

=back

The size of the icons displayed on the widget.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut