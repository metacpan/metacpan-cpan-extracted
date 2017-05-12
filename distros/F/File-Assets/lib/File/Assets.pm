package File::Assets;

use warnings;
use strict;

=head1 NAME

File::Assets - Manage .css and .js assets for a web page or application

=head1 VERSION

Version 0.064

=cut

our $VERSION = '0.064';

=head1 SYNOPSIS

    use File::Assets

    my $assets = File::Assets->new( base => [ $uri_root, $dir_root ] )

    # Put minified files in $dir_root/built/... (the trailing slash is important)
    $assets->set_output_path("built/")

    # File::Assets will automatically detect the type based on the extension
    $assets->include("/static/style.css")

    # You can also include external assets:
    $assets->include("http://ajax.googleapis.com/ajax/libs/jquery/1.2.6/jquery.min.js");

    # This asset won't get included twice, as File::Assets will ignore repeats of a path
    $assets->include("/static/style.css")

    # And finally ...
    $assets->export

    # Or you can iterate (in order)
    for my $asset ($assets->exports) {
        
        print $asset->uri, "\n";

    }

In your .tt (Template Toolkit) files:

    [% WRAPPER page.tt %]

    [% assets.include("/static/special-style.css", 100) %] # The "100" is the rank, which makes sure it is exported after other assets

    [% asset = BLOCK %]
    <style media="print">
    body { font: serif; }
    </style>
    [% END %]
    [% assets.include(asset) %] # This will include the css into an inline asset with the media type of "print"

    # ... finally, in your "main" template:

    [% CLEAR -%]
    <html>

        <head>
            [% assets.export("css") %]
        </head>

        <body>

            [% content %]

            <!-- Generally, you want to include your JavaScript assets at the bottom of your html -->

            [% assets.export("js") %]

        </body>

    </html>

Use the minify option to perform minification before export

    my $assets = File::Assets->new( minify => 1, ... )

=head1 DESCRIPTION

File::Assets is a tool for managing JavaScript and CSS assets in a (web) application. It allows you to "publish" assests in one place after having specified them in different parts of the application (e.g. throughout request and template processing phases).

