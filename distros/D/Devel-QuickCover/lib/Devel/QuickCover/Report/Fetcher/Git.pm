package Devel::QuickCover::Report::Fetcher::Git;

use strict;
use warnings;

use IPC::Open2 qw();

sub new {
    my ($class, $prefix, $repo, $commit) = @_;
    my ($out, $in);
    my $pid = IPC::Open2::open2(
        $out, $in, 'git', '--git-dir', $repo, 'cat-file', '--batch', '--follow-symlinks'
    );
    my $self = bless {
        prefix  => $prefix,
        pid     => $pid,
        in      => $in,
        out     => $out,
        commit  => $commit,
    }, $class;

    return $self;
}

sub fetch {
    my ($self, $path) = @_;

    die "'$self->{prefix}' is not a prefix of '$path'"
        unless rindex($path, $self->{prefix}, 0) == 0;
    my $relative = substr($path, length($self->{prefix}));

    print {$self->{in}} "$self->{commit}:$relative\n";
    $self->{in}->flush;

    my $header = do {
        local $/ = "\n";
        readline $self->{out};
    };
    my ($hash, $type, $length) = split / /, $header;
    my $nohash = $hash eq 'symlink' || $hash eq 'dangling' || $hash eq 'loop' || $hash eq 'nodir';
    $length = $type if $nohash;

    return '' if $type eq "missing\n";
    read $self->{out}, my $buffer, $length, 0;
    read $self->{out}, my $newlinw, 1;
    return '' if $nohash;

    return \$buffer;
}

sub DESTROY {
    my ($self) = @_;

    close $self->{out} if $self->{out};
    close $self->{in} if $self->{in};
    waitpid $self->{pid}, 0;
}

1;
