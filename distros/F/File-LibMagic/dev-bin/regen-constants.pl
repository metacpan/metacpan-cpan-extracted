#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::Constant;

my @names = (
    qw(
        MAGIC_CHECK
        MAGIC_COMPRESS
        MAGIC_CONTINUE
        MAGIC_DEBUG
        MAGIC_DEVICES
        MAGIC_ERROR
        MAGIC_MIME
        MAGIC_NONE
        MAGIC_PRESERVE_ATIME
        MAGIC_RAW
        MAGIC_SYMLINK
        )
);

ExtUtils::Constant::WriteConstants(
    NAME         => 'File::LibMagic',
    NAMES        => \@names,
    DEFAULT_TYPE => 'IV',
    C_FILE       => 'const/inc.c',
    XS_FILE      => 'const/inc.xs',
);

exit 0;
