package HTML::RewriteAttributes;
use strict;
use warnings;
use base 'HTML::Parser';
use Carp 'croak';
use HTML::Entities 'encode_entities';

our $VERSION = '0.06';

sub new {
    my $class = shift;
    return $class->SUPER::new(
        start_h   => [ '_start_tag', "self,tagname,attr,attrseq,text" ],
        default_h => [ '_default',   "self,tagname,attr,text"         ],
    );
}

sub rewrite {
    my $self = shift;
    $self = $self->new if !ref($self);
    $self->_rewrite(@_);
}

sub _rewrite {
    my $self = shift;
    my $html = shift;
    my $cb   = shift || sub { $self->rewrite_resource(@_) };

    $self->_begin_rewriting($cb);

    $self->parse($html);
    $self->eof;

    $self->_done_rewriting;

    return $self->{rewrite_html};
}

sub rewrite_resource {
    my $self = shift;
    my $class = ref($self) || $self;

    my $error = "You must specify a callback to $class->rewrite";
    $error .= " or define $class->rewrite_resource" if $class ne __PACKAGE__;
    croak "$error.";
}

sub _begin_rewriting {
    my $self = shift;
    my $cb   = shift;

    $self->{rewrite_html} = '';
    $self->{rewrite_callback} = $cb;
}

sub _done_rewriting { }

sub _should_rewrite { 1 }

sub _start_tag {
    my ($self, $tag, $attrs, $attrseq, $text) = @_;

    $self->{rewrite_html} .= "<$tag";

    my @attr_list;
    for my $attr (@$attrseq) {
        next if $attr eq '/';

        if ($self->_should_rewrite($tag, $attr)) {
            $attrs->{$attr} = $self->_invoke_callback($tag, $attr, $attrs->{$attr}, $attrs, \@attr_list);
            next if !defined($attrs->{$attr});
        }

        push @attr_list, $attr;
    }

    for my $attr (@attr_list) {
        $self->{rewrite_html} .= sprintf ' %s="%s"', $attr, encode_entities( $attrs->{$attr} );
    }

    $self->{rewrite_html} .= ' /' if $attrs->{'/'};
    $self->{rewrite_html} .= '>';
}

sub _default {
    my ($self, $tag, $attrs, $text) = @_;
    $self->{rewrite_html} .= $text;
}

sub _invoke_callback {
    my $self = shift;
    return $self->{rewrite_callback}->(@_);
}

1;

__END__

=head1 NAME

HTML::RewriteAttributes - concise attribute rewriting

=head1 SYNOPSIS

Locate a tag in a provided block of HTML and delete, add, or
rewrite the attributes associated with that tag. The updated
HTML is returned.

Delete an attribute by returning undef.

    $html = HTML::RewriteAttributes->rewrite($html, sub {
        my ($tag, $attr, $value) = @_;

        # delete any attribute that mentions..
        return if $value =~ /COBOL/i;

        $value =~ s/\brocks\b/rules/g;
        return $value;
    });

Add an attribute by appending it to the C<$attr_list> arrayref
and adding the value to the C<$attrs> hashref. For example,
you could add C<loading="lazy"> to all C<img> tags.

    $html = HTML::RewriteAttributes->rewrite($html, sub {
        my ( $tag, $attr, $value, $attrs, $attr_list ) = @_;
        return $value unless $tag eq 'img' && !$attrs->{loading};
        $attrs->{loading} = 'lazy';
        push @$attr_list, 'loading';
        return $value;
    });

Modify an existing attribute by returning the new value.
The example below would be a C<src> attribute for an C<img>
in an email.

    $html = HTML::RewriteAttributes::Resources->rewrite($html, sub {
        my $uri = shift;
        my $content = render_template($uri);
        my $cid = generate_cid_from($content);
        $mime->attach($cid => content);
        return "cid:$cid";
    });

Passing a URL, L<HTML::RewriteAttributes::Links> can update resources
like C<href>s or C<img>s to include the base URL, changing
C<E<lt>img src="/bar.gif"E<gt>> to C<E<lt>img src="https://search.cpan.org/bar.gif"E<gt>>.
See also L<HTML::ResolveLink>.

    $html = HTML::RewriteAttributes::Links->rewrite($html, "https://search.cpan.org");

    # Passing a subroutine reference, L<HTML::RewriteAttributes::Links> can
    # extract all links, similar to L<HTML::LinkExtor>.

    HTML::RewriteAttributes::Links->rewrite($html, sub {
        my ($tag, $attr, $value) = @_;
        push @links, $value;
        $value;
    });

=head1 DESCRIPTION

C<HTML::RewriteAttributes> is designed for simple yet powerful HTML attribute
rewriting.

You simply specify a callback to run for each attribute and we do the rest
for you.

This module is designed to be subclassable to make handling special cases
easier. See the source for methods you can override.

See the SYNOPSIS above and included tests in the C<t> directory for more
examples.

=head1 METHODS

=head2 C<new>

You don't need to call C<new> explicitly - it's done in L</rewrite>. It takes
no arguments.

=head2 C<rewrite> HTML, callback -> HTML

This is the main interface of the module. You pass in some HTML and a callback,
the callback is invoked potentially many times, and you get back some similar
HTML.

As C<rewrite> parses the HTML block, it calls the provided callback,
passing as arguments the current tag name, the attribute name, and the
attribute value (though subclasses may override this --
L<HTML::RewriteAttributes::Resources> does). The callback can then use the
arguments to determine if you want to change the current tag or attribute,
or skip it by returning the current value unchanged. If you find the tag
and attribute you want to change, return C<undef> to remove the attribute,
or any other value to set the value of the attribute.

The callback also is passed a hashref C<$attrs> which has keys for attributes
and values with the current values. Finally C<$attr_list> is passed as an
arrayref contain all attributes for the current tag. To add a new attribute,
add the attribute name to the C<$attr_list> arrayref, and add the new value
to C<$attrs>.

=head1 SEE ALSO

L<HTML::Parser>, L<HTML::ResolveLink>, L<Email::MIME::CreateHTML>,
L<HTML::LinkExtor>

=head1 THANKS

Some code was inspired by, and tests borrowed from, Miyagawa's
L<HTML::ResolveLink>.

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE

Copyright 2008-2024 Best Practical Solutions, LLC.
HTML::RewriteAttributes is distributed under the same terms as Perl itself.

=cut

