package HTML::Template::Compiled::Plugin::InlineImage;
# $Id: InlineImage.pm,v 1.14 2006/09/14 10:28:35 tinita Exp $
use strict;
use warnings;
use Carp qw(croak carp);
use HTML::Template::Compiled::Expression qw(:expressions);
use HTML::Template::Compiled;
use MIME::Base64;
our $VERSION = '0.03';
HTML::Template::Compiled->register(__PACKAGE__);
our $SIZE_WARNING = 1;


sub register {
    my ($class) = @_;
    my %plugs = (
        escape => {
            # <img <%= gd_object escape="INLINE_IMG"%> alt="blah">
            INLINE_IMG => sub {
                HTML::Template::Compiled::Plugin::InlineImage::inline(
                    type => 'png',
                    image => $_[0],
                );
            },
            INLINE_IMG_PNG => sub {
                HTML::Template::Compiled::Plugin::InlineImage::inline(
                    type => 'png',
                    image => $_[0],
                );
            },
            INLINE_IMG_GIF => sub {
                HTML::Template::Compiled::Plugin::InlineImage::inline(
                    type => 'gif',
                    image => $_[0],
                );
            },
            INLINE_IMG_JPEG => sub {
                HTML::Template::Compiled::Plugin::InlineImage::inline(
                    type => 'jpeg',
                    image => $_[0],
                );
            },
        },
    );
    return \%plugs;
}

sub inline {
    my (%args) = @_;
    my $image = $args{image};
    my $type = $args{type};
    my ($binary, $width, $height);
    unless (ref $image) {
        # we have raw data, try guessing mime type
        require File::MMagic;
        my $mm = File::MMagic->new;
        my $mtype = $mm->checktype_contents($image)
            or croak "Could not determine mime type";
        my ($type_a,$type_b) = split m#/#, $mtype;
        $type = $type_b;
        $binary = $image;
    }
    else {
        ($binary, $width, $height) = ref $image eq 'GD::Image'
            ? gd_to_binary($image,$type)
            : croak "unknown image type " . ref $image;
    }
    my $base64 = encode_base64($binary);
    my $string = "data:image/$type;base64,$base64";
    my $l = length $string;
    if ($l > 1024 && $SIZE_WARNING) {
        carp "Image is too big ($l characters > 1024)";
    }
    my $attributes = qq{src="$string"};
    if (defined $width) { $attributes .= qq{ width="$width"} }
    if (defined $height) { $attributes .= qq{ height="$height"} }
    return $attributes;
}

sub gd_to_binary {
    my $binary;
    if ($_[1] eq 'png') { $binary = $_[0]->png }
    if ($_[1] eq 'gif') { $binary = $_[0]->gif }
    if ($_[1] eq 'jpeg') { $binary = $_[0]->jpeg }
    my ($width,$height) = $_[0]->getBounds();
    return ($binary, $width, $height);
}

1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::InlineImage - Inline-Images with HTML::Template::Compiled

=head1 SYNOPSIS

The Perl code:

    use HTML::Template::Compiled::Plugin::InlineImage;

    my $htc = HTML::Template::Compiled->new(
        plugin => [qw(HTML::Template::Compiled::Plugin::InlineImage)],
        filename => "template.htc",
        tagstyle => [qw(+tt)],
    );
    $htc->param(gd_object => $gd);
    $htc->param(raw_data => $data_from_image_file);
    print $htc->output;

The Template:

    <html>
        <body>
        <img [%= gd_object escape="INLINE_IMG" %] alt="[Rendered GD Image]">
        <img [%= raw_data escape="INLINE_IMG" %] alt="[Rendered Image]">
        </body>
    </html>

This will create an inline image. The GD-object/the raw image output
is turned into base64 and put into a src attribute.

The output looks like

    src="data:image/type;base64,...." width="42" height="42"

Note that the maximum length for a HTML src attribute is 1024. If your image
is bigger you will get a warning.

To avoid the warning, set
C<$HTML::Template::Compiled::Plugin::InlineImage::SIZE_WARNING> to 0.

=head1 DESCRIPTION

This is a plugin for L<HTML::Template::Compiled>. If you feed it GD-objects
or raw images (other image-object-types could be added in the future),
then it will render the object like described in RFC 2397
(http://www.ietf.org/rfc/rfc2397.txt).

=head1 ESCAPE TYPES

There are four escapy types at the moment:

=over 4

=item INLINE_IMG_PNG

renders as png

=item INLINE_IMG_GIF

renders as gif

=item INLINE_IMG_JPEG

renders as jpeg

=item INLINE_IMG

renders per default as png, or if you feed it raw data, it will guess
the image type.

=back

=head1 METHODS

=over 4

=item register

Gets called by HTC. It should return a hashref. I will document soon
in L<HTML::Template::Compiled> what this method should return to
create a plugin. Until then, have a lok at the source =)

=back

=head1 SUBROUTINES

=over 4

=item inline

Arguments: a hash like

    type  => 'png', # or jpeg, gif
    image => $gd_object,

The subroutine determines which kind of image object we have
and calls the corresponding *_to_binary method. (At the moment
only L<GD> is supported.)

This function is usually only used internally.

=item gd_to_binary

Arguments: ($gd_object, $type)

$type can be png, jpeg or gif.

Returns:

    src="data:image/$type;base64,$the_rendered_image_as_base64",
    width of image,
    heigth of image

This function is usually only used internally.

=back

=head1 ERROR MESSAGES, WARNINGS

If your image is (in base64, plus mime type) bigger than 1024 bytes,
you'll get a warning like:

    Image is too big (1234 characters > 1024)

To avoid the warning, set
C<$HTML::Template::Compiled::Plugin::InlineImage::SIZE_WARNING> to 0.

EXAMPLES

Simple examples:

L<"examples/gd.pl"> and L<"examples/gd.html">

L<"examples/raw.pl"> and L<"examples/raw.html">

=head1 SEE ALSO

L<HTML::Template::Compiled>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by tina mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
