package KinoSearch1::Index::IndexFileNames;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;

use base qw( Exporter );

our @EXPORT_OK = qw(
    SEGMENTS
    DELETEABLE
    SORTFILE_EXTENSION
    @INDEX_EXTENSIONS
    @COMPOUND_EXTENSIONS
    @VECTOR_EXTENSIONS
    @SCRATCH_EXTENSIONS

    WRITE_LOCK_NAME
    WRITE_LOCK_TIMEOUT
    COMMIT_LOCK_NAME
    COMMIT_LOCK_TIMEOUT
);

# name of the index segments file
use constant SEGMENTS => 'segments';

# name of the index deletable file
use constant DELETABLE => 'deletable';

# extension of the temporary file used by the SortExternal sort pool
use constant SORTFILE_EXTENSION => '.srt';

# Most, but not all of Lucene file extenstions. Missing are the ".f$num"
# extensions.  Also note that 'segments' and 'deletable' don't have
# extensions.
our @INDEX_EXTENSIONS
    = qw( cfs fnm fdx fdt tii tis frq prx del tvx tvd tvf tvp );

# extensions for files which are subsumed into the cfs compound file
our @COMPOUND_EXTENSIONS = qw( fnm frq prx fdx fdt tii tis );

# file extensions for term vectors
our @VECTOR_EXTENSIONS = qw( tvd tvx tvf );

our @SCRATCH_EXTENSIONS = qw( srt );

# names and constants for lockfiles
use constant WRITE_LOCK_NAME     => 'write.lock';
use constant COMMIT_LOCK_NAME    => 'commit.lock';
use constant WRITE_LOCK_TIMEOUT  => 1000;
use constant COMMIT_LOCK_TIMEOUT => 10_000;

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::IndexFileNames - filenames and suffixes used in an invindex

==head1 DESCRIPTION

This module abstracts the names of the files that make up an invindex,
similarly to the way InStream and OutStream abstract filehandle operations.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut
