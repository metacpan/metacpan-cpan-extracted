use strict;
use warnings;
use utf8;

use Encode qw(decode encode FB_CROAK);
use File::Spec;
use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;

local $ENV{HOME} = tempdir(CLEANUP => 1);
local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
local $ENV{DEVELOPER_DASHBOARD_CONFIGS};
local $ENV{DEVELOPER_DASHBOARD_CHECKERS};
chdir $ENV{HOME} or die "Unable to chdir to $ENV{HOME}: $!";

my $paths = Developer::Dashboard::PathRegistry->new;
my $store = Developer::Dashboard::PageStore->new(paths => $paths);

my $page = Developer::Dashboard::PageDocument->new(
    id          => 'example',
    title       => 'Example',
    description => 'Example page',
    layout      => { body => 'hello world' },
    state       => { project => 'demo' },
    actions     => [ { id => 'run', label => 'Run' } ],
);

my $file = $store->save_page($page);
ok(-f $file, 'saved page file created');

is_deeply([$store->list_saved_pages], ['example'], 'saved page is listed');

my $loaded = $store->load_saved_page('example');
is($loaded->as_hash->{title}, 'Example', 'saved page loads back');
is($loaded->{meta}{raw_instruction}, $page->canonical_instruction, 'saved page load keeps the raw saved instruction text');

my $token = $store->encode_page($page);
ok($token, 'page token generated');

my $decoded = $store->load_transient_page($token);
is($decoded->as_hash->{layout}{body}, 'hello world', 'transient page decodes');
like($decoded->canonical_instruction, qr/^TITLE:\s+Example/m, 'transient page round-trips canonical instruction');

my $legacy = <<'PAGE';
TITLE: Legacy Example
:--------------------------------------------------------------------------------:
STASH:
  name => 'Michael'
:--------------------------------------------------------------------------------:
HTML: Hello [% name %]
:--------------------------------------------------------------------------------:
code1: print "Legacy output";
PAGE

my $legacy_page = Developer::Dashboard::PageDocument->from_instruction($legacy);
is($legacy_page->as_hash->{title}, 'Legacy Example', 'legacy page syntax parses title');
is($legacy_page->as_hash->{state}{name}, 'Michael', 'legacy page syntax parses stash');
like($legacy_page->canonical_instruction, qr/^TITLE: Legacy Example/m, 'legacy page preserves legacy syntax on canonical output');
is(scalar(@{ $legacy_page->as_hash->{meta}{codes} || [] }), 1, 'legacy lowercase code sections are parsed');

my $legacy_with_markdown_tail = <<'PAGE';
TITLE: Legacy Separator
:--------------------------------------------------------------------------------:
HTML: <div>ok</div>
:--------------------------------------------------------------------------------:
CODE1: print 123;
---
This trailing prose should not be compiled as CODE1.
PAGE

my $markdown_sep_page = Developer::Dashboard::PageDocument->from_instruction($legacy_with_markdown_tail);
is(scalar(@{ $markdown_sep_page->as_hash->{meta}{codes} || [] }), 1, 'standalone markdown separators still terminate legacy sections');
is($markdown_sep_page->as_hash->{meta}{codes}[0]{body}, 'print 123;', 'markdown separator keeps trailing prose out of CODE bodies');

my $broken_file = File::Spec->catfile($paths->dashboards_root, 'broken-icons');
open my $broken_fh, '>:raw', $broken_file or die "Unable to write $broken_file: $!";
print {$broken_fh} "TITLE: Broken Icons\n";
print {$broken_fh} ":--------------------------------------------------------------------------------:\n";
print {$broken_fh} "BOOKMARK: broken-icons\n";
print {$broken_fh} ":--------------------------------------------------------------------------------:\n";
print {$broken_fh} "HTML: <h2>";
print {$broken_fh} pack( 'C*', 0xF0, 0x9F, 0x9A );
print {$broken_fh} " Learning</h2>\n<span class=\"icon\">";
print {$broken_fh} pack( 'C*', 0x95 );
print {$broken_fh} "</span>\n";
close $broken_fh or die "Unable to close $broken_file: $!";

my $broken_source = $store->read_saved_entry('broken-icons');
ok( eval { decode( 'UTF-8', encode( 'UTF-8', $broken_source ), FB_CROAK ); 1 }, 'read_saved_entry normalizes malformed legacy bookmark bytes to valid UTF-8' );
like( $broken_source, qr/◈ Learning/, 'read_saved_entry converts malformed legacy section icon bytes to a stable heading fallback glyph' );
like( $broken_source, qr/<span class="icon">🏷️<\/span>/, 'read_saved_entry converts malformed legacy item icon bytes to a stable icon fallback glyph' );
my $broken_page = $store->load_saved_page('broken-icons');
is( $broken_page->{meta}{raw_instruction}, $broken_source, 'load_saved_page keeps the normalized raw instruction text for later edit/source views' );
like( $broken_page->as_hash->{layout}{body}, qr/◈ Learning/, 'load_saved_page parses normalized malformed legacy heading glyphs into the page body' );

like($store->editable_url($page), qr{^\Q/?token=\E}, 'editable url generated');
like($store->render_url($page), qr{mode=render}, 'render url generated');
like($store->source_url($page), qr{mode=source}, 'source url generated');

done_testing;

__END__

=head1 NAME

01-page-flow.t - page persistence and transient token tests

=head1 DESCRIPTION

This test verifies saved page storage, transient page encoding, and canonical
page instruction behavior.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This test is the executable regression contract for saved pages, bookmark rendering, and page-routing behavior. Read it when you need to understand the real fixture setup, assertions, and failure modes for this slice of the repository instead of guessing from the module names alone.

=head1 WHY IT EXISTS

It exists because saved pages, bookmark rendering, and page-routing behavior has enough moving parts that a code-only review can miss real regressions. Keeping those expectations in a dedicated test file makes the TDD loop, coverage loop, and release gate concrete.

=head1 WHEN TO USE

Use this file when changing saved pages, bookmark rendering, and page-routing behavior, when a focused CI failure points here, or when you want a faster regression loop than running the entire suite.

=head1 HOW TO USE

Run it directly with C<prove -lv t/01-page-flow.t> while iterating, then keep it green under C<prove -lr t> and the coverage runs before release. 

=head1 WHAT USES IT

Developers during TDD, the full C<prove -lr t> suite, the coverage gates, and the release verification loop all rely on this file to keep this behavior from drifting.

=head1 EXAMPLES

Example 1:

  prove -lv t/01-page-flow.t

Run the focused regression test by itself while you are changing the behavior it owns.

Example 2:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lv t/01-page-flow.t

Exercise the same focused test while collecting coverage for the library code it reaches.

Example 3:

  prove -lr t

Put the focused fix back through the whole repository suite before calling the work finished.

=for comment FULL-POD-DOC END

=cut
