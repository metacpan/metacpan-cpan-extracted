###############################################################################
#
# This file copyright © 2017 by Randy J. Ray, all rights reserved
#
# See "LICENSE AND COPYRIGHT" in the POD for terms.
#
###############################################################################
#
#   Description:    Simple support for comments in JSON content.
#
#   Functions:      import
#                   comment_style
#                   get_comment_style
#                   decode
#
#   Libraries:      JSON
#
#   Global Consts:  %PATTERNS
#
#   Environment:    None
#
###############################################################################

package JSON::WithComments;

use 5.008;
use strict;
use warnings;
use base qw(JSON);

use Carp ();

our $VERSION = '0.001'; # VERSION

# These regular expressions are adapted from Regexp::Common::comment.

# The length of the regexp for JS multi-line comments triggers this:
## no critic(RegularExpressions::RequireExtendedFormatting)
my $JS_SINGLE = qr{(?://)(?:[^\n]*)};
my $JS_MULTI  = qr{(?:\/[*])(?:(?:[^*]+|[*](?!\/))*)(?:[*]\/)};
my $PERL      = qr{(?:#)(?:[^\n]*)};
my %PATTERNS  = (
    perl       => qr{(?<!\\)($PERL)},
    javascript => qr{(?<!\\)($JS_SINGLE|$JS_MULTI)},
);

# This is the comment-style that will be used if/when an object has not
# specified a style. It can be changed in import() with -default_comment_style.
# This is also the style that will be used by decode_json.
my $default_comment_style = 'javascript';

sub import {
    my ($class, @imports) = @_;

    my ($index, $style);
    for my $idx (0 .. $#imports) {
        if ($imports[$idx] eq '-default_comment_style') {
            $index = $idx;
            $style = $imports[$idx + 1];
            last;
        }
    }
    if (defined $index) {
        $style ||= '(undef)';
        if (! $PATTERNS{$style}) {
            Carp::croak "Unknown comment style '$style' given as default";
        }
        $default_comment_style = $style;
        splice @imports, $index, 2;
    }

    return $class->SUPER::import(@imports);
}

sub comment_style {
    my ($self, $value) = @_;

    if (defined $value) {
        if (! $PATTERNS{$value}) {
            Carp::croak "Unknown comment_style ($value)";
        }
        $self->{comment_style} = $value;
    }

    return $self;
}

sub get_comment_style {
    my $self = shift;

    return $self->{comment_style} || $default_comment_style;
}

sub decode {
    my ($self, $text) = @_;

    my $comment_re = $PATTERNS{$self->get_comment_style};
    # The JSON module reports errors using the character-offset within the
    # string as a whole. So rather than deleting comments, replace them with a
    # string of spaces of the same length. This should mean that any reported
    # character offsets in the JSON data will still be correct.
    $text =~ s/$comment_re/q{ } x length($1)/ge;

    return $self->SUPER::decode($text);
}

1;

__END__

=head1 NAME

JSON::WithComments - Parse JSON content with embedded comments

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use JSON::WithComments;
    
    my $content = <<JSON;
    /*
     * This is a block-comment in the JavaScript style, the default.
     */
    {
        // Line comments are also recognized
        "username" : "rjray",  // As are side-comments
        // This should probably be hashed:
        "password" : "C0mputer!"
    }
    JSON
    
    my $json = JSON::WithComments->new;
    my $hashref = $json->decode($json);

=head1 DESCRIPTION

NOTE: This is an early release, and should be considered alpha-quality. The
interface is subject to change in future versions.

B<JSON::WithComments> is a simple wrapper around the B<JSON> module that
pre-processes any JSON input before decoding it. The pre-processing is simple:
based on the style of comments that the object is configured for, it strips all
comments of that style it finds, before passing the remaining content to the
B<decode> method of the parent class.

The motivation for this was simple: with JSON becoming more and more popular
as a configuration format, some tools have started adding as-hoc support for
comments into their JSON parsers. This allows documentation to be a part of
these (sometimes quite large) JSON files. This module slightly extends the
concept by allowing you to opt for different styles of comments.

The B<JSON> module itself allows for shell-style (Perl-style) comments via
use of the B<relaxed> method. IF YOU ONLY NEED PERL-STYLE COMMENTS, you can
get that from B<JSON> directly. The advantage that this module offers is the
flexibility of also recognizing JavaScript-style comments.

=head2 Comment Styles

The B<JSON::WithComments> module will support the following named styles of
comments:

=over 4

=item C<javascript>

This is the default, and recognizes both line comments denoted by C<//>, and
block comments denoted by C</*> followed at some point by C<*/>. This is also
the style used by C/C++, but as JSON itself is based in the JavaScript world,
this style is referred to as C<javascript>.

=item C<perl>

This is an optional style that can be specified either by setting the default
style C<perl> via the C<-default_comment_style> import option, or by using the
B<comment_style> method. This style recognizes line comments delimited by a
C<#> character, and does not have a block-style comment.

=back

Comment delimiters may be prefixed with a backslash character (C<\>) to prevent
their removal. This may be needed if the delimiter character(s) appear in a
string, for example.

=head1 IMPORT OPTIONS

The class provides an B<import> method which will process any arguments
specific to this class, before passing everything else to the parent class.
Currently, there is only one option recognized:

=over 4

=item B<-default_comment_style> I<style>

Set a different default comment style. If not given, the default is
C<javascript>. Must be one of C<perl> or C<javascript>, otherwise it dies via
B<croak>.

=back

=head1 SUBROUTINES/METHODS

This class provides the following methods:

=over 4

=item B<comment_style>

This method takes a single value and sets it to be the new comment style for
the calling object. The new value must be one of the named styles listed
above. If an unknown style is specified, the method dies using B<croak>. The
return value is the object reference itself.

=item B<get_comment_style>

Returns the current comment style, or the default comment style if the calling
object does not have its own style set.

=item B<decode>

This method takes one argument, the JSON text to parse. The text is first
scrubbed of comments, then passed to the superclass B<decode> method.

=back

At present, this module does not facilitate the import of the non-method
functions that B<JSON> provides.

=head1 DIAGNOSTICS

The B<JSON> module reports parsing errors by throwing an exception (dying)
and reporting the character offset within the string at which the error
occurred. This module attempts to preserve that behavior by replacing comments
with an equal-length string of spaces. As such, if you see a parsing error
that refers to character 1023, the comments should not interfere with your
ability to go to character 1023 via your preferred text editor and see the
actual source of the error.

Additionally, trying to set the comment-style to an unknown value (either in
the B<comment_style> method or at import time) will result in an exception.

=head1 CAVEATS

Comments are not an official feature of JSON, so by using comments with JSON
data you are limiting the range of tools that you can use with that data. If
in the future a new JSON standard is published that supports comments, this
module will have to be updated (or deprecated) accordingly.

=head1 BUGS

As this is alpha software, the likelihood of bugs is pretty close to 100%.
Please report any issues you find to either the CPAN RT instance or to the
GitHub issues page:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-WithComments>

=item * GitHub Issues page

L<https://github.com/rjray/json-withcomments/issues>

=back

=head1 SUPPORT

=over 4

=item * Source code on GitHub

L<https://github.com/rjray/json-withcomments>

=item * MetaCPAN

L<https://metacpan.org/release/JSON-WithComments>

=back

=head1 LICENSE AND COPYRIGHT

This file and the code within are copyright (c) 2017 by Randy J. Ray.

Copying and distribution are permitted under the terms of the Artistic
License 1.0 or the GNU GPL 1. See the file F<LICENSE> in the distribution of
this module.

=head1 AUTHOR

Randy J. Ray <rjray@blackperl.com>
