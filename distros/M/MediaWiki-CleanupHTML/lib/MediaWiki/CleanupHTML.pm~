package MediaWiki::CleanupHTML;

use 5.008;

use strict;
use warnings;

use HTML::TreeBuilder::XPath;
use Scalar::Util (qw(blessed));

=head1 NAME

MediaWiki::CleanupHTML - cleanup the MediaWiki-generated HTML from MediaWiki
embellishments.

=head1 VERSION

Version 0.0.2

=cut

our $VERSION = '0.0.2';


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

=cut

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
    my ($self, $args) = @_;

    if (!exists($args->{'fh'}))
    {
        Carp::confess("MediaWiki::CleanupHTML->new was not passed a filehandle.");
    }

    $self->_fh($args->{fh});

    my $tree = HTML::TreeBuilder::XPath->new;

    $self->_tree($tree);

    $self->_tree->parse_file($self->_fh);

    $self->_is_processed(0);

    return;
}


sub _process
{
    my $self = shift;

    if ($self->_is_processed())
    {
        return;
    }

    my $tree = $self->_tree;

    {
        my @nodes = $tree->findnodes( '//div[@class="editsection"]' );

        foreach my $n (@nodes)
        {
            $n->detach();
            $n->delete();
        }
    }

    {
        my @nodes = map { $tree->findnodes( '//h' . $_ ) } (2 .. 4);

        foreach my $h2 (@nodes)
        {
            my $a_tag = $h2->left();
            if (blessed($a_tag) && $a_tag->tag() eq "a" && $a_tag->attr('name'))
            {
                my $id = $a_tag->attr('name');
                $h2->attr('id', $id);
                $a_tag->detach();
                $a_tag->delete();
            }
        }
    }

    my (@divs_to_delete) =
    (
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

=head2 $cleaner->print_into_fh($fh)

Output to a filehandle. The filehandle should be able to process UTF-8 output.

=cut

sub print_into_fh
{
    my ($self, $fh) = @_;

    $self->_process();

    print {$fh} $self->_tree->as_XML();
}

=head2 $cleaner->destroy_resources()

Destroy the allocated resources (of the L<HTML::TreeBuilder> tree, etc.). Must
be called before destruction.

=cut

sub destroy_resources
{
    my $self = shift;

    $self->_tree->delete();
    $self->_tree(undef());

    return;
}

sub DESTROY
{
    my $self = shift;

    $self->destroy_resources();

    return;
}

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

This program is distributed under the MIT (X11) License:
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


=cut

1; # End of MediaWiki::CleanupHTML
