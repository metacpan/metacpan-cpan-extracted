package MVC::Neaf::X::Files;

use strict;
use warnings;
our $VERSION = 0.2501;

=head1 NAME

MVC::Neaf::X::Files - serve static content for Not Even A Framework.

=head1 SYNOPSIS

     use MVC::Neaf;

     neaf static "/path/in/url" => "/local/path", %options;

These options would go to this module's new() method described below.

=head1 DESCRIPTION

Serving static content in production via a perl application framework
is a bad idea.
However, forcing the user to run a separate web-server just to test
their CSS, JS, and images is an even worse one.

So this module is here to fill the gap in L<MVC::Neaf>.

=head1 METHODS

=cut

use File::Basename;
use Encode;

use MVC::Neaf::Util qw(http_date canonize_path);
use MVC::Neaf::View::TT;
use parent qw(MVC::Neaf::X);

# Enumerate most common file types. Patches welcome.
our %ExtType = (
    css  => 'text/css',
    gif  => 'image/gif',
    htm  => 'text/html',
    html => 'text/html',
    jpeg => 'image/jpeg',
    jpg  => 'image/jpeg',
    js   => 'application/javascript',
    pl   => 'text/plain',
    png  => 'image/png',
    txt  => 'text/plain',
);

=head2 new( %options )

%options may include:

=over

=item * root - where to search for files. May point to asingle file, too.
(Required).

=item * buffer - buffer size for serving files.
Currently this is also the size below which in-memory caching is on,
but this MAY change in the future.

=item * cache_ttl - if given, files below the buffer size will be stored
in memory for cache_ttl seconds.
B<EXPERIMENTAL>. Cache API is not yet established.

=item * in_memory = { name => [ "content", "type" ] }

Serve some files from memory.
Content-type defaults to text/plain.

B<EXPERIMENTAL>. Name and signature MAY change in the future.

=back

=cut

my $dir_template = <<"HTML";
<html>
<head>
    <title>Directory index of [% path | html %]</title>
</head>
<body>
<h1>Directory index of [% path | html %]</h1>
<h2>Generated on [% date | html %]</h2>
[% IF updir.length %]
    <a href="[% updir | html %]">Parent directory</a>
[% END %]
<table width="100%" border="0">
[% FOREACH item IN list %]
    <tr>
        <td>[% IF item.dir %]DIR[% END %]</td>
        <td><a href="[% path _ '/' _ item.name | url %]">[% item.name | html %]</a></td>
        <td>[% IF !item.dir %][% item.size %][% END %]</td>
        <td>[% item.lastmod %]</td>
    </tr>
