#!/usr/bin/env perl

# Copyright (C) 2008  Joshua Hoblitt
# 
# $Id: 02_mountpoint.t,v 1.2 2008/09/30 06:58:08 jhoblitt Exp $

use strict;
use warnings FATAL => qw( all );

use lib qw( ./lib ./t );

use Test::More tests => 5;

use File::Temp qw( tempdir );

use File::Mountpoint qw( is_mountpoint );

# / (root) should always be considered a mountpoint
ok(is_mountpoint('/'), "/ (root) is a mountpoint");

{
    # a newly created temp dir should not be a mountpoint
    my $dir = tempdir( CLEANUP => 1 );

    is(is_mountpoint($dir), undef, "tmp dir is not a mountpoint");
}

eval {
    is_mountpoint('/foo/bar/baz/quix');
};
like($@, qr/No such file or directory/, 'No such file or directory');

eval {
    my $fh = File::Temp->new( UNLINK => 1 );
    is_mountpoint($fh->filename);
};
like($@, qr/not a directory/, 'not a directory');

is(is_mountpoint(), undef, "no paarms");
