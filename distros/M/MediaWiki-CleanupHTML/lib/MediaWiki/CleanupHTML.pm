package MediaWiki::CleanupHTML;
$MediaWiki::CleanupHTML::VERSION = '0.0.5';
use 5.008;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Scalar::Util (qw(blessed));



sub new
{
    my $class = shift;

    my $self = bless {}, $class;

    $self->_init(@_);

    return $self;
}

sub _is_processed
{
    my $self = shift;

    if (@_)
    {
        $self->{_is_processed} = shift;
    }

    return $self->{_is_processed};
}

sub _fh
{
    my $self = shift;

    if (@_)
    {
        $self->{_fh} = shift;
    }

    return $self->{_fh};
}

sub _tree
{
    my $self = shift;

    if (@_)
    {
        $self->{_tree} = shift;
    }

    return $self->{_tree};
}

sub _init
{
    my ( $self, $args ) = @_;

    if ( !exists( $args->{'fh'} ) )
    {
        Carp::confess(
            "MediaWiki::CleanupHTML->new was not passed a filehandle.");
    }

    $self->_fh( $args->{fh} );

    my $tree = HTML::TreeBuilder::XPath->new;

    $self->_tree($tree);

    $self->_tree->parse_file( $self->_fh );

    $self->_is_processed(0);

    return;
}

sub _process
{
    my $self = shift;

    if ( $self->_is_processed() )
    {
        return;
    }

    my $tree = $self->_tree;

    {
        my @nodes = $tree->findnodes('//div[@class="editsection"]');

        foreach my $n (@nodes)
        {
            $n->detach();
            $n->delete();
        }
    }

    {
        my @nodes = map { $tree->findnodes( '//h' . $_ ) } ( 2 .. 4 );

        foreach my $h2 (@nodes)
        {
            my $a_tag = $h2->left();
            if (   blessed($a_tag)
                && $a_tag->tag() eq "a"
                && $a_tag->attr('name') )
            {
                my $id = $a_tag->attr('name');
                $h2->attr( 'id', $id );
                $a_tag->detach();
                $a_tag->delete();
            }
        }
    }

    my (@divs_to_delete) = (
        $tree->findnodes('//div[@class="printfooter"]'),
        $tree->findnodes('//div[@id="catlinks"]'),
        $tree->findnodes('//div[@class="visualClear"]'),
        $tree->findnodes('//div[@id="column-one"]'),
        $tree->findnodes('//div[@id="footer"]'),
        $tree->findnodes('//head//style'),
        $tree->findnodes('//script'),
    );

    foreach my $div (@divs_to_delete)
    {
        $div->detach();
        $div->delete();
    }

    $self->_is_processed(1);

    return;
}


sub print_into_fh
{
    my ( $self, $fh ) = @_;

    $self->_process();

    print {$fh} $self->_tree->as_XML();
}


sub destroy_resources
{
    my $self = shift;

    $self->_tree->delete();
    $self->_tree( undef() );

    return;
}

sub DESTROY
{
    my $self = shift;

    $self->destroy_resources();

    return;
}


1;    # End of MediaWiki::CleanupHTML

__END__

=pod

=encoding UTF-8

=head1 NAME

MediaWiki::CleanupHTML - cleanup the MediaWiki-generated HTML from MediaWiki
embellishments.

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

    use MediaWiki::CleanupHTML;

    open my $fh, '<:encoding(UTF-8)', $filename
        or die "Cannot open '$filename' - $!";

    my $cleaner = MediaWiki::CleanupHTML->new({ fh => $fh });

    open my $out_fh, '>:encoding(UTF-8)', $processed_filename
        or die "Cannot open '$processed_filename' for output - $!";

    $cleaner->print_into_fh($out_fh);

    $cleaner->destroy_resources();

=head1 DESCRIPTION

The HTML rendered on MediaWiki pages is full of MediaWiki-specific
embellishments such as edit sections. This module attempts to clean it up
and return a more straightforward HTML. Note that the HTML returned by
MediaWiki APIs may not always available (for instance if the wiki is down), so
this module should be considered a fallback.

=head1 SUBROUTINES/METHODS

=head2 MediaWiki::CleanupHTML->new({fh => $fh})

The constructor - accepts the filehandle from which to read the XHTML.

=head2 $cleaner->print_into_fh($fh)

Output to a filehandle. The filehandle should be able to process UTF-8 output.

=head2 $cleaner->destroy_resources()

Destroy the allocated resources (of the L<HTML::TreeBuilder> tree, etc.). Must
be called before destruction.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to C<bug-mediawiki-cleanuphtml at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=MediaWiki-CleanupHTML>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MediaWiki::CleanupHTML

You can also look for information at:

=over 4

=item * MetaCPAN

L<http://metacpan.org/release/MediaWiki-CleanupHTML>

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=MediaWiki-CleanupHTML>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/MediaWiki-CleanupHTML>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MediaWiki-CleanupHTML>

=back

=head1 ACKNOWLEDGEMENTS

The developers of L<HTML::TreeBuilder::XPath>, L<HTML::TreeBuilder> and related
modules for their helpful code.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shlomi Fish.

This program is distributed under the MIT / Expat License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/MediaWiki-CleanupHTML>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/MediaWiki-CleanupHTML>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MediaWiki-CleanupHTML>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/MediaWiki-CleanupHTML>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/MediaWiki-CleanupHTML>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/M/MediaWiki-CleanupHTML>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=MediaWiki-CleanupHTML>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=MediaWiki::CleanupHTML>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-mediawiki-cleanuphtml at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=MediaWiki-CleanupHTML>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/perl-mediawiki-cleanuphtml>

  git clone git://github.com/shlomif/perl-mediawiki-cleanuphtml.git

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/perl-mediawiki-cleanuphtml/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=cut
