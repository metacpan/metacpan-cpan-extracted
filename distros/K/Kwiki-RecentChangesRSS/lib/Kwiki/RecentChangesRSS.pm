# $Id: RecentChangesRSS.pm,v 1.21 2005/11/06 23:47:58 peregrin Exp $
package Kwiki::RecentChangesRSS;
use strict;
use warnings;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';
use POSIX qw(strftime);
use Time::Local;
our $VERSION = '0.07';

const class_id        => 'RecentChangesRSS';
const class_title     => 'RecentChangesRSS';
const screen_template => 'rss_screen.xml';
const config_file     => 'rss.yaml';

sub register {
    my $registry = shift;
    $registry->add( action => 'RecentChangesRSS' );
    $registry->add(
        toolbar  => 'rss_button',
        template => 'rss_button.html',
    );
}

sub RecentChangesRSS {
    use XML::RSS;

    my $display_the_page = $self->config->rss_display_page;

    my %channel_info = (
        link           => $self->config->rss_link,
        copyright      => $self->config->rss_copyright,
        language       => $self->config->rss_language,
        description    => $self->config->rss_description,
        title          => $self->config->rss_title,
        docs           => $self->config->rss_docs,
        generator      => $self->config->rss_generator,
        managingEditor => $self->config->rss_managingEditor,
        webMaster      => $self->config->rss_webMaster,
        category       => $self->config->rss_category,
        image          => $self->config->rss_image,
    );
    my $rss = new XML::RSS( version => '2.0' );
    while ( my ( $key, $value ) = each %channel_info ) {
        $rss->channel( $key => $value );
    }

    my $depth = $self->config->rss_depth;

    my $pages;
    @$pages = sort { $b->modified_time <=> $a->modified_time; }
        $self->pages->all_since( $depth * 1440 );

    $ENV{SERVER_PROTOCOL} =~ m!^(\w+)/!;
    my $protocol = $1;
    foreach my $page (@$pages) {

    #
    # Because we are using RSS 2.0, we are forced to put the author/creator in
    # either the title or description.  Putting the author/creator in <author>
    # is not valid RSS 2.0 because it must include an email address, which we
    # currently don't have for each user.  Perhaps future versions of Kwiki
    # will force users to have an email address.
    # Note: RSS 1.0 does not have this restriction -- it can use <dc:creator>.
    #
        my ( $title, $description );
        if ($display_the_page) {
            $title = $page->title
                . " (last edited by "
                . $page->metadata->edit_by . ")";
            $description = '<![CDATA[' . $page->to_html . ']]>',;
        }
        else {
            $title       = $page->title;
            $description = "Last edited by " . $page->metadata->edit_by;
        }

        $rss->add_item(
            title       => $title,
            description => $description,
            link        => $self->config->rss_link . '?' . $page->uri,
            pubDate     => strftime(
                "%a, %d %b %Y %T %Z",
                localtime( $page->modified_time )
            ),
        );
    }

   #
   # lastBuildDate is the time the content last changed, therefore the time of
   # the latest wiki page...
   # However $@pages is the array of pages since $depth * 1440 and so will be
   # undefined if no page has changes since $depth * 1440.  Otherwise we skip
   # it.
    $rss->channel(
        lastBuildDate => strftime(
            "%a, %d %b %Y %T %Z",
            localtime( $pages->[0]->modified_time )
        )
        )
        if $pages->[0];

    # Set the correct Content-Type header

    $self->hub->headers->content_type('application/xml');

    $self->render_screen(
        xml          => $rss->as_string,
        screen_title => "Changes in the last $depth " . $depth == 1
        ? "day"
        : "days",
    );

}

1;

__DATA__

=head1 NAME 

Kwiki::RecentChangesRSS - Kwiki RSS Plugin

=head1 SYNOPSIS

Provides an RSS 2.0 feed of your recent changes.

=head1 REQUIRES

   Kwiki 0.33
   XML::RSS

=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

   cd ~/where/your/kwiki/is/located
   vi plugins

Add this line to the plugins file:

   Kwiki::RecentChangesRSS

   kwiki -update

Then glance over the settings in config/rss.yaml and the documentation
below.  Add your settings to config.yaml.

=head1 UPGRADING

You should always run 'kwiki -update' after upgrading Kwiki::RecentChangesRSS,
as typically there are new configuration options that need to be installed in
config/rss.yaml.

=head1 CONFIGURATION

In config.yaml, following are necessary for proper functioning:

=over

=item rss_link

The URL of the site this feed applies to.  Don't include the default
"script_name" set in your config.yaml or config/config.yaml.

For example, if your URL looks like

 http://speedysite.com/cgi-bin/kwiki/index.cgi?HomePage

then use

 http://speedysite.com/cgi-bin/kwiki/

