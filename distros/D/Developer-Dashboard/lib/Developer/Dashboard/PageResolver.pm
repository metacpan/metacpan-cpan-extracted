package Developer::Dashboard::PageResolver;

use strict;
use warnings;

our $VERSION = '4.31';

use Developer::Dashboard::PageDocument;

# new(%args)
# Constructs the page resolver over saved and config-backed page sources.
# Input: config, pages, paths, and actions objects.
# Output: Developer::Dashboard::PageResolver object.
sub new {
    my ( $class, %args ) = @_;
    my $config  = $args{config}  || die 'Missing config';
    my $pages   = $args{pages}   || die 'Missing page store';
    my $paths   = $args{paths}   || die 'Missing path registry';
    my $actions = $args{actions} || die 'Missing action runner';
    return bless {
        actions => $actions,
        config  => $config,
        pages   => $pages,
        paths   => $paths,
    }, $class;
}

# list_pages()
# Lists all resolvable page ids from saved and provider sources.
# Input: none.
# Output: sorted list of page id strings.
sub list_pages {
    my ($self) = @_;
    my %ids = map { $_ => 1 } $self->{pages}->list_saved_pages;
    for my $provider ( @{ $self->providers } ) {
        next if ref($provider) ne 'HASH';
        $ids{ $provider->{id} } = 1 if $provider->{id};
    }
    return sort keys %ids;
}

# load_named_page($id)
# Loads a page by id from saved storage or provider sources.
# Input: page id string.
# Output: Developer::Dashboard::PageDocument object.
sub load_named_page {
    my ( $self, $id, $report ) = @_;
    die 'Missing page id' if !defined $id || $id eq '';
    my $saved = eval { $self->{pages}->load_saved_page($id) };
    if ($saved) {
        $saved->{meta}{source_kind} = 'saved';
        _note( $report, 'saved', 'matched' );
        return $saved;
    }
    # DD-603: load_saved_page dies for three distinct reasons - genuine
    # "not found", a file-read failure, or a parse/validation failure - and
    # only the first one means "fall through to provider lookup". Collapsing
    # all three into a silent fallthrough turns a real read/parse error into
    # a misleading generic "not found" once provider lookup also fails to
    # match. Only the exact not-found die falls through; anything else is
    # the real diagnostic and must surface as-is. $@ is always a truthy,
    # eval-set error string here: this line is reached only when $saved is
    # falsy, and load_saved_page's own contract is to always either die or
    # return a truthy page hashref, never return falsy without dying.
    if ( $@ !~ /\APage '\Q$id\E' not found/ ) {
        _note( $report, 'saved', 'error', $@ );
        die $@;
    }
    _note( $report, 'saved', 'not-found' );
    return $self->load_provider_page( $id, $report );
}

# _note($report, $source, $outcome, $detail)
# Appends one step to an optional resolution report. Does nothing at all when no
# report is being collected, which is what keeps the default path byte-identical.
# Input: report arrayref or undef, source name, outcome string, optional detail.
# Output: nothing.
sub _note {
    my ( $report, $source, $outcome, $detail ) = @_;
    return if !$report;
    my %step = ( source => $source, outcome => $outcome );
    if ( defined $detail ) {
        $detail =~ s/\s+\z//;
        $step{detail} = $detail;
    }
    push @{$report}, \%step;
    return;
}

# resolution_report($id)
# Resolves a page id exactly as load_named_page does, and returns the sequence of
# sources consulted with what each one said - whether resolution succeeded or not.
#
# This exists because the resolver ALREADY knows two things it discards: which
# kind of saved-storage failure occurred, and which provider ids exist. For the
# commonest failure - a mistyped or renamed id - the bare "not found" is the
# least useful thing that could be said, while the answer is sitting in the
# resolver at the moment it gives up. Perl's own loader is the model: it does not
# say "module not found", it says which paths it tried.
#
# Input: page id string.
# Output: hash reference with 'resolved' (0 or 1), 'steps' (arrayref of
#         {source, outcome, detail?}), and 'error' when resolution failed.
sub resolution_report {
    my ( $self, $id ) = @_;
    my @steps;
    my $page = eval { $self->load_named_page( $id, \@steps ) };
    return {
        resolved => $page ? 1 : 0,
        steps    => \@steps,
        ( $page ? () : ( error => $@ ) ),
    };
}

