package Git::Status::Tackle::WorkingTreeChanges;
use strict;
use warnings;
use parent 'Git::Status::Tackle::Plugin';

sub synopsis { "Lists files with unstaged changes" }

sub list {
    return [`git diff --color --stat`];
}

1;

