package File::Assets::Asset;

use warnings;
use strict;

use File::Assets::Util;
use File::Assets::Carp;
use File::Assets::Asset::Content;

use XML::Tiny;
use IO::Scalar;
use Object::Tiny qw/type rank attributes hidden rsc outside/;
use Scalar::Util qw/blessed/;

=head1 SYNPOSIS 

    my $asset = File::Asset->new(base => $base, path => "/static/assets.css");
    $asset = $assets->include("/static/assets.css"); # Or, like this, usually.

    print "The rank for asset at ", $asset->uri, " is ", $asset->rank, "\n";
    print "The file for the asset is ", $asset->file, "\n";

=head1 DESCRIPTION

A File::Asset object represents an asset existing in both URI-space and file-space (on disk). The asset is usually a .js (JavaScript) or .css (CSS) file.

=head1 METHODS

=head2 File::Asset->new( base => <base>, path => <path>, [ rank => <rank>, type =>  <type> ]) 

Creates a new File::Asset. You probably don't want to use this, create a L<File::Assets> object and use $assets->include instead.

=cut

sub _html_parse ($) {
    XML::Tiny::parsefile(IO::Scalar->new(shift));
}

sub new {
    my $self = bless {}, shift;
    my $asset = @_ == 1 && ref $_[0] eq "HASH" ? shift : { @_ };

    my $content = delete $asset->{content};
    $content = ref $content eq "SCALAR" ? $$content : $content;
    if (defined $content && $content =~ m/^\s*</) { # Looks like tagged content (<script> or <style>)
        my $tag = _html_parse \$content;
        croak "Unable to parse $content" unless $tag && $tag->[0];
        $tag = $tag->[0];
        my $type = delete $tag->{attrib}->{type};
        if (! $type) {
            if ($tag->{name} =~ m/^script$/i) {
                $type = "js"
            }
            elsif ($tag->{name} =~ m/^style$/i) {
                $type = "css"
            }
        }
        $asset->{type} = $type unless defined $asset->{type};
        while (my ($name, $value) = each %{ $tag->{attrib} }) {
            $asset->{$name} = $value unless exists $asset->{$name};
        }
        $content = $tag->{content}->[0]->{content};
        $content = "" unless defined $content;
    }

    my ($path, $rsc, $base, $type) = delete @$asset{qw/path rsc base type/};
    if (defined $type) {
        my $_type = $type;
        $type = File::Assets::Util->parse_type($_type) or croak "Don't understand type ($_type) for this asset";
    }

    if ($rsc) {
        croak "Don't have a type for this asset" unless $type;
        $self->{rsc} = $rsc;
        $self->{type} = $type;
        croak "Can't also specify content and ", $self->rsc->file if defined $content;
    }
    elsif ($path && $path =~ m/^https?:\/\// || (blessed $path && $path->isa("URI"))) {
        my $uri = $self->{uri} = URI->new($path);
        $self->{type} = $type || do {
            File::Assets::Util->parse_type($uri->path) or croak "Unable to determine type of $uri";
        };
        $self->{outside} = 1;
    }
    elsif ($base && $path) {
        if ($path =~ m/^\//) {
            $self->{rsc} = $base->clone($path);
        }
        else {
            $self->{rsc} = $base->child($path);
        }
        croak "Can't also specify content and ", $self->rsc->file if defined $content;
        $self->{type} = $type || File::Assets::Util->parse_type($path) or croak "Don't know type for asset ($path)";
    }
    elsif (defined $content) {
        croak "Don't have a type for this asset" unless $type;
        $self->{type} = $type;
        $self->{digest} = File::Assets::Util->digest->add($content)->hexdigest;
        $self->{content} = \$content;
    }
    else {
        croak "Don't know what to do";
    }

    my $rank = $self->{rank} = delete $asset->{rank} || 0;
    croak "Don't understand rank ($rank)" if $rank && $rank =~ m/[^\d\+\-\.]/;
    $self->{cache} = delete $asset->{cache};
    $self->{inline} = exists $asset->{inline} ?
        (delete $asset->{inline} ? 1 : 0) :
        $self->{content} ? 1 : 0;
    $self->{attributes} = { %$asset }; # The rest goes here!

    return $self;
}

