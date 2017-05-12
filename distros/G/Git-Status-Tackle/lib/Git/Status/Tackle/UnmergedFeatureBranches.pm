package Git::Status::Tackle::UnmergedFeatureBranches;
use strict;
use warnings;
use parent 'Git::Status::Tackle::Plugin';

sub synopsis { "Lists branches not fully merged into the integration branch" }

sub integration {
    my $self = shift;
    if (!exists($self->{integration})) {
        chomp($self->{integration} = `git config status-tackle.integration`);
    }

    return $self->{integration};
}

sub list {
    my $self = shift;

    my $integration = $self->integration;
    if (!$integration) {
        die "The integration branch must be configured. Please set the integration branch for this project like:\n    git config --add status-tackle.integration release-2.1.0\n";
    }

    if (`git rev-parse $integration 2>&1` =~ /unknown revision/) {
        die "Your configured integration branch ($integration) does not exist. Please create it or change the integration branch for this project like:\n    git config --replace-all status-tackle.integration release-2.1.1\n";
    }

    my @output;
    for my $colored_name ($self->branches) {
        my $plain_name = $colored_name;
        $plain_name =~ s/^[\s*]+//;
        # strip ansi colors, ew
        # http://stackoverflow.com/questions/7394889/best-way-to-remove-ansi-color-escapes-in-unix
        $plain_name =~ s/\e\[[\d;]*[a-zA-Z]//g;

        next if $plain_name eq '(no branch)';

        my $status = `git rev-list $integration..$plain_name 2>&1`;

        my $diff;
        if (my $lines = $status =~ tr/\n/\n/) {
            $diff .= "\e[32m+$lines\e[m";
        }

        push @output, " $colored_name: $diff\n"
            if $diff;
    }

    return \@output;
}

sub header {
    my $self = shift;
    return $self->name . " (merging into " . $self->integration . "):\n";
}

1;

