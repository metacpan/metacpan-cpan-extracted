package HTML::Differences;
# git description: c74b954

$HTML::Differences::VERSION = '0.01';
use strict;
use warnings;

use Exporter qw( import );
use HTML::TokeParser;
use Text::Diff qw( diff );

our @EXPORT_OK = qw( html_text_diff diffable_html );

sub html_text_diff {
    my $html1 = shift;
    my $html2 = shift;
    my %p     = @_;

    return diff(
        diffable_html( $html1, %p ),
        diffable_html( $html2, %p ),
        {
            CONTEXT => ( $p{context} || 2**31 ),
            STYLE => $p{style} || 'Table',
        },
    );
}

{
    my %dispatch = (
        D  => 'declaration',
        S  => 'start_tag',
        E  => 'end_tag',
        T  => 'text',
        C  => 'comment',
        PI => 'processing_instruction',
    );

    sub diffable_html {
        my $html = shift;
        my %p    = @_;

        my $accumulator = _HTMLAccumulator->new( $p{ignore_comments} );

        my $parser = HTML::TokeParser->new( ref $html ? $html : \$html );
        while ( my $token = $parser->get_token() ) {
            my $type   = shift @{$token};
            my $method = $dispatch{$type}
                or die "Unknown token type: $type";

            $accumulator->$method( @{$token} );
        }

        return $accumulator->html_as_arrayref();
    }
}

package    # hide from PAUSE
    _HTMLAccumulator;

use HTML::Entities qw( encode_entities );

sub new {
    my $class           = shift;
    my $ignore_comments = shift;

    return bless {
        ignore_comments => $ignore_comments,
        html            => [],
        in_pre          => 0,
    }, $class;
}

sub html_as_arrayref { $_[0]->{html} }

sub declaration {
    push @{ $_[0]->{html} }, $_[1];
}

sub start_tag {
    my $self = shift;
    my $tag  = shift;
    my $attr = shift;

    # Things like <hr/> give us "hr/" as the value of $tag.
    $tag =~ s{\s*/$}{};

    # And <hr /> gives us "/" as an attribute.
    delete $attr->{'/'};

    if ( $tag eq 'pre' ) {
        $self->{in_pre} = 1;
    }

    my $text = '<' . $tag;
    if ( $attr && %{$attr} ) {
        my @attrs;
        for my $key ( sort keys %{$attr} ) {
            push @attrs,
                  $key . '='
                . q{"}
                . encode_entities( $attr->{$key} )
                . q{"};
        }
        $text .= q{ } . join q{ }, @attrs;
    }
    $text .= '>';

    push @{ $self->{html} }, $text;
}

sub end_tag {
    my $self = shift;
    my $tag  = shift;

    if ( $tag eq 'pre' ) {
        $self->{in_pre} = 0;
    }

    push @{ $self->{html} }, '</' . $tag . '>';
}

sub text {
    my $self = shift;
    my $text = shift;

    unless ( $self->{in_pre} ) {
        return unless $text =~ /\S/;
        $text =~ s/^\s+|\s+$//g;
        $text =~ s/\s+/ /s;
    }

    push @{ $self->{html} }, $text;
}

sub comment {
    my $self = shift;

    return if $self->{ignore_comments};

    push @{ $self->{html} }, $_[0];
}

sub processing_instruction {
    my $self = shift;
    push @{ $self->{html} }, $_[0];
}

1;

# ABSTRACT: Reasonable sane HTML diffing

__END__

=pod

=head1 NAME

HTML::Differences - Reasonable sane HTML diffing

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use HTML::Differences qw( html_text_diff );

    my $html1 = <<'EOF';
    <p>Some text</p>
    EOF

    my $html2 = <<'EOF';
    <p>Some <strong>strong</strong> text</p>
    EOF

    print html_text_diff( $html1, $html2 );

=head1 DESCRIPTION

This module provides a reasonable sane way to get the diff between two HTML
documents or fragments. Under the hood, it uses L<HTML::Parser>.

=head2 How the Diffing Works

Internally, this module converts the HTML it gets into an array reference
containing each unique HTML token. These tokens consists of things such as the
doctype declaration, tag start & end, text, etc.

All whitespace between two pieces of text is converted to a single space,
I<except> when inside a C<< <pre> >> block. Leading and trailing space on text
is also stripped out.

Start tags are normalized so that attributes appear in sorted order, and all
quotes are converted to double quotes, with one space before each
attribute. Self-closing tags (like C<< <hr/> >>) are converted to their
simpler form (C<< <hr> >>).

Note that because L<HTML::Parser> decodes HTML entities inside attribute
values, this module cannot distinguish between two attributes where one
contains an entity and one does not.

Missing end tags I<are not> added, and will show up in the diff.

Comments are included by default, but you can pass a flag to ignore them.

=head1 IMPORTABLE SUBROUTINES

This module offers two optionally importable subroutines. Nothing is exported
by default.

=head2 html_text_diff( $html1, $html2, %options )

This subroutine uses L<Text::Diff>'s C<diff()> subroutine to provide a string
version of the diff between the two pieces of HTML provided.

The HTML can be passed as a plain scalar or as a reference to a scalar.

After the two HTML parameters, you can pass key/value pairs as options:

=over 4

=item * ignore_comments

If this is true, then comments are ignored for the purpose of the diff. This
defaults to false.

=item * style

The style for the diff. This defaults to "Table". See L<Text::Diff> for the
available options.

=item * context

The amount of context to show in the diff. This defaults to C<2**31> to
include all the context. You can set this to some smaller value if you prefer.

=back

=head2 diffable_html( $html1, $html2, %options )

This returns an array reference of strings suitable for passing to any of
L<Algorithm::Diff>'s methods or exported subroutines.

The only option currently accepted is C<ignore_comments>.

=head1 WHY THIS MODULE EXISTS

There are a couple other modules out there that do HTML diffs, so why write
this one?

The L<HTML::Diff> module uses regexes to parse HTML. This is crazy.

The L<Test::HTML::Differences> module attempts to fix up the HTML a little too
much for my purposes. It ends up ignoring missing end tags or breaking on them
in various ways.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
