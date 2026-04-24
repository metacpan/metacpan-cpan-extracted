#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Path qw(make_path);

use FastGlob ();

# Test that recurseglob warns on opendir failure when $verbose is set

subtest 'silent return when opendir fails and verbose is off' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $noread = "$tmpdir/noaccess";
    make_path($noread);

    # Create a file inside so glob would match if readable
    open my $fh, '>', "$noread/foo.txt" or die "Cannot create file: $!";
    close $fh;

    # Remove read+execute permission on the directory
    chmod 0000, $noread;

    # Skip if we're root (root can read anything)
    if ( -r $noread ) {
        chmod 0755, $noread;
        plan skip_all => 'Running as root — cannot test permission denial';
        return;
    }

    local $FastGlob::verbose = 0;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @result = FastGlob::glob("$noread/*");

    is( scalar @result, 0, 'no results when directory is unreadable' );
    is( scalar @warnings, 0, 'no warning emitted when verbose is off' );

    # Restore permissions for cleanup
    chmod 0755, $noread;
};

subtest 'warning emitted when opendir fails and verbose is set' => sub {
    my $tmpdir = tempdir( CLEANUP => 1 );
    my $noread = "$tmpdir/noaccess";
    make_path($noread);

    open my $fh, '>', "$noread/foo.txt" or die "Cannot create file: $!";
    close $fh;

    chmod 0000, $noread;

    if ( -r $noread ) {
        chmod 0755, $noread;
        plan skip_all => 'Running as root — cannot test permission denial';
        return;
    }

    local $FastGlob::verbose = 1;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my @result = FastGlob::glob("$noread/*");

    is( scalar @result, 0, 'no results when directory is unreadable' );
    ok( scalar @warnings >= 1, 'warning emitted when verbose is on' );
    like( $warnings[0], qr/opendir.*\Q$noread\E/i, 'warning mentions the failing directory' )
        if @warnings;

    # Restore permissions for cleanup
    chmod 0755, $noread;
};

done_testing;