=item rss_depth

The number of days you go back in time for recent changes.  Defaults to 7 days.

=item rss_icon

Included in this distribution is a sample icon, xml.png.  To use it, put

   rss_icon: xml.png

in your config.yaml file.  If you have a better one, just put it in
the top of your Kwiki directory.

=item rss_display_page

This plugin defaults to a terse RSS 2.0 feed, where news reader will
simply display the page title and who last edited it.  If you want to
see the entire page, the following into your config.yaml file:

   rss_display_page: 1

=back

The E<lt>channelE<gt> block of the feed requires the following elements to be defined:

=over

=item rss_title

The title of your website.

=item rss_description

Short descriptive text describing this feed or website.

=back

The following are optional for RSS 2.0:

=over

=item rss_language

An RFC 1766 language code, such as en-US.

=item rss_rating

A PICS rating, if necessary.  See http://www.w3.org/PICS/.

=item rss_copyright

Your copyright line.

=item rss_docs

The URL to a document describing the RSS 2.0 protocol, currently: http://blogs.law.harvard.edu/tech/rss

=item rss_managingEditor

Email address of the person responsible for the editorial content.

=item rss_webMaster

Email address of the person responsible for technical issues regarding the RSS feed.

=item rss_category

A category designation for this feed.  Can be any short text or word.

=item rss_generator

A string indicating what program generated this feed. Currently 'Kwiki::RecentChangesRSS/XML::RSS'.

=item rss_cloud

Not implemented.  Specifies a HTTP-POST, XML-RPC or SOAP interface to get notification of updates to this feed.

=item rss_ttl

Not implemented.  Specifies a time to live value in minutes to determine how long you should cache this feed before updating.

=item rss_image

URL of a GIF, JPEG or PNG image to be displayed with the channel.

=item rss_rating

Not implemented. The PICS rating for the wiki.

=item rss_textInput

Not implemented.  Allows you to define a simple form for input.

=item rss_skipHours

Not implemented.  Speficies the hours in which this feed should not be used.

=item rss_skipDays

Not implemented.  Speficies the days of the week in which this feed
should not be used.

=back

=head1 ACKNOWLEDGEMENTS

This is a modified a private version of Kwiki::RecentChanges by Brian
Ingerson. To fix [cpan #7524] bug, used website link method used by
Brian's own version of Kwiki::RecentChangesRSS (developed
independently of this module).

Joon and ambs on #kwiki for finding UTF-8 problems.

David Jones for catching that <img> wasn't XHTML compliant.

=head1 AUTHOR

James Peregrino, C<< <jperegrino@post.harvard.edu> >>

=head1 COPYRIGHT

Copyright (c) 2004. James Peregrino. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__config/rss.yaml__
rss_title: a title goes here
rss_description: a short description goes here
rss_link: http://configure.me/
rss_docs: http://blogs.law.harvard.edu/tech/rss
rss_generator: Kwiki::RecentChangesRSS/XML::RSS 0.07
rss_depth: 7
rss_language: en-US
rss_copyright:
rss_managingEditor:
rss_webMaster:
rss_category:
rss_cloud:
rss_ttl:
rss_image:
rss_rating:
rss_textInput:
rss_skipHours:
rss_skipDays:
rss_display_page: 0
__template/tt2/rss_button.html__
<!-- BEGIN rss_button.html -->
<a href="[% script_name %]?action=RecentChangesRSS" accesskey="c" title="RSS">
[% INCLUDE rss_button_icon.html %]
</a>
<!-- END rss_button.html -->
__template/tt2/rss_button_icon.html__
<!-- BEGIN rss_button_icon.html -->
<img src="[% rss_icon %]" alt="rss" />
<!-- END rss_button_icon.html -->
__template/tt2/rss_screen.xml__
[% xml %]
__xml.png__
iVBORw0KGgoAAAANSUhEUgAAACQAAAAOBAMAAAC1GaP7AAAAMFBMVEU9GgL1sYOeQgLmhkL22sfd
XQfcdC/7yaf+/Pt+MgLDUgbupHL+gi7+ZgP+lE/OZiLJkrvQAAAAAWJLR0QAiAUdSAAAAJlJREFU
eNpjdDdgQAX/Gd9+QBP6w8SAAYBC/1YzcBdYr2eYvYG7ACTEAhQ98JVb9vRvBoG/DD+gqhga2Jmd
GRhbYBqBqhjEWPZfYvgg/kEIbhYQsDYw2As0IIxn+PXHCOic/xuQhBYYsScw/A8GCv0xEYA4guf9
BCCLGajRvdwA4ohrN/de7bjAwKrwVYmhg4EBi4cYFDA8BACwrCv4QvvgfAAAAABJRU5ErkJggg==
