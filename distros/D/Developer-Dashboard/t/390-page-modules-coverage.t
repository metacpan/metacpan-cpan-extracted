#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Fcntl qw(O_RDONLY);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

use lib 'lib';

use Developer::Dashboard::PageDocument;
use Developer::Dashboard::PageResolver;
use Developer::Dashboard::PageRuntime;
use Developer::Dashboard::PageStore;
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::Prompt;

my $home = tempdir( CLEANUP => 1 );
local $ENV{HOME} = $home;
delete local $ENV{DEVELOPER_DASHBOARD_BOOKMARKS};
delete local $ENV{DEVELOPER_DASHBOARD_STATE_ROOT};
chdir $home or die "chdir $home: $!";

# PageDocument: an empty HEAD string is omitted from the legacy instruction.
{
    my $doc = Developer::Dashboard::PageDocument->from_hash( { id => 'h', title => 'T', meta => { head => '' } } );
    unlike( $doc->legacy_instruction, qr/^HEAD:/m, 'empty head metadata emits no HEAD section' );
}

# PageResolver: only an exact not-found falls through to providers.
{
    my $pages = bless {}, 'Local::DyingPages';
    {
        package Local::DyingPages;
        sub load_saved_page { die "parse exploded\n" }
    }
    my $resolver = Developer::Dashboard::PageResolver->new(
        config => {}, pages => $pages, paths => {}, actions => {},
    );
    my $report = [];
    eval { $resolver->load_named_page( 'boom', $report ) };
    like( $@, qr/parse exploded/, 'non-not-found saved page errors surface unchanged' );
    eval { $resolver->load_named_page('boom') };
    like( $@, qr/parse exploded/, 'same without a report' );
}

# PageRuntime: include roots.
{
    package Local::OddPaths;
    sub new { bless { d => $_[1], r => $_[2] }, $_[0] }
    sub dashboards_roots { @{ $_[0]{d} } }
    sub runtime_roots { @{ $_[0]{r} } }
}
{
    my $paths = Local::OddPaths->new( [ undef, '', 'a', 'a' ], ['a', 'b'] );
    my $rt = Developer::Dashboard::PageRuntime->new( paths => $paths );
    is_deeply( [ $rt->_template_include_roots(undef) ], [ 'a', 'b' ], 'undef page, blank and duplicate roots are dropped' );
    my $page = { meta => { skill_path => '' } };
    is_deeply( [ $rt->_template_include_roots($page) ], [ 'a', 'b' ], 'empty skill_path adds no root' );
    is_deeply( [ $rt->_template_include_roots( { meta => 'x' } ) ], [ 'a', 'b' ], 'non-hash meta tolerated' );
    my $none = Developer::Dashboard::PageRuntime->new( paths => Local::OddPaths->new( [], [] ) );
    is_deeply( [ $none->_template_include_roots(undef) ], ['.'], 'no roots falls back to dot' );
}

# PageRuntime: a request-scoped TT service is reused only for unchanged roots.
{
    my $include_root = File::Spec->catdir( $home, 'template-root-a' );
    my $other_root   = File::Spec->catdir( $home, 'template-root-b' );
    make_path($include_root, $other_root);
    my $paths = Local::OddPaths->new( [$include_root], [] );
    my $rt = Developer::Dashboard::PageRuntime->new( paths => $paths );
    my $template_new_calls = 0;
    my $original_template_new = Template->can('new');
    {
        no warnings qw(redefine once);
        local *Template::new = sub {
            $template_new_calls++;
            return $original_template_new->(@_);
        };
        my $include_file = File::Spec->catfile( $include_root, 'live.tt' );
        open my $include_fh, '>:encoding(UTF-8)', $include_file or die "open $include_file: $!";
        print {$include_fh} 'live include';
        close $include_fh or die "close $include_file: $!";
        local $rt->{_template_processor_scope} = {};
        for my $title (qw(first second)) {
            my $page = Developer::Dashboard::PageDocument->from_hash(
                { id => $title, title => $title, layout => { body => '[% title %]' } }
            );
            $rt->_render_templates( page => $page, runtime_context => {} );
            is( $page->{layout}{body}, $title, "cached TT service renders the current '$title' stash" );
        }
        is( $template_new_calls, 1, 'same include roots reuse one Template Toolkit service within a request' );

        # Scalar templates bypass TT's file-provider cache. Keep the parse tree
        # only in this request scope while constructing a fresh document for
        # each render; the stash and include provider remain request-local.
        my $body_source = '[% META marker = "yes" %][% template.name %]|[% template.modtime %]|[% template.marker %]|[% title %]|[% INCLUDE live.tt %]';
        my $parse_calls = 0;
        my $document_compile_calls = 0;
        my $original_parse = Template::Parser->can('parse');
        my $original_document_new = Template::Document->can('new');
        {
            no warnings qw(redefine once);
            local *Template::Parser::parse = sub {
                my ( $parser_object, $source, @rest ) = @_;
                $parse_calls++ if defined $source && $source eq $body_source;
                return $original_parse->(@_);
            };
            local *Template::Document::new = sub {
                my ( $class, $document ) = @_;
                $document_compile_calls++
                  if ref($document) eq 'HASH'
                  && ref( $document->{METADATA} ) eq 'HASH'
                  && ( $document->{METADATA}{name} || '' ) eq 'input text'
                  && !ref( $document->{BLOCK} );
                return $original_document_new->(@_);
            };
            for my $title (qw(parse-first parse-second)) {
                my $parsed_page = Developer::Dashboard::PageDocument->from_hash(
                    { id => $title, title => $title, layout => { body => $body_source } }
                );
                $rt->_render_templates( page => $parsed_page, runtime_context => {} );
                like( $parsed_page->{layout}{body}, qr/^input text\|\d+\|yes\|\Q$title\E\|live include$/,
                    "cached scalar parse preserves TT metadata, current stash, and live include for $title" );
            }
            is( $parse_calls, 1, 'identical scalar template source is parsed once per request scope' );

            my $different_source = '[% title %]|changed';
            my $different_page = Developer::Dashboard::PageDocument->from_hash(
                { id => 'different', title => 'different', layout => { body => $different_source } }
            );
            $rt->_render_templates( page => $different_page, runtime_context => {} );
            is( $different_page->{layout}{body}, 'different|changed',
                'a distinct source gets its own compiled document' );
            {
                local $rt->{_template_processor_scope} = {};
                my $next_request_page = Developer::Dashboard::PageDocument->from_hash(
                    { id => 'new-scope', title => 'new-scope', layout => { body => $body_source } }
                );
                $rt->_render_templates( page => $next_request_page, runtime_context => {} );
                like( $next_request_page->{layout}{body}, qr/^input text\|\d+\|yes\|new-scope\|live include$/,
                    'the next request reuses parsed syntax while refreshing document metadata, stash, and include lookup' );
            }
            is( $parse_calls, 1, 'identical scalar source parses once across request scopes' );
            is( $document_compile_calls, 2,
                'each distinct scalar template compiles its Perl block only once across renders and request scopes' );
        }
        is( $parse_calls, 1, 'compiled cache distinguishes scalar source while retaining the worker-local template' );

        my $included = Developer::Dashboard::PageDocument->from_hash(
            { id => 'include', title => 'include', layout => { body => '[% INCLUDE live.tt %]' } }
        );
        $rt->_render_templates( page => $included, runtime_context => {} );
        is( $included->{layout}{body}, 'live include', 'request-scoped service resolves include files' );
        is( $template_new_calls, 2, 'include rendering reuses the unchanged-root service within the request' );

        $paths->{d} = [$other_root];
        my $changed_roots = Developer::Dashboard::PageDocument->from_hash(
            { id => 'changed', title => 'changed', layout => { body => '[% title %]' } }
        );
        $rt->_render_templates( page => $changed_roots, runtime_context => {} );
        is( $changed_roots->{layout}{body}, 'changed', 'changed roots keep template rendering correct' );
        is( $template_new_calls, 3, 'changed include roots construct a separately configured service' );

        open $include_fh, '>:encoding(UTF-8)', $include_file or die "open $include_file: $!";
        print {$include_fh} 'updated include';
        close $include_fh or die "close $include_file: $!";
        $paths->{d} = [$include_root];
        {
            local $rt->{_template_processor_scope} = {};
            my $updated_include = Developer::Dashboard::PageDocument->from_hash(
                { id => 'updated-include', title => 'updated', layout => { body => '[% INCLUDE live.tt %]' } }
            );
            $rt->_render_templates( page => $updated_include, runtime_context => {} );
            is( $updated_include->{layout}{body}, 'updated include', 'next request scope observes an include edit immediately' );
            is( $template_new_calls, 4, 'a later request creates a fresh template service' );
        }

        my $block_source = '[% BLOCK greeting %]Hello [% title %][% END %][% PROCESS greeting %]';
        for my $title (qw(Perl Python)) {
            local $rt->{_template_processor_scope} = {};
            my $block_page = Developer::Dashboard::PageDocument->from_hash(
                { id => "block-$title", title => $title, layout => { body => $block_source } }
            );
            $rt->_render_templates( page => $block_page, runtime_context => {} );
            is( $block_page->{layout}{body}, "Hello $title",
                "cached named BLOCK document uses the current '$title' stash" );
        }
    }
}

