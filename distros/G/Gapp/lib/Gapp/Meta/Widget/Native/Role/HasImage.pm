package Gapp::Meta::Widget::Native::Role::HasImage;
{
  $Gapp::Meta::Widget::Native::Role::HasImage::VERSION = '0.60';
}

use Moose::Role;
use MooseX::SemiAffordanceAccessor;

has 'image' => (
    is => 'rw',
    isa => 'Maybe[Gapp::Image]',
);

1;




__END__

=pod

=head1 NAME

Gapp::Meta::Widget::Native::Role::HasImage - image attribute for widgets

    
=head1 PROVIDED ATTRIBUTES

=over 4

=item B<image>

=over 4

=item is rw

=item isa L<Gapp::Image>|Undef

=back

The image to apply to the widget.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut