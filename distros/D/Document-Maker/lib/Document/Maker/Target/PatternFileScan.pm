package Document::Maker::Target::PatternFileScan;

use strict;
use warnings;

use Moose;

use Document::Maker::Dependency;
use Document::Maker::Target::PatternFile;

with map { "Document::Maker::Role::$_" } qw/Component TargetMaker Dependency/;

has finder => qw/is ro required 1/, handles => [qw/found/];
has script => qw/is rw/;
has target_pattern => qw/is ro isa Document::Maker::Pattern required 1/;
has source_pattern => qw/is ro isa Document::Maker::Pattern required 1/;
has dependency => qw/is ro lazy 1/, default => sub {
    return Document::Maker::Dependency->new(maker => shift->maker);
};
has target_cache => qw/is ro lazy 1/, default => sub {
    my $self = shift;
    my %cache;
    for my $name (@{ $self->found }) {
        next unless $name =~ $self->source_pattern->matcher;
        my $target = Document::Maker::Target::PatternFile->new(maker => $self->maker, nickname => $name, dependency => $self->dependency->clone,
                target_pattern => $self->target_pattern, source_pattern => $self->source_pattern, script => $self->script);
        $cache{$target->name} = $target;
    }
    return \%cache;
};

sub BUILD {
    my $self = shift;
    my $finder = $self->finder;
    return if blessed $finder;
    if (Document::Maker::FileFinder::Query->recognize($finder)) {
        $self->{finder} = Document::Maker::FileFinder::Query->new(maker => $self->maker, query => $finder);
        $self->log->debug("New pattern target file scan (by query): $finder");
    }
}

sub can_make {
    my $self = shift;
    my $name = shift;
    return $self->target_cache->{$name};
}

sub make {
    my $self = shift;
    for my $target (values %{ $self->target_cache }) {
        $target->make;
    }
}

sub fresh {
    my $self = shift;
    for my $target (values %{ $self->target_cache }) {
        return 0 unless $target->fresh;
    }
    return 1;
}

sub freshness {
    my $self = shift;
    my $freshness;
    for my $target (values %{ $self->target_cache }) {
        $freshness = $target->freshness if ! defined $target || $freshness > $target->freshness;
    }
    return $freshness || 0;
}


1;
