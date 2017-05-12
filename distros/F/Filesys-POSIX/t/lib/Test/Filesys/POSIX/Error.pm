# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Test::Filesys::POSIX::Error;

use strict;
use warnings;

use Errno;
use Try::Tiny;

use base 'Test::Builder::Module';

our @EXPORT = qw(throws_errno_ok);

my $CLASS = __PACKAGE__;
my %cache;

BEGIN {
    #
    # First, store a basic table of number => number mappings as a fallback
    # for when symbols cannot be pulled reliably from the Errno stash.
    #
    %cache = map { $_ => $_ } 0 .. 255;

    #
    # Next, attempt to store a number => symbolic name mapping.
    #
    foreach my $name ( @Errno::EXPORT_OK, @{ $Errno::EXPORT_TAGS{'POSIX'} } ) {
        my $sv = $Errno::{$name};

        next unless $$sv;

        $cache{ int $$sv } = $name;
    }

    $cache{0} = 'No error';
}

sub throws_errno_ok (&$$) {
    my ( $sub, $errno, $message ) = @_;
    my $builder = $CLASS->builder;
    my $pass    = 1;

    try {
        $sub->();
        $pass = 0;
    };

    my $found = int $!;

    $pass = 0 unless $found == $errno;

    $builder->ok( $pass, $message );

    unless ($pass) {
        $builder->diag("expected: $cache{$errno}");
        $builder->diag("found: $cache{$found}");
    }

    return $pass;
}

1;
