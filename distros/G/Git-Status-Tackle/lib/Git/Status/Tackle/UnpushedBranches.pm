package Git::Status::Tackle::UnpushedBranches;
use strict;
use warnings;
use parent 'Git::Status::Tackle::Plugin';

sub synopsis { "Lists branches not fully merged into their upstream branch" }

sub list {
    my $self = shift;

    my @output;
    for my $colored_name ($self->branches) {
        my $plain_name = $colored_name;
        $plain_name =~ s/^[\s*]+//;
        # strip ansi colors, ew
        # http://stackoverflow.com/questions/7394889/best-way-to-remove-ansi-color-escapes-in-unix
        $plain_name =~ s/\e\[[\d;]*[a-zA-Z]//g;

        next if $plain_name eq '(no branch)';

        my $status = `git rev-list $plain_name\@{u}..$plain_name 2>&1`;
        if ($status =~ /No upstream branch found/ || $status =~ /unknown revision/) {
            push @output, " $colored_name: No upstream\n";
            next;
        }

        my $diff;
        if (my $lines = $status =~ tr/\n/\n/) {
            $diff .= "\e[32m+$lines\e[m";
        }

        my $reverse = `git rev-list $plain_name..$plain_name\@{u} 2>&1`;
        if (my $reverse_lines = $reverse =~ tr/\n/\n/) {
            $diff .= "\e[31m-$reverse_lines\e[m";
        }

        push @output, " $colored_name: $diff\n"
            if $diff;
    }

    return \@output;
}

1;

