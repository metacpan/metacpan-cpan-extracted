#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::close override must exist before the module under test is
# compiled. It fails only for handles opened on exact registered paths, so the
# deferred-write close failure runs for any uid, including root.
our %FAIL_CLOSE;
my %close_handles;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        my $rc = @_ == 2 ? CORE::open( $_[0], $_[1] ) : CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
        if ( $rc && @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL_CLOSE{ $_[2] } ) {
            $close_handles{ Scalar::Util::refaddr( $_[0] ) } = 1;
        }
        return $rc;
    };
    *CORE::GLOBAL::close = sub (;*) {
        my $fail = @_ && ref $_[0] && delete $close_handles{ Scalar::Util::refaddr( $_[0] ) };
        my $rc = @_ ? CORE::close( $_[0] ) : CORE::close();
        if ($fail) {
            $! = 5;
            return 0;
        }
        return $rc;
    };
}

use Test::More;
use Scalar::Util ();
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::SeedSync;

my $dir  = tempdir( CLEANUP => 1 );
my $file = File::Spec->catfile( $dir, 'seed.txt' );
open my $fh, '>', $file or die "Unable to write $file: $!";
print {$fh} "seed body\n";
close $fh or die "Unable to close $file: $!";

ok( Developer::Dashboard::SeedSync::file_matches_content_md5( $file, "seed body\n" ), 'a readable matching file is reported as matching' );

local $FAIL_CLOSE{$file} = 1;
my $ok = eval { Developer::Dashboard::SeedSync::file_matches_content_md5( $file, "seed body\n" ); 1 };
ok( !$ok, 'a close failure after reading is fatal' );
like( $@, qr/Unable to close \Q$file\E/, 'the close failure names the file' );

done_testing;

__END__

=pod

=head1 NAME

t/594-seedsync-close-coverage.t - covers the close-failure branch of Developer::Dashboard::SeedSync

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the close failure in file_matches_content_md5 for a file that exists.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate must be met without any C<# uncoverable> annotation, and these paths can only be reached by injecting failures that work for any uid, including root.

=head1 WHEN TO USE

Use this file when you change Developer::Dashboard::SeedSync, or when a coverage run reports one of these paths as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/594-seedsync-close-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/594-seedsync-close-coverage.t

Run this coverage-gap test by itself while editing Developer::Dashboard::SeedSync.

=cut
