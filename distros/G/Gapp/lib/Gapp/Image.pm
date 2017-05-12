package Gapp::Image;
{
  $Gapp::Image::VERSION = '0.60';
}

use Moose;
use MooseX::SemiAffordanceAccessor;

extends 'Gapp::Widget';

has '+gclass' => (
    default => 'Gtk2::Image',
);

has 'file' => (
    is => 'rw',
    isa => 'Maybe[Str]',
);

has 'stock' => (
    is => 'rw',
    isa => 'Maybe[ArrayRef]',
);

1;



__END__

=pod

=head1 NAME

Gapp::Image - Image Widget

=head1 OBJECT HIERARCHY

=over 4

=item L<Gapp::Object>

=item +-- L<Gapp::Widget>

=item ....+-- L<Gapp::Image>

=back

=head1 PROVIDED ATTRIBUTES

=over 4

=item B<stock [$stock_id, $size]>

=over 4

=item is rw

=item isa ArrayRef

=item default []

=back

The stock item to create the image from.

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

    Copyright (c) 2011-2012 Jeffrey Ray Hallock.

    This program is free software; you can redistribute it and/or
    modify it under the same terms as Perl itself.

=cut

