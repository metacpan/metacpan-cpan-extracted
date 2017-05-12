#!/usr/bin/env perl
package HTML::RewriteAttributes::Resources;
use strict;
use warnings;
use base 'HTML::RewriteAttributes';
use URI;

our $VERSION = '0.03';

my %rewritable_attrs = (
    bgsound => { src        => 1 },
    body    => { background => 1 },
    img     => { src        => 1 },
    input   => { src        => 1 },
    table   => { background => 1 },
    td      => { background => 1 },
    th      => { background => 1 },
    tr      => { background => 1 },
);

sub _rewrite {
    my $self = shift;
    my $html = shift;
    my $cb   = shift;
    my %args = @_;

    $self->{rewrite_inline_css_cb} = $args{inline_css};
    $self->{rewrite_inline_imports} = $args{inline_imports};
    $self->{rewrite_inline_imports_seen} = {};

    $self->SUPER::_rewrite($html, $cb);
}

sub _should_rewrite {
    my ($self, $tag, $attr) = @_;

    return ( $rewritable_attrs{$tag} || {} )->{$attr};
}

sub _invoke_callback {
    my $self = shift;
    my ($tag, $attr, $value) = @_;

    return $self->{rewrite_callback}->($value, tag => $tag, attr => $attr, rewriter => $self);
}

sub _start_tag {
    my $self = shift;
    my ($tag, $attr, $attrseq, $text) = @_;

    if ($self->{rewrite_inline_css_cb}) {
        if ($tag eq 'link' and defined $attr->{type} and $attr->{type} eq 'text/css' and defined $attr->{href}) {
            my $content = $self->_import($attr->{href});
            if (defined $content) {
                $content = $self->_handle_imports($content, $attr->{href});
                $self->{rewrite_html} .= "\n<style type=\"text/css\"";
                $self->{rewrite_html} .= " media=\"$attr->{media}\"" if $attr->{media};
                $self->{rewrite_html} .= ">\n<!--\n$content\n-->\n</style>\n";
                return;
            }
        }
        if ($tag eq 'style' and defined $attr->{type} and $attr->{type} eq 'text/css') {
            $self->{rewrite_look_for_style} = 1;
        }
    }

    $self->SUPER::_start_tag(@_);
}

sub _default {
    my ($self, $tag, $attrs, $text) = @_;
    if (delete $self->{rewrite_look_for_style}) {
        $text = $self->_handle_imports($text, '.');
    }

    $self->SUPER::_default($tag, $attrs, $text);
}

sub _handle_imports {
    my $self    = shift;
    my $content = shift;
    my $base    = shift;

    return $content if !$self->{rewrite_inline_imports};

    # here we both try to preserve comments *and* ignore any @import
    # statements that are in comments
    $content =~ s{
        ( /\* .*? \*/ )
        |
        (//[^\n]*)
        |
        \@import \s* " ([^"]+) " \s* ;
    }{
          defined($1) ? $1
        : defined($2) ? $2
        : $self->_import($self->_absolutify($3, $base))
    }xsmeg;

    return $content;
}

sub _absolutify {
    my $self = shift;
    my $path = shift;
    my $base = shift;

    my $uri = URI->new($path);
    unless (defined $uri->scheme) {
        $uri = $uri->abs($base);
    }

    return $uri->as_string;
}

sub _import {
    my $self = shift;
    my $path = shift;

    return '' if $self->{rewrite_inline_imports_seen}{$path}++;

    my $content = "\n/* $path */\n"
                . $self->{rewrite_inline_css_cb}->($path);
    return $self->_handle_imports($content, $path);
}

1;

__END__

=head1 NAME

HTML::RewriteAttributes::Resources - concise resource-link rewriting

=head1 SYNOPSIS

    # writing some HTML email I see..
    $html = HTML::RewriteAttributes::Resources->rewrite($html, sub {
        my $uri = shift;
        my $content = render_template($uri);
        my $cid = generate_cid_from($content);
        $mime->attach($cid => content);
        return "cid:$cid";
    });

    # need to inline CSS too?
    $html = HTML::RewriteAttributes::Resources->rewrite($html, sub {
        # see above
    },
    inline_css => sub {
        my $uri = shift;
        return render_template($uri);
    });

    # need to inline CSS and follow @imports?
    $html = HTML::RewriteAttributes::Resources->rewrite($html, sub {
        # see above
    },
    inline_css => sub {
        # see above
    }, inline_imports => 1);

=head1 DESCRIPTION

C<HTML::RewriteAttributes::Resources> is a special case of
L<HTML::RewriteAttributes> for rewriting links to resources. This is to
facilitate generating, for example, HTML email in an extensible way.

We don't care about how to fetch resources and attach them to the MIME object;
that's your job. But you don't have to care about how to rewrite the HTML.

=head1 METHODS

=head2 C<new>

You don't need to call C<new> explicitly - it's done in L</rewrite>. It takes
no arguments.

=head2 C<rewrite> HTML, callback[, args] -> HTML

See the documentation of L<HTML::RewriteAttributes>.

The callback receives as arguments the resource URI (the attribute value), then, in a hash, C<tag> and C<attr>.

=head3 Inlining CSS

C<rewrite> can automatically inline CSS for you.

Passing C<inline_css> will invoke that callback to inline C<style> tags. The
callback receives as its argument the URI to a CSS file, and expects as a
return value the contents of that file, so that it may be inlined. Returning
C<undef> prevents any sort of inlining.

Passing C<inline_imports> (a boolean) will look at any inline CSS and call
the C<inline_css> callback to inline that import.

This keeps track of what CSS has already been inlined, and won't inline a
particular CSS file more than once (to prevent import loops).

=head1 SEE ALSO

L<HTML::RewriteAttributes>, L<HTML::Parser>, L<Email::MIME::CreateHTML>

=head1 AUTHOR

Shawn M Moore, C<< <sartak@bestpractical.com> >>

=head1 LICENSE

Copyright 2008-2010 Best Practical Solutions, LLC.
HTML::RewriteAttributes::Resources is distributed under the same terms as Perl itself.

=cut

