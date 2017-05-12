package HTML::Barcode::2D;
use Moo;
extends 'HTML::Barcode';

has '+show_text' => (default => 0);

has '+bar_width' => (default => '3px');
has '+bar_height' => (default => '3px');
has module_size => (
    is      => 'rw',
    default => '3px',
    trigger => \&_module_size_set,
);
sub _module_size_set {
    my ($self, $size) = @_;
    $self->bar_width($size);
    $self->bar_height($size);
}


=head1 NAME

HTML::Barcode::2D - A base class for HTML representations of 2D barcodes

=head1 DESCRIPTION

This is a base class for creating HTML representations of one-dimensional barcodes.  Do not use it directly.

If you are looking to generate a barcode, please see one of the following
modules instead:

=head2 Known Types

Here are some of the types of barcodes you can scan with the modules in 
this distribution.  Others may exist, so try searching CPAN.

=over 4

=item L<HTML::Barcode::QRCode> - Two dimensional QR codes.

=item L<HTML::Barcode::Code93> - Code 93 barcodes.

=item L<HTML::Barcode::Code128> - Code 128 barcodes.

=back

=head2 Subclassing

=head3 barcode_data

You need to either override this, or override the C<render_barcode> method
so it does not use this.

This should return a 2-dimensional arrayref of true and false values
(for "on" and "off").

It is not recommended to publish this method in your API.

=head1 ATTRIBUTES

In addition to those provided by L<HTML::Barcode>, a 2D barcode has these:

=head2 module_size

This is a CSS value for width and height of a square block within the barcode.

It is simply a convenience method that sets
both the L<bar_height|HTML::Barcode/bar_height> and L<bar_width|HTML::Barcode/bar_width> attributes.

=head1 AUTHOR

Mark A. Stratman, C<< <stratman@gmail.com> >>

=head1 SOURCE REPOSITORY

L<http://github.com/mstratman/HTML-Barcode>

=head1 SEE ALSO

L<HTML::Barcode>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::Barcode
