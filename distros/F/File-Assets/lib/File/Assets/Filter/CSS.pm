package File::Assets::Filter::CSS;

use strict;
use warnings;

use base qw/File::Assets::Filter/;

use Digest;
use File::Assets;

my %default = (qw/
        skip_single 0
        check_age 1 
        check_digest 1
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

sub post {
    my $self = shift;
    $self->SUPER::post(@_);

    my $assets = shift;
    my $matched = shift;

    return unless @$matched;

    return if $self->cfg->{skip_single} && 1 == @$matched;

    my %bucket;
    for my $asset (@$matched) {
    }

    my $type = $self->type;

    return if $self->skip_if_exists;

    my $build = $self->should_build;

    if ($build) {
        $self->check_digest_file->touch;
        $self->build;
    }

    $self->replace;
}
1;