This package has the added bonus of assisting with minification and filtering of assets. Support is built-in for YUI Compressor (L<http://developer.yahoo.com/yui/compressor/>), L<JavaScript::Minifier>, L<CSS::Minifier>, L<JavaScript::Minifier::XS>, and L<CSS::Minifier::XS>.

File::Assets was built with L<Catalyst> in mind, although this package is framework agnostic. Look at L<Catalyst::Plugin::Assets> for an easy way to integrate File::Assets with Catalyst.

=head1 USAGE

=head2 Cascading style sheets and their media types

A cascading style sheet can be one of many different media types. For more information, look here: L<http://www.w3.org/TR/REC-CSS2/media.html>

This can cause a problem when minifying, since, for example, you can't bundle a media type of screen with a media type of print. File::Assets handles this situation by treating .css files of different media types separately. 

To control the media type of a text/css asset, you can do the following:

    $assets->include("/path/to/printstyle.css", ..., { media => "print" }); # The asset will be exported with the print-media indicator

    $assets->include_content($content, "text/css", ..., { media => "screen" }); # Ditto, but for the screen type

=head2 Including assets in the middle of processing a Template Toolkit template

Sometimes, in the middle of a TT template, you want to include a new asset. Usually you would do something like this:

    [% assets.include("/include/style.css") %]  

But then this will show up in your output, because ->include returns an object:

    File::Assets::Asset=HASH(0x99047e4)

The way around this is to use the TT "CALL" directive, as in the following:

    [% CALL assets.include("/include/style.css") %]

=head2 Avoid minifying assets on every request (if you minify)

By default, File::Assets will avoid re-minifying assets if nothing in the files have changed. However, in a web application, this can be a problem if you serve up two web pages that have different assets. That's because File::Assets will detect different assets being served in page A versus assets being served in page B (think AJAX interface vs. plain HTML with some CSS). The way around this problem is to name your assets object with a unique name per assets bundle. By default, the name is "assets", but can be changed with $assets->name(<a new name>):

    my $assets = File::Assets->new(...);
    $assets->name("standard");

You can change the name of the assets at anytime before exporting.

=head2 YUI Compressor 2.2.5 is required

If you want to use the YUI Compressor, you should have version 2.2.5 or above. 

YUI Compressor 2.1.1 (and below) will *NOT WORK*

To use the compressor for minification specify the path to the .jar like so:

    my $assets = File::Assets->new( minify => "/path/to/yuicompressor.jar", ... )

=head2 Specifying an C<output_path> pattern

When aggregating or minifying assets, you need to put the result in a new file. 

You can use the following directives when crafting a path/filename pattern:

    %n      The name of the asset, "assets" by default
    %e      The extension of the asset (e.g. css, js)
    %f      The fingerprint of the asset collection (a hexadecimal digest of the concatenated digest of each asset in the collection)
    %k      The kind of the asset (e.g. css-screen, css, css-print, js)
    %h      The kind head-part of the asset (e.g. css, js)
    %l      The kind tail-part of the asset (e.g. screen, print) (essentially the media type of a .css asset)

In addition, in each of the above, a ".", "/" or "-" can be placed in between the "%" and directive character.
This will result in a ".", "/", or "-" being prepended to the directive value.

The default pattern is:

    %n%-l%-f.%e

A pattern of C<%n%-l.%e> can result in the following:

    assets.css          # name of "assets", no media type, an asset type of CSS (.css)
    assets-screen.css   # name of "assets", media type of "screen", an asset type of CSS (.css)
    assets.js           # name of "assets", an asset type of JavaScript (.js)

If the pattern ends with a "/", then the default pattern will be appended

    xyzzy/          => xyzzy/%n%-l-%f.%e

If the pattern does not have an extension-like ending, then "%.e" will be appended

    xyzzy           => xyzzy.%e

=head2 Strange output or "sticky" content

File::Assets uses built-in caching to share content across different objects (via File::Assets::Cache). If you're having problems
try disabling the cache by passing "cache => 0" to File::Assets->new

=head1 METHODS

=cut

# If the pattern does NOT begin with a "/", then the base dir will be prepended

use strict;
use warnings;

use Object::Tiny qw/cache registry _registry_hash rsc filter_scheme output_path_scheme output_asset_scheme/;
use File::Assets::Carp;

use Tie::LLHash;
use Path::Resource;
use Scalar::Util qw/blessed refaddr/;
use HTML::Declare qw/LINK SCRIPT STYLE/;

use File::Assets::Asset;
use File::Assets::Cache;
use File::Assets::Kind;
use File::Assets::Bucket;

=head2 File::Assets->new( base => <base>, output_path => <output_path>, minify => <minify> )

Create and return a new File::Assets object.

You can configure the object with the following:
    
    base            # A hash reference with a "uri" key/value and a "dir" key/value.
                      For example: { uri => http://example.com/assets, dir => /var/www/htdocs/assets }
    
                    # A URI::ToDisk object

                    # A Path::Resource object

    minify          # "1" or "best" - Will either use JavaScript::Minifier::XS> & CSS::Minifier::XS or
                                      JavaScript::Minifier> & CSS::Minifier (depending on availability)
                                      for minification

                    # "0" or "" or undef - Don't do any minfication (this is the default)

                    # "./path/to/yuicompressor.jar" - Will use YUI Compressor via the given .jar for minification

                    # "minifier" - Will use JavaScript::Minifier & CSS::Minifier for minification

                    # "xs" or "minifier-xs" - Will use JavaScript::Minifier::XS & CSS::Minifier::XS for minification

    output_path     # Designates the output path for minified .css and .js assets
                      The default output path pattern is "%n%-l%-d.%e" (rooted at the dir of <base>)
                      See above in "Specifying an output_path pattern" for details

=cut

sub new {
    my $self = bless {}, shift;
    local %_ = @_;

    $self->set_base($_{rsc} || $_{base_rsc} || $_{base});
    $self->set_base_uri($_{uri} || $_{base_uri}) if $_{uri} || $_{base_uri};
    $self->set_base_dir($_{dir} || $_{base_dir}) if $_{dir} || $_{base_dir};
    $self->set_base_path($_{base_path}) if $_{base_path};

    $self->set_output_path($_{output_path} || $_{output_path_scheme} || []);

    $self->name($_{name});
    
    $_{cache} = 1 unless exists $_{cache};
    $self->set_cache($_{cache}) if $_{cache};

#    my $rsc = File::Assets::Util->parse_rsc($_{rsc} || $_{base_rsc} || $_{base});
#    $rsc->uri($_{uri} || $_{base_uri}) if $_{uri} || $_{base_uri};
#    $rsc->dir($_{dir} || $_{base_dir}) if $_{dir} || $_{base_dir};
#    $rsc->path($_{base_path}) if $_{base_path};
#    $self->{rsc} = $rsc;

    my %registry;
    $self->{registry} = tie(%registry, qw/Tie::LLHash/, { lazy => 1 });
    $self->{_registry_hash} = \%registry;

    $self->{filter_scheme} = {};
    my $filter_scheme = $_{filter} || $_{filters} || $_{filter_scheme} || [];
    for my $rule (@$filter_scheme) {
        $self->filter(@$rule);
    }

    if (my $minify = $_{minify}) {
        if      ($minify eq 1 || $minify =~ m/^\s*(?:minifier-)?best\s*$/i)  { $self->filter("minifier-best") }
        elsif   ($minify =~ m/^\s*yui-?compressor:/)                         { $self->filter($minify) }
        elsif   ($minify =~ m/\.jar/i)                                       { $self->filter("yuicompressor:$minify") }
        elsif   ($minify =~ m/^\s*(?:minifier-)?xs\s*$/i)                    { $self->filter("minifier-xs") }
        elsif   ($minify =~ m/^\s*minifier\s*$/i)                            { $self->filter("minifier") }
        elsif   ($minify =~ m/^\s*concat\s*$/i)                              { $self->filter("concat") }
        else                                                                 { croak "Don't understand minify option ($minify)" }
    }

    return $self;
}

=head2 $asset = $assets->include(<path>, [ <rank>, <type>, { ... } ])

=head2 $asset = $assets->include_path(<path>, [ <rank>, <type>, { ... } ])

First, if <path> is a scalar reference or "looks like" some HTML (starts with a angle bracket, e.g.: <script></script>), then
it will be treated as inline content.

Otherwise, this will include an asset located at "<base.dir>/<path>" for processing. The asset will be exported as "<base.uri>/<path>"

Optionally, you can specify a rank, where a lower number (i.e. -2, -100) causes the asset to appear earlier in the exports
list, and a higher number (i.e. 6, 39) causes the asset to appear later in the exports list. By default, all assets start out
with a neutral rank of 0.

Also, optionally, you can specify a type override as the third argument.

By default, the newly created $asset is NOT inline.

Returns the newly created asset.

NOTE: See below for how the extra hash on the end is handled

=head2 $asset = $assets->include({ ... })

Another way to invoke include is by passing in a hash reference.

The hash reference should contain the follwing information:
    
    path        # The path to the asset file, relative to base
    content     # The content of the asset

    type        # Optional if a path is given, required for content
    rank        # Optional, 0 by default (Less than zero is earlier, greater than zero is later)
    inline      # Optional, by default true if content was given, false is a path was given
    base        # Optional, by default the base of $assets

You can also pass extra information through the hash. Any extra information will be bundled in the ->attributes hash of $asset.
For example, you can control the media type of a text/css asset by doing something like:

    $assets->include("/path/to/printstyle.css", ..., { media => "print" }) # The asset will be exported with the print-media indicator

NOTE: The order of <rank> and <type> doesn't really matter, since we can detect whether something looks like a rank (number) or
not, and correct for it (and it does).

=cut

sub include_path {
    my $self = shift;
    return $self->include(@_);
}

my $rankish = qr/^[\-\+]?[\.\d]+$/; # A regular expression for a string that looks like a rank
sub _correct_for_proper_rank_and_type_order ($) {
    my $asset = shift;
    if (defined $asset->{type} && $asset->{type} =~ $rankish ||
        defined $asset->{rank} && $asset->{rank} !~ $rankish) {
        # Looks like someone entered a rank as the type or vice versa, so we'll switch them
        my $rank = delete $asset->{type};
        my $type = delete $asset->{rank};
        $asset->{type} = $type if defined $type;
        $asset->{rank} = $rank if defined $rank;
    }
}

sub include {
    my $self = shift;

    my (@asset, $path);
    if (ref $_[0] ne "HASH") {
        $path = shift;
        croak "Don't have a path to include" unless defined $path && length $path;
        if (ref $path eq "SCALAR" || $path =~ m/^\s*</) {
            push @asset, content => $path;
        }
        else {
            return $self->fetch($path) if $self->exists($path);
            push @asset, path => $path;
        }
    }

    for (qw/rank type/) {
        last if ! @_ || ref $_[0] eq "HASH";
        push @asset, $_ => shift;
    }
    push @asset, %{ $_[0] } if @_ && ref $_[0] eq "HASH";
    my %asset = @asset;
    _correct_for_proper_rank_and_type_order \%asset;

    my $asset = File::Assets::Asset->new(base => $self->rsc, cache => $self->cache, %asset);

    return $self->fetch_or_store($asset);
}

=head2 $asset = $assets->include_content(<content>, [ <type>, <rank>, { ... } ])

Include an asset with some content and of the supplied type. The value of <content> can be a "plain" string or a scalar reference.

You can include content that looks like HTML:

    <style media="print">
    body {
        font: serif;
    }
    </style>

In the above case, <type> is optional, as File::Assets can detect from the tag that you're supplying a style sheet. Furthermore, 
the method will find all the attributes in the tag and put them into the asset. So the resulting asset from including the above
will have a type of "text/css" and media of "print".

For now, only <style> and <script> will map to types (.css and .js, respectively)

See ->include for more information on <rank>.

By default, the newly created $asset is inline.

Returns the newly created asset.

NOTE: The order of the <type> and <rank> arguments are reversed from ->include and ->include_path
Still, the order of <rank> and <type> doesn't really matter, since we can detect whether something looks like a rank (number) or
not, and correct for it (and it does).

=cut

sub include_content {
    my $self = shift;

    my @asset;
    for (qw/content type rank/) {
        last if ! @_ || ref $_[0] eq "HASH";
        push @asset, $_ => shift;
    }
    push @asset, %{ $_[0] } if @_ && ref $_[0] eq "HASH";
    my %asset = @asset;
    _correct_for_proper_rank_and_type_order \%asset;

    my $asset = File::Assets::Asset->new(%asset);

    $self->store($asset);

    return $asset;
}

=head2 $name = $assets->name([ <name> ])

Retrieve and/or change the "name" of $assets; by default it is "assets"

This is useful for controlling the name of minified assets files.

Returns the name of $assets

=cut

sub name {
    my $self = shift;
    $self->{name} = shift if @_;
    my $name = $self->{name};
    return defined $name && length $name ? $name : "assets";
}

=head2 $html = $assets->export([ <type> ])

Generate and return HTML for the assets of <type>. If no type is specified, then assets of every type are exported.

$html will be something like this:

    <link rel="stylesheet" type="text/css" href="http://example.com/assets.css">
    <script src="http://example.com/assets.js" type="text/javascript"></script>

=cut

sub export {
    my $self = shift;
    my $type = shift;
    my $format = shift;
    $format = "html" unless defined $format;
    my @assets = $self->exports($type);

    if ($format eq "html") {
        return $self->_export_html(\@assets);
    }
    else {
        croak "Don't know how to export for format ($format)";
    }
}

sub _export_html {
    my $self = shift;
    my $assets = shift;

    my @content;
    for my $asset (@$assets) {
        my %attributes = %{ $asset->attributes };
        if ($asset->type->type eq "text/css") {
#        if ($asset->kind->extension eq "css") {
            if (! $asset->inline) {
                push @content, LINK({ rel => "stylesheet", type => $asset->type->type, href => $asset->uri, %attributes });
            }
            else {
                push @content, STYLE({ type => $asset->type->type, %attributes, _ => [ "\n${ $asset->content }" ] });
            }
        }
#        elsif ($asset->kind->extension eq "js") {
        elsif ($asset->type->type eq "application/javascript" ||
                $asset->type->type eq "application/x-javascript" || # Handle different MIME::Types versions.
                $asset->type->type =~ m/\bjavascript\b/) {
            if (! $asset->inline) {
                push @content, SCRIPT({ type => "text/javascript", src => $asset->uri, _ => "", %attributes });
            }
            else {
                push @content, SCRIPT({ type => "text/javascript", %attributes, _ => [ "\n${ $asset->content }" ] });
            }
        }

        else {
            croak "Don't know how to handle asset $asset" unless ! $asset->inline;
            push @content, LINK({ type => $asset->type->type, href => $asset->uri });
        }
    }
    return join "\n", @content;
}

=head2 @assets = $assets->exports([ <type> ])

Returns a list of assets, in ranking order, that are exported. If no type is specified, then assets of every type are exported.

You can use this method to generate your own HTML, if necessary.

=cut

sub exports {
    my $self = shift;
    my @assets = sort { $a->rank <=> $b->rank } $self->_exports(@_);
    return @assets;
}

=head2 $assets->empty

Returns 1 if no assets have been included yet, 0 otherwise.

=cut

sub empty {
    my $self = shift;
    return keys %{ $self->_registry_hash } ? 0 : 1;
}

=head2 $assets->exists( <path> )

Returns true if <path> has been included, 0 otherwise.

=cut

sub exists {
    my $self = shift;
    my $key = shift;

    return exists $self->_registry_hash->{$key} ? 1 : 0;
}

=head2 $assets->store( <asset> )

Store <asset> in $assets

=cut

sub store {
    my $self = shift;
    my $asset = shift;

    return $self->_registry_hash->{$asset->key} = $asset;
}

=head2 $asset = $assets->fetch( <path> )

Fetch the asset located at <path>

Returns undef if nothing at <path> exists yet

=cut

sub fetch {
    my $self = shift;
    my $key = shift;

    return $self->_registry_hash->{$key};
}

sub fetch_or_store {
    my $self = shift;
    my $asset = shift;

    return $self->fetch($asset->key) if $self->exists($asset->key);

    return $self->store($asset);
}

sub kind {
    my $self = shift;
    my $asset = shift;
    my $type = $asset->type;

    my $kind = File::Assets::Util->type_extension($type);
    if (File::Assets::Util->same_type("css", $type)) {
#        my $media = $asset->attributes->{media} || "screen"; # W3C says to assume screen by default, so we'll do the same.
        my $media = $asset->attributes->{media};
        $kind = "$kind-$media" if defined $media && length $media;
    }

    return File::Assets::Kind->new($kind, $type);
}

sub _exports {
    my $self = shift;
    my $type = shift;
    $type = File::Assets::Util->parse_type($type);
    my $hash = $self->_registry_hash;
    my @assets; 
    if (defined $type) {
        @assets = grep { $type->type eq $_->type->type } values %$hash;
    }
    else {
        @assets = values %$hash;
    }

    my %bucket;
    for my $asset (@assets) {
        my $kind = $self->kind($asset);
        my $bucket = $bucket{$kind->kind} ||= File::Assets::Bucket->new($kind, $self);
        $bucket->add_asset($asset);
    }

    my $filter_scheme = $self->{filter_scheme};
    my @global = @{ $filter_scheme->{'*'} || [] };
    my @bucket;
    for my $kind (sort keys %bucket) {
        push @bucket, my $bucket = $bucket{$kind};
        $bucket->add_filter($_) for @global;
        my $head = $bucket->kind->head;
        for my $category (sort grep { ! m/^$head-/ } keys %$filter_scheme) {
            next if length $category > length $kind; # Too specific
            next unless 0 == index $kind, $category;
            $bucket->add_filter($_) for (@{ $filter_scheme->{$category} });
        }
    }

    return map { $_->exports } @bucket;
}

=head2 $assets->set_name( <name> )

Set the name of $assets

This is exactly the same as

    $assets->name( <name> )

=cut


=head2 $assets->set_base( <base> )

Set the base uri, dir, and path for assets

<base> can be a L<Path::Resource>, L<URI::ToDisk>, or a hash reference of the form:

    { uri => ..., dir => ..., path => ... }

Given a dir of C</var/www/htdocs>, a uri of C<http://example.com/static>, and a
path of C<assets> then:

    $assets will look for files in "/var/www/htdocs/assets"

    $assets will "serve" files with "http://example.com/static/assets"

=cut

sub set_base {
    my $self = shift;
    croak "No base given" unless @_;
    my $base = 1 == @_ ? shift : { @_ };
    croak "No base given" unless $base;

    $self->{rsc} = File::Assets::Util->parse_rsc($base);
}

=head2 $assets->set_base_uri( <uri> )

Set the base uri for assets 

=cut

sub set_base_uri {
    my $self = shift;
    croak "No base uri given" unless defined $_[0];

    $self->{rsc}->base->uri(shift);
}

=head2 $assets->set_base_dir( <dir> )

Set the base dir for assets 

=cut

sub set_base_dir {
    my $self = shift;
    croak "No base dir given" unless defined $_[0];

    $self->{rsc}->base->dir(shift);
}

=head2 $assets->set_base_path( <path> )

Set the base path for assets 

Passing an undefined value for <path> will clear/get-rid-of the path

=cut

sub set_base_path {
    my $self = shift;
    my $path;
    $path = defined $_[0] ? Path::Abstract->new(shift) :  Path::Abstract->new;
    # TODO-b This is very bad
    $self->{rsc}->_path($path);
}

sub set_output_path_scheme {
    my $self = shift;
    my $scheme = shift;

    if ($scheme && ref $scheme ne "ARRAY") {
        $scheme = [ [ qw/*/ => $scheme ] ];
    }

    $self->{output_path_scheme} = $scheme;
}

=head2 $assets->set_output_path( <path> )

Set the output path for assets generated by $assets

See "Specifying an C<output_path> pattern" above

=cut

sub set_output_path {
    my $self = shift;
    $self->set_output_path_scheme(@_);
}

=head2 $assets->set_cache( <cache> )

Specify the cache object or cache name to use

=cut 

sub set_cache {
    my $self = shift;
    my $cache = shift;

    if ($cache) {
        $cache = File::Assets::Cache->new(name => $cache) unless blessed $cache && $cache->isa("File::Assets::Cache");
        $self->{cache} = $cache;
    }
    else {
        delete $self->{cache};
    }
}

sub filter {
    my $self = shift;
    my ($kind, $filter);
    if (@_ == 1) {
        $filter = shift;
    }
    else {
        $kind = File::Assets::Kind->new(shift);
        $filter = shift;
    }

    my $name = $kind ? $kind->kind : '*';

    my $category = $self->{filter_scheme}->{$name} ||= [];

    my $_filter = $filter;
    unless (blessed $_filter) {
        croak "Couldn't find filter for ($filter)" unless $_filter = File::Assets::Util->parse_filter($_filter, @_, assets => $self);
    }

    push @$category, $_filter;

    return $_filter;
} 

sub filter_clear {
    my $self = shift;
    if (blessed $_[0] && $_[0]->isa("File::Assets::Filter")) {
        my $target = shift;
        while (my ($name, $category) = each %{ $self->{filter_scheme} }) {
            my @filters = grep { $_ != $target } @$category;
            $self->{filter_scheme}->{$name} = \@filters;
        }
        return;
    }
    carp __PACKAGE__, "::filter_clear(\$type) is deprecated, nothing happens" and return if @_;
    $self->{filter_scheme} = {};
}

sub _calculate_best {
    my $self = shift;
    my $scheme = shift;
    my $kind = shift;
    my $signature = shift;
    my $handler = shift;
    my $default = shift;

    my $key = join ":", $kind->kind, $signature;

    my ($best_kind, %return);
    %return = %$default if $default;

    # TODO-f Cache the result of this
    for my $rule (@$scheme) {
        my ($condition, $action, $flags) = @$rule;

        my $result; # 1 - A better match; -1 - A match, but worse; undef - Skip, not a match!

        if (ref $condition eq "CODE") {
            next unless defined ($result = $condition->($kind, $signature, $best_kind));
        }
        elsif (ref $condition eq "") {
            if ($condition eq $key) {
                # Best possible match
                $result = 1;
                $best_kind = $kind;
            }
            elsif ($condition eq "*" || $condition eq "default") {
                $result = $best_kind ? -1 : 1; 
            }
        }

        my ($condition_kind, $condition_signature) = split m/:/, $condition, 2;
            
        unless (defined $result) {

            # No exact match, try to find the best fit...

            # Signature doesn't match or is not a wildcard, so move on to the next rule
            next if defined $condition_signature && $condition_signature ne '*' && $condition_signature ne $signature;

            if (length $condition_kind && $condition_kind ne '*') {
                $condition_kind = File::Assets::Kind->new($condition_kind);

                # Type isn't the same as the asset (or whatever) kind, so move on to the next rule
                next unless File::Assets::Util->same_type($condition_kind->type, $kind->type);
            }
        }

        # At this point, we have a match, but is it a better match then one we already have?
        if (! $best_kind || ($condition_kind && $condition_kind->is_better_than($best_kind))) {
            $result = 1;
        }

        next unless defined $result;

        my %action;
        %action = $handler->($action);

        if ($result > 0) {
            $return{$_} = $action{$_} for keys %action;
        }
        else {
            for (keys %action) {
                $return{$_} = $action{$_} unless defined $action{$_};
            }
        }
    }

    return \%return;
}

sub output_path {
    my $self = shift;
    my $filter = shift;

    my $result = $self->_calculate_best($self->{output_path_scheme}, $filter->kind, $filter->signature, sub {
        my $action = shift;
        return ref $action eq "CODE" ? %$action : path => $action;
    });

    return $result;
}

sub output_asset {
    my $self = shift;
    my $filter = shift;

    if (0) {
        my $result = $self->_calculate_best($self->{output_asset_scheme}, $filter->kind, $filter->signature, sub {
            my $action = shift;
            return %$action;
        });
    }

    my $kind = $filter->kind;
    my $output_path = $self->output_path($filter) or croak "Couldn't get output path for ", $kind->kind;
    $output_path = File::Assets::Util->build_output_path($output_path, $filter);

    my $asset = File::Assets::Asset->new(path => $output_path, base => $self->rsc, type => $kind->type);
    return $asset;
}

1;

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 SEE ALSO

L<Catalyst::Plugin::Assets>

L<Google::AJAX::Library>

L<JS::YUI::Loader>

L<JS::jQuery::Loader>

=head1 SOURCE

You can contribute or fork this project via GitHub:

L<http://github.com/robertkrimen/file-assets/tree/master>

    git clone git://github.com/robertkrimen/file-assets.git File-Assets

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::Assets


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/File-Assets>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Robert Krimen

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of File::Assets

__END__

#    if (my $cache = $self->cache) {
#        return 1 if $cache->exists($self->rsc->dir, $key);
#    }

#    if (my $cache = $self->cache) {
#        $cache->store($self->rsc->dir, $asset);
#    }

#    if (my $cache = $self->cache) {
#        if ($asset = $cache->fetch($self->rsc->dir, $key)) {
#            return $self->store($asset);
#        }
#    }

