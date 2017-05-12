package TestUtils;

use strict;
use warnings;

use base 'Exporter';

our @EXPORT = qw(silent_system list_archive);

sub silent_system {
    my ( @args ) = @_;

    my $pid = fork;

    if($pid) {
        waitpid -1, 0;
    } else {
        close STDOUT;
        close STDERR;

        exec @args;
        exit 1;
    }
}

sub list_archive {
    my ( $archive_filename ) = @_;

    my $archive = Archive::Tar->new($archive_filename);

    my @files = $archive->list_files;

    return @files;
}

1;
