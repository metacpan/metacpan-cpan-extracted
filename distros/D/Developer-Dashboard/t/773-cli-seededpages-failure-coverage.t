#!/usr/bin/env perl

use strict;
use warnings;

# close() is overridden before the module is compiled so the manifest reader's
# close failure can be forced for any uid. The override fails only while
# $FAIL_CLOSE is set, and otherwise delegates to the real close.
our $FAIL_CLOSE = 0;

BEGIN {
    *CORE::GLOBAL::close = sub (;*) {
        my $result = @_ ? CORE::close( $_[0] ) : CORE::close();
        if ( $FAIL_CLOSE && $result ) {
            $! = 5;
            return 0;
        }
        return $result;
    };
}

use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PageDocument;
use Developer::Dashboard::CLI::SeededPages;

my $SP   = 'Developer::Dashboard::CLI::SeededPages';
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
my $store = Developer::Dashboard::PageStore->new( paths => $paths );

my $manifest = $SP->can('seed_manifest_path')->( paths => $paths );
make_path( ( File::Spec->splitpath($manifest) )[1] );
open my $fh, '>', $manifest or die "Unable to write $manifest: $!";
print {$fh} "{}\n";
close $fh or die "Unable to close $manifest: $!";

{
    local $FAIL_CLOSE = 1;
    my $ok = eval { $SP->can('_read_manifest')->( paths => $paths ); 1 };
    my $err = $@;
    local $FAIL_CLOSE = 0;
    ok( !$ok, 'a manifest whose handle cannot be closed dies' );
    like( $err, qr/Unable to close \Q$manifest\E/, 'the close failure names the manifest' );
}

# A whitespace-only manifest reads back as an empty hash.
open $fh, '>', $manifest or die "Unable to write $manifest: $!";
print {$fh} "  \n";
close $fh or die "Unable to close $manifest: $!";
is_deeply( $SP->can('_read_manifest')->( paths => $paths ), {}, 'a blank manifest decodes to an empty hash' );

# A diverged page whose md5 is a known managed copy is refreshed even when the
# manifest never recorded it.
{
    $store->save_page(
        Developer::Dashboard::PageDocument->new(
            id     => 'seed-known',
            title  => 'Old Managed',
            layout => { body => 'old managed body' },
        )
    );
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::SeededPages::is_known_managed_page_md5 = sub { 1 };
    is(
        $SP->can('ensure_seeded_page')->(
            pages => $store,
            paths => $paths,
            page  => Developer::Dashboard::PageDocument->new(
                id     => 'seed-known',
                title  => 'New Managed',
                layout => { body => 'new managed body' },
            ),
        ),
        'updated',
        'a page matching a known managed md5 is refreshed without a manifest record',
    );
}

done_testing;

__END__

=pod

=head1 NAME

t/773-cli-seededpages-failure-coverage.t - covers the manifest close failure and known-managed refresh of SeededPages

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the manifest reader close failure and the known-managed-md5 refresh condition.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/773-cli-seededpages-failure-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/773-cli-seededpages-failure-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/773-cli-seededpages-failure-coverage.t

Confirm the targeted lines are reported as covered.

=cut
