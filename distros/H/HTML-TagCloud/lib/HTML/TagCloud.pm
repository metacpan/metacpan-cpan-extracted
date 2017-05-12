package HTML::TagCloud;
use strict;
use warnings;
our $VERSION = '0.38';

use constant EMPTY_STRING => q{};

sub new {
    my $class = shift;
    my $self  = {
        counts                    => {},
        urls                      => {},
        category_for              => {},
        categories                => [],
        levels                    => 24,
        distinguish_adjacent_tags => 0,
        @_
    };
    bless $self, $class;
    return $self;
}

sub add {
    my ( $self, $tag, $url, $count, $category ) = @_;
    $self->{counts}->{$tag} = $count;
    $self->{urls}->{$tag}   = $url;
    if ( scalar @{ $self->{categories} } > 0 && defined $category ) {
        $self->{category_for}->{$tag} = $category;
    }
}

sub add_static {
    my ( $self, $tag, $count, $category ) = @_;
    $self->{counts}->{$tag} = $count;

    if ( scalar @{ $self->{categories} } > 0 && defined $category ) {
        $self->{category_for}->{$tag} = $category;
    }
}

sub css {
    my ($self) = @_;
    my $css = q(
#htmltagcloud {
  text-align:  center;
  line-height: 1;
}
);
    foreach my $level ( 0 .. $self->{levels} ) {
        if ( $self->{distinguish_adjacent_tags} ) {
            $css .= $self->_css_for_tag( $level, 'even' );
            $css .= $self->_css_for_tag( $level, 'odd' );
        }
        else {
            $css .= $self->_css_for_tag( $level, q{} );
        }
    }
    return $css;
}

sub _css_for_tag {
    my ( $self, $level, $subclass ) = @_;
    my $font = 12 + $level;
    return <<"END_OF_TAG";
span.tagcloud${level}${subclass} {font-size: ${font}px;}
span.tagcloud${level}${subclass} a {text-decoration: none;}
END_OF_TAG
}

sub tags {
    my ( $self, $limit ) = @_;
    my $counts       = $self->{counts};
    my $urls         = $self->{urls};
    my $category_for = $self->{category_for};
    my @tags         = sort { $counts->{$b} <=> $counts->{$a} || $a cmp $b } keys %$counts;
    @tags = splice( @tags, 0, $limit ) if defined $limit;

    return unless scalar @tags;

    my $min = log( $counts->{ $tags[-1] } );
    my $max = log( $counts->{ $tags[0] } );
    my $factor;

    # special case all tags having the same count
    if ( $max - $min == 0 ) {
        $min    = $min - $self->{levels};
        $factor = 1;
    }
    else {
        $factor = $self->{levels} / ( $max - $min );
    }

    if ( scalar @tags < $self->{levels} ) {
        $factor *= ( scalar @tags / $self->{levels} );
    }
    my @tag_items;
    foreach my $tag ( sort @tags ) {
        my $tag_item;
        $tag_item->{name}  = $tag;
        $tag_item->{count} = $counts->{$tag};
        $tag_item->{url}   = $urls->{$tag};
        $tag_item->{level}
            = int( ( log( $tag_item->{count} ) - $min ) * $factor );
        $tag_item->{category} = $category_for->{$tag};
        push @tag_items, $tag_item;
    }
    return @tag_items;
}

sub html {
    my ( $self, $limit ) = @_;
    my $html
        = scalar @{ $self->{categories} } > 0
        ? $self->html_with_categories($limit)
        : $self->html_without_categories($limit);
    return $html;
}

sub html_without_categories {
    my ( $self, $limit ) = @_;
    my $html = $self->_html_for( [ $self->tags($limit) ] );
}

sub _html_for {
    my ( $self, $tags_ref ) = @_;
    my $ntags = scalar( @{$tags_ref} );
    return EMPTY_STRING if $ntags == 0;

    # Format the HTML division.
    my $html
        = $ntags == 1
        ? $self->_html_for_single_tag($tags_ref)
        : $self->_html_for_multiple_tags($tags_ref);

    return $html;
}

