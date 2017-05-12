package HTML::Barcode;
use Moo;

our $VERSION = '0.13';

has 'text' => (
    is  => 'rw',
    documentation => 'The information to put into the barcode.',
);
has 'foreground_color' => (
    is      => 'rw',
    default => '#000',
    documentation => 'A CSS color value for the foreground.',
);
has 'background_color' => (
    is      => 'rw',
    default => '#fff',
    documentation => 'A CSS color value for the background.',
);
has 'bar_width' => (
    is      => 'rw',
    default => '2px',
    documentation => 'A CSS value for the width of an individual bar.',
);
has 'bar_height' => (
    is      => 'rw',
    default => '100px',
    documentation => 'A CSS value for the height of an individual bar.',
);
has show_text => (
    is      => 'rw',
    default => 1,
    documentation => 'Boolean. Indicates whether or not to render the text below the barcode.',
);

has 'css_class' => (
    is      => 'rw',
    default => 'hbc',
    trigger => \&_css_class_set,
    documentation => 'The value for the "class" attribute applied to any container tags.',
);

has 'embed_style' => (
    is      => 'rw',
    default => 0,
    documentation => 'Boolean. Embed the style information in HTML "style" attributes. This is NOT recommended.',
);

has 'td_on_class' => (is => 'rw', lazy => 1, builder => '_build_td_on_class');
has 'td_off_class' => (is => 'rw', lazy => 1, builder => '_build_td_off_class');
sub _css_class_set {
    my ($self) = @_;
    $self->td_on_class($self->_build_td_on_class);
    $self->td_off_class($self->_build_td_off_class);
}
sub _build_td_on_class { return $_[0]->css_class . '_on'; }
sub _build_td_off_class { return $_[0]->css_class . '_off'; }

# You need to override this.
sub barcode_data { return []; }

sub render {
    my ($self) = @_;
    return '' unless defined $self->text;
    return q(<style type="text/css">) . $self->css . q(</style>)
        . $self->render_barcode();
}

# If you're doing anything that can't be represented by a rectangular
# grid, you need to override this.
# This needs to also render the text, if $self->show_text is true.
sub render_barcode {
    my ($self) = @_;
    return '' unless defined $self->text;

    my $data = $self->barcode_data;
    my $num_columns = 1;

    my @rows = ();
    if (@$data > 0) {
        if (ref $data->[0] && ref $data->[0] eq 'ARRAY') {
            $num_columns = scalar @{$data->[0]};
            push @rows, map {
                $self->_generate_tr(
                    join('', map { $self->_generate_td($_) } @$_)
                );
            } @$data;
        } else {
            $num_columns = scalar @$data;
            push @rows, $self->_generate_tr(
                join('', map { $self->_generate_td($_) } @$data)
            );
        }
    }

    if ($self->show_text) {
        push @rows, $self->_generate_tr(
            $self->_generate_td(undef, $num_columns, $self->text)
        );
    }

    return $self->_generate_table(join '', @rows);
}

sub css {
    my $self = shift;
    my $class = $self->css_class;
    my $on = $self->td_on_class;
    my $off = $self->td_off_class;
    return
           "table.${class} {border-width:0;border-spacing:0;}"
         . "table.${class} {border-width:0;border-spacing:0;}"
         . "table.${class} tr, table.${class} td{border:0;margin:0;padding:0;}"
         . "table.${class} td{text-align:center;}"
         . "table.${class} td.${on},table.${class} td.${off} {width:" . $self->bar_width . ";height:" . $self->bar_height . ";}"
         . "table.${class} td.${on} {background-color:" . $self->foreground_color . ";color:inherit;}"
         . "table.${class} td.${off} {background-color:" . $self->background_color . ";color:inherit;}"
         ;
}

sub _generate_table {
    my ($self, $contents) = @_;
    my $class = $self->css_class;

    my $style = '';
    if ($self->embed_style) {
        $style = ' style="border:0;margin:0;padding:0;border-spacing:0;"';
    }

    return qq{<table$style class="$class">$contents</table>};
}

