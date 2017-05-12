package File::Assets::Filter::Concat;

use strict;
use warnings;

use base qw/File::Assets::Filter::Collect/;

sub signature {
    return "concat";
}

sub build_content {
    my $self = shift;

    my $matched = $self->matched;

    my $content = "";
    for my $match (@$matched) {
        $content .= ${ $match->{asset}->content };
    }

    return \$content;
}

1;

__END__

use Digest;

use base qw/File::Assets::Filter/;

sub post_process {
    my $self = shift;
    my $assets = shift;
    my $matched = shift;

    return unless @$matched;

    return if 1 == @$matched;

    my $top_match = $matched->[0];
    my $top_asset = $top_match->{asset};

    for my $match (reverse @$matched) {
        my $rank = $match->{rank};
        splice @$assets, $rank, 1, ();
    }

    my $content = "";
    for my $match (@$matched) {
        $content .= ${ $match->{asset}->content };
    }

    my $type = $top_asset->type;
    my $path;
    if ($self->package) {
        $path = $self->package->path;
    }
    if (! defined $path) {
        my $digest = Digest->new("MD5");
        $digest->add($content);
        $path = $digest->hexdigest;
    }
    $path .= "." . ($type->extensions)[0] if $path =~ m/(?:^|\/)[^\.]+/;

    my $asset = File::Assets->_parse_asset_by_path(
        path => $path,
        type => $type,
        base => $top_asset->resource->base,
    );

    my $file = $asset->file;
    my $dir = $file->parent;
    $dir->mkpath unless -d $dir;
    $file->openw->print($content);

    splice @$assets, $top_match->{rank}, 0, $asset; 
}

1;