sub _html_for_single_tag {
    my ( $self, $tags_ref ) = @_;

    # Format the contents of the div.
    my $tag_ref = $tags_ref->[0];
    my $html = $self->_format_span( @{$tag_ref}{qw(name url)}, 1, 1 );

    return qq{<div id="htmltagcloud">$html</div>\n};
}

sub _html_for_multiple_tags {
    my ( $self, $tags_ref ) = @_;

    # Format the contents of the div.
    my $html    = EMPTY_STRING;
    my $is_even = 1;
    foreach my $tag ( @{$tags_ref} ) {
        my $span
            = $self->_format_span( @{$tag}{qw(name url level)}, $is_even );
        $html .= "$span\n";
        $is_even = !$is_even;
    }
    $html = qq{<div id="htmltagcloud">
$html</div>};
    return $html;
}

sub html_with_categories {
    my ( $self, $limit ) = @_;

    # Get the collection of tags, organized by category.
    my $tags_by_category_ref = $self->_tags_by_category($limit);
    return EMPTY_STRING if !defined $tags_by_category_ref;

    # Format the HTML document.
    my $html = EMPTY_STRING;
    CATEGORY:
    for my $category ( @{ $self->{categories} } ) {
        my $tags_ref = $tags_by_category_ref->{$category};
        $html .= $self->_html_for_category( $category, $tags_ref );
    }

    return $html;
}

sub _html_for_category {
    my ( $self, $category, $tags_ref ) = @_;

    # Format the HTML.
    my $html
        = qq{<div class='$category'>}
        . $self->_html_for($tags_ref)
        . qq{</div>};

    return $html;
}

sub _tags_by_category {
    my ( $self, $limit ) = @_;

    # Get the tags.
    my @tags = $self->tags($limit);
    return if scalar @tags == 0;

    # Build the categorized collection of tags.
    my %tags_by_category;
    for my $tag_ref (@tags) {
        my $category
            = defined $tag_ref->{category}
            ? $tag_ref->{category}
            : '__unknown__';
        push @{ $tags_by_category{$category} }, $tag_ref;
    }

    return \%tags_by_category;
}

sub html_and_css {
    my ( $self, $limit ) = @_;
    my $html = qq{<style type="text/css">\n} . $self->css . "</style>";
    $html .= $self->html($limit);
    return $html;
}

sub _format_span {
    my ( $self, $name, $url, $level, $is_even ) = @_;
    my $subclass = q{};
    if ( $self->{distinguish_adjacent_tags} ) {
        $subclass = $is_even ? 'even' : 'odd';
    }
    my $span_class = qq{tagcloud$level$subclass};
    my $span       = qq{<span class="$span_class">};
    if ( defined $url ) {
        $span .= qq{<a href="$url">};
    }
    $span .= $name;
    if ( defined $url ) {
        $span .= qq{</a>};
    }
    $span .= qq{</span>};
}

1;

__END__

=head1 NAME

HTML::TagCloud - Generate An HTML Tag Cloud

=head1 SYNOPSIS

  # A cloud with tags that link to other web pages.
  my $cloud = HTML::TagCloud->new;
  $cloud->add($tag1, $url1, $count1);
  $cloud->add($tag2, $url2, $count2);
  $cloud->add($tag3, $url3, $count3);
  my $html = $cloud->html_and_css(50);

  # A cloud with tags that do not link to other web pages.
  my $cloud = HTML::TagCloud->new;
  $cloud->add_static($tag1, $count1);
  $cloud->add_static($tag2, $count2);
  $cloud->add_static($tag3, $count3);
  my $html = $cloud->html_and_css(50);

  # A cloud that is comprised of tags in multiple categories.
  my $cloud = HTML::TagCloud->new;
  $cloud->add($tag1, $url1, $count1, $category1);
  $cloud->add($tag2, $url2, $count2, $category2);
  $cloud->add($tag3, $url3, $count3, $category3);
  my $html = $cloud->html_and_css(50);

  # The same cloud without tags that link to other web pages.
  my $cloud = HTML::TagCloud->new;
  $cloud->add_static($tag1, $count1, $category1);
  $cloud->add_static($tag2, $count2, $category2);
  $cloud->add_static($tag3, $count3, $category3);
  my $html = $cloud->html_and_css(50);

  # Obtaining uncategorized HTML for a categorized tag cloud.
  my $html = $cloud->html_without_categories();

  # Explicitly requesting categorized HTML.
  my $html = $cloud->html_with_categories();

