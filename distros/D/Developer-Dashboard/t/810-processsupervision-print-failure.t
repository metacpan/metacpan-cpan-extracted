#!/usr/bin/env perl
use strict;
use warnings;
use Symbol qw(gensym);

{
    package DD::Test::FailedOverwrite;
    sub TIEHANDLE { return bless {}, shift }
    sub PRINT { $! = 5; return 0 }
    sub CLOSE { return 1 }
}

our $FAIL_TARGET;
BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if (@_ >= 3 && defined $_[2] && defined $FAIL_TARGET
            && $_[1] eq '>' && $_[2] eq $FAIL_TARGET) {
            $_[0] = Symbol::gensym();
            tie *{ $_[0] }, 'DD::Test::FailedOverwrite';
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
use Developer::Dashboard::ProcessSupervision ();

my $dir = tempdir( CLEANUP => 1 );
my $source = File::Spec->catfile( $dir, 'source-pending' );
my $target = File::Spec->catfile( $dir, 'target-state' );
open my $fh, '>', $source or die "Unable to create $source: $!";
print {$fh} 'payload';
close $fh or die "Unable to close $source: $!";

my $self = bless {}, 'Developer::Dashboard::ProcessSupervision';
{
    no warnings 'redefine';
    local *Developer::Dashboard::ProcessSupervision::is_windows = sub { 1 };
    local $FAIL_TARGET = $target;
    my ( $ok, $err ) = $self->_overwrite_state_file_in_place( $source, $target );
    ok( !$ok, 'an in-place overwrite rejects a failed target print' );
    like( $err, qr/Unable to write \Q$target\E/,
        'the failed in-place overwrite names its target' );
    ok( -f $source, 'failed overwrite preserves its pending source' );
}

done_testing;

__END__

=head1 NAME

t/810-processsupervision-print-failure.t - state overwrite print failure

=head1 PURPOSE

Exercise the ProcessSupervision in-place overwrite print-error branch.

=head1 WHY IT EXISTS

A target can become unwritable after its handle was opened, and the
fallback must report the error rather than claim success. This test
models that with a tied handle and works across platforms.

=head1 WHEN TO USE

Run when changing state-file overwrite error handling.

=head1 HOW TO USE

  prove -lv t/810-processsupervision-print-failure.t

=head1 WHAT USES IT

The developer test suite and the strict CI coverage gate.

=head1 EXAMPLES

  prove -lv t/810-processsupervision-print-failure.t

Verify the failed overwrite retains its pending source.

=cut