[% END # FOREACH %]
</table>
</body>
</html>
HTML

my %static_options;
$static_options{$_}++ for qw(
    root base_url in_memory
    description buffer cache_ttl allow_dots dir_index dir_template view );

sub new {
    my ($class, %options) = @_;

    defined $options{root}
        or $class->my_croak( "option 'root' is required" );

    my @extra = grep { !$static_options{$_} } keys %options;
    $class->my_croak( "Unknown options @extra" )
        if @extra;

    $options{buffer} ||= 4096;
    $options{buffer} =~ /^(\d+)$/
        or $class->my_croak( "option 'buffer' must be a positive integer" );

    if ($options{dir_index}) {
        $options{view} ||= MVC::Neaf::View::TT->new;
        $options{dir_template} ||= \$dir_template;
    };

    $options{base_url} = canonize_path(($options{base_url} || '/'), 1);

    $options{description} = "Static content at $options{root}"
        unless defined $options{description};

    # Don't store files twice
    my $preload = delete $options{in_memory};
    my $self = $class->SUPER::new(%options);

    $self->preload( %$preload )
        if ($preload);

    return $self;
};

=head2 serve_file( $path )

Create a Neaf-compatible response using given path.
The response is like follows:

    {
        -content => (file content),
        -headers => (length, name etc),
        -type => (content-type),
        -continue => (serve the rest of the file, if needed),
    };

Will C<die 404;> if file is not there.

This MAY be used to create more fine-grained control over static files.

B<EXPERIMENTAL>. New options MAY be added.

=cut

sub serve_file {
    my ($self, $file) = @_;

    my $bufsize = $self->{buffer};
    my $dir = $self->{root};
    my $time = time;
    my @header;

    # sanitize file path before caching
    $file = canonize_path($file);

    if (my $data = $self->{cache_content}{$file}) {
        if ($data->[1] and $data->[1] < $time) {
            delete $self->{cache_content}{$file};
        }
        else {
            return $data->[0];
        };
    };

    # don't let unsafe paths through
    $file =~ m#/\.\./# and die 404;
    $file =~ m#(^|/)\.# and die 404
        unless $self->{allow_dots};

    # open file
    my $xfile = join "", $dir, $file;

    if (-d $xfile) {
        return $self->list_dir( $file )
            if $self->{dir_index};
        die 404; # Sic! Don't reveal directory structure
    };
    my $ok = open (my $fd, "<", "$xfile");
    if (!$ok) {
        # TODO 0.30 Warn
        die 404;
    };
    binmode $fd;

    my $size = [stat $fd]->[7];
    local $/ = \$bufsize;
    my $buf = <$fd>;

    # determine type, fallback to extention
    my $type;
    $xfile =~ m#(?:^|/)([^\/]+?(?:\.(\w+))?)$#;
    $type = $ExtType{lc $2} if defined $2; # TODO 0.40 unify with guess_type

    my $show_name = $1;
    $show_name =~ s/[\"\x00-\x19\\]/_/g;

    my $disposition = ($type && $type =~ qr#^text|^image|javascript#)
        ? ''
        : "attachment; filename=\"$show_name\"";
    push @header, content_disposition => $disposition
            if $disposition;

    # return whole file if possible
    if ($size < $bufsize) {
        my $ret = { -content => $buf, -type => $type, -headers => \@header };
        if ($self->{cache_ttl}) {
            my $expires = $time + $self->{cache_ttl};
            push @{ $ret->{-headers} }, expires => http_date( $expires );
            $self->save_cache( $file, $expires, $ret );
        };
        return $ret;
    };

    # If file is big, print header & first data chunk ASAP
    # then do the rest via a second callback
    push @header, content_length => $size;
    my $continue = sub {
        my $req = shift;

        local $/ = \$bufsize; # MUST do it again
        while (<$fd>) {
            $req->write($_);
        };
        $req->close;
    };

    return { -content => $buf, -type => $type, -continue => $continue, -headers => \@header };
};

=head2 list_dir( $path )

Create a directory index reply.
Used by serve_file() if dir_index given.

As of current, indices are not cached.

=cut

sub list_dir {
    my ($self, $dir) = @_;

    # TODO 0.30 better error handling (404 or smth)
    opendir( my $fd, "$self->{root}/$dir" )
        or $self->my_croak( "Failed to locate directory at $dir: $!" );

    my @ret;
    while (my $entry = readdir($fd)) {
        $entry = decode_utf8($entry);
        $entry =~ /^\./ and next
            unless $self->{allow_dots};

        my @stat = stat "$self->{root}/$dir/$entry";
        my $isdir = -d "$self->{root}/$dir/$entry" ? 1 : 0;

        push @ret, {
            name => $entry,
            dir => $isdir,
            size => $stat[7],
            lastmod => http_date( $stat[9] ),
        };
    };
    closedir $fd;

    @ret = sort { $b->{dir} <=> $a->{dir} || $a->{name} cmp $b->{name} } @ret;

    my $updir = dirname($dir);
    $updir = '' if $updir eq '.';
    return {
        -view      => $self->{view},
        -template  => $self->{dir_template},
        list       => \@ret,
        date       => http_date( time ),
        path       => $self->{base_url} . $dir,
        updir      => $self->{base_url} . $updir,
    };
};

=head2 preload( %files )

Preload multiple in-memory files.

Returns self.

=cut

sub preload {
    my ($self, %files) = @_;

    foreach (keys %files) {
        my $spec = $files{$_};
        # guess order: png; image/png; filename.png; screw it - text
        my $type = $ExtType{$spec->[1] || ''} || $spec->[1]
            || $self->guess_type( $_, $spec->[0] ) || 'text/plain';

        $self->save_cache( $_, undef, {
            -content => $spec->[0],
            -type    => $type,
        } );
    };

    return $self;
};

=head2 one_file_handler()

Returns a simple closure that accepts a L<MVC::Neaf::Request> and
serves the requested path as is, relative to the X::Files objects's
root, or from cache.

B<EXPERIMENTAL>. This is used internally by Neaf, name & meaning may change.

=cut

sub one_file_handler {
    my $self = shift;

    return $self->{one_file} ||= sub {
        my $req = shift;
        return $self->serve_file( $req->path );
    };
};

=head2 save_cache( $name, $expires, \%data )

Save data in cache.

$name is canonized file name.

$expires is unix timestamp. If undef, cache forever.

=cut

sub save_cache {
    my ($self, $name, $expires, $content) = @_;

    $name = canonize_path( $name );
    $self->{cache_content}{$name} = [ $content, $expires ];

    return $self;
};

=head2 guess_type( $filename, $content )

Returns file's MIME type. As of current, content is ignored,
and only file extention is considered.

=cut

sub guess_type {
    my ($self, $name, $content) = @_;

    return unless $name =~ /\.([a-z0-9]{1,4})$/;
    return $ExtType{lc $1};
};


=head2 make_route()

Returns list of arguments suitable for C<neaf-E<gt>route(...)>:

=over

=item * base url;

=item * handler sub;

=item * a hash of options: path_info_regex, cache_ttl, and description.

=back

=cut

sub make_route {
    my $self = shift;

    $self->my_croak("useless call in scalar/void context")
        unless wantarray;

    my $handler = sub {
        my $req = shift;

        my $file = $req->path_info();
        return $self->serve_file( $file );
    }; # end handler sub

    return (
        $self->{base_url} => $handler,
        method => ['GET', 'HEAD'],
        path_info_regex => '.*',
        cache_ttl => $self->{cache_ttl},
        description => $self->{description},
    );
};

=head2 make_handler

Returns a Neaf-compatible handler sub.

B<DEPRECATED> Use make_route instead. This dies.

=cut

sub make_handler {
    my $self = shift;
    $self->my_croak("DEPRECATED, use make_route() instead");
};

=head1 LICENSE AND COPYRIGHT

This module is part of L<MVC::Neaf> suite.

Copyright 2016-2018 Konstantin S. Uvarin C<khedin@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;
