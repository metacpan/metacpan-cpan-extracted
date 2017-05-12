package HTML::Barcode::Code128;
use Moo;
extends 'HTML::Barcode::1D';
use Barcode::Code128;

our $VERSION = '0.13';

has '_code128' => (
    is      => 'ro',
    default => sub { Barcode::Code128->new },
);

sub barcode_data {
    my ($self) = @_;
    my $data_str = $self->_code128->barcode($self->text);
    return [
        map { $_ eq '#' ? 1 : 0 }
        split //, $data_str
    ];
}

=head1 NAME

HTML::Barcode::Code128 - Generate HTML representations of Code 128 barcodes

=head1 SYNOPSIS

L<Barcode::Code128> is required by this class, so please install it first.

  my $code = HTML::Barcode::Code128->new(text => 'MONKEY');
  print $code->render;

=head1 DESCRIPTION

This class allows you to easily create HTML representations of Code 128 barcodes.

=begin html

<p>Here is an example of a Code 128 barcode rendered with this module:</p>

<table style="border:0;margin:0;padding:0;border-spacing:0;" class="hbc"><tr style="border:0;margin:0;padding:0;"><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#fff;color:inherit;text-align:center;" class="hbc_off"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td><td style="border:0;margin:0;padding:0;width:2px;height:100px;background-color:#000;color:inherit;text-align:center;" class="hbc_on"></td></tr><tr style="border:0;margin:0;padding:0;"><td style="border:0;margin:0;padding:0;width:auto;height:auto;background-color:#fff;color:inherit;text-align:center;" colspan="101">MONKEY</td></tr></table>

=end html

This B<requires> L<Barcode::Code128>. You may also use the
L<character constants|Barcode::Code128/EXPORTS> from this module in your text.
Be sure to provide their full package name.
For example:

  my $text = Barcode::Code128::FNC1 . '00000123455555555558';
  HTML::Barcode::Code128->new(text => $text)->render;

You can read more about Code 128 online (e.g. L<http://en.wikipedia.org/wiki/Code_128>).

=head1 METHODS

=head2 new (%attributes)

Instantiate a new HTML::Barcode::Code128 object. The C<%attributes> hash
requires the L</text> attribute, and can take any of the other
L<attributes|/ATTRIBUTES> listed below.

=head2 render

This is a convenience routine which returns C<< <style>...</style> >> tags
and the rendered barcode.

If you are printing multiple barcodes or want to ensure your C<style> tags
are in your HTML headers, then you probably want to output the barcode
and style separately with L</render_barcode> and
L</css>.

=head2 render_barcode

Returns only the rendered barcode.  You will need to provide stylesheets
separately, either writing them yourself or using the output of L</css>.

=head2 css

Returns CSS needed to properly display your rendered barcode.  This is
only necessary if you are using L</render_barcode> instead of the
easier L</render> method.

=head1 ATTRIBUTES

These attributes can be passed to L<new|/"new (%attributes)">, or used
as accessors.

=head2 text

B<Required> - The information to put into the barcode.

=head2 foreground_color

A CSS color value (e.g. '#000' or 'black') for the foreground. Default is '#000'.

=head2 background_color

A CSS color value background. Default is '#fff'.

=head2 bar_width

A CSS value for the width of an individual bar. Default is '2px'.

=head2 bar_height

A CSS value for the height of an individual bar. Default is '100px'.

=head2 show_text

Boolean, default true. Indicates whether or not to render the text
below the barcode.

=head2 css_class

The value for the C<class> attribute applied to any container tags
in the HTML (e.g. C<table> or C<div>).
C<td> tags within the table will have either css_class_on or css_class_off
classes applied to them.

For example, if css_class is "barcode", you will get C<< <table class="barcode"> >> and its cells will be either C<< <td class="barcode_on"> >> or
C<< <td class="barcode_off"> >>.

=head2 embed_style

Rather than rendering CSS stylesheets, embed the style information
in HTML C<style> attributes.  You should not use this option without
good reason, as it greatly increases the size of the generated markup,
and makes it impossible to override with stylesheets.

=head1 AUTHOR

Mark A. Stratman, C<< <stratman@gmail.com> >>

=head1 SOURCE REPOSITORY

L<http://github.com/mstratman/HTML-Barcode-Code128>

=head1 SEE ALSO

L<Barcode::Code128>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut


1;
