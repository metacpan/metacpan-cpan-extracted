package HTML::RewriteAttributes::Links;
use strict;
use warnings;
use base 'HTML::RewriteAttributes';
use HTML::Tagset ();
use URI;

our $VERSION = '0.03';

my %rewritable_attrs;

for my $tag (keys %HTML::Tagset::linkElements) {
    for my $attr (@{ $HTML::Tagset::linkElements{$tag} }) {
        $rewritable_attrs{$tag}{$attr} = 1;
    }
}

sub _should_rewrite {
    my ($self, $tag, $attr) = @_;

    return ( $rewritable_attrs{$tag} || {} )->{$attr};
}

sub _rewrite {
    my ($self, $html, $arg) = @_;

    if (!ref($arg)) {
        $self->{rewrite_link_base} = $arg;

        $arg = sub {
            my ($tag, $attr, $value) = @_;
            my $uri = URI->new($value);

            $uri = $uri->abs($self->{rewrite_link_base})
                unless defined $uri->scheme;

            return $uri->as_string;
        };
    }

    $self->SUPER::_rewrite($html, $arg);
}

# if we see a base tag, steal its href for future link resolution
sub _start_tag {
    my $self = shift;
    my ($tag, $attr, $attrseq, $text) = @_;

    if ($tag eq 'base' && defined $attr->{href}) {
        $self->{rewrite_link_base} = $attr->{href};
    }

    $self->SUPER::_start_tag(@_);
}

1;

__END__

=head1 NAME

HTML::RewriteAttributes::Links - concise link rewriting

=head1 SYNOPSIS

    # up for some HTML::ResolveLink?
    $html = HTML::RewriteAttributes::Links->rewrite($html, "http://search.cpan.org");

    # or perhaps HTML::LinkExtor?
    HTML::RewriteAttributes::Links->rewrite($html, sub {
        my ($tag, $attr, $value) = @_;
        push @links, $value;
        $value;
    });

=head1 DESCRIPTION

C<HTML::RewriteAttributes::Links> is a special case of
L<HTML::RewriteAttributes> for rewriting links. 

See L<HTML::ResolveLink> and L<HTML::LinkExtor> for examples of what you can do
with this.

=head1 METHODS

=head2 C<new>

You don't need to call C<new> explicitly - it's done in L</rewrite>. It takes
no arguments.

=head2 C<rewrite> HTML, (callback|base)[, args] -> HTML

See the documentation of L<HTML::RewriteAttributes>.

Instead of a callback, you may pass a string. This will mimic the behavior of
L<HTML::ResolveLink> -- relative links will be rewritten using the given string
as a base URL.

=head1 SEE ALSO

L<HTML::RewriteAttributes>, L<HTML::Parser>, L<HTML::ResolveLink>, L<HTML::LinkExtor>

=head1 AUTHOR

Best Practical Solutions, LLC <modules@bestpractical.com>

=head1 LICENSE

Copyright 2008-2024 Best Practical Solutions, LLC.
HTML::RewriteAttributes::Links is distributed under the same terms as Perl itself.

=cut

