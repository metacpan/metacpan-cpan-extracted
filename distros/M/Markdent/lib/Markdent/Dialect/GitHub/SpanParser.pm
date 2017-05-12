package Markdent::Dialect::GitHub::SpanParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::Event::AutoLink;
use Markdent::Event::LineBreak;

use Moose::Role;

with 'Markdent::Role::Dialect::SpanParser';

sub _build_emphasis_start_delimiter_re {
    my $self = shift;

    return qr/(?:\*|(?<=\W)_|(?<=^)_)/;
}

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _emphasis_end_delimiter_re {
    my $self  = shift;
    my $delim = shift;

    return $delim eq '*' ? qr/\Q$delim\E/ : qr/\Q$delim\E(?=$|\W)/;
}
## use critic

around _possible_span_matches => sub {
    my $orig = shift;
    my $self = shift;

    my @look_for = $self->$orig();

    return @look_for
        if $self->_open_start_event_for_span('code')
        || $self->_open_start_event_for_span('link');

    return (
        $self->$orig(),
        'bare_link',
    );
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _match_bare_link {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ m{ \G
                                 (?:
                                     (?<=^)
                                     |
                                     (?<=\W)
                                 )
                                 (
                                   https?
                                   ://
                                   \S+
                                 )
                               }xgc;

    my $link = $self->_make_event( AutoLink => uri => $1 );

    $self->_markup_event($link);

    return 1;
}
## use critic

around _text_end_res => sub {
    my $orig = shift;
    my $self = shift;

    return (
        $self->$orig(),
        qr{https?://},
    );
};

1;

# ABSTRACT: Span parser for GitHub Markdown

__END__

=pod

=head1 NAME

Markdent::Dialect::GitHub::SpanParser - Span parser for GitHub Markdown

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role adds parsing for some of the Markdown extensions used on GitHub. See
http://github.github.com/github-flavored-markdown/ for details.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::SpanParser> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