# providers()
# Returns the full provider page registry, including built-ins.
# Input: none.
# Output: array reference of provider hash references.
sub providers {
    my ($self) = @_;
    my @providers = (
        {
            id          => 'system-status',
            kind        => 'builtin',
            title       => 'System Status',
            description => 'Generated page describing the local runtime.',
        },
        {
            id          => 'project-context',
            kind        => 'builtin',
            title       => 'Project Context',
            description => 'Generated page describing the active project.',
        },
    );

    push @providers, @{ $self->{config}->providers };
    return \@providers;
}

# load_provider_page($id)
# Builds a generated page from a provider definition.
# Input: provider page id string.
# Output: Developer::Dashboard::PageDocument object.
sub load_provider_page {
    my ( $self, $id, $report ) = @_;
    my @providers = @{ $self->providers };
    my ($provider) = grep { ref($_) eq 'HASH' && $_->{id} && $_->{id} eq $id } @providers;
    if ( !$provider ) {
        # Report the CANDIDATES, not just the verdict. The ids that DO exist are
        # what a reader needs in order to act on a mistyped or renamed page id.
        _note( $report, 'providers', 'no-match',
            join ', ', sort grep { defined && length } map { ref($_) eq 'HASH' ? $_->{id} : () } @providers );
        die "Page '$id' not found";
    }
    _note( $report, 'providers', 'matched' );

    my $page;
    if ( ( $provider->{kind} || '' ) eq 'builtin' && $id eq 'system-status' ) {
        $page = Developer::Dashboard::PageDocument->new(
            id          => $id,
            title       => 'System Status',
            description => 'Generated overview of runtime paths and roots.',
            layout      => {
                body => join(
                    "\n",
                    'Developer Dashboard runtime paths:',
                    'home: ' . $self->{paths}->home,
                    'runtime: ' . $self->{paths}->runtime_root,
                    'dashboards: ' . $self->{paths}->dashboards_root,
                    'config: ' . $self->{paths}->config_root,
                    'cli: ' . $self->{paths}->cli_root,
                ),
            },
            actions => [
                { id => 'paths', label => 'Show paths', kind => 'builtin', builtin => 'paths.list', safe => 1 },
            ],
        );
    }
    elsif ( ( $provider->{kind} || '' ) eq 'builtin' && $id eq 'project-context' ) {
        my $root = $self->{paths}->current_project_root || '(none)';
        $page = Developer::Dashboard::PageDocument->new(
            id          => $id,
            title       => 'Project Context',
            description => 'Generated page describing the current project root.',
            layout      => { body => "Current project root:\n$root" },
            state       => { current_project_root => $root },
            actions     => [
                { id => 'state', label => 'Show state', kind => 'builtin', builtin => 'page.state', safe => 1 },
            ],
        );
    }
    elsif ( ref( $provider->{page} ) eq 'HASH' ) {
        $page = Developer::Dashboard::PageDocument->from_hash( $provider->{page} );
    }
    else {
        $page = Developer::Dashboard::PageDocument->new(
            id          => $provider->{id},
            title       => $provider->{title} || $provider->{id},
            description => $provider->{description} || 'Generated provider page.',
            layout      => { body => $provider->{body} || '' },
            actions     => $provider->{actions} || [],
            state       => $provider->{state} || {},
        );    # uncoverable condition false count:1
    }

    $page->{meta}{source_kind} = 'provider';
    return $page;
}

1;

__END__

=head1 NAME

Developer::Dashboard::PageResolver - page source resolver

=head1 SYNOPSIS

  my $resolver = Developer::Dashboard::PageResolver->new(...);
  my $page = $resolver->load_named_page('system-status');

=head1 DESCRIPTION

This module resolves pages from saved files and generated provider sources into
the common page document model.

=head1 METHODS

=head2 new, list_pages, load_named_page, providers, load_provider_page

Resolve saved and generated pages.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module resolves which page object should answer a browser request. It decides whether a request targets a saved bookmark, a config-backed provider page, or another page source, and it hands the resulting page object to the rest of the web stack in a normalized shape.

=head1 WHY IT EXISTS

It exists because the browser surface includes more than one page source. Keeping that routing logic in one resolver prevents the web app from mixing saved bookmark lookup, provider-page lookup, and action wiring in the same route code.

=head1 WHEN TO USE

Use this file when adding a new page source, changing the order in which page providers are consulted, or fixing browser routes that land on the wrong saved/config-backed page.

=head1 HOW TO USE

Construct it with the config, page store, action runner, and paths services, then ask it to resolve the requested page identifier. Treat the returned structure as the canonical page object for the render and source flows.

=head1 WHAT USES IT

It is used by the web app routes, by provider-backed pages such as dashboard workspaces, and by tests that verify page selection across saved and config-backed sources.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::PageResolver -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/07-core-units.t t/21-refactor-coverage.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
