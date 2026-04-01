use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;

local $ENV{HOME} = tempdir(CLEANUP => 1);
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

=cut
