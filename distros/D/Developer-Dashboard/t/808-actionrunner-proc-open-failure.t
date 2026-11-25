#!/usr/bin/env perl
use strict;
use warnings;

# A readable stat fixture whose open fails deterministically, even as root.
our $FAIL_STAT;
BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if (@_ >= 3 && defined $_[2] && defined $FAIL_STAT && $_[2] eq $FAIL_STAT) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[2 .. $#_] );
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use lib 'lib';
use Developer::Dashboard::ActionRunner ();

my $root = tempdir( CLEANUP => 1 );
my $pid_dir = File::Spec->catdir( $root, 424242 );
make_path($pid_dir);
my $stat = File::Spec->catfile( $pid_dir, 'stat' );
open my $fh, '>', $stat or die "Unable to create $stat: $!";
print {$fh} "424242 (fixture process) S 1 2 3\n";
close $fh or die "Unable to close $stat: $!";
my $reader = bless {}, 'Developer::Dashboard::ActionRunner';

{
    local $Developer::Dashboard::ActionRunner::PROCFS_ROOT = $root;
    # The reader builds its path as "$PROCFS_ROOT/$pid/stat" with forward
    # slashes on every platform, so the injected failure is keyed on that
    # exact spelling; File::Spec would give backslashes on Windows and the
    # override would never match there.
    local $FAIL_STAT = "$root/424242/stat";
    is( $reader->_read_process_state(424242), undef,
        'a readable stat entry that cannot be opened returns undef' );
}

done_testing;

__END__

=head1 NAME

t/808-actionrunner-proc-open-failure.t - procfs open failure coverage

=head1 PURPOSE

Exercise the open-failure branch in ActionRunner's procfs state reader.

=head1 WHY IT EXISTS

A file can pass the readable-file check and disappear or become unreadable
before the open. The strict coverage gate requires this case on every host,
including macOS and Windows where Linux procfs does not exist.

=head1 WHEN TO USE

Run this test when changing process-state detection or file-open guards.

=head1 HOW TO USE

  prove -lv t/808-actionrunner-proc-open-failure.t

=head1 WHAT USES IT

The test suite and mandatory CI all-metric coverage gate.

=head1 EXAMPLES

  prove -lv t/808-actionrunner-proc-open-failure.t

A targeted regression for the procfs read race.

=cut
