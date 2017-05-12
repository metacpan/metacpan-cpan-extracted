package HTTP::CDN;
{
  $HTTP::CDN::VERSION = '0.8';
}

use strict;
use warnings;

=head1 NAME

HTTP::CDN - Serve static files with unique URLs and far-future expiry


=head1 SYNOPSIS

To use this module in your Catalyst app, see L<Catalyst::Plugin::CDN>.  For
other uses, see below:

  my $cdn = HTTP::CDN->new(
      root => '/path/to/static/root',
      base => '/cdn/',
      plugins => [qw(
          CSS::LESSp
          CSS
          CSS::Minifier::XS
          JavaScript::Minifier::XS
      )],
  );

  # Generate a URL based on hashed file contents

  say $cdn->resolve('css/style.less');  # e.g.: "/cdn/css/style.B97EA317759D.less"

  # Find source file, apply plugins and return content

  my ($uri, $hash) = $cdn->unhash_uri('css/style.B97EA317759D.less');
  return $cdn->filedata($uri);

In a real application you'd also want to add a Content-Type header using the
MIME type set by the plugins as well as headers for cache-control and expiry.
You can trivially mount a handler to do all of that for the static content in
your Plack app (using the HTTP::CDN object as defined above):

  use Plack::Builder;

  my $app = sub {
      # Define Plack app here
  };

  builder {
      mount '/cdn/' => $cdn->to_plack_app;
      mount '/'     => $app;
  }


=head1 DESCRIPTION

Web application plugin for serving static files with content-hashed unique URLs
and far-future expiry.

Additionally provides automatic minification/compiling of css/less/javascript.

=cut

use Moose;
use Moose::Util::TypeConstraints;

use URI;
use Path::Class;
use MIME::Types;
use Digest::MD5;
use Module::Load;

our $mimetypes = MIME::Types->new;
our $default_mimetype = $mimetypes->type('application/octet-stream');

use constant EXPIRES => 315_576_000; # ~ 10 years

subtype 'HTTP::CDN::Dir' => as class_type('Path::Class::Dir');
subtype 'HTTP::CDN::URI' => as class_type('URI');

coerce 'HTTP::CDN::Dir' => from 'Str' => via { Path::Class::dir($_)->resolve->absolute };
coerce 'HTTP::CDN::URI' => from 'Str' => via { URI->new($_) };

has 'plugins' => (
    traits   => ['Array'],
    isa      => 'ArrayRef[Str]',
    required => 1,
    default  => sub { [qw(HTTP::CDN::CSS)] },
    handles  => {
        plugins => 'elements',
    },
);
has 'base' => (
    isa      => 'HTTP::CDN::URI',
    is       => 'rw',
    required => 1,
    coerce   => 1,
    default  => sub { URI->new('') },
);
has 'root' => (
    isa      => 'HTTP::CDN::Dir',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);
has '_cache' => (
    isa      => 'HashRef',
    is       => 'ro',
    required => 1,
    default  => sub { {} },
);

sub BUILD {
    my ($self) = @_;

    my @plugins;

    foreach my $plugin ( $self->plugins ) {
        eval { load "HTTP::CDN::$plugin" };
        if ( $@ ) {
            load $plugin;
        }
        else {
            $plugin = "HTTP::CDN::$plugin";
        }
        push @plugins, $plugin;
    }
    $self->{plugins} = \@plugins;
}

sub to_plack_app {
    my ($self) = @_;

    load 'Plack::Request';
    load 'Plack::Response';

    return sub {
        my $request = Plack::Request->new(@_);
        my $response = Plack::Response->new(200);

        my ($uri, $hash) = $self->unhash_uri($request->path);

        my $info = eval { $self->fileinfo($uri) };

        unless ( $info and $info->{hash} eq $hash ) {
            $response->status(404);
            $response->content_type( 'text/plain' );
            $response->body( 'HTTP::CDN - not found' );
            return $response->finalize;
        }

        $response->status( 200 );
        $response->content_type( $info->{mime}->type );
        $response->headers->header('Last-Modified' => HTTP::Date::time2str($info->{stat}->mtime));
        $response->headers->header('Expires' => HTTP::Date::time2str(time + EXPIRES));
        $response->headers->header('Cache-Control' => 'max-age=' . EXPIRES . ', public');
        $response->body($self->filedata($uri));
        return $response->finalize;
    }
}