# PageRuntime: scalar-document cache boundaries and normal-path fallbacks.
{
    my $rt = Developer::Dashboard::PageRuntime->new;
    my $source = '[% title %]';
    ok( !defined $rt->_template_document_for_source( undef, ['.'], $source ),
        'direct rendering without a request scope skips the parse cache' );
    {
        local $rt->{_template_processor_scope} = {};
        ok( !defined $rt->_template_document_for_source( undef, ['.'], \$source ),
            'reference-valued template input skips the scalar parse cache' );
        ok( $rt->_template_document_for_source( undef, '.', $source ),
            'invalid include-root input uses the safe default cache key' );
        ok( $rt->_template_document_for_source( undef, [ undef, \ $source ], $source ),
            'undefined and reference include roots stay out of the parse-cache key' );
        my $oversized = ( 'x' x 262_145 ) . '[% title %]';
        ok( !defined $rt->_template_document_for_source( undef, ['.'], $oversized ),
            'oversized scalar source bypasses parse-cache allocation' );
        my $oversized_unicode = ( "\x{1f642}" x 65_537 ) . '[% title %]';
        ok( !defined $rt->_template_document_for_source( undef, ['.'], $oversized_unicode ),
            'cache source bound counts UTF-8 bytes rather than characters' );
        ok( !defined $rt->_template_document_for_source( undef, [ 'r' x 262_145 ], $source ),
            'oversized include-root keys bypass worker cache allocation' );
    }

    {
        my $parser_failure_rt = Developer::Dashboard::PageRuntime->new;
        local $parser_failure_rt->{_template_processor_scope} = {};
        no warnings qw(redefine once);
        local *Template::Config::parser = sub { return };
        ok( !defined $parser_failure_rt->_template_document_for_source( undef, ['.'], '[% parser-failure %]' ),
            'parser initialization failure leaves the existing TT path available' );
    }
    {
        my $parse_failure_rt = Developer::Dashboard::PageRuntime->new;
        local $parse_failure_rt->{_template_processor_scope} = {};
        no warnings qw(redefine once);
        local *Template::Config::parser = sub { return bless {}, 'Local::Problem48Parser' };
        local *Local::Problem48Parser::parse = sub { return };
        ok( !defined $parse_failure_rt->_template_document_for_source( undef, ['.'], '[% parse-failure %]' ),
            'parse failure leaves the existing TT error path available' );
    }
    {
        my $document_failure_rt = Developer::Dashboard::PageRuntime->new;
        local $document_failure_rt->{_template_processor_scope} = {};
        no warnings qw(redefine once);
        local *Template::Document::new = sub { return };
        ok( !defined $document_failure_rt->_template_document_for_source( undef, ['.'], '[% document-failure %]' ),
            'document construction failure leaves the existing TT path available' );
    }
    {
        my $metadata_rt = Developer::Dashboard::PageRuntime->new;
        local $metadata_rt->{_template_processor_scope} = {};
        my $original_parse = Template::Parser->can('parse');
        no warnings qw(redefine once);
        local *Template::Parser::parse = sub {
            my $parsed = $original_parse->(@_);
            delete $parsed->{DEFBLOCKS};
            delete $parsed->{METADATA};
            return $parsed;
        };
        my $document = $metadata_rt->_template_document_for_source(
            undef, ['.'], '[% title %]'
        );
        ok( $document, 'parsed trees without optional blocks or metadata still create documents' );
        my $tt = Template->new( { EVAL_PERL => 1, INCLUDE_PATH => ['.'] } );
        my $rendered = '';
        ok( $tt->process( $document, { title => 'default metadata' }, \$rendered ),
            'fresh document with default metadata renders successfully' );
        is( $rendered, 'default metadata', 'default metadata document preserves output' );
    }
    {
        local $rt->{_template_processor_scope} = {};
        my $invalid_page = Developer::Dashboard::PageDocument->from_hash(
            { id => 'invalid-template', title => 'invalid', layout => { body => '[% IF %]' } }
        );
        $rt->_render_templates( page => $invalid_page, runtime_context => {} );
        is( $invalid_page->{layout}{body}, '',
            'a TT parse failure preserves the established empty rendered body' );
        like( $invalid_page->{meta}{runtime_errors}[0] || '', qr/(?:parse|syntax|error)/i,
            'a TT parse failure remains visible in runtime errors' );
    }
    {
        my $aggregate_rt = Developer::Dashboard::PageRuntime->new;
        local $aggregate_rt->{_template_processor_scope} = {};
        $aggregate_rt->{_template_parsed_tree_cache} = {
            sources => {
                '1:.' => {
                    '[% title %]' => {
                        tree  => {},
                        bytes => 1_048_576,
                        used  => 1,
                    },
                },
            },
            entries => 1,
            bytes   => 1_048_576,
            clock   => 1,
        };
        my $next_document = $aggregate_rt->_template_document_for_source( undef, ['.'], $source . '|new' );
        ok( $next_document, 'aggregate byte pressure evicts an old tree and admits the new source' );
        is( $aggregate_rt->{_template_parsed_tree_cache}{entries}, 1,
            'aggregate-pressure eviction replaces the displaced cache entry' );
        cmp_ok( $aggregate_rt->{_template_parsed_tree_cache}{bytes}, '<=', 1_048_576,
            'worker parse-tree cache stays within its aggregate byte bound' );
    }
    {
        my $limit_rt = Developer::Dashboard::PageRuntime->new;
        local $limit_rt->{_template_processor_scope} = {};
        my $parse_calls = 0;
        my $original_parse = Template::Parser->can('parse');
        no warnings qw(redefine once);
        local *Template::Parser::parse = sub {
            $parse_calls++;
            return $original_parse->(@_);
        };
        for my $number ( 1 .. 16 ) {
            my $document = $limit_rt->_template_document_for_source(
                undef, ['.'], "[% title %]$number"
            );
            ok( $document, "worker cache accepts template source $number" );
        }
        $limit_rt->_template_document_for_source( undef, ['.'], '[% title %]1' );
        ok( $limit_rt->_template_document_for_source( undef, ['.'], '[% title %]17' ),
            'worker cache admits a new source by evicting the least-recently-used tree' );
        is( $limit_rt->{_template_parsed_tree_cache}{entries}, 16,
            'worker parse-tree cache stays within its source-entry bound' );
        my $calls_before_hits = $parse_calls;
        $limit_rt->_template_document_for_source( undef, ['.'], '[% title %]1' );
        is( $parse_calls, $calls_before_hits, 'recently used source remains cached after eviction' );
        $limit_rt->_template_document_for_source( undef, ['.'], '[% title %]2' );
        is( $parse_calls, $calls_before_hits + 1, 'least-recently-used source is reparsed after eviction' );
    }
    {
        my $untracked_rt = Developer::Dashboard::PageRuntime->new;
        local $untracked_rt->{_template_processor_scope} = {};
        $untracked_rt->{_template_parsed_tree_cache} = {
            sources => { '1:.' => {} },
            entries => 16,
            bytes   => 0,
            clock   => 0,
        };
        my $uncached = $untracked_rt->_template_document_for_source( undef, ['.'], '[% title %]' );
        ok( $uncached, 'cache bookkeeping without any indexed entry still returns a usable document' );
        is( $untracked_rt->{_template_parsed_tree_cache}{entries}, 16,
            'inconsistent cache bookkeeping is not decremented without an evictable entry' );
        ok( !exists $untracked_rt->{_template_parsed_tree_cache}{sources}{'1:.'}{'[% title %]'},
            'a document is rendered but not retained when no cache entry can be evicted' );
    }
    {
        my $invalid_entry_rt = Developer::Dashboard::PageRuntime->new;
        local $invalid_entry_rt->{_template_processor_scope} = {};
        my $cached = $invalid_entry_rt->_template_document_for_source( undef, ['.'], '[% title %]' );
        ok( $cached, 'a valid compiled source seeds a worker cache entry' );
        $invalid_entry_rt->{_template_parsed_tree_cache}{sources}{'1:.'}{'[% title %]'}{compiled}{block} = 'not a code reference';
        ok( !defined $invalid_entry_rt->_template_document_for_source( undef, ['.'], '[% title %]' ),
            'a malformed cached compiled block is rejected for normal template fallback' );
        $invalid_entry_rt->{_template_parsed_tree_cache}{sources}{'1:.'}{'[% title %]'}{compiled} = 'not a compiled record';
        ok( !defined $invalid_entry_rt->_template_document_for_source( undef, ['.'], '[% title %]' ),
            'a non-hash cached compiler record is rejected before its block is read' );
    }
    {
        my $optional_fields_rt = Developer::Dashboard::PageRuntime->new;
        local $optional_fields_rt->{_template_processor_scope} = {};
        my $cached = $optional_fields_rt->_template_document_for_source( undef, ['.'], '[% title %]' );
        ok( $cached, 'a valid compiled source seeds optional-field fallback coverage' );
        my $compiled = $optional_fields_rt->{_template_parsed_tree_cache}{sources}{'1:.'}{'[% title %]'}{compiled};
        $compiled->{blocks}   = undef;
        $compiled->{metadata} = undef;
        ok( $optional_fields_rt->_template_document_for_source( undef, ['.'], '[% title %]' ),
            'missing cached blocks and metadata use safe empty defaults' );
    }
    {
        my $final_document_failure_rt = Developer::Dashboard::PageRuntime->new;
        local $final_document_failure_rt->{_template_processor_scope} = {};
        my $original_new = Template::Document->can('new');
        my $calls = 0;
        no warnings qw(redefine once);
        local *Template::Document::new = sub {
            $calls++;
            return if $calls == 2;
            return $original_new->(@_);
        };
        ok( !defined $final_document_failure_rt->_template_document_for_source( undef, ['.'], '[% title %]' ),
            'failure to build the fresh per-render document uses normal template fallback' );
        is( $calls, 2, 'cache compilation succeeds before fresh document construction fails' );
    }
}

