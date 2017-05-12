package Git::Status::Tackle::CompletedFeatureBranches;
use strict;
use warnings;
use parent 'Git::Status::Tackle::Plugin';

sub synopsis { "Lists branches fully merged into destination branch" }

sub destination {
    my $self = shift;
    if (!exists($self->{destination})) {
        chomp($self->{destination} = `git config status-tackle.destination`);
    }

    return $self->{destination};
}

sub list {
    my $self = shift;

    my $destination = $self->destination;
    if (!$destination) {
        die "The destination branch must be configured. Please set the destination branch for this project like:\n    git config --add status-tackle.destination release-2.1.0\n";
    }

    if (`git rev-parse $destination 2>&1` =~ /unknown revision/) {
        die "Your configured destination branch ($destination) does not exist. Please create it or change the destination branch for this project like:\n    git config --replace-all status-tackle.destination release-2.1.1\n";
    }

    chomp(my $destination_sha = `git rev-parse $destination`);

    my @output;
    for my $colored_name ($self->branches) {
        my $plain_name = $colored_name;
        $plain_name =~ s/^[\s*]+//;
        # strip ansi colors, ew
        # http://stackoverflow.com/questions/7394889/best-way-to-remove-ansi-color-escapes-in-unix
        $plain_name =~ s/\e\[[\d;]*[a-zA-Z]//g;

        next if $plain_name eq '(no branch)' || $plain_name eq $destination;

        chomp(my $current_sha = `git rev-parse $plain_name`);
        next if $current_sha eq $destination_sha;

        my $status = `git rev-list $destination_sha..$current_sha 2>&1`;

        my $diff;
        if (my $lines = $status =~ tr/\n/\n/) {
            $diff .= "\e[32m+$lines\e[m";
        }

        push @output, " $colored_name\n"
            if !$diff;
    }

    return \@output;
}

sub header {
    my $self = shift;
    return $self->name . " (merged into " . $self->destination . "):\n";
}

1;