=head1 DESCRIPTION

The L<HTML::TagCloud> module enables you to generate "tag clouds" in
HTML. Tag clouds serve as a textual way to visualize terms and topics
that are used most frequently. The tags are sorted alphabetically and a
larger font is used to indicate more frequent term usage.

Example sites with tag clouds: L<http://www.43things.com/>,
L<http://www.astray.com/recipes/> and
L<http://www.flickr.com/photos/tags/>.

This module provides a simple interface to generating a CSS-based HTML
tag cloud. You simply pass in a set of tags, their URL and their count.
This module outputs stylesheet-based HTML. You may use the included CSS
or use your own.

=head1 CONSTRUCTOR

=head2 new

The constructor takes a few optional arguments:

  my $cloud = HTML::TagCloud->new(levels=>10);

if not provided, levels defaults to 24

  my $cloud = HTML::TagCloud->new(distinguish_adjacent_tags=>1);

If distinguish_adjacent_tags is true HTML::TagCloud will use different CSS
classes for adjacent tags in order to be able to make it easier to
distinguish adjacent multi-word tags.  If not specified, this parameter
defaults to a false value.

  my $cloud = HTML::TagCloud->new(categories=>\@categories);

If categories are provided then tags are grouped in separate divisions by
category when the HTML fragment is generated.

=head1 METHODS

=head2 add

This module adds a tag into the cloud. You pass in the tag name, its URL
and its count:

  $cloud->add($tag1, $url1, $count1);
  $cloud->add($tag2, $url2, $count2);
  $cloud->add($tag3, $url3, $count3);

=head2 add_static

This module adds a tag that does not link to another web page into the
cloud.  You pass in the tag name and its count:

  $cloud->add_static($tag1, $count1);
  $cloud->add_static($tag2, $count2);

=head2 tags($limit)

Returns a list of hashrefs representing each tag in the cloud, sorted by
alphabet. Each tag has the following keys: name, count, url and level.

=head2 css

This returns the CSS that will format the HTML returned by the html()
method with tags which have a high count as larger:

  my $css  = $cloud->css;

=head2 html($limit)

This returns the tag cloud as HTML without the embedded CSS (you should
use both css() and html() or simply the html_and_css() method). If any
categories were specified when items were being placed in the cloud then
the tags will be organized into divisions by category name.  If a limit
is provided, only the top $limit tags are in the cloud, otherwise all the
tags are in the cloud:

  my $html = $cloud->html(200);

=head2 html_with_categories($limit)

This returns the tag cloud as HTML without the embedded CSS.  The tags will
be arranged into divisions by category.  If a limit is provided, only the top
$limit tags are in the cloud.  Otherwise, all tags are in the cloud.

=head2 html_without_categories($limit)

This returns the tag cloud as HTML without the embedded CSS.  The tags will
not be grouped by category if this method is used to generate the HTML.

=head2 html_and_css($limit)

This returns the tag cloud as HTML with embedded CSS. If a limit is
provided, only the top $limit tags are in the cloud, otherwise all the
tags are in the cloud:

  my $html_and_css = $cloud->html_and_css(50);

=head1 AUTHOR

Leon Brocard, C<< <acme@astray.com> >>.

=head1 COPYRIGHT

Copyright (C) 2005-6, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
