package Markdown::Pod;
# ABSTRACT: Convert Markdown to POD

use strict;
use warnings;

our $VERSION = '0.006';

use Encode qw( encodings );
use List::Util qw( first );
use Markdent::Parser;
use Markdent::Types qw( Str );
use Markdown::Pod::Handler;
use Moose;
use MooseX::Params::Validate qw( validated_list );
use MooseX::StrictConstructor;
use namespace::autoclean;

sub markdown_to_pod {
    my $self = shift;
    my ( $dialect, $markdown, $encoding ) = validated_list(
        \@_,
        dialect  => { isa => Str, default => 'Standard', optional => 1 },
        markdown => { isa => Str },
        encoding => { isa => Str, default => q{},        optional => 1 },
    );

    my $capture = q{};
    open my $fh, '>', \$capture
        or die $!;

    if ($encoding) {
        my $found = first { $_ eq $encoding } Encode->encodings;
        if ($found) {
            binmode $fh, ":encoding($encoding)";
        }
        else {
            warn "cannot find such '$encoding' encoding\n";
        }
    }

    my $handler = Markdown::Pod::Handler->new(
        encoding => $encoding,
        output   => $fh,
    );

    my $parser = Markdent::Parser->new(
        dialect => $dialect,
        handler => $handler,
    );

    $parser->parse( markdown => $markdown );

    close $fh;

    $capture =~ s/\n+$/\n/;

    #
    # FIXME
    # dirty code to support blockquote
    #
    # UPDATE A.Speer - not needed, blockquote converted to use =over 2, =back
    #
    #$capture =~ s{
    #    ^ =begin \s+ blockquote
    #    \s+
    #    (.*?)
    #    \s+
    #    ^ =end \s+ blockquote
    #}{
    #    my $quoted = $1;
    #    $quoted =~ s/^/    /gsm;
    #    $quoted;
    #}xgsme;

    return $capture;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdown::Pod - Convert Markdown to POD

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use Markdown::Pod;
    
    my $m2p = Markdown::Pod->new;
    my $pod = $m2p->markdown_to_pod(
        markdown => $markdown,
    );

=head1 DESCRIPTION

This module parses Markdown text and return POD text.
It uses L<Markdent> module to parse Markdown.
Due to POD doesn't support blockquoted HTML tag,
so quoted text of Markdown will not be handled properly.
Quoted text will be converted to POD verbatim section.

=head1 ATTRIBUTES

=head2 markdown

markdown text

=head2 encoding

encoding to use. Available type of encoding is same as L<Encode> module.

=head1 METHODS

=head2 new

create Markdown::Pod object

=head2 markdown_to_pod

convert markdown text to POD text

=head1 SEE ALSO

=over

=item *

L<Markdent>

=item *

L<Pod::Markdown>

=item *

L<Text::MultiMarkdown>, L<Text::Markdown>

=back

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/keedi/Markdown-Pod/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/keedi/Markdown-Pod>

  git clone https://github.com/keedi/Markdown-Pod.git

=head1 AUTHOR

김도형 - Keedi Kim <keedi@cpan.org>

=head1 CONTRIBUTORS

=for stopwords Andrew Speer (ASPEER) Jason McIntosh (JMAC) Zakariyya Mughal (ZMUGHAL)

=over 4

=item *

Andrew Speer (ASPEER) <andrew@webdyne.org>

=item *

Jason McIntosh (JMAC) <jmac@jmac.org>

=item *

Zakariyya Mughal (ZMUGHAL) <zmughal@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Keedi Kim.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
