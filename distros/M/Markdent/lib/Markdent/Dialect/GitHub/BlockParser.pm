package Markdent::Dialect::GitHub::BlockParser;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use List::AllUtils qw( insert_after_string );
use Markdent::Event::CodeBlock;
use Markdent::Regexes qw( $BlockStart );

use Moose::Role;

with 'Markdent::Role::Dialect::BlockParser';

around _possible_block_matches => sub {
    my $orig = shift;
    my $self = shift;

    my @look_for = $self->$orig();
    insert_after_string 'list', 'fenced_code_block', @look_for;

    return @look_for;
};

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _match_fenced_code_block {
    my $self = shift;
    my $text = shift;

    return unless ${$text} =~ / \G
                                $BlockStart
                                ```
                                \s?\{?\.?([\w-]+)?\}?\s*        # optional language name
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

=head1 NAME

Markdent::Dialect::GitHub::BlockParser - Block parser for GitHub Markdown

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This role adds parsing for some of the Markdown extensions used on GitHub. See
http://github.github.com/github-flavored-markdown/ for details.

=head1 ROLES

This role does the L<Markdent::Role::Dialect::BlockParser> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
