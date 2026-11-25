#!/usr/bin/env perl
use strict;
use warnings;
use Symbol qw(gensym);

{
    package DD::Test::FailPrint;
    sub TIEHANDLE { return bless {}, shift }
    sub PRINT { $! = 5; return 0 }
    sub CLOSE { return 1 }
}

# Return a tied writable handle only for the exact staging-file fixture.
our $FAIL_PRINT_PATH;
BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if (@_ >= 3 && defined $_[2] && defined $FAIL_PRINT_PATH
            && $_[2] eq $FAIL_PRINT_PATH && $_[1] eq '>:raw') {
            $_[0] = Symbol::gensym();
            tie *{ $_[0] }, 'DD::Test::FailPrint';
            return 1;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[2 .. $#_] );
    };
}

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use lib 'lib';
use Developer::Dashboard::PathRegistry ();

my $home = tempdir( CLEANUP => 1 );
my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $stage = File::Spec->catfile( $home, 'pending-file' );
my $final = File::Spec->catfile( $home, 'published-file' );

{
    local $FAIL_PRINT_PATH = $stage;
    my $ok = eval { $paths->atomic_write_secure( $stage, $final, 'payload' ); 1 };
    ok( !$ok, 'atomic write rejects a staging-handle print failure' );
    like( $@, qr/Unable to write \Q$stage\E/,
        'the staging print error identifies the path' );
    ok( !-e $final, 'failed staging writes never publish the destination' );
}

done_testing;

__END__

=head1 NAME

t/809-pathregistry-print-failure.t - atomic staging write failure

=head1 PURPOSE

Exercise the print failure branch of PathRegistry atomic_write_secure.

=head1 WHY IT EXISTS

A writable handle can fail during output even after open succeeds.
A tied handle provides this failure on macOS and Windows without relying
on Linux devices or on process privileges.

=head1 WHEN TO USE

Run when changing atomic-write or staged-file publishing behavior.

=head1 HOW TO USE

  prove -lv t/809-pathregistry-print-failure.t

=head1 WHAT USES IT

The developer test suite and mandatory coverage CI.

=head1 EXAMPLES

  prove -lv t/809-pathregistry-print-failure.t

Verify a failed write never reaches the final destination.

=cut
