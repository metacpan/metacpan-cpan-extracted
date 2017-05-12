package Git::Repository::Plugin::FileHistory;
use strict;
use warnings;

use parent 'Git::Repository::Plugin';
sub _keywords { qw/file_history/ }

use Git::Repository::FileHistory;

our $VERSION = '0.06';

sub file_history {
    Git::Repository::FileHistory->new(@_);
}

1;
