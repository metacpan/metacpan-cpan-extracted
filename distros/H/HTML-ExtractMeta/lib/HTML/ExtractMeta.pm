package HTML::ExtractMeta;
use Moose;
use namespace::autoclean;

use Mojo::DOM;

=head1 NAME

HTML::ExtractMeta - Helper class for extracting useful meta data from HTML pages.

=head1 VERSION

Version 0.21

=cut

our $VERSION = '0.21';

=head1 SYNOPSIS

    use HTML::ExtractMeta;

    my $em = HTML::ExtractMeta->new( $html );

    print "Title       = " . $em->title       . "\n";
    print "Description = " . $em->description . "\n";
    print "Author      = " . $em->author      . "\n";
    print "URL         = " . $em->url         . "\n";
    print "Site name   = " . $em->site_name   . "\n";
    print "Type        = " . $em->type        . "\n";
    print "Locale      = " . $em->locale      . "\n";
    print "Image URL   = " . $em->image_url   . "\n";
    print "Authors     = " . join( ', ', @{$em->authors} )  . "\n";
    print "Keywords    = " . join( ', ', @{$em->keywords} ) . "\n";

=head1 DESCRIPTION

HTML::ExtractMeta is a helper class for extracting useful metadata from HTML
pages, like their title, description, authors etc.

=head1 METHODS

=head2 new( %opts )

Returns a new HTML::ExtractMeta instance. Requires HTML as input argument;

    my $em = HTML::ExtractMeta->new( $html );

=cut

has 'html' => (
    isa => 'Str',
    is => 'rw',
    required => 1,
    default => '',
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( @_ == 1 && !ref $_[0] ) {
        return $class->$orig( html => $_[0] );
    }
    else {
        return $class->$orig( @_ );
    }
};

has '_dom' => (
    isa => 'Mojo::DOM',
    is => 'ro',
    lazy => 1,
    default => sub { Mojo::DOM->new(shift->html) },
);

has '_meta' => (
    isa => 'ArrayRef[HashRef]',
    is => 'ro',
    lazy => 1,
    default => sub {
        my $self = shift;

        # my %meta = ();
        my @meta = ();

        foreach ( $self->_dom->find('meta')->each ) {
            my $name    = $_->attr( 'name' )    // $_->attr( 'property' ) // $_->attr( 'itemprop' ) // '';
            my $content = $_->attr( 'content' ) // '';

            if ( length $name && length $content ) {
                # $meta{ $name } = squish( $content );
                push( @meta, { $name => squish($content) } );
            }
        }

        # return \%meta;
        return \@meta;
    },
);

sub _get {
    my $self = shift;
    my $what = shift || [];

    my @data = ();

    foreach my $w ( @{$what} ) {
        foreach my $m ( @{$self->_meta} ) {
            if ( my $d = $m->{$w} ) {
                push( @data, $d );
            }
        }
    }

    return \@data;
}

=head2 title

Returns the HTML page's title.

=cut

sub title {
    my $self = shift;

    my @ids = (
        'og:title',
        'twitter:title',
    );

    my $title = $self->_get( \@ids )->[0] // '';

    $title =~ s/\s*\|.+//;

    $title =~ s/^\w+\.\w+\s+\-\s+//;
    $title =~ s/^\w+\.\w+\s+\–\s+//;

    $title =~ s/\s+\-\s+[[:upper:]].+//;
    $title =~ s/\s+\–\s+[[:upper:]].+//;

    return squish( $title );
}

=head2 description

Returns the HTML page's description.

=cut

sub description {
    my $self = shift;

    my @ids = (
        'og:description',
        'twitter:description',
        'description',
        'Description',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 url

Returns the HTML page's URL.

=cut

sub url {
    my $self = shift;

    my @ids = (
        'og:url',
        'twitter:url',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 image_url

Returns the HTML page's descriptive image URL.

=cut

sub image_url {
    my $self = shift;

    my @ids = (
        'og:image',
        'og:image:url',
        'og:image:secure_url',
        'twitter:image',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 site_name

Returns the HTML page's site name.

=cut

sub site_name {
    my $self = shift;

    my @ids = (
        'og:site_name',
        'application-name',
        'twitter:site',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 type

Returns the HTML page's type.

=cut

sub type {
    my $self = shift;

    my @ids = (
        'og:type',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 locale

Returns the HTML page's locale.

=cut

sub locale {
    my $self = shift;

    my @ids = (
        'og:locale',
        'inLanguage',
        'Content-Language',
    );

    return $self->_get( \@ids )->[0] // '';
}

=head2 authors

Returns the HTML page's author names as an array reference.

=cut

sub authors {
    my $self = shift;

    my @ids = (
        'article:author',
        'author',
        'Author',
        'twitter:creator',
        'DC.creator',
    );

    my @authors = ();

    foreach my $id ( @ids ) {
        foreach ( @{$self->_get([$id])} ) {
            push( @authors, $_ );
        }
    }

    return \@authors;
}

=head2 author

Helper method; returns the HTML page's first mentioned author. Basically the
same as:

    my $author = $em->authors->[0];

=cut

sub author {
    my $self = shift;

    return $self->authors->[0] // '';
}

=head2 keywords

Returns the HTML page's keywords.

=cut

sub keywords {
    my $self = shift;

    my @ids = (
        'keywords',
    );

    my @keywords = ();
    my %seen     = ();

    foreach my $id ( @ids ) {
        if ( my $keywords = $self->_get([$id])->[0] ) {
            foreach my $keyword ( split(/\s*,\s*/, $keywords) ) {
                unless ( $seen{$keyword} ) {
                    push( @keywords, $keyword );
                    $seen{ $keyword }++;
                }
            }
        }
    }

    return \@keywords;
}

sub squish {
    my $str = shift // '';

    $str =~ s/\s+/ /sg;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;

    return $str;
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-ExtractMeta>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTML::ExtractMeta

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-ExtractMeta>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-ExtractMeta>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-ExtractMeta/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012-2016 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
