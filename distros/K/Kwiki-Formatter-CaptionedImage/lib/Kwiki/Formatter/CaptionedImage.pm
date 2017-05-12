package Kwiki::Formatter::CaptionedImage;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';
our $VERSION = '0.01';

const class_title => 'Captioned Image';
const class_id => 'captionedimage';
const css_file => 'captioned_image.css';

sub register {
        my $registry = shift;
        $registry->add(preload => $self->class_id);
        $registry->add(hook => 'formatter:all_blocks',
                post => 'add_note_to_list',
        );
}

sub init {
        super;
        my $formatter = $self->hub->load_class('formatter');
        $formatter->table->{capimage} = 'Kwiki::Formatter::CaptionedImage::Block';
}

sub add_note_to_list {
        return [('capimage', @{$_[-1]->returned})];
}

package Kwiki::Formatter::CaptionedImage::Block;
use Spoon::Base -Base;
use base 'Spoon::Formatter::Block';

const formatter_id => 'capimage';
const pattern_block =>
        qr{^\[(?:\s*([^\|]+)\|\s*)?(?:\s*([^\]]+)\s+)?(\w+:(?://|\?)[^\]\s]+)(?:\s+([^\]]+)\s*)?\]\n}m;

field wrapper_float => '';
field target => '';
field float => '';
const html_end => q{</th></tr></tfoot></table></div>};

sub match {
        return unless $self->text =~ $self->pattern_block;
        $self->start_offset($-[0]);
        $self->end_offset($+[0]);
        my ($float, $text1, $target, $text2) = ($1, $2, $3, $4);
        return unless $target =~ /(?:jpe?g|gif|png)$/i;

        $self->target($self->normalize_target($target));
        $float = '' unless defined $float;
        $self->wrapper_float(' style="text-align: center"') if $float eq '';
        $float = $float ne ''
                ? "float: $float"
                : "margin-left: auto; margin-right: auto";
        $float = " style=\"$float\" ";
        $self->float($float);
        $text1 = '' unless defined $text1;
        $text2 = '' unless defined $text2;
        my $text = $text1 . ' ' . $text2;
        $text =~ s/^\s*(.*?)\s*$/$1/;
        $text = $target unless $text =~ /\S/;
        $self->text($text);
        return 1;
}

sub html_start {
        my ( $wrapper_float, $float, $target ) =
                ( $self->wrapper_float, $self->float, $self->target );
        return <<HTML;
                <div$wrapper_float><table class="captioned_image"$float>
                        <tbody><tr><td><img src="$target" /></td></tr></tbody>
                        <tfoot><tr><th>
HTML
}

sub normalize_target {
        my ( $target ) = @_;
        if( $target =~ /^img:\/\/(?:([^\/]+)\/)?(.+)$/i ) {
                my $page = defined $1 ? $1 : $self->hub->pages->current_id;
                my $file = $2;
                $target = "plugin/attachments/$page/$file";
        }
        return $target;
}

package Kwiki::Formatter::CaptionedImage;
1; # End of Kwiki::Formatter::CaptionedImage;

__DATA__

=head1 NAME

Kwiki::Formatter::CaptionedImage - Will display an image to the screen with a
caption below it.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module handles the common idiom of displaying a caption below an image
This is very common in manuals and more formal documents. Syntax is basically
the same as a titled external link but the URL points to an image instead of
a document.

In your wiki markup:

    [http://foo.com/images/foo.gif Picture of Footastic product]

The HTML produced should be something like:

    <table class="captioned_image">
        <tbody><tr><td><img src="http://foo.com/images/foo.gif" /></td></tr></tbody>
        <tfoot><tr><th>Picture of Footastic product</th></tr></tfoot>
    </table>

With the default stylesheets this will look something like:

    |------------------------------|
    |                              |
    |     <Pic displays here>      |
    |                              |
    |------------------------------|
    | Picture of Footastic product |
    |------------------------------|

=head1 Floating the image

By default the captioned image is centered on the screen with both sides
cleared. You can also float the captioned image left or right and the text
will flow around it.

For a left floated image:

    [left| http://foo.com/images/foo.gif Picture of Footastic product]

For a right floated image:

    [right| http://foo.com/images/foo.gif Picture of Footastic product]

=head1 AUTHOR

Eric Anderson, C<< <eric at cordata.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2006 CorData, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See http://www.perl.com/perl/misc/Artistic.html

=cut
__css/captioned_image.css__
.captioned_image {
        border: 1px solid black;
        border-collapse: collapse;
        margin: 1em;
}

.captioned_image tfoot th {
        background-color: #999999;
        color: white;
        text-align: center;
}
