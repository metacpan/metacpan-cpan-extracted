# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Filesys::POSIX::Real::Inode ();       # required
use Filesys::POSIX::Real::Directory ();

use Test::More tests => 1;
use File::Temp ();

my $tmpdir = File::Temp::tempdir( 'CLEANUP' => 1 ) or die "$!";

for (qw(0 1 2 3 4 5 6 7 8 9)) {
    _touch( $tmpdir . '/' . $_ );
}

my $fs = Filesys::POSIX::Real::Directory->new($tmpdir);
$fs->open;

my @contents;

while ( defined( $_ = $fs->read ) ) {
    push @contents, $_;
}

@contents = sort @contents;

is_deeply \@contents, [qw(. .. 0 1 2 3 4 5 6 7 8 9)], "got complete directory listing even when one filename evaluates to a false value"
  or note explain \@contents;

sub _touch {
    my $f = shift;
    open my $fh, '>', $f;
    close $fh;
    return;
}
