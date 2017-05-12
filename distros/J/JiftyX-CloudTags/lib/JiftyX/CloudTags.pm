package JiftyX::CloudTags;

use warnings;
use strict;
use Mouse;
use JiftyX::ModelHelpers;

our $VERSION = '0.01';

has 'collection'          => ( is => 'rw', isa => 'Object' );
has 'args'                => (
    is => 'rw',
    isa => 'HashRef'
);

has 'default_link_format' => ( 
    is => 'rw', 
    isa => 'Str' , 
    default => '?id=%i&text=%t&custom=%{hit}'
);

sub set_tags {
    my $self             = shift;
    my $collection_class = shift;
    my %args             = @_;


    my $collection;
    if( ref $collection_class ) {
        $collection = $collection_class;
    }
    else {
        $collection = M($collection_class);
        $collection->unlimit;
    }
    $collection->order_by( column => $args{text_by}, order => 'desc' );
    $self->collection( $collection );
    $self->args( \%args );
}

sub find_quantity {
    my $collection = shift;
    my $size_by    = shift;
    my ( $min_quantity, $max_quantity ) = ( 0, 0 );
    while( my $c = $collection->next ) {
        my $size = ( ref $c->$size_by ? $c->$size_by->count : $c->$size_by );
        $min_quantity = $size if( $size < $min_quantity );
        $max_quantity = $size if( $size > $max_quantity );
    };
    return ( $min_quantity, $max_quantity );
}


sub render {
    my $self = shift;
    my $collection = $self->collection;
    my %args = %{ $self->args };
    my $link_format = $args{link_format} || $self->default_link_format;

    my $min_fontsize = $args{min_fontsize} || 9;
    my $max_fontsize = $args{max_fontsize} || 48;
    my $fontsize_degree = $max_fontsize - $min_fontsize ;

    my ( $min_quantity , $max_quantity );
    $min_quantity ||= $args{min_quantity};
    $max_quantity ||= $args{max_quantity};
    unless( $min_quantity || $max_quantity ) {
        ( $min_quantity , $max_quantity ) = find_quantity( $collection , $args{size_by} );
    }

    my $degree = $args{degree}
        || ( $fontsize_degree / ( $max_quantity - $min_quantity ) );

    my $offset = 0;
    my $div_width = $args{break_width} || -1;

    my $output = '';
    while( my $c = $collection->next ) {
        my ( $text_acc, $size_acc ) = ( $args{text_by}, $args{size_by} );

        my $id = $c->id;
        my $text = $c->$text_acc;
        my $size = ( ref $c->$size_acc ? $c->$size_acc->count : $c->size_acc );
        my $fontsize = int( $size * $degree + $min_fontsize );

        my $url = $link_format;
        $url =~ s/%i/$id/g;
        $url =~ s/%t/$text/g;

        # custom column
        $url =~ s/\%\{(\w+)\}/ $c->$1 /eg;

        # my $url = 
        $output .= qq|
            <span class="cloudtags" style="font-size: ${fontsize}px;">
                <a href="$url">$text</a>
            </span>
        |;

        $offset += length($text) * $fontsize;
        if ( $div_width != -1 and $offset > $div_width ) {
            $output .= q|<br/>|;
            $offset = 0;
        }
    }

    $output;
}

1; 

__END__

=head1 NAME

JiftyX::CloudTags 

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use JiftyX::CloudTags;

    my $cloudtag = JiftyX::CloudTags->new( 'LabelCollection'  ,
        text_by => 'name',
        size_by => 'related_posts',
        link_format => '?id=%i',
    );
    $cloudtag->render;

in more detail:

    my $cloudtag = JiftyX::CloudTags->new( 'LabelCollection'  ,
        text_by => 'name',
        size_by => 'related_posts',

        link_format => '?id=%i&text=%t&%{custom_column}',

        min_fontsize => 9,
        max_fontsize => 72,
        degree => 6,

        min_quantity => 0,
        max_quantity => 100,

        break_width => 200,   # in pixel

    );
    $cloudtag->render;



=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=head2 set_tags COLLECTION or COLLECTION_NAME , ARGS

=over 4

=item COLLECTION or COLLECTION_NAME

=item ARGS

Arguments:

=over 8

=item size_by

column name

=item text_by

column name

=item link_format

In string.  C<%i> is for id , C<%t> is for text. C<%{custom_column}> for custom
column name of your model object.

=back

Optional Arguments:

=over 8

=item min_quantity

=item max_quantity

if you've know the quantity boundary , then we dont need to find the boundary
by iterating collection items

=item min_fontsize

the minimal font size

=item max_fontsize

the maximal fontsize

=item degree

font size degree , the quantiy of the model will be multiply by the font size degree

=item break_width

break line if the tag text width overflows

=back
    

=back

=head2 find_quantity COLLECTION , SIZE_BY

find_quantity method returns (min,max) list. by searching the max,min value in
collection object.

=over 4

=item COLLECCTION

COLLECTION is a L<Jifty::DBI::Collection> Object. it will be something like
L<MyApp::Model::LabelCollection> object in your application.

=item SIZE_BY

the column name of your model.

=back 

=head2 render 

return the rendered html of cloudtags.

=head1 AUTHOR

Cornelius, C<< <cornelius.howl at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-jiftyx-cloudtags at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JiftyX-CloudTags>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JiftyX::CloudTags


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JiftyX-CloudTags>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JiftyX-CloudTags>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JiftyX-CloudTags>

=item * Search CPAN

L<http://search.cpan.org/dist/JiftyX-CloudTags/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Cornelius, all rights reserved.

This program is released under the following license: GPL

=cut
