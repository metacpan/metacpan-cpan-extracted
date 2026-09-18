#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

use lib 'lib';
use Developer::Dashboard::FileSlurp qw(slurp_file);

my $dir = tempdir( CLEANUP => 1 );
chdir $dir or die "Unable to chdir $dir: $!";

# AC-1: default (text mode, on_missing => 'die')
my $text_path = File::Spec->catfile( $dir, 'text.txt' );
open my $fh, '>', $text_path or die $!;
print {$fh} "hello\n";
close $fh;
is( slurp_file($text_path), "hello\n", 'default text-mode read returns file content' );

# raw mode
my $raw_path = File::Spec->catfile( $dir, 'raw.bin' );
open my $rfh, '>:raw', $raw_path or die $!;
print {$rfh} "\x00\x01raw";
close $rfh;
is( slurp_file( $raw_path, raw => 1 ), "\x00\x01raw", 'raw => 1 reads in :raw mode' );

# on_missing => 'empty'
my $missing_path = File::Spec->catfile( $dir, 'does-not-exist.txt' );
is( slurp_file( $missing_path, on_missing => 'empty' ), '', "on_missing => 'empty' returns '' for a missing file" );

# on_missing => 'empty' with a file that DOES exist - must still read it normally
is( slurp_file( $text_path, on_missing => 'empty' ), "hello\n", "on_missing => 'empty' still reads an existing file normally" );

# on_missing default is 'die'
eval { slurp_file($missing_path) };
like( $@, qr/Unable to read/, 'default on_missing dies with a message naming the failure' );

# custom missing_message template
eval { slurp_file( $missing_path, missing_message => 'Unable to read attachment %s: %s' ) };
like( $@, qr/Unable to read attachment \Q$missing_path\E: /, 'missing_message templates the path and $!' );

# Collector.pm contract: raw + on_missing empty, no exception on a missing file
is( slurp_file( $missing_path, raw => 1, on_missing => 'empty' ), '', 'Collector.pm-shaped call: raw + empty-on-missing' );

# CollectorRunner.pm contract: text mode, dies on missing, default message
eval { slurp_file($missing_path) };
like( $@, qr/\Q$missing_path\E/, 'CollectorRunner.pm-shaped call: text mode, dies naming the path' );

# CLI/Ask.pm contract: raw + custom message + never returns undef
is( slurp_file( $text_path, raw => 1 ), "hello\n", 'CLI/Ask.pm-shaped call: raw mode on an existing file' );

# normalize_undef: an I/O error on an already-open handle (not a missing file)
# yields undef from <$fh>. Reproduced hermetically the same way as
# t/89-collector-coverage.t's "unreadable artifact" case: symlink to
# /proc/self/mem, which opens successfully but fails to read.
SKIP: {
    skip 'requires /proc/self/mem to force a read error', 2
      if !-f '/proc/self/mem';

    my $unreadable = File::Spec->catfile( $dir, 'unreadable-via-symlink' );
    my $symlinked = symlink( '/proc/self/mem', $unreadable );
    skip "unable to symlink /proc/self/mem: $!", 2 if !$symlinked;

    is( slurp_file( $unreadable, raw => 1 ), undef,
        'default (normalize_undef off): an I/O read error returns undef, matching Collector.pm/CollectorRunner.pm original behavior' );
    is( slurp_file( $unreadable, raw => 1, normalize_undef => 1 ), '',
        "normalize_undef => 1: the same I/O read error returns '' instead, matching CLI/Ask.pm's original behavior" );
}

done_testing;

__END__

=head1 NAME

t/189-fileslurp-coverage.t - coverage for Developer::Dashboard::FileSlurp

=head1 PURPOSE

Exercises C<slurp_file>'s option surface (raw vs text mode, on_missing
die-vs-empty, custom missing_message templating) added for DD-888, which
consolidates three independently-drifted C<_slurp> implementations
(Collector.pm, CollectorRunner.pm, CLI/Ask.pm) into one shared helper.

=head1 WHY IT EXISTS

DD-888 found the three call sites had already diverged in raw-mode and
missing-file behavior with no shared source of truth. This test proves the
new shared helper can express all three original contracts exactly, so the
migration in each call site is behavior-preserving.

=head1 WHEN TO USE

Run whenever C<Developer::Dashboard::FileSlurp> changes, or when any of its
three call sites' contract changes.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/189-fileslurp-coverage.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Its subject is
C<Developer::Dashboard::FileSlurp>, used by C<Collector.pm>,
C<CollectorRunner.pm> and C<CLI/Ask.pm>.

=head1 EXAMPLES

    my $text = slurp_file($path);
    my $raw  = slurp_file($path, raw => 1, on_missing => 'empty');

=cut
