package JS::YUI::Loader;

use warnings;
use strict;

=head1 NAME

JS::YUI::Loader - Load (and cache) the Yahoo JavaScript YUI framework

=head1 VERSION

Version 0.06

=head1 SYNOPSIS

    use JS::YUI::Loader;

    my $loader = JS::YUI::Loader->new_from_yui_host;
    $loader->include->yuitest->reset->fonts->base;
    print $loader->html;

    # The above will yield:
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/reset/reset.css" type="text/css"/>
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/fonts/fonts.css" type="text/css"/>
    # <link rel="stylesheet" href="http://yui.yahooapis.com/2.5.1/build/base/base.css" type="text/css"/>
    # <script src="http://yui.yahooapis.com/2.5.1/build/yahoo/yahoo.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/dom/dom.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/event/event.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/logger/logger.js" type="text/javascript"></script>
    # <script src="http://yui.yahooapis.com/2.5.1/build/yuitest/yuitest.js" type="text/javascript"></script>

You can also cache YUI locally:

    my $loader = JS::YUI::Loader->new_from_yui_host(cache => { dir => "htdocs/assets", uri => "http://example.com/assets" });
    $loader->include->yuitest->reset->fonts->base;
    print $loader->html;

    # The above will yield:
    # <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    # <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    # <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    # <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    # <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=head1 DESCRIPTION

JS::YUI::Loader is a tool for loading YUI assets within your application. Loader will either provide the URI/HTML to access http://yui.yahooapis.com directly,
or you can cache assets locally or serve them from an exploded yui_x.x.x.zip dir.

=cut

our $VERSION = '0.06';

use constant LATEST_YUI_VERSION => "2.5.1";

use Moose;

use JS::YUI::Loader::Carp;
use JS::YUI::Loader::Catalog;
use HTML::Declare qw/LINK SCRIPT/;

has catalog => qw/is ro required 1 isa JS::YUI::Loader::Catalog lazy 1/, default => sub { shift->source->catalog };
has manifest => qw/is ro required 1 isa JS::YUI::Loader::Manifest lazy 1/, handles => [qw/include exclude clear select parse schedule/], default => sub {
    my $self = shift;
    require JS::YUI::Loader::Manifest;
    return JS::YUI::Loader::Manifest->new(catalog => $self->catalog, loader => $self);
};
has list => qw/is ro required 1 isa JS::YUI::Loader::List lazy 1/, default => sub {
    my $self = shift;
    require JS::YUI::Loader::List;
    return JS::YUI::Loader::List->new(loader => $self);
};
has source => qw/is ro required 1 isa JS::YUI::Loader::Source/;
has cache => qw/is ro isa JS::YUI::Loader::Cache/;
has filter => qw/is rw isa Str/, default => "";

=head1 METHODS

=cut

=head2 JS::YUI::Loader->new_from_yui_host([ base => <base>, version => <version> ])

=head2 JS::YUI::Loader->new_from_internet([ base => <base>, version => <version> ])

Return a new JS::YUI::Loader object configured to fetch and/or serve assets from http://yui.yahooapis.com/<version>

=cut

sub new_from_yui_host {
    return shift->new_from_internet(@_);
}

sub new_from_internet {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{version} = delete $given->{version} if exists $given->{version};
    $source{base} = delete $given->{base} if exists $given->{base};
    require JS::YUI::Loader::Source::Internet;
    my $source = JS::YUI::Loader::Source::Internet->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}

=head2 JS::YUI::Loader->new_from_yui_dir([ dir => <dir>, version => <version> ])

Return a new JS::YUI::Loader object configured to fetch/serve assets from a local, exploded yui_x.x.x.zip dir

As an example, for a dir of C<./assets>, the C<reset.css> asset should be available as:

    ./assets/reset/reset.css

=cut

sub new_from_yui_dir {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{version} = delete $given->{version} if exists $given->{version};
    $source{base} = delete $given->{base} if exists $given->{base};
    $source{dir} = delete $given->{dir} if exists $given->{dir};
    require JS::YUI::Loader::Source::YUIDir;
    my $source = JS::YUI::Loader::Source::YUIDir->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}

=head2 JS::YUI::Loader->new_from_uri([ base => <base> ])

Return a new JS::YUI::Loader object configured to serve assets from an arbitrary uri

As an example, for a base of C<http://example.com/assets>, the C<reset.css> asset should be available as:

    http://example.com/assets/reset.css

=cut

sub new_from_uri {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{base} = delete $given->{base} if exists $given->{base};
    require JS::YUI::Loader::Source::URI;
    my $source = JS::YUI::Loader::Source::URI->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}

=head2 JS::YUI::Loader->new_from_dir([ dir => <dir> ])

Return a new JS::YUI::Loader object configured to serve assets from an arbitrary dir

As an example, for a dir of C<./assets>, the C<reset.css> asset should be available as:

    ./assets/reset.css

=cut

sub new_from_dir {
    my $class = shift;

    my ($given, $catalog) = $class->_new_given_catalog(@_);

    my %source;
    $source{base} = delete $given->{base} if exists $given->{base};
    $source{dir} = delete $given->{dir} if exists $given->{dir};
    require JS::YUI::Loader::Source::Dir;
    my $source = JS::YUI::Loader::Source::Dir->new(catalog => $catalog, %source);

    return $class->_new_finish($given, $source);
}

=head2 select( <component>, <component>, ..., <component> )

Include each <component> in the "manifest" for the loader.

A <component> should correspond to an entry in the C<YUI component catalog> (see below)

=head2 include

Returns a chainable component selector that will include what is called

You can use the methods of the selector to choose components to include. See C<YUI component catalog> below 

You can return to the loader by using the special ->then method:

    $loader->include->reset->yuilogger->grids->fonts->then->html;

=head2 exclude

Returns a chainable component selector that will exclude what is called

You can use the methods of the selector to choose components to include. See C<YUI component catalog> below 

You can return to the loader by using the special ->then method:

    $loader->exclude->yuilogger->then->html;

=cut

=head2 filter_min 

Turn on the -min filter for all included components

For example:

    connection-min.js
    yuilogger-min.js
    base-min.css
    fonts-min.css

=cut

sub filter_min {
    my $self = shift;
    return $self->filter("min");
    return $self;
}

=head2 filter_debug 

Turn on the -debug filter for all included components

For example:

    connection-debug.js
    yuilogger-debug.js
    base-debug.css
    fonts-debug.css

=cut

sub filter_debug {
    my $self = shift;
    $self->filter("debug");
    return $self;
}

=head2 no_filter 

Disable filtering of included components

For example:

    connection.js
    yuilogger.js
    base.css
    fonts.css

=cut

sub no_filter {
    my $self = shift;
    $self->filter("");
    return $self;
}

=head2 uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=cut

sub uri {
    my $self = shift;
    return $self->cache_uri(@_) if $self->cache;
    return $self->source_uri(@_);
}

=head2 file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.)

If the loader has a cache, then this method will try to fetch from the cache. Otherwise it will use the source.

=cut

sub file {
    my $self = shift;
    return $self->cache_file(@_) if $self->cache;
    return $self->source_file(@_);
}

=head2 cache_uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the cache

=cut

sub cache_uri {
    my $self = shift;
    my $name = shift;
    return $self->cache->uri([ $name => $self->filter ]) || croak "Unable to get uri for $name from cache ", $self->cache;
}

=head2 cache_file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the cache

=cut

sub cache_file {
    my $self = shift;
    my $name = shift;
    return $self->cache->file([ $name => $self->filter ]) || croak "Unable to get file for $name from cache ", $self->cache;
}

=head2 source_uri( <component> )

Attempt to fetch a L<URI> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the source

=cut

sub source_uri {
    my $self = shift;
    my $name = shift;
    return $self->source->uri([ $name => $self->filter ]) || croak "Unable to get uri for $name from source ", $self->source;
}

=head2 source_file( <component> )

Attempt to fetch a L<Path::Class::File> for <component> using the current filter setting of the loader (-min, -debug, etc.) from the source

=cut

sub source_file {
    my $self = shift;
    my $name = shift;
    return $self->source->file([ $name => $self->filter ]) || croak "Unable to get file for $name from source ", $self->source;
}

=head2 item( <component> )

Return a L<JS::YUI::Loader::Item> for <component> using the current filter setting of the loader (-min, -debug, etc.)

=cut

sub item {
    my $self = shift;
    my $name = shift;
    return $self->catalog->item([ $name => $self->filter ]);
}

=head2 item_path( <component> )

Return the item path for <component> using the current filter setting of the loader (-min, -debug, etc.)

=cut

sub item_path {
    my $self = shift;
    my $name = shift;
    return $self->item($name)->path;
}

=head2 item_file( <component> )

Return the item file for <component> using the current filter setting of the loader (-min, -debug, etc.)

=cut

sub item_file {
    my $self = shift;
    my $name = shift;
    return $self->item($name)->file;
}

sub name_list {
    my $self = shift;
    return $self->manifest->schedule;
}

sub _html {
    my $self = shift;
    my $uri_list = shift;
    my $separator = shift || "\n";
    my @uri_list = $self->list->uri;
    my @html;
    for my $uri (@uri_list) {
        if ($uri =~ m/\.css/) {
            push @html, LINK({ rel => "stylesheet", type => "text/css", href => $uri });
        }
        else {
            push @html, SCRIPT({ type => "text/javascript", src => $uri, _ => "" });
        }
    }
    return join $separator, @html;
}

=head2 html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

If the loader has a cache, then it will attempt to generate URIs from the cache, otherwise it will use the source.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=cut

sub html {
    my $self = shift;
    return $self->_html([ $self->list->uri ], @_);
}

=head2 source_html

Generate and return a string containing HTML describing how to include components. For example, you can use this in the <head> section
of a web page.

