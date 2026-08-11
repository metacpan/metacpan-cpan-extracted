#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::ActionRunner;
use Developer::Dashboard::Config;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;

# Hermetic, isolated runtime rooted in a throwaway home. The config root is
# resolved from the deepest .developer-dashboard layer of the current working
# directory, so we must chdir into the temp home before building services.
my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
chdir $home or die "Unable to chdir to $home: $!";

my $paths   = Developer::Dashboard::PathRegistry->new( home => $home );
my $files   = Developer::Dashboard::FileRegistry->new( paths => $paths );
my $config  = Developer::Dashboard::Config->new( files => $files, paths => $paths );
my $pages   = Developer::Dashboard::PageStore->new( paths => $paths );
my $actions = Developer::Dashboard::ActionRunner->new( files => $files, paths => $paths );

# Inject config-backed providers that drive every provider-resolution edge:
#   * a non-HASH entry            -> list_pages and the resolver grep must skip
#                                    anything that is not a hash reference
#   * a hash with no id           -> list_pages and the grep must skip id-less
#                                    provider hashes
#   * a builtin-kind provider whose id is neither system-status nor
#     project-context             -> it must fall through both builtin elsif
#                                    arms into the generic else arm; it also
#                                    supplies description/actions/state but no
#                                    title or body so the generic page assembly
#                                    exercises the "present" side of some `||`
#                                    fallbacks and the "absent" side of others
#   * a plain titled provider     -> exercises the title/body "present" side of
#                                    the generic page assembly
$config->save_global(
    {
        providers => [
            'ghost-string-provider',
            { title => 'No Id Provider', body => 'no id body' },
            {
                id          => 'generic-builtin',
                kind        => 'builtin',
                description => 'Generic builtin description',
                actions     => [
                    { id => 'state', label => 'Show state', kind => 'builtin', builtin => 'page.state', safe => 1 },
                ],
                state => { seeded => 'yes' },
            },
            {
                id    => 'generic-titled',
                title => 'Generic Titled',
                body  => 'generic titled body',
            },
        ],
    }
);

my $resolver = Developer::Dashboard::PageResolver->new(
    actions => $actions,
    config  => $config,
    pages   => $pages,
    paths   => $paths,
);

# --- Constructor guards: each required service must be present. ---
{
    eval { Developer::Dashboard::PageResolver->new() };
    like( $@, qr/Missing config/, 'new dies when the config service is absent' );

    eval { Developer::Dashboard::PageResolver->new( config => 1 ) };
    like( $@, qr/Missing page store/, 'new dies when the page store is absent' );

    eval { Developer::Dashboard::PageResolver->new( config => 1, pages => 1 ) };
    like( $@, qr/Missing path registry/, 'new dies when the path registry is absent' );

    eval { Developer::Dashboard::PageResolver->new( config => 1, pages => 1, paths => 1 ) };
    like( $@, qr/Missing action runner/, 'new dies when the action runner is absent' );
}

# --- list_pages must skip non-HASH and id-less provider entries. ---
{
    my %seen = map { $_ => 1 } $resolver->list_pages;
    ok( $seen{'system-status'},   'list_pages surfaces the builtin system-status provider' );
    ok( $seen{'generic-builtin'}, 'list_pages surfaces an id-bearing config provider' );
    ok( $seen{'generic-titled'},  'list_pages surfaces the titled config provider' );
    ok( !$seen{'ghost-string-provider'}, 'list_pages skips the non-hash provider entry' );
    ok( !$seen{'No Id Provider'},        'list_pages skips the id-less provider hash' );
}

# --- load_named_page must reject an undefined or empty id. ---
{
    eval { $resolver->load_named_page(undef) };
    like( $@, qr/Missing page id/, 'load_named_page dies on an undefined id' );

    eval { $resolver->load_named_page('') };
    like( $@, qr/Missing page id/, 'load_named_page dies on an empty-string id' );
}

# --- An unknown provider id must die, after the grep has scanned every
#     provider (including the non-hash and id-less entries). ---
{
    eval { $resolver->load_provider_page('does-not-exist-anywhere') };
    like(
        $@,
        qr/Page 'does-not-exist-anywhere' not found/,
        'load_provider_page dies for an id that matches no provider'
    );
}

