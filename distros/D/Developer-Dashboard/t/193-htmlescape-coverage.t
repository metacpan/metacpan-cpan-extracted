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
require Developer::Dashboard::HtmlEscape;
Developer::Dashboard::HtmlEscape->import(qw(_escape_html _escape_html_attr));

# AC-1: the module exists and exports both functions.
ok( Developer::Dashboard::HtmlEscape->can('_escape_html'), 'AC-1: HtmlEscape defines _escape_html' );
ok( Developer::Dashboard::HtmlEscape->can('_escape_html_attr'), 'AC-1: HtmlEscape defines _escape_html_attr' );
ok( __PACKAGE__->can('_escape_html'), 'AC-1: _escape_html is importable via @EXPORT_OK' );
ok( __PACKAGE__->can('_escape_html_attr'), 'AC-1: _escape_html_attr is importable via @EXPORT_OK' );

# ATDD: concrete sample data, matching the card's ATDD exactly.
is( _escape_html('<x>'), '&lt;x&gt;', 'ATDD: _escape_html escapes angle brackets' );
is( _escape_html_attr('"quoted"'), '&quot;quoted&quot;', 'ATDD: _escape_html_attr escapes double quotes' );

# Behavior parity with the two private copies this replaces.
is( _escape_html(undef), '', 'undef input normalizes to empty string' );
is( _escape_html(''), '', 'empty string input stays empty' );
is( _escape_html('&'), '&amp;', 'ampersand escaped' );
is( _escape_html('no markup'), 'no markup', 'plain text unchanged' );
is( _escape_html_attr(undef), '', '_escape_html_attr treats undef as empty string, delegating to _escape_html' );
is( _escape_html_attr(q{it's "quoted"}), 'it&#39;s &quot;quoted&quot;', 'both quote types escaped' );
is( _escape_html_attr('<script>'), '&lt;script&gt;', '_escape_html_attr also applies base HTML escaping' );

done_testing;

__END__

=head1 NAME

t/193-htmlescape-coverage.t - unit test for Developer::Dashboard::HtmlEscape

=head1 PURPOSE

Proves DD-898's extraction: a single canonical C<_escape_html>/
C<_escape_html_attr> pair now lives in C<Developer::Dashboard::HtmlEscape>,
matching the exact behavior of the two byte-identical private copies it
replaces in C<Web::App> and C<Zipper>.

=head1 WHY IT EXISTS

DD-898: C<Web::App::_escape_html>/C<_escape_html_attr> and
C<Zipper::_escape_html>/C<_escape_html_attr> were byte-for-byte identical -
the same "small helper reimplemented per file" pattern already fixed
several times on this board (DD-762, DD-785, DD-888, DD-891, DD-894), here
notable for having been created deliberately by DD-892 mirroring rather
than sharing. This is the shared module's own focused unit test, written
RED before C<HtmlEscape.pm> existed.

=head1 WHEN TO USE

Run whenever C<HtmlEscape.pm> changes, or when a new caller adopts these
functions and needs confidence its behavior is unchanged from the inline
copies it replaced.

=head1 HOW TO USE

    PERL5LIB="$HOME/perl5/lib/perl5" prove -lv t/193-htmlescape-coverage.t

=head1 WHAT USES IT

The suite, via C<prove -lr t>. Exercises
C<Developer::Dashboard::HtmlEscape> directly; C<Web::App>'s and
C<Zipper>'s own coverage tests exercise the same functions indirectly
through their call sites.

=head1 EXAMPLES

    perl -Ilib -MDeveloper::Dashboard::HtmlEscape=_escape_html \
      -e 'print _escape_html("<hi>"), "\n"'

=cut
