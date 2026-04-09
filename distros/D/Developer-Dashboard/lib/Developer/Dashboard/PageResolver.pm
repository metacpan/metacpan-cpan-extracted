package Developer::Dashboard::PageResolver;

use strict;
use warnings;

our $VERSION = '2.02';

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
    my ( $self, $id ) = @_;
    die 'Missing page id' if !defined $id || $id eq '';
    my $saved = eval { $self->{pages}->load_saved_page($id) };
    if ($saved) {
        $saved->{meta}{source_kind} = 'saved';
        return $saved;
    }
    return $self->load_provider_page($id);
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
    my ( $self, $id ) = @_;
    my ($provider) = grep { ref($_) eq 'HASH' && $_->{id} && $_->{id} eq $id } @{ $self->providers };
    die "Page '$id' not found" if !$provider;

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
        );
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

Perl module in the Developer Dashboard codebase. This file resolves bookmark pages and action-backed routes across layered runtime roots.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::PageResolver> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::PageResolver -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