{
    my $rt = Developer::Dashboard::PageRuntime->new;
    my $static_body = '<section data-label="static">100% '
      . chr(0x1f642) . ' no Template Toolkit tags</section>';
    my $page = Developer::Dashboard::PageDocument->new(
        layout => { body => $static_body },
        state  => {},
        meta   => {},
    );
    my $setup_calls = 0;
    {
        no warnings qw(redefine once);
        my $system_context = Developer::Dashboard::PageRuntime->can('_system_context');
        my $include_roots = Developer::Dashboard::PageRuntime->can('_template_include_roots');
        my $processor = Developer::Dashboard::PageRuntime->can('_template_processor_for_roots');
        local *Developer::Dashboard::PageRuntime::_system_context = sub {
            $setup_calls++;
            return $system_context->(@_);
        };
        local *Developer::Dashboard::PageRuntime::_template_include_roots = sub {
            $setup_calls++;
            return $include_roots->(@_);
        };
        local *Developer::Dashboard::PageRuntime::_template_processor_for_roots = sub {
            $setup_calls++;
            return $processor->(@_);
        };
        $rt->_render_templates( page => $page, runtime_context => {} );
    }
    is( $page->{layout}{body}, $static_body,
        'a static UTF-8 HTML body remains unchanged' );
    is( $setup_calls, 0,
        'a static body bypasses system context, include-root discovery, and Template Toolkit setup' );
}

