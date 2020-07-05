package Markdent::Dialect::GitHub::BlockParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Event::CodeBlock;
use Markdent::Regexes qw( $BlockStart $HorizontalWS );

use Moose::Role;

with 'Markdent::Role::Dialect::BlockParser';

around _possible_block_matches => sub {
    my $orig = shift;
    my $self = shift;

    my @look_for = $self->$orig();
    unshift @look_for, 'fenced_code_block';

    return @look_for;
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _match_fenced_code_block {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                $BlockStart
                                ```
                                $HorizontalWS?\{?\.?([\w-]+)?\}?$HorizontalWS*   # optional language name
                                \n
                                (                # code block content
                                  (?:.|\n)+?
                                )
                                \n
                                ```
                                \n
                              /xmgc;

    my $lang = $1;
    my $code = $2;

    $self->_debug_parse_result(
        $code,
        'code block',
        ( $lang ? [ language => $lang ] : () ),
    ) if $self->debug();

    $self->_send_event(
        'CodeBlock',
        code => $code,
        ( defined $lang ? ( language => $lang ) : () ),
    );

    return 1;
}
## use critic

1;

# ABSTRACT: Block parser for GitHub Markdown

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Dialect::GitHub::BlockParser - Block parser for GitHub Markdown

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This role adds parsing for some of the Markdown extensions used on GitHub. See
http://github.github.com/github-flavored-markdown/ for details.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::BlockParser> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
