package File::Assets::Cache;

use strict;
use warnings;

use Object::Tiny qw/_content_registry/;
use File::Assets::Carp;

use File::Assets;

my %cache;

sub new {
    my $class = shift;
    local %_ = @_;

    my $name = $_{name};
    if (defined $name) {
        if (ref $name eq "SCALAR") {
            $name = $$name;
        }
        elsif ($name eq 1) {
            $name = "__File::Assets::Cache_cache__";
        }
        return $cache{$name} if $cache{$name}
    }

    my $self = bless {}, $class;

    $self->{_content_registry} = {};

    $cache{$name} = $self if $name;

    return $self;
}

sub assets {
    my $self = shift;
    return File::Assets->new(cache => $self, @_);
}

sub clear {
    my $self = shift;
    $self->{_content_registry} = {};
}

sub content {
    my $self = shift;
    my $file = shift;
    croak "Wasn't given a file" unless $file;
    my $content = $self->_content_registry->{$file} ||= File::Assets::Asset::Content->new($file);
    $content->refresh;
    return $content;
}

1;

__END__

sub exists {
    my $self = shift;
    my $base = shift;
    my $key = shift;

    return exists $self->_asset_registry($base)->{$key} ? 1 : 0;
}

sub store {
    my $self = shift;
    my $base = shift;
    my $asset = shift;

    return $self->_asset_registry($base)->{$asset->key} = $asset;
}

sub fetch {
    my $self = shift;
    my $base = shift;
    my $key = shift;

    if (my $asset = $self->_asset_registry($base)->{$key}) {
        $asset->refresh;
        return $asset;
    }

    return undef;
}

sub _asset_registry {
    my $self = shift;
    return $self->{_asset_registry} unless @_;
    my $base = shift;
    return $self->{_asset_registry}->{$base} ||= {};
}

