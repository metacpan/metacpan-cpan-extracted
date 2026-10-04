#!/usr/bin/env perl

use strict;
use warnings;

use Cwd ();
use Test::More;
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::CLI::Paths ();

my $load = \&Developer::Dashboard::CLI::Paths::_load_skill_folder_module;

my $home = Cwd::abs_path( tempdir( CLEANUP => 1 ) );
my $root = File::Spec->catdir( $home, 'skill' );
my $lib  = File::Spec->catdir( $root, 'lib' );
make_path($lib);
my $file = File::Spec->catfile( $lib, 'Folder.pm' );
open my $fh, '>', $file or die "Unable to write $file: $!";
print {$fh} "package Folder; 1;\n";
close $fh or die "Unable to close $file: $!";

my $entry = { dir => $root, lib => $lib, file => $file };

# Each of the three abs_path lookups can fail independently; only the one for
# the named path is made to return undef.
for my $victim ( [ dir => $root ], [ lib => $lib ], [ file => $file ] ) {
    my ( $label, $path ) = @{$victim};
    no warnings 'redefine';
    local *Developer::Dashboard::CLI::Paths::abs_path = sub { return $_[0] eq $path ? undef : Cwd::abs_path( $_[0] ) };
    my $ok = eval { $load->($entry); 1 };
    ok( !$ok, "an unresolvable $label path dies" );
    like( $@, qr/Unable to resolve skill Folder\.pm/, "the $label failure is reported" );
}

done_testing;

__END__

=pod

=head1 NAME

t/774-cli-paths-folder-resolve-coverage.t - covers the abs_path failure conditions of the skill Folder.pm loader

=head1 PURPOSE

Test file in the Developer Dashboard codebase. It makes each abs_path lookup in the skill Folder.pm loader fail independently.

=head1 WHY IT EXISTS

It exists because the mandatory 100 percent lib/ coverage gate allows no uncoverable annotations, so every branch in the covered modules must be reached by a real test that also works when the suite runs as root.

=head1 WHEN TO USE

Use this file when you change the code it covers, or when a coverage run reports one of its lines, branches or conditions as uncovered.

=head1 HOW TO USE

Run it directly with C<prove -lv t/774-cli-paths-folder-resolve-coverage.t> while iterating, then keep it green under C<prove -lr t> and the Devel::Cover run before release.

=head1 WHAT USES IT

It is used by developers during TDD, by the full C<prove -lr t> suite, by the Devel::Cover coverage gate, and by release verification before commit or push.

=head1 EXAMPLES

Example 1:

  prove -lv t/774-cli-paths-folder-resolve-coverage.t

Run this coverage-gap test by itself while editing the covered modules.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/774-cli-paths-folder-resolve-coverage.t

Confirm the targeted lines are reported as covered.

=cut