{
    package Local::FailingTemplate;
    # process($self, $template, $variables, $output)
    # Records invocation and reports a deterministic failed template render.
    # Input: Template Toolkit process arguments.
    # Output: false, matching a service processing failure.
    sub process { $_[0]{calls}++; return 0 }

    # error($self)
    # Returns the visible error text for the fixture's failed render.
    # Input: the fixture service object.
    # Output: stable error string.
    sub error   { return 'reference body rejected by template service' }
}

{
    my $runtime = Developer::Dashboard::PageRuntime->new;
    my $tt = bless { calls => 0 }, 'Local::FailingTemplate';
    my $page = Developer::Dashboard::PageDocument->new(
        layout => { body => [] },
        state  => {},
        meta   => {},
    );
    {
        no warnings qw(redefine once);
        local *Developer::Dashboard::PageRuntime::_template_processor_for_roots = sub { return $tt };
        $runtime->_render_templates( page => $page, runtime_context => {} );
    }
    is( $tt->{calls}, 1,
        'a reference-valued body remains on the original Template Toolkit error path' );
    is( $page->{layout}{body}, '',
        'a template service failure keeps the existing empty-body behavior' );
    like( $page->{meta}{runtime_errors}[0], qr/reference body rejected/,
        'the reference-body rendering error remains visible on the page' );
}