sub _generate_tr {
    my ($self, $contents) = @_;

    my $style = '';
    if ($self->embed_style) {
        $style = ' style="border:0;margin:0;padding:0;"';
    }

    return qq(<tr$style>$contents</tr>);
}

sub _generate_td {
    my ($self, $on, $colspan, $content) = @_;

    my $style = '';
    if ($self->embed_style) {
        my $color = $on ? $self->foreground_color : $self->background_color;
        $style = ' style="border:0;margin:0;padding:0;width:' . ($colspan ? 'auto' : $self->bar_width) . ';height:' . ($colspan ? 'auto' : $self->bar_height) . ';background-color:' . $color . ';color:inherit;text-align:center;"';
    }

    if ($colspan) {
        return qq{<td$style colspan="$colspan">$content</td>};
    } else {
        my $class = $on ? $self->td_on_class : $self->td_off_class;
        return qq{<td$style class="$class"></td>};
    }
}

=head1 NAME

HTML::Barcode - Render HTML representations of barcodes

=head1 SYNOPSIS

  # HTML::Barcode::Code93 is just one example, there are others.
  my $code = HTML::Barcode::Code93->new(text => 'MONKEY');
  print $code->render;

See the documentation for the specific L<types of barcodes|/"Known Types"> 
for detailed instructions.

=head1 DESCRIPTION

This is a base class for creating HTML representations of barcodes.
Do not use it directly.  If you are looking to generate a barcode, please see one of the following modules instead:

=head2 Known Types

Here are the types of barcodes you can generate with this distribution.
Others may exist, so try searching CPAN.

=over 4

=item L<HTML::Barcode::QRCode> - Two dimensional QR codes.

=item L<HTML::Barcode::DataMatrix> - Two dimensional Data Matrix barcodes.

=item L<HTML::Barcode::Code93> - Code 93 barcodes.

=item L<HTML::Barcode::Code128> - Code 128 barcodes.

=back

=head2 Subclassing

To add a new type of barcode, create a subclass of either L<HTML::Barcode::1D|HTML::Barcode::1D/Subclassing>
for traditional barcodes, L<HTML::Barcode::2D|HTML::Barcode::2D/Subclassing> for 2-dimensional barcodes,
or L<HTML::Barcode> if neither of those suit your needs.

Use one of the L<existing modules|/"Known Types"> as a starting point.

=head3 Required methods for your subclass

=over 4

=item barcode_data

You need to either override this, or override the C<render_barcode> method
so it does not use this.

This should return an arrayref of true and false values (for "on" and "off"),
or an arrayref of arrayrefs (for 2D).

It is not recommended to publish this method in your API.

=item Other methods

Feel free to override any other methods, or use method modifiers
(C<around>, C<before>, C<after>) as you see fit.

=back

=head1 METHODS

=head2 new (%attributes)

Default constructor provided by L<Moo>, which can take values for
any of the L<attributes|/ATTRIBUTES>.

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

Returns CSS needed to properly display your rendered barcode.

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

Boolean. Indicates whether or not to render the text below the barcode.

=head2 css_class

The value for the C<class> attribute applied to any container tags
in the HTML (e.g. C<table> or C<div>).
C<td> tags within the table will have either css_class_on or css_class_off
classes applied to them.

For example, if css_class is "barcode", you will get C<< <table class="barcode"> >> and its cells will be either C<< <td class="barcode_on"> >> or
C<< <td class="barcode_off"> >>.

=head2 embed_style

Boolean. Rather than rendering CSS stylesheets, embed the style information
in HTML C<style> attributes.  You should not use this option without
good reason, as it greatly increases the size of the generated markup,
and makes it impossible to override with stylesheets.

=head1 AUTHOR

Mark A. Stratman, C<< <stratman@gmail.com> >>

=head1 SOURCE REPOSITORY

L<http://github.com/mstratman/HTML-Barcode>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mark A. Stratman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of HTML::Barcode
