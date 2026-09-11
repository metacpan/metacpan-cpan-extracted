package Developer::Dashboard::CLI::TableHelpers;

use strict;
use warnings;

our $VERSION = '4.31';

use Cwd qw(cwd);
use Exporter 'import';
use Developer::Dashboard::PathRegistry;

our @EXPORT_OK = qw(
    build_paths
    aliases_table
    list_table
    mutation_table
    removal_table
    render_table
);

# build_paths()
# Builds the lightweight path registry shared by the file/path/which CLI
# helper commands.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object scoped to the current cwd.
sub build_paths {
    my $home = $ENV{HOME} || '';
    my @roots = grep { -d } map { "$home/$_" } qw(projects src work);
    return Developer::Dashboard::PathRegistry->new(
        home            => $home,
        cwd             => cwd(),
        workspace_roots => \@roots,
        project_roots   => \@roots,
    );
}

# aliases_table($aliases_hash)
# Renders one saved alias registry (file or path) as a summary table.
# Input: hash reference keyed by alias name.
# Output: formatted table text string.
sub aliases_table {
    my ($aliases) = @_;
    my @rows = map { [ $_, $aliases->{$_} ] } sort keys %{ $aliases || {} };
    return render_table( [ 'Alias', 'Path' ], \@rows );
}

# list_table($label, $items)
# Renders one flat list as a single-column summary table.
# Input: column label string and array reference of scalar items.
# Output: formatted table text string.
sub list_table {
    my ( $label, $items ) = @_;
    my @rows = map { [ $_ ] } @{ $items || [] };
    return render_table( [$label], \@rows );
}

# mutation_table(%args)
# Renders one alias add/update result (file or path) as a summary table.
# Input: alias, stored path, resolved path, and status strings.
# Output: formatted table text string.
sub mutation_table {
    my (%args) = @_;
    return render_table(
        [ 'Alias', 'Stored', 'Resolved', 'Status' ],
        [ [ map { $args{$_} // '' } qw(alias stored resolved status) ] ],
    );
}

# removal_table(%args)
# Renders one alias removal result (file or path) as a summary table.
# Input: alias string and removed boolean flag.
# Output: formatted table text string.
sub removal_table {
    my (%args) = @_;
    return render_table(
        [ 'Alias', 'Removed', 'Status' ],
        [ [ $args{alias} // '', $args{removed} ? 'yes' : 'no', $args{removed} ? 'removed' : 'no-change' ] ],
    );
}

# render_table($header, $rows)
# Formats one rectangular data set as a padded terminal table.
# Input: header array reference and row array reference.
# Output: formatted table text string.
sub render_table {
    my ( $header, $rows ) = @_;
    my @widths = map { length( defined $_ ? $_ : '' ) } @{ $header || [] };
    for my $row ( @{ $rows || [] } ) {
        for my $idx ( 0 .. $#{$row} ) {
            my $value = defined $row->[$idx] ? $row->[$idx] : '';
            my $width = length($value);
            $widths[$idx] = $width if $width > $widths[$idx];
        }
    }
    my @lines;
    push @lines, join( '  ', map { sprintf "%-*s", $widths[$_], ( $header->[$_] // '' ) } 0 .. $#widths );
    push @lines, join( '  ', map { '-' x $widths[$_] } 0 .. $#widths );
    for my $row ( @{ $rows || [] } ) {
        push @lines, join( '  ', map { sprintf "%-*s", $widths[$_], ( defined $row->[$_] ? $row->[$_] : '' ) } 0 .. $#widths );
    }
    return join( "\n", @lines ) . "\n";
}

1;

__END__

=head1 NAME

Developer::Dashboard::CLI::TableHelpers - shared path-registry and table
rendering helpers for the lightweight file/path/which CLI commands

=head1 SYNOPSIS

  use Developer::Dashboard::CLI::TableHelpers qw(
      build_paths aliases_table list_table mutation_table removal_table render_table
  );
  my $paths = build_paths();
  print aliases_table( { home => '/home/mv' } );

=head1 DESCRIPTION

Provides the path-registry builder and the five table-rendering helpers that
used to be written out identically (or near-identically) in
C<CLI/Files.pm>, C<CLI/Paths.pm> and C<CLI/Which.pm>.

=head1 PURPOSE

This module exists to give the codebase one place to build the lightweight
CLI path registry and to render the small summary tables the file/path
helper commands print, instead of repeating the same bodies verbatim at
every call site.

=head1 WHY IT EXISTS

C<_build_paths> was byte-identical in C<CLI/Files.pm> and C<CLI/Which.pm>,
and functionally identical in C<CLI/Paths.pm> (which carried an extra
C<defined &&> check that could never be false, annotated
C<# uncoverable branch false>). C<_aliases_table>, C<_list_table>,
C<_mutation_table> and C<_removal_table> were byte-identical between
C<CLI/Files.pm> and C<CLI/Paths.pm>; C<_render_table> differed only by one
trailing blank line (DD-773). A future change to how these tables render,
or to how the path registry is built, would otherwise have to find every
site by hand, since nothing connected them by name.

=head1 WHEN TO USE

Use these helpers whenever CLI code needs the lightweight path registry
used by the file/path/which commands, or needs to render a two-column,
single-column, mutation-result or removal-result summary table in the same
style those commands already use.

=head1 HOW TO USE

  use Developer::Dashboard::CLI::TableHelpers qw(build_paths render_table);
  my $paths = build_paths();
  print render_table( [ 'Alias', 'Path' ], [ [ 'proj', '/home/mv/projects' ] ] );

=head1 WHAT USES IT

C<Developer::Dashboard::CLI::Files>, C<Developer::Dashboard::CLI::Paths> and
C<Developer::Dashboard::CLI::Which> all call C<build_paths> in place of
their own former copies; C<Files.pm> and C<Paths.pm> also call the four
alias/list/mutation/removal table helpers and C<render_table> in place of
their own former copies.

=head1 EXAMPLES

Example 1:

  my $paths = build_paths();
  # $paths is a Developer::Dashboard::PathRegistry scoped to the current cwd

Example 2:

  print list_table( 'Match', [ '/home/mv/projects/a', '/home/mv/projects/b' ] );
  # File  Match
  # -----------
  # /home/mv/projects/a
  # /home/mv/projects/b

=cut