{
    my $root = File::Spec->catdir( $home, 'template-fallback-root' );
    make_path($root);
    my $rt = Developer::Dashboard::PageRuntime->new;
    my $original_template_new = Template->can('new');
    my $template_new_calls = 0;
    {
        no warnings qw(redefine once);
        local *Template::new = sub {
            $template_new_calls++;
            return if $template_new_calls == 1;
            return $original_template_new->(@_);
        };
        ok( $rt->_template_processor_for_roots( [$root] ), 'TT service falls back to existing include roots after initialization failure' );
        is( $template_new_calls, 2, 'fallback tries the remaining existing include roots once' );
    }
    my $fallback_runtime = Developer::Dashboard::PageRuntime->new;
    my $missing_root = File::Spec->catdir( $home, 'template-root-not-created' );
    my $missing_root_calls = 0;
    {
        no warnings qw(redefine once);
        local *Template::new = sub {
            $missing_root_calls++;
            return if $missing_root_calls == 1;
            return $original_template_new->(@_);
        };
        ok( $fallback_runtime->_template_processor_for_roots( [$missing_root] ), 'TT service falls back to dot when every requested root is absent' );
        is( $missing_root_calls, 2, 'missing roots skip the existing-root attempt and build the dot fallback' );
    }
    ok( $rt->_template_processor_for_roots('not-an-array'), 'non-array root input safely uses the dot fallback' );

    my $captured_roots;
    {
        no warnings qw(redefine once);
        local *Template::new = sub {
            $captured_roots = $_[1]{INCLUDE_PATH};
            return bless {}, $_[0];
        };
        ok( $rt->_template_processor_for_roots( [ undef, $root ] ), 'TT service accepts a root list containing an undefined entry' );
        is_deeply( $captured_roots, [$root], 'undefined include roots are discarded before reaching Template Toolkit' );
        ok( $rt->_template_processor_for_roots( [ {}, $root ] ), 'TT service accepts a root list containing a reference-valued entry' );
        is_deeply( $captured_roots, [$root], 'reference-valued include roots are discarded before reaching Template Toolkit' );
        ok( $rt->_template_processor_for_roots( [undef] ), 'TT service handles a list containing no valid roots' );
        is_deeply( $captured_roots, ['.'], 'an empty sanitized include-root list falls back to the current directory' );
    }

    my $failed_runtime = Developer::Dashboard::PageRuntime->new;
    my $failure_calls = 0;
    {
        no warnings qw(redefine once);
        local *Template::new = sub { $failure_calls++; return };
        is( $failed_runtime->_template_processor_for_roots( [$root] ), undef, 'TT service failure is returned when all initialization attempts fail' );
        is( $failure_calls, 3, 'all configured, existing-root, and dot fallback attempts are made' );
    }
}

