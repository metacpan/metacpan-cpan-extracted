package File::Assets::Bucket;

use warnings;
use strict;

use Object::Tiny qw/kind assets/;

sub new {
    my $self = bless {}, shift;
    $self->{kind} = my $kind = shift;
    $self->{assets} = my $assets = shift;
    $self->{slice} = [];
    $self->{filters} = [];
    return $self;
}

sub add_asset {
    my $self = shift;
    my $asset = shift;
    push @{ $self->{slice} }, $asset;
}

sub add_filter {
    my $self = shift;
    my $filter = shift;

    my $signature = $filter->signature;
    my $filters = $self->{filters};

    if (defined $signature) {
        for my $entry (@$filters) {
            if (defined $entry->[0] && $entry->[0] eq $signature) {
                $entry->[1] = $filter;
                return;
            }
        }
    }

    push @$filters, [ $signature, $filter ];
}

sub exports {
    my $self = shift;
    my @assets = $self->all;
    my $filters = $self->{filters};
    for my $entry (@$filters) {
        $entry->[1]->filter(\@assets, $self, $self->assets);
    }
    return @assets;
}

sub clear {
    my $self = shift;
    $self->{slice} = [];
    $self->{filters} = {};
}

sub all {
    my $self = shift;
    return @{ $self->{slice} };
}

1;
