package EPUB::Parser::File::Navi::Context::Toc;
use strict;
use warnings;
use Carp;
use parent 'EPUB::Parser::File::Navi::Context';
use List::Util qw/first/;

# todo: nested
sub list {
    my $self = shift;
    my @list;

    for my $anchor  ( $self->parser->find('xhtml:ol/xhtml:li/xhtml:a') ) {
        my $href = first { $_->name eq 'href' } $anchor->attributes();
        croak 'parse error: ', $anchor->nodePath unless $href;

        push @list, {
            title => $anchor->textContent || 'none',
            href  => $href->value,
        };
    }

    return wantarray ? @list : \@list;
}

1;
