package Labyrinth::RSS;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::RSS - RSS Handler for Labyrinth

=head1 DESCRIPTION

Contains all the RSS/Atom feeds used by Labyrinth

=cut

# -------------------------------------
# Library Modules

use XML::RSS;
use XML::Atom;
use XML::Atom::Feed;
use XML::Atom::Entry;

use Labyrinth::DTUtils;
use Labyrinth::Variables;
use Labyrinth::Writer;

# -------------------------------------
# Variables

my $RSSFEED = 10;
my $GENERATOR = 'Labyrinth v' . $VERSION;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 Constructor

=over

=item new

=back

=cut

sub new {
    my $class = shift;
    my %hash  = @_;

    # verify we have the necessary settings
    for(qw(rssmail rssname)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    my $rssuser = "$settings{rssmail} ($settings{rssname})";
    $settings{rsseditor} ||= $rssuser;
    $settings{rssmaster} ||= $rssuser;

    my $atts = {
        type    => ($hash{type}     || 'rss'),
        version => ($hash{version}  || '2.0'),
        perma   => ($hash{perma}    || $settings{perma}),
        id      => ($hash{id}       || 'articleid'),
        block   => ($hash{block}    || 'articles/arts-block.html'),
    };

    bless $atts, $class;
    return $atts;
}

=head2 Public Methods

=over

=item feed

For the given list of entries, reformats into the requested feed type.

=back

=cut

sub feed {
    my $self = shift;

    return  unless(@_);

    return $self->RSS_0_9(@_)    if($self->{type} eq 'rss'  && $self->{version} eq '0.9');
    return $self->RSS_1_0(@_)    if($self->{type} eq 'rss'  && $self->{version} eq '1.0');
    return $self->RSS_2_0(@_)    if($self->{type} eq 'rss'  && $self->{version} eq '2.0');
    return $self->Atom_0_3(@_)   if($self->{type} eq 'atom' && $self->{version} eq '0.3');
    return $self->Atom_1_0(@_)   if($self->{type} eq 'atom' && $self->{version} eq '1.0');

    $tvars{errcode} = 'ERROR';
}

=head2 Private Methods

=over

=item RSS_0_9

Reformats article list into RSS 0.9.

=item RSS_1_0

Reformats article list into RSS 1.0.

=item RSS_2_0

Reformats article list into RSS 2.0.

=item Atom_0_3

Reformats article list into Atom 0.3.

=item Atom_1_0

Reformats article list into Atom 1.0.

=item CleanEntities

For a given string, reformats basic entities to avoid potential XML 
irregularities.

=back

=cut

sub RSS_0_9 {
    my $self = shift;

    # verify we have the necessary settings
    for(qw(rsstitle rsslink rssdesc)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    my $rss = XML::RSS->new(version => '0.9');
    $rss->channel(
        title        => $settings{rsstitle},
        link         => $settings{rsslink},
        description  => $settings{rssdesc},
    );

    for my $item (@_) {
        my $id    = $item->{data}{$self->{id}};
        my $perma = $item->{data}{permapath} || $self->{perma} . $id;

        $rss->add_item(
            title       => CleanEntities($item->{data}{title}),
            link        => $settings{rsslink} . $perma
        );
    }

    $tvars{rss} = $rss->as_string;
}

sub RSS_1_0 {
    my $self = shift;

    # verify we have the necessary settings
    for(qw(rsstitle rsslink rssdesc rsssubject rsscreator rsspublisher copyright)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    my $rss = XML::RSS->new(version => '1.0');
    $rss->channel(
        title        => $settings{rsstitle},
        link         => $settings{rsslink},
        description  => $settings{rssdesc},

        dc => {
            date       => formatDate(16),
            subject    => $settings{rsssubject},
            creator    => $settings{rsscreator},
            publisher  => $settings{rsspublisher},
            rights     => $settings{copyright},
            language   => 'en-gb',
        },
        syn => {
            updatePeriod     => "daily",
            updateFrequency  => "1",
            updateBase       => "2000-01-01T00:00:00+00:00",
        },
    );

    for my $item (@_) {
        my $id    = $item->{data}{$self->{id}};
        my $perma = $item->{data}{permapath} || $self->{perma} . $id;

        my $block = '';
        my $body = $item->{data}{body} || $item->{body};
        if($self->{id} eq 'articleid') {
            my %vars = ( 'block' => $body );
            $block = Transform($self->{block},\%vars);
        } else {
            $block = $body;
        }

        $rss->add_item(
#           date        => formatDate(16,$item->{data}{createdate}),
            title       => CleanEntities($item->{data}{title}),
            description => CleanEntities($block),
            link        => $settings{rsslink} . $perma
        );
    }

    $tvars{rss} = $rss->as_string;
}

sub RSS_2_0 {
    my $self = shift;

    # verify we have the necessary settings
    for(qw(rsstitle rsslink rssdesc copyright rsseditor rssmaster)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    my $rss = XML::RSS->new(version => '2.0');
    $rss->channel(
        title           => $settings{rsstitle},
        link            => $settings{rsslink},
        description     => $settings{rssdesc},
        language        => 'en',
        copyrights      => $settings{copyright},
        pubDate         => formatDate(16),
        managingEditor  => $settings{rsseditor},
        webMaster       => $settings{rssmaster},
        generator       => $GENERATOR,
    );

    for my $item (@_) {
        my $id    = $item->{data}{$self->{id}};
        my $perma = $item->{data}{permapath} || $self->{perma} . $id;

        my $block = '';
        my $body = $item->{data}{body} || $item->{body};
        if($self->{id} eq 'articleid') {
            my %vars = ( 'block' => $body );
            $block = Transform($self->{block},\%vars);
        } else {
            $block = $body;
        }

        $rss->add_item(
            pubDate     => formatDate(16,$item->{data}{createdate}),
            title       => CleanEntities($item->{data}{title}),
            description => CleanEntities($block),
            link        => $settings{rsslink} . $perma,
            guid        => $settings{rsslink} . $perma,
            comments    => $settings{rsslink} . $perma . '#comments'
        );
    }

    $tvars{rss} = $rss->as_string;
}

sub Atom_0_3 {
    my $self = shift;

    # verify we have the necessary settings
    for(qw(rsstitle rsslink)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    my ($tag) = $settings{rsslink} =~ m!http://([^/]+)/!;

    my $feed = XML::Atom::Feed->new;
    $feed->title($settings{rsstitle});
    $feed->id("tag:$tag,".formatDate(1).':atom03');

    for my $item (@_) {
        my $id    = $item->{data}{$self->{id}};
        my $perma = $item->{data}{permapath} || $self->{perma} . $id;

        my $block = '';
        my $body = $item->{data}{body} || $item->{body};
        if($self->{id} eq 'articleid') {
            my %vars = ( 'block' => $body );
            $block = Transform($self->{block},\%vars);
        } else {
            $block = $body;
        }

        my $entry = XML::Atom::Entry->new;
        $entry->title(CleanEntities($item->{data}{title}));
        $entry->id("tag:$tag,".formatDate(1) . ':' . $id);
        $entry->link($settings{rsslink} . $perma);
        $entry->content(CleanEntities($block));
        $feed->add_entry($entry);
    }

    $tvars{rss} = $feed->as_xml;
}

sub Atom_1_0 {
    my $self = shift;

    # verify we have the necessary settings
    for(qw(rsstitle rsslink rssname rssmail)) {
        die "Missing configuration setting: '$_'\n" unless($settings{$_});
    }

    $XML::Atom::DefaultVersion = "1.0";
    my ($tag) = $settings{rsslink} =~ m!http://([^/]+)/?!;

    my $feed = XML::Atom::Feed->new;
    $feed->title($settings{rsstitle});
    $feed->id("tag:$tag,".formatDate(1).':atom10');
    $feed->updated(formatDate(12,$_[0]->{data}{creatdate}));

    my $author = XML::Atom::Person->new;
    $author->name($settings{rssname});
    $author->email($settings{rssmail});

    for my $item (@_) {
        my $id    = $item->{data}{$self->{id}};
        my $perma = $item->{data}{permapath} || $self->{perma} . $id;

        my $block = '';
        my $body = $item->{data}{body} || $item->{body};
        if($self->{id} eq 'articleid') {
            my %vars = ( 'block' => $body );
            $block = Transform($self->{block},\%vars);
        } else {
            $block = $body;
        }

        my $entry = XML::Atom::Entry->new;
        $entry->title(CleanEntities($item->{data}{title}));
        $entry->id("tag:$tag,".formatDate(1) . ':' . $id);
        $entry->content(CleanEntities($block));
        $entry->author($author);
        $entry->updated(formatDate(12,$item->{data}{createdate}));

        my $link = XML::Atom::Link->new;
        $link->type('text/html');
        $link->rel('alternate');
        $link->href($settings{rsslink} . $perma);
        $entry->add_link($link);

        $feed->add_entry($entry);
    }

    $tvars{rss} = $feed->as_xml;

}

sub CleanEntities {
    my $text = shift;
    return ''    unless($text);

    $text =~ s/&ndash;/-/gs;    # ndash causes XML problems!
    $text =~ s/&amp;/&/gs;
    $text =~ s/&#39;/'/gs;
    $text =~ s!(src|href)=(["'])/!$1=$2$settings{rssweb}/!igs;
    return $text;
}

1;

__END__

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2007-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
