package Document::Maker::FileFinder::Query;

use strict;
use warnings;

use Moose;

with qw/Document::Maker::Role::Component/;

has query => qw/is ro required 1/;
has matcher => qw/is ro/;
has depth => qw/is ro/;
has dir => qw/is ro/;
has skip_dot => qw/is ro/;
has found => qw/is ro lazy 1/, default => sub {
    return [ shift->find ];
};

use Path::Class;
use File::Find::Rule();

sub parse {
    my $self = shift;
    my $query = shift;
    my ($dir, $pattern) = $query =~ m/^(.*)\/(\!?\*.*)$/;
    my ($depth, $skip_dot);
    $skip_dot = !($pattern =~ s/^\!//);
    $pattern =~ s/(\d+|\*)$//;
    $depth = $1;
    $depth = 1 unless defined $depth;
    $depth = 0 if $depth eq "*";
    my ($matcher) = $pattern =~ m/^\*\{(.*)\}$/;
    $matcher = qr/$matcher/ if $matcher;
    $self->log->debug("Source scan query $query is ", join " ", map { defined $_ ? $_ : "" } ($dir, $matcher, $depth, $skip_dot ? "!." : "."));
    return ($dir, $matcher, $depth, $skip_dot);
}

sub BUILD {
    my $self = shift;
    my $query = $self->query;
    @$self{qw/dir matcher depth skip_dot/} = my ($dir, $matcher, $depth, $skip_dot) = $self->parse($query);
}

sub find {
    my $self = shift;

    my $query = $self->query;
    my $rule = File::Find::Rule->new;
    $rule = $rule->mindepth(1);
    $rule = $rule->maxdepth($self->depth) if $self->depth;
    $rule = $rule->not($rule->new->name(qr/^\./)->prune->discard) if $self->skip_dot;
    $rule = $rule->name($self->matcher) if $self->matcher;
    return $rule->in($self->dir);
}

sub recognize {
    shift;
    return unless my $possible = shift;
    return $possible =~ m/^(.*)\/(\!?\*.*)$/;
}

1;