# PageRuntime: code inc roots and env overlay.
{
    my $rt = Developer::Dashboard::PageRuntime->new();
    my $skill = File::Spec->catdir( $home, 'skill-a' );
    my $layer = File::Spec->catdir( $home, 'layer-b' );
    my $bare  = File::Spec->catdir( $home, 'layer-c' );
    make_path( File::Spec->catdir( $skill, 'lib' ), File::Spec->catdir( $layer, 'lib' ), $bare );
    is_deeply(
        [ $rt->_code_inc_roots( { meta => { skill_path => $skill, skill_layers => [ $bare, $layer, $skill ] } } ) ],
        [ File::Spec->catdir( $skill, 'lib' ), File::Spec->catdir( $layer, 'lib' ) ],
        'page lib first, then layer libs, skipping missing and duplicate ones',
    );
    is_deeply( [ $rt->_code_inc_roots( { meta => { skill_path => '' } } ) ], [], 'empty skill_path yields no roots' );
    is_deeply( $rt->_code_env_overlay( { meta => { skill_path => '' } } ), {}, 'empty skill_path yields no env overlay' );
    {
        no warnings 'redefine';
        local *Developer::Dashboard::EnvLoader::load_skill_layers_into_hash = sub { return {} };
        is_deeply( $rt->_skill_env_overlay( [$skill] ), {}, 'loader without env key yields empty overlay' );
    }
}

# PageStore.
{
    my $paths = Developer::Dashboard::PathRegistry->new( home => $home );
    my $store = Developer::Dashboard::PageStore->new( paths => $paths );
    my $root  = $paths->dashboards_root;

    my $gone = Developer::Dashboard::PageStore->new( paths => Local::OddStorePaths->new( File::Spec->catdir( $home, 'nope' ) ) );
    is_deeply( $gone->migrate_legacy_json_pages, [], 'missing dashboards root migrates nothing' );

    open my $fh, '>', File::Spec->catfile( $root, 'legacy.json' ) or die $!;
    print {$fh} '{"id":"legacy","title":"L"}';
    close $fh;
    {
        no warnings 'redefine';
        local *Developer::Dashboard::PageStore::_open_saved_page_for_read = sub { die "unreadable\n" };
        is_deeply( $store->migrate_legacy_json_pages, [], 'unreadable legacy json is skipped' );
    }
    ok( -f File::Spec->catfile( $root, 'legacy.json' ), 'skipped file remains' );

    eval { $store->_open_saved_page_at( root => $root, id => 'missing-page', flags => O_RDONLY ) };
    like( $@, qr/Invalid page path/, 'reading a missing page file fails' );
}

{
    package Local::OddStorePaths;
    sub new { bless { r => $_[1] }, $_[0] }
    sub dashboards_root { $_[0]{r} }
    sub dashboards_roots { $_[0]{r} }
}

done_testing;

__END__

=pod

=head1 NAME

t/390-page-modules-coverage.t - closes the remaining coverage gaps in the page modules

=head1 PURPOSE

Exercises the last uncovered branches and conditions of PageDocument (empty HEAD
metadata), PageResolver (non-not-found saved-page failures surface), PageRuntime
(template service fallback, static-body TT bypass with exact Unicode parity,
worker-local parsed and compiled template reuse, invalid include roots, code inc roots and skill
env overlays with empty, duplicate and missing inputs)
and PageStore (missing dashboards root, unreadable legacy files, missing page
file). PageRuntime coverage also exercises bounded-cache bookkeeping without
evictable entries, malformed cached compiler values, missing optional fields,
and failure while constructing the fresh per-render document.

=head1 WHY IT EXISTS

These guard clauses are unreachable through ordinary save and render flows, so
this file reaches them directly to keep the modules at full coverage.

=head1 WHEN TO USE

Use it when changing page document, resolver, runtime or store guard logic.

=head1 HOW TO USE

Run C<prove -lv t/390-page-modules-coverage.t>.

=head1 WHAT USES IT

The repository test suite and the coverage gate.

=head1 EXAMPLES

Example 1:

  prove -lv t/390-page-modules-coverage.t

=cut
