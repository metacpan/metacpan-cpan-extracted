#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;
use File::Temp qw(tempdir);
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec;

my $repo_root = abs_path( File::Spec->catdir( dirname(__FILE__), '..' ) );

my $tempdir = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $tempdir;
chdir $tempdir or die "Unable to chdir to $tempdir: $!";

require lib;
lib->import( File::Spec->catdir( $repo_root, 'lib' ) );
require Developer::Dashboard::TextUtils;
Developer::Dashboard::TextUtils->import('_trim');

# AC-1: the module exists and exports _trim.
ok( Developer::Dashboard::TextUtils->can('_trim'), 'AC-1: TextUtils defines _trim' );
ok( __PACKAGE__->can('_trim'), 'AC-1: _trim is importable via @EXPORT_OK' );

# AC-3 / ATDD: concrete sample data, matching the card's ATDD exactly.
is( _trim("  hello world  \n"), 'hello world', 'ATDD: leading/trailing whitespace and newline trimmed' );

# Behavior parity with the two private copies this replaces (both did the
# same undef-guard and \A\s+ / \s+\z substitutions).
is( _trim(undef), '', 'undef input normalizes to empty string' );
is( _trim(''), '', 'empty string input stays empty' );
is( _trim('no whitespace'), 'no whitespace', 'a string with no leading/trailing whitespace is unchanged' );
is( _trim("\t\tleading tabs"), 'leading tabs', 'leading tabs are trimmed' );
is( _trim("trailing spaces   "), 'trailing spaces', 'trailing spaces are trimmed' );
is( _trim('  internal   spacing  kept  '), 'internal   spacing  kept',
    'internal whitespace is preserved, only leading/trailing is stripped' );
is( _trim("\n\nmultiple\nblank\nlines\n\n"), "multiple\nblank\nlines",
    'multiple leading/trailing newlines are trimmed; internal newlines survive' );

done_testing;

__END__

=head1 NAME

t/188-textutils-coverage.t - unit test for Developer::Dashboard::TextUtils

=head1 PURPOSE

Proves DD-891's extraction: a single canonical C<_trim> now lives in
C<Developer::Dashboard::TextUtils>, matching the exact behavior of the two
byte-identical private copies it replaces in C<PageDocument.pm> and
C<Web::App.pm> (undef-guard to empty string, then C<s/\A\s+//> and
C<s/\s+\z//>).

=head1 WHY IT EXISTS

DD-891: C<PageDocument::_trim> and C<Web::App::_trim> were byte-for-byte
identical implementations maintained separately - the same "small helper
reimplemented per file" pattern this project already fixed once (DD-762,
C<DirEntries.pm>). This is the shared module's own focused unit test,
written RED before C<TextUtils.pm> existed.

=head1 WHEN TO USE

Run whenever C<TextUtils.pm> changes, or when a new caller adopts
C<_trim> and needs confidence its behavior is unchanged from the inline
copies it replaced.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/188-textutils-coverage.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Exercises C<Developer::Dashboard::TextUtils>
directly; C<t/59>-series coverage files for C<PageDocument.pm> and
C<Web/App.pm> exercise the same function indirectly through their own
call sites.

=head1 EXAMPLES

    perl -Ilib -MDeveloper::Dashboard::TextUtils=_trim -e 'print _trim("  hi  "), "\n"'

=cut