# --- A builtin-kind provider whose id is neither system-status nor
#     project-context falls through to the generic else arm. ---
{
    my $page = $resolver->load_provider_page('generic-builtin');
    my $hash = $page->as_hash;
    is( $hash->{title}, 'generic-builtin', 'generic page title falls back to the provider id when no title is given' );
    is( $hash->{description}, 'Generic builtin description', 'generic page keeps the provider description when present' );
    is( $hash->{layout}{body}, '', 'generic page body falls back to an empty string when no body is given' );
    is_deeply( $hash->{state}, { seeded => 'yes' }, 'generic page keeps the provider state when present' );
    is( scalar @{ $hash->{actions} }, 1, 'generic page keeps the provider actions when present' );
    is( $hash->{meta}{source_kind}, 'provider', 'generic provider page is tagged as provider-sourced' );
}

# --- A titled provider exercises the title/body "present" side. ---
{
    my $hash = $resolver->load_provider_page('generic-titled')->as_hash;
    is( $hash->{title}, 'Generic Titled', 'generic page keeps the provider title when present' );
    is( $hash->{layout}{body}, 'generic titled body', 'generic page keeps the provider body when present' );
}

# --- project-context must reflect a resolved (truthy) git project root. ---
{
    my $projdir = File::Spec->catdir( $home, 'gitproj' );
    make_path( File::Spec->catdir( $projdir, '.git' ) );

    my $paths_git   = Developer::Dashboard::PathRegistry->new( home => $home, cwd => $projdir );
    my $files_git   = Developer::Dashboard::FileRegistry->new( paths => $paths_git );
    my $config_git  = Developer::Dashboard::Config->new( files => $files_git, paths => $paths_git );
    my $pages_git   = Developer::Dashboard::PageStore->new( paths => $paths_git );
    my $actions_git = Developer::Dashboard::ActionRunner->new( files => $files_git, paths => $paths_git );
    my $resolver_git = Developer::Dashboard::PageResolver->new(
        actions => $actions_git,
        config  => $config_git,
        pages   => $pages_git,
        paths   => $paths_git,
    );

    my $hash = $resolver_git->load_provider_page('project-context')->as_hash;
    is( $hash->{state}{current_project_root}, $projdir, 'project-context reports the resolved git project root' );
    like( $hash->{layout}{body}, qr/\Q$projdir\E/, 'project-context body embeds the resolved project root' );
}

done_testing;

__END__

=head1 NAME

t/66-pageresolver-coverage.t - branch and condition coverage closure for the page resolver

=head1 PURPOSE

This test drives every decision arm of the page source resolver so that its
saved-versus-provider routing, its provider registry scan, and its generated
provider-page assembly are all exercised. It exists to hold the resolver at full
branch and condition coverage, including the guard clauses that reject missing
constructor services and malformed page identifiers.

=head1 WHY IT EXISTS

The resolver mixes several page sources behind one interface: builtin generated
pages, config-backed provider hashes, and saved bookmarks. Several of its arms
are only reachable with deliberately shaped inputs - a provider list that
contains a non-hash entry or an id-less hash, a builtin-kind provider whose id
matches neither builtin, a request with an undefined or empty id, and a project
context resolved against a real git root. Without this test those arms silently
rot and the coverage gate cannot certify the module.

=head1 WHEN TO USE

Use this file when changing how the resolver enumerates providers, how it maps a
requested id onto a saved page or a provider definition, or how it assembles a
generated page from a provider hash. Extend it whenever a new provider kind or a
new fallback default is introduced.

=head1 HOW TO USE

Run C<prove -lv t/66-pageresolver-coverage.t> while iterating on the resolver,
and keep it green under C<prove -lr t> before release. The test builds a fully
isolated runtime under a temporary home so it never touches a developer's real
dashboard state.

=head1 WHAT USES IT

The repository test suite and the Devel::Cover branch and condition gate use
this file to keep the page resolver fully exercised. Developers practising the
test-first workflow use it as the executable specification for provider
resolution edge cases.

=head1 EXAMPLES

Example 1:

  prove -lv t/66-pageresolver-coverage.t

Run the page-resolver coverage closure test on its own.

Example 2:

  prove -lr t

Run it inside the full repository suite before release.

=cut
