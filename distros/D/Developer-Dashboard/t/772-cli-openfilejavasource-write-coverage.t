#!/usr/bin/env perl

use strict;
use warnings;

# The CORE::GLOBAL::open override must exist before the module under test is
# compiled. It fails only for exact paths registered in %FAIL, so the write
# failure is deterministic even when the suite runs as root.
our %FAIL;

BEGIN {
    *CORE::GLOBAL::open = sub (*;$@) {
        if ( @_ >= 3 && defined $_[2] && !ref $_[2] && $FAIL{ $_[2] } ) {
            $! = 13;
            return 0;
        }
        return CORE::open( $_[0], $_[1] ) if @_ == 2;
        return CORE::open( $_[0], $_[1], @_[ 2 .. $#_ ] );
    };
}

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Archive::Zip qw(:ERROR_CODES);

use lib 'lib';

use Developer::Dashboard::CLI::OpenFileJavaSource;
use Developer::Dashboard::PathRegistry;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
my $reg = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $home );

my $jar = File::Spec->catfile( $home, 'sources.jar' );
my $zip = Archive::Zip->new;
$zip->addString( "class Foo {}\n", 'com/example/Foo.java' );
$zip->writeToFileNamed($jar) == AZ_OK or die "Unable to write $jar";

my $target = Developer::Dashboard::CLI::OpenFileJavaSource::_cached_archive_source_path(
    paths   => $reg,
    archive => $jar,
    entry   => 'com/example/Foo.java',
);
ok( $target, 'the cache target for the member resolves' );

{
    local $FAIL{$target} = 1;
    my @got = eval {
        Developer::Dashboard::CLI::OpenFileJavaSource::_extract_java_sources_from_archive(
            paths    => $reg,
            archive  => $jar,
            relative => 'com/example/Foo.java',
        );
    };
    like( $@, qr/Unable to write \Q$target\E/, 'a cache file that cannot be opened for writing dies naming the target' );
}

my @ok = Developer::Dashboard::CLI::OpenFileJavaSource::_extract_java_sources_from_archive(
    paths    => $reg,
    archive  => $jar,
    relative => 'com/example/Foo.java',
);
is_deeply( \@ok, [$target], 'without the injected failure the member is extracted to the cache target' );

done_testing;

__END__

=pod

=head1 NAME

t/772-cli-openfilejavasource-write-coverage.t - covers the cache write failure of OpenFileJavaSource

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It forces the open-for-write failure of a Java source cache file.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/772-cli-openfilejavasource-write-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/772-cli-openfilejavasource-write-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/772-cli-openfilejavasource-write-coverage.t

Confirm the targeted lines are reported as covered.

=cut