sub unhash_uri {
    my ($self, $uri) = @_;

    unless ( $uri =~ s/\.([0-9A-F]{12})\.([^.]+)$/\.$2/ ) {
        return;
    }
    my $hash = $1;
    return wantarray ? ($uri, $hash) : $uri;
}

sub cleanup_uri {
    my ($self, $uri) = @_;

    return $self->root->file($uri)->cleanup->relative($self->root);
}

sub resolve {
    my ($self, $uri) = @_;

    my $fileinfo = $self->update($uri);

    return $self->base . $fileinfo->{components}{cdnfile};
}

sub fileinfo {
    my ($self, $uri) = @_;

    return $self->update($uri);
}

sub filedata {
    my ($self, $uri) = @_;

    return $self->_fileinfodata($self->update($uri));
}

sub _fileinfodata {
    my ($self, $fileinfo) = @_;

    return $fileinfo->{data} // scalar($fileinfo->{fullpath}->slurp);
}

sub update {
    my ($self, $uri) = @_;

    die "No URI specified" unless $uri;

    my $force_update;

    my $fragment = ($uri =~ s/(#.*)//) ? $1 : undef;

    my $file = $self->cleanup_uri($uri);

    my $fileinfo = $self->_cache->{$file} ||= {};

    if ( ($fragment // '') ne ($fileinfo->{components}{fragment} // '') ) {
        $fileinfo->{components}{fragment} = $fragment;
        $force_update = 1;
    }

    my $fullpath = $fileinfo->{fullpath} //= $self->root->file($file);

    my $stat = $fullpath->stat;

    die "Failed to stat $fullpath" unless $stat;

    unless ( not $force_update and $fileinfo->{stat} and $fileinfo->{stat}->mtime == $stat->mtime ) {
        $fileinfo->{mime} = $mimetypes->mimeTypeOf($file) // $default_mimetype;
        delete $fileinfo->{data};
        $fileinfo->{dependancies} = {};

        $fileinfo->{components} = do {
            my $extension = "$file";
            $extension =~ s/(.*)\.//;
            {
                file      => "$file",
                extension => $extension,
                barename  => $1,
                fragment  => $fileinfo->{components}{fragment},
            }
        };

        foreach my $plugin ( $self->plugins ) {
            next unless $plugin->can('preprocess');
            $plugin->can('preprocess')->($self, $file, $stat, $fileinfo);
        }

        # Need to update this file
        $fileinfo->{hash} = $self->hash_fileinfo($fileinfo);
        $fileinfo->{components}{cdnfile} = join('.', $fileinfo->{components}{barename}, $fileinfo->{hash}, $fileinfo->{components}{extension});
        $fileinfo->{components}{cdnfile} .= $fileinfo->{components}{fragment} if $fileinfo->{components}{fragment};
    }
    # TODO - need to check dependancies?

    $fileinfo->{stat} = $stat;

    return $fileinfo;
}

sub hash_fileinfo {
    my ($self, $fileinfo) = @_;

    return uc substr(Digest::MD5::md5_hex(scalar($self->_fileinfodata($fileinfo))), 0, 12);
}

1;


__END__

=head1 METHODS

=head2 new

Construct an object for generating URL paths and also for producing the
response content for a requested URL.  The constructor accepts these names
options:

=over 4

=item root

Filesystem path to the directory where your static files are stored.

This option is required and has no default value.

=item base

URL path prefix to be added when generating unique URL paths.  Defaults to
no prefix.  A typical value might be '/cdn/'.

=item plugins

A list of plugins that you wish to enable.  Default value is:
C<< [ 'HTTP::CDN::CSS' ] >>.

=back

=head2 resolve

Takes a URL path of a file in the C<root> directory and returns a CDN URL with
C<base> prefix and content hash added.

=head2 unhash_uri

Takes a URI path and returns the same path with content hash removed.  In list
context, the hash is also returned.

Note: This method does not attempt to strip the C<base> prefix (e.g.: C</cdn/>)
from the URI path as that would usually have been done already by the
application framework's routing layer.

=head2 fileinfo

Takes a URI path (with hash removed) and returns a hash of information about
the file and its contents.

=head2 filedata

Takes a URI path (with hash removed) and returns the contents of that file with
any plug-in transformations applied.

=head2 to_plack_app

Returns a subroutine reference that can be used as a Plack application -
typically 'mounted' on a URL path like C</cdn/> as shown in the L<SYNOPSIS>.


=head1 AUTHOR

Martyn Smith <martyn@dollyfish.net.nz>


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2012 by Martyn Smith

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