Here is an example:

    <link rel="stylesheet" href="http://example.com/assets/reset.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/fonts.css" type="text/css"/>
    <link rel="stylesheet" href="http://example.com/assets/base.css" type="text/css"/>
    <script src="http://example.com/assets/yahoo.js" type="text/javascript"></script>
    <script src="http://example.com/assets/dom.js" type="text/javascript"></script>
    <script src="http://example.com/assets/event.js" type="text/javascript"></script>
    <script src="http://example.com/assets/logger.js" type="text/javascript"></script>
    <script src="http://example.com/assets/yuitest.js" type="text/javascript"></script>

=cut

sub source_html {
    my $self = shift;
    return $self->_html([ $self->list->source_uri ], @_);
}

sub _new_given {
    my $class = shift;
    return @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };
}

sub _new_catalog {
    my $class = shift;
    my $given = shift;
    my $catalog = delete $given->{catalog} || {};
    return $given->{catalog} = $catalog if blessed $catalog;
    return $given->{catalog} = JS::YUI::Loader::Catalog->new(%$catalog);
}

sub _build_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    my (%cache, $cache_class);

    if (ref $given eq "ARRAY") {
        $cache_class = "JS::YUI::Loader::Cache::URI";
        my ($uri, $dir) = @$given;
        %cache = (uri => $uri, dir => $dir);
    }
    elsif (ref $given eq "HASH") {
        $cache_class = "JS::YUI::Loader::Cache::URI";
        my ($uri, $dir) = @$given{qw/uri dir/};
        %cache = (uri => $uri, dir => $dir);
    }
    elsif (ref $given eq "Path::Resource") {
        $cache_class = "JS::YUI::Loader::Cache::URI";
        %cache = (uri => $given->uri, dir => $given->dir);
    }
    else {
        $cache_class = "JS::YUI::Loader::Cache::Dir";
        %cache = (dir => $given);
    }

    eval "require $cache_class;" or die $@;

    return $cache_class->new(source => $source, %cache);
}

sub _new_cache {
    my $class = shift;
    my $given = shift;
    my $source = shift;
    if (my $cache = delete $given->{cache}) {
        $given->{cache} = $class->_build_cache($cache, $source);
    }
}

sub _new_given_catalog {
    my $class = shift;
    my $given = $class->_new_given(@_);

    my $catalog = $class->_new_catalog($given);

    return ($given, $catalog);
}

sub _new_finish {
    my $class = shift;
    my $given = shift;
    my $source = shift;

    $class->_new_cache($given, $source);

    return $class->new(%$given, source => $source);
}

=head1 YUI component catalog

=head2 animation

Animation Utility (utility)

=head2 autocomplete

AutoComplete Control (widget)

=head2 base

Base CSS Package (css)

=head2 button

Button Control (widget)

=head2 calendar

Calendar Control (widget)

=head2 charts

Charts Control (widget)

=head2 colorpicker

Color Picker Control (widget)

=head2 connection

Connection Manager (utility)

=head2 container

Container Family (widget)

=head2 containercore

Container Core (Module, Overlay) (widget)

=head2 cookie

Cookie Utility (utility)

=head2 datasource

DataSource Utility (utility)

=head2 datatable

DataTable Control (widget)

=head2 dom

Dom Collection (core)

=head2 dragdrop

Drag &amp; Drop Utility (utility)

=head2 editor

Rich Text Editor (widget)

=head2 element

Element Utility (utility)

=head2 event

Event Utility (core)

=head2 fonts

Fonts CSS Package (css)

=head2 get

Get Utility (utility)

=head2 grids

Grids CSS Package (css)

=head2 history

Browser History Manager (utility)

=head2 imagecropper

ImageCropper Control (widget)

=head2 imageloader

ImageLoader Utility (utility)

=head2 json

JSON Utility (utility)

=head2 layout

Layout Manager (widget)

=head2 logger

Logger Control (tool)

=head2 menu

Menu Control (widget)

=head2 profiler

Profiler (tool)

=head2 profilerviewer

ProfilerViewer Control (tool)

=head2 reset

Reset CSS Package (css)

=head2 reset_fonts

=head2 reset_fonts_grids

=head2 resize

Resize Utility (utility)

=head2 selector

Selector Utility (utility)

=head2 simpleeditor

Simple Editor (widget)

=head2 slider

Slider Control (widget)

=head2 tabview

TabView Control (widget)

=head2 treeview

TreeView Control (widget)

=head2 uploader

Uploader (widget)

=head2 utilities

=head2 yahoo

Yahoo Global Object (core)

=head2 yahoo_dom_event

=head2 yuiloader

Loader Utility (utility)

=head2 yuiloader_dom_event

=head2 yuitest

YUI Test Utility (tool)

=cut

1;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

L<http://developer.yahoo.com/yui/>

L<http://developer.yahoo.com/yui/yuiloader/>

L<JS::jQuery::Loader>

=head1 BUGS

Please report any bugs or feature requests to C<bug-js-yui-loader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JS-YUI-Loader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JS::YUI::Loader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JS-YUI-Loader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JS-YUI-Loader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JS-YUI-Loader>

=item * Search CPAN

L<http://search.cpan.org/dist/JS-YUI-Loader>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of JS::YUI::Loader
