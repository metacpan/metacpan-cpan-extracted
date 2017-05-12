package File::Assets::Filter::Collect;

use strict;
use warnings;

use base qw/File::Assets::Filter/;

use Digest;
use File::Assets;

for my $ii (qw/fingerprint_digest fingerprint_digester/) {
    no strict 'refs';
    *$ii = sub {
        my $self = shift;
        return $self->stash->{$ii} unless @_;
        return $self->stash->{$ii} = shift;
    };
}

sub signature {
    return "collect";
}

my %default = (qw/
        skip_single 0
        skip_if_exists 0
        skip_inline 1
        check_content 0
        fingerprint_digest 1
        check_age 1 
    /,
);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    local %_ = @_;
    while (my ($setting, $value) = each %default) {
        $self->cfg->{$setting} = exists $_{$setting} ? $_{$setting} : $value;
    }
    return $self;
}

sub pre {
    my $self = shift;
    $self->SUPER::pre(@_);

    return 0 if $self->skip_if_exists;

    if ($self->cfg->{fingerprint_digest}) {
        $self->fingerprint_digester(File::Assets::Util->digest);
    }

    return 1;
}

sub process {
    my $self = shift;
    $self->SUPER::process(@_);
    if (my $digester = $self->fingerprint_digester) {
        my $asset = $_[0];
        $digester->add($asset->digest."\n");
    }
}

sub post {
    my $self = shift;
    $self->SUPER::post(@_);

    my $matched = $self->matched;

    return unless @$matched;

    return if $self->cfg->{skip_single} && 1 == @$matched;

    if (my $digester = $self->fingerprint_digester) {
        $self->fingerprint_digest($digester->hexdigest);
    }

    return if $self->skip_if_exists;

    my $build = $self->should_build;

    if ($build) {
        $self->build;
    }

    $self->substitute;
}

sub skip_if_exists {
    my $self = shift;

    if ($self->cfg->{skip_if_exists} && $self->asset) {
        if (-e $self->asset->file && -s _) {
            $self->replace;
            return 1;
        }
    }
    return 0;
}

sub should_build {
    my $self = shift;

#    if ($self->cfg->{check_content}) {
#        my $digest = $self->fingerprint_digest;
#        my $dir = $self->group->rsc->dir->subdir(".check-content-digest");
#        my $file = $dir->file($digest);
#        unless (-e $file) {
#            $file->touch;
#            return 1;
#        }
#        $file->touch;
#    }

    if ($self->cfg->{check_age}) {
        my $mtime = $self->mtime;
        return 1 if $mtime > $self->output_asset->file_mtime;
    }

#    if ($self->cfg->{check_digest}) {
#        my $file = $self->check_digest_file;
#        unless (-e $file) {
#            return 1;
#        }
#    }

    return 0;
}

sub match {
    my $self = shift;
    my $asset = shift;
    my $match = shift;
    return $self->SUPER::match($asset, $match &&
        (! $asset->inline || ! $self->cfg->{skip_inline}) &&
        (! $asset->outside)
    );
}

#sub check_digest_file {
#    my $self = shift;
#    my $key_digest = $self->key_digest;
#    my $dir = $self->assets->rsc->dir->subdir(".check-digest");
#    $dir->mkpath unless -d $dir;
#    my $file = $dir->file($key_digest);
#    return $file;
#}

sub build {
    my $self = shift;

    my $content = $self->build_content;

    my $output_asset = $self->output_asset;

    $output_asset->write($content) if defined $content;

    return $output_asset;
}

sub output_asset {
    my $self = shift;
    return $self->stash->{output_asset} ||= do {
        $self->assets->output_asset($self);
    };
}

sub substitute {
    my $self = shift;
    my $asset = shift || $self->output_asset;

    my $slice = $self->slice;
    my $matched = $self->matched;
    my $top_match = $matched->[0];
    my $top_asset = $top_match->{asset};

    for my $match (reverse @$matched) {
        my $rank = $match->{rank};
        splice @$slice, $rank, 1, ();
    }

    splice @$slice, $top_match->{rank}, 0, $asset; 
}

sub fingerprint {
    return $_[0]->fingerprint_digest;
}

1;

__END__

sub find_type {
    my $self = shift;
    my $frob;
    return $frob if $frob = $self->type;
    return $frob if (($frob = $self->matched->[0]) && ($frob = $frob->{asset}->type));
    return undef;
}

