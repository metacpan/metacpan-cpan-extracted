#!perl

package HTML::ExtractMain;
use Carp qw( carp );
use HTML::TreeBuilder;
use Object::Destroyer 2.0;
use Scalar::Util qw( blessed refaddr );
use base qw( Exporter );
use strict;
use warnings;

our @EXPORT_OK = qw( extract_main_html );

sub extract_main_html {
    my $arg = shift;

    unless ( defined $arg ) {
        carp 'extract_main_html requires HTML content as an argument';
        return;
    }

    my $tree;
    if ( ref $arg and blessed $arg and $arg->isa('HTML::TreeBuilder') ) {
        $tree = $arg;
    } else {
        my $raw_html = $arg;

        $tree = eval { HTML::TreeBuilder->new_from_content($raw_html) };
        if ( !$tree ) {
            carp 'check HTML input, could not create new HTML::TreeBuilder';
            return;
        }
    }

    my %options = @_;
    if ( defined $options{output_type} ) {
        $options{output_type} = lc( $options{output_type} );
    } else {
        $options{output_type} = "xhtml";
    }

    # Remove any lingering circular references. Details at:
    # http://www.perl.com/pub/2007/06/07/better-code-through-destruction.html
    my $sentry = Object::Destroyer->new( $tree, 'delete' );

    # Use the Readability algorithm, inspired by:
    # http://lab.arc90.com/experiments/readability/js/readability.js

    # Study all the paragraphs and find the chunk that has the best score.
    # A score is determined by things like: Number of <p>'s, commas,
    #  class names, etc.

    my %parents;
    foreach my $p ( $tree->find_by_tag_name('p') ) {
        my $parent    = $p->parent;
        my $parent_id = refaddr($parent);

        if ( !defined $parents{$parent_id} ) {
            $parents{$parent_id}->{element}     = $parent;
            $parents{$parent_id}->{readability} = 0;

            my $text_to_scan = join q{ },
                grep {defined}
                ( $parent->attr('class'), $parent->attr('id') );

            if ( $text_to_scan =~ m/\b(?:comment|meta|footer|footnote)\b/ ) {
                $parents{$parent_id}->{readability} -= 50;
            } elsif ( $text_to_scan
                =~ m/\b(post|hentry|entry[-]?(content|text|body)?|article[-]?(content|text|body)?)\b/
                ) {
                $parents{$parent_id}->{readability} += 25;
            }
        }

        # add point for each para found
        $parents{$parent_id}->{readability}++;

        # add a point for each comma found in the paragraph
        foreach my $text_ref ( $p->content_refs_list ) {
            my $num_commas = ( ${$text_ref} =~ m/,/g );
            $parents{$parent_id}->{readability} += $num_commas;
        }
    }

    my $best_parent;
    foreach my $id ( keys %parents ) {
        if (   !$best_parent
             || $parents{$id}->{readability} > $best_parent->{readability} ) {
            $best_parent = $parents{$id};
        }
    }

    if ($best_parent) {
        my $best_parent_element = $best_parent->{element};
        $best_parent_element->detach;

        my $output;
        if ( $options{output_type} eq 'tree' ) {
            $output = $best_parent_element;
        } elsif ( $options{output_type} eq 'html' ) {
            $output = $best_parent_element->as_HTML;
        } else {
            $output = $best_parent_element->as_XML;
        }

        unless ( $options{output_type} eq 'tree' ) {
            $output =~ s{^<body>(.*)</body>\s*$}{$1}s;  # kill wrapping <body>
            $best_parent_element->delete;
        }

        return $output;
    } else {
        return;
    }
}

=head1 NAME

HTML::ExtractMain - Extract the main content of a web page

=head1 VERSION

Version 0.63

=cut

our $VERSION = '0.63';

=head1 SYNOPSIS

    use HTML::ExtractMain qw( extract_main_html );

    my $html = <<'END';
    <div id="header">Header</div>
    <div id="nav"><a href="/">Home</a></div>
    <div id="body">
        <p>Foo</p>
        <p>Baz</p>
    </div>
    <div id="footer">Footer</div>
    END

    my $main_html = extract_main_html($html, output_type => 'xhtml');
    if (defined $main_html) {
	# do something with $main_html here
        # $main_html is '<div id="body"><p>Foo</p><p>Baz</p></div>'
    }

=head1 EXPORT

C<extract_main_html> is optionally exported

=head1 FUNCTIONS

=head2 extract_main_html

C<extract_main_html> takes HTML content, and uses the Readability
algorithm to detect the main body of the page, usually skipping
headers, footers, navigation, etc.

The first argument is either an HTML string, or an
HTML::TreeBuilder tree. (If passed a tree, the tree will be modified
and destroyed.)

Remaining arguments are optional and represent key/value options. The
available options are:

=head3 output_type

This determines what format to return data in. If not specified then
xhtml format will be used. Valid formats are:

=over 4

=item C<xhtml>

=item C<html>

=item C<tree>

=back

If C<tree> is selected, then an L<HTML::Element> object will be
returned instead of a string.

If the HTML's main content is found, it's returned in the chosen
output format. The returned HTML/XHTML will I<not> look like what you put
in. (Source formatting, e.g. indentation, will be removed.)

If a most relevant block of content is not found, C<extract_main_html>
returns undef.

=cut

=head1 AUTHOR

Anirvan Chatterjee, C<< <anirvan at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-extractmain at rt.cpan.org>, or through the web interface
at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-ExtractMain>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::ExtractMain

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-ExtractMain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-ExtractMain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-ExtractMain>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-ExtractMain/>

=back

=head1 SEE ALSO

=over 4

=item * C<HTML::Feature>

=item * C<HTML::ExtractContent>

=back

=head1 ACKNOWLEDGEMENTS

The Readability algorithm is ported from Arc90's JavaScript original,
built as part of the excellent Readability application, online at
L<http://lab.arc90.com/experiments/readability/>, repository at
L<http://code.google.com/p/arc90labs-readability/>.

=head1 COPYRIGHT & LICENSE

Copyright 2009-2013 Anirvan Chatterjee, Rupert Lane, kryde, all rights
reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of HTML::ExtractMain

# Local Variables:
# mode: perltidy
# End:
