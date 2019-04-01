package HTML::Latemp::News;
$HTML::Latemp::News::VERSION = '0.2.1';
use warnings;
use strict;

use 5.014;


package HTML::Latemp::News::Base;
$HTML::Latemp::News::Base::VERSION = '0.2.1';
use CGI ();

sub new
{
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->initialize(@_);
    return $self;
}

package HTML::Latemp::News::Item;
$HTML::Latemp::News::Item::VERSION = '0.2.1';
our @ISA = (qw(HTML::Latemp::News::Base));

sub author
{
    my $self = shift;

    if (@_)
    {
        $self->{author} = shift;
    }

    return $self->{author};
}

sub category
{
    my $self = shift;

    if (@_)
    {
        $self->{category} = shift;
    }

    return $self->{category};
}

sub date
{
    my $self = shift;

    if (@_)
    {
        $self->{date} = shift;
    }

    return $self->{date};
}

sub description
{
    my $self = shift;

    if (@_)
    {
        $self->{description} = shift;
    }

    return $self->{description};
}

sub id
{
    my $self = shift;

    if (@_)
    {
        $self->{id} = shift;
    }

    return $self->{id};
}

sub index
{
    my $self = shift;

    if (@_)
    {
        $self->{index} = shift;
    }

    return $self->{index};
}

sub text
{
    my $self = shift;

    if (@_)
    {
        $self->{text} = shift;
    }

    return $self->{text};
}

sub title
{
    my $self = shift;

    if (@_)
    {
        $self->{title} = shift;
    }

    return $self->{title};
}

sub initialize
{
    my $self = shift;

    my (%args) = (@_);

    foreach my $k ( keys(%args) )
    {
        if ( !$self->can($k) )
        {
            die "Unknown property for HTML::Latemp::News::Item - \"$k\"!";
        }
        $self->can($k)->( $self, $args{$k} );
    }
}

package HTML::Latemp::News;

our @ISA = (qw(HTML::Latemp::News::Base));

sub copyright
{
    my $self = shift;

    if (@_)
    {
        $self->{copyright} = shift;
    }

    return $self->{copyright};
}

sub description
{
    my $self = shift;

    if (@_)
    {
        $self->{description} = shift;
    }

    return $self->{description};
}

sub docs
{
    my $self = shift;

    if (@_)
    {
        $self->{docs} = shift;
    }

    return $self->{docs};
}

sub generator
{
    my $self = shift;

    if (@_)
    {
        $self->{generator} = shift;
    }

    return $self->{generator};
}

sub items
{
    my $self = shift;

    if (@_)
    {
        $self->{items} = shift;
    }

    return $self->{items};
}

sub language
{
    my $self = shift;

    if (@_)
    {
        $self->{language} = shift;
    }

    return $self->{language};
}

sub link
{
    my $self = shift;

    if (@_)
    {
        $self->{link} = shift;
    }

    return $self->{link};
}

sub managing_editor
{
    my $self = shift;

    if (@_)
    {
        $self->{managing_editor} = shift;
    }

    return $self->{managing_editor};
}

sub lastBuildDate
{
    my $self = shift;

    if (@_)
    {
        $self->{lastBuildDate} = shift;
    }

    return $self->{lastBuildDate};
}

sub pubDate
{
    my $self = shift;

    if (@_)
    {
        $self->{pubDate} = shift;
    }

    return $self->{pubDate};
}

sub rating
{
    my $self = shift;

    if (@_)
    {
        $self->{rating} = shift;
    }

    return $self->{rating};
}

sub title
{
    my $self = shift;

    if (@_)
    {
        $self->{title} = shift;
    }

    return $self->{title};
}

sub ttl
{
    my $self = shift;

    if (@_)
    {
        $self->{ttl} = shift;
    }

    return $self->{ttl};
}

sub webmaster
{
    my $self = shift;

    if (@_)
    {
        $self->{webmaster} = shift;
    }

    return $self->{webmaster};
}
use XML::RSS;

sub input_items
{
    my $self = shift;

    my $items = shift;

    return [ map { $self->input_single_item( $_, $items->[$_] ) }
            ( 0 .. $#$items ) ];
}

sub input_single_item
{
    my $self = shift;
    my ( $index, $inputted_item ) = (@_);

    return HTML::Latemp::News::Item->new( %$inputted_item, 'index' => $index, );
}

sub initialize
{
    my $self = shift;

    my %args = (@_);

    my $items = $args{'news_items'};

    $self->items( $self->input_items($items) );

    $self->title( $args{'title'} );
    $self->link( $args{'link'} );
    $self->language( $args{'language'} );
    $self->rating( $args{'rating'}
            || '(PICS-1.1 "http://www.classify.org/safesurf/" 1 r (SS~~000 1))'
    );
    $self->copyright( $args{'copyright'} || "" );
    $self->docs( $args{'docs'} || "http://blogs.law.harvard.edu/tech/rss" );
    $self->ttl( $args{'ttl'}   || "360" );
    $self->generator( $args{'generator'} || "Perl and XML::RSS" );
    $self->webmaster( $args{'webmaster'} );
    $self->managing_editor( $args{'managing_editor'} || $self->webmaster() );
    $self->description( $args{'description'} );

    if ( defined( my $date = delete $args{lastBuildDate} ) )
    {
        $self->lastBuildDate($date);
    }
    if ( defined( my $date = delete $args{pubDate} ) )
    {
        $self->pubDate($date);
    }

    return 0;
}


sub add_item_to_rss_feed
{
    my $self = shift;
    my %args = (@_);

    my $item     = $args{'item'};
    my $rss_feed = $args{'feed'};

    my $item_url = $self->get_item_url($item);

    $rss_feed->add_item(
        'title'       => $item->title(),
        'link'        => $item_url,
        'permaLink'   => $item_url,
        'enclosure'   => { 'url' => $item_url, },
        'description' => $item->description(),
        'author'      => $item->author(),
        'pubDate'     => $item->date(),
        'category'    => $item->category(),
    );
}

sub get_item_url
{
    my $self = shift;
    my $item = shift;
    return $self->link() . $self->get_item_rel_url($item);
}

sub get_item_rel_url
{
    my $self = shift;
    my $item = shift;
    return "news/" . $item->id() . "/";
}

sub get_items_to_include
{
    my $self = shift;
    my $args = shift;

    my $num_items_to_include = $args->{'num_items'} || 10;

    my $items = $self->items();

    if ( @$items < $num_items_to_include )
    {
        $num_items_to_include = scalar(@$items);
    }

    return [ @$items[ ( -$num_items_to_include ) .. (-1) ] ];
}

sub generate_rss_feed
{
    my $self = shift;

    my %args = (@_);

    my $rss_feed = XML::RSS->new( 'version' => "2.0" );
    $rss_feed->channel(
        'title'       => $self->title(),
        'link'        => $self->link(),
        'language'    => $self->language(),
        'description' => $self->description(),
        'rating'      => $self->rating(),
        'copyright'   => $self->copyright(),
        'pubDate'     => ( $self->pubDate // ( scalar( localtime() ) ) ),
        'lastBuildDate' =>
            ( $self->lastBuildDate // ( scalar( localtime() ) ) ),
        'docs'           => $self->docs(),
        'ttl'            => $self->ttl(),
        'generator'      => $self->generator(),
        'managingEditor' => $self->managing_editor(),
        'webMaster'      => $self->webmaster(),
    );

    foreach my $single_item ( @{ $self->get_items_to_include( \%args ) } )
    {
        $self->add_item_to_rss_feed(
            'item' => $single_item,
            'feed' => $rss_feed,
        );
    }

    my $filename = $args{'output_filename'} || "rss.xml";

    $rss_feed->save($filename);
}


sub get_navmenu_items
{
    my $self = shift;
    my %args = (@_);

    my @ret;

    foreach my $single_item (
        reverse( @{ $self->get_items_to_include( \%args ) } ) )
    {
        push @ret,
            {
            'text' => $single_item->title(),
            'url'  => $self->get_item_rel_url($single_item),
            };
    }
    return \@ret;
}


sub format_news_page_item
{
    my $self = shift;
    my (%args) = (@_);

    my $item     = $args{'item'};
    my $base_url = $args{'base_url'};

    return
          "<h3><a href=\"$base_url"
        . $item->id() . "/\">"
        . CGI::escapeHTML( $item->title() )
        . "</a></h3>\n" . "<p>\n"
        . $item->description()
        . "\n</p>\n";
}

sub get_news_page_entries
{
    my $self = shift;
    my %args = (@_);

    my $html = "";

    my $base_url = exists( $args{'base_url'} ) ? $args{'base_url'} : "";

    foreach my $single_item (
        reverse( @{ $self->get_items_to_include( \%args ) } ) )
    {
        $html .= $self->format_news_page_item(
            'item'     => $single_item,
            'base_url' => $base_url,
        );
    }
    return $html;
}


sub get_news_box_contents
{
    my $self = shift;
    my (%args) = (@_);

    my $html = "";
    foreach my $item ( reverse( @{ $self->get_items_to_include( \%args ) } ) )
    {
        $html .=
              "<li><a href=\""
            . $self->get_item_rel_url($item) . "\">"
            . CGI::escapeHTML( $item->title() )
            . "</a></li>\n";
    }
    return $html;
}

sub get_news_box
{
    my $self = shift;

    my $html = "";

    $html .= qq{<div class="news">\n};
    $html .= qq{<h3>News</h3>\n};
    $html .= qq{<ul>\n};
    $html .= $self->get_news_box_contents(@_);
    $html .= qq{<li><a href="./news/">More&hellip;</a></li>};
    $html .= qq{</ul>\n};
    $html .= qq{</div>\n};
    return $html;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::Latemp::News - News Maintenance Module for Latemp (and possibly other
web frameworks)

=head1 VERSION

version 0.2.1

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;

    use MyManageNews;

    my @news_items =
    (
        .
        .
        .
        {
            'title' => "Changes of 18-April-2005",
            'id' => "changes-2005-04-18",
            'description' => q{Around 18 April, 2005, Jane's Site has seen a
                lot of changes. Click the link for details on them.},
            'date' => "2005-04-18",
            'author' => "Jane Smith",
            'category' => "Jane's Site",
        },
        .
        .
        .
    );

    my $news_manager =
        HTML::Latemp::News->new(
            'news_items' => \@news_items,
            'title' => "Better SCM News",
            'link' => "http://janes-site.tld/",
            'language' => "en-US",
            'copyright' => "Copyright by Jane Smith, (c) 2005",
            'webmaster' => "Jane Smith <jane@janes-site.tld>",
            'managing_editor' => "Jane Smith <jane@janes-site.tld>",
            'description' => "News of Jane's Site - a personal site of " .
                "Jane Smith",
        );

    $news_manager->generate_rss_feed(
        'output_filename' => "dest/rss.xml"
    );

    1;

=head1 DESCRIPTION

This is a module that maintains news item for a web-site. It can generate
an RSS feed, as well as a news page, and an HTML newsbox, all from the same
data.

=head1 VERSION

version 0.2.1

=head1 FUNCTION

=head2 HTML::Latemp::News->new(...)

This is the constructor for the news manager. It accepts the following named
parameters:

=over 8

=item 'news_items'

This is a reference to a list of news_items. See below.

=item 'title'

The title of the RSS feed.

=item 'link'

The link to the homepage of the site.

=item 'language'

The language of the text.

=item 'copyright'

The copyright notice of the text.

=item 'webmaster'

The Webmaster.

=item 'managing_editor'

The managing editor.

=item 'description'

A description of the news feed as will be put in the RSS feed.

=back

=head3 Format of the news_items

The news_items is a reference to an array, of which each element is a hash
reference. The hash may contain the following keys:

=over 8

=item 'title'

The title of the item.

=item 'id'

The ID of the item. This will also be used to calculate URLs.

=item 'description'

A text description explaining what the item is all about.

=item 'author'

The author of the item.

=item 'date'

A string representing the daet.

=item 'category'

The cateogry of the item.

=back

=head2 $news_manager->generate_rss_feed('output_filename' => "rss.xml")

This generates an RSS feed. It accepts two named arguments.
C<'output_filename'> is the name of the RSS file to write to. C<'num_items'>
is the number of items to include, which defaults to 10.

=head2 $news_manager->get_navmenu_items('num_items' => 5)

This generates navigation menu items for input to the navigation menu of
L<HTML::Widgets::NavMenu>. It accepts a named argument C<'num_items'> which
defaults to 10.

=head2 $news_manager->get_news_page_entries('num_items' => 5, 'base_url' => "news/")

This generates HTML for the news page. 'base_url' points to a URL to be
appended to each item's ID.

=head2 $news_manager->get_news_box('num_items' => 5)

This generates an HTML news box with the recent headlines.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

=head1 BUGS

Please report any bugs or feature requests to
C<bug-html-latemp-news@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-Latemp-News>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<XML::RSS>, L<HTML::Widgets::NavMenu>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of the MIT X11 license.

=head1 AUTHOR

Shlomi Fish <shlomif@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2005 by Shlomi Fish.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/shlomif/html-latemp-news/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc HTML::Latemp::News

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<https://metacpan.org/release/HTML-Latemp-News>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/HTML-Latemp-News>

=item *

RT: CPAN's Bug Tracker

The RT ( Request Tracker ) website is the default bug/issue tracking system for CPAN.

L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Latemp-News>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/HTML-Latemp-News>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/HTML-Latemp-News>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/HTML-Latemp-News>

=item *

CPAN Testers

The CPAN Testers is a network of smoke testers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/H/HTML-Latemp-News>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=HTML-Latemp-News>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=HTML::Latemp::News>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests by email to C<bug-html-latemp-news at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=HTML-Latemp-News>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/shlomif/html-latemp-news>

  git clone git://github.com/shlomif/html-latemp-news.git

=cut