=head2 $asset->uri 

Returns a L<URI> object represting the uri for $asset

=cut

sub uri {
    my $self = shift;
    return $self->{uri} unless $self->{rsc};
    return ($self->{uri} ||= $self->rsc->uri)->clone;
}

=head2 $asset->file 

Returns a L<Path::Class::File> object represting the file for $asset

=cut

sub file {
    my $self = shift;
    return unless $self->{rsc};
    return $self->{file} ||= $self->rsc->file;
}

=head2 $asset->path 

Returns the path of $asset

=cut

sub path {
    my $self = shift;
    return unless $self->{rsc};
    return $self->{path} ||= $self->rsc->path;
}

=head2 $asset->content 

Returns a SCALAR reference to the content contained in $asset->file

=cut

sub content {
    my $self = shift;
    return $self->{content} || $self->_content->content;
}

=head2 $asset->write( <content> ) 

Writes <content>, which should be a SCALAR reference, to the file located at $asset->file

If the parent directory for $asset->file does not exist yet, this method will create it first

=cut

sub write {
    my $self = shift;
    my $content = shift;

    my $file = $self->file;
    my $dir = $file->parent;
    $dir->mkpath unless -d $dir;
    $file->openw->print($$content);
}

=head2 $asset->digest

Returns a hex digest for the content of $asset

=cut

# NOTE: $asset->digest used to return a unique signature for the asset (based off the filename), but this has changed to
# now return the actual hex digest of the content of $asset

sub digest {
    my $self = shift;
    return $self->{digest} || $self->_content->digest;
}

sub content_digest {
    my $self = shift;
    carp "File::Assets::Asset::content_digest is DEPRECATED (use ::digest instead)";
    return $self->digest;
}

sub mtime {
    return 0;
    carp "File::Assets::Asset::mtime is DEPRECATED";
}

sub file_mtime {
    my $self = shift;
    return 0 unless $self->file;
    return $self->_content->file_mtime;
}

sub file_size {
    my $self = shift;
    return 0 unless $self->file;
    return $self->_content->file_size;
}

sub content_mtime {
    my $self = shift;
    return 0 unless $self->file;
    return $self->_content->content_mtime;
}

sub content_size {
    my $self = shift;
    return length ${ $self->{content} } unless $self->file;
    return $self->_content->content_size;
}

sub refresh {
    my $self = shift;
    return 0 unless $self->file;
    return $self->_content->refresh;
}

sub stale {
    my $self = shift;
    return 0 unless $self->file;
    return $self->_content->stale;
}

sub _content {
    my $self = shift;
    return $self->{_content} ||= do {
        if (my $cache = $self->{cache}) {
            $cache->content($self->file);
        }
        else {
            File::Assets::Asset::Content->new($self->file);
        }
    };
}

=head2 $asset->key

Returns the unique key for the $asset. Usually the path/filename of the $asset, but for content-based assets returns a value based off of $asset->digest

=cut

sub key {
    my $self = shift;
    return $self->path || $self->uri || ($self->{key} ||= '%' . $self->digest);
}

=head2 $asset->hide

Hide $asset (mark it as hidden). That is, don't include $asset during export

=cut

sub hide {
    shift->{hidden} = 1;
}

=head2 $asset->inline

Returns whether $asset is inline (should be embedded into the document) or external.

If an argument is given, then it will set whether $asset is inline or not (1 for inline, 0 for external).

=cut

sub inline {
    my $self = shift;
    $self->{inline} = shift() ? 1 : 0 if @_;
    return $self->{inline};
}

1;

__END__

#    elsif (0 && $base && $content) { # Nonsense scenario?
#        croak "Don't have a type for this asset" unless $type;
#        my $path = File::Assets::Util->build_asset_path(undef, type => $type, digest => $self->digest);
#        $self->{rsc} = $base->child($path);
#        $self->{type} = $type;
#    }
