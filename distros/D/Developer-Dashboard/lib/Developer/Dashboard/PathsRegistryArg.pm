package Developer::Dashboard::PathsRegistryArg;

use strict;
use warnings;

our $VERSION = '4.31';

use Exporter 'import';

our @EXPORT_OK = qw(require_paths_arg);

# require_paths_arg(%args)
# Extracts the mandatory "paths" registry from a constructor's argument
# hash, dying with the shared message when it is absent.
# Input: the constructor's own %args hash.
# Output: the paths registry object; dies 'Missing paths registry' if
#         $args{paths} is absent or false.
sub require_paths_arg {
    my (%args) = @_;
    return $args{paths} || die 'Missing paths registry';
}

1;

__END__

=head1 NAME

Developer::Dashboard::PathsRegistryArg - shared paths-registry constructor guard

=head1 SYNOPSIS

  use Developer::Dashboard::PathsRegistryArg qw(require_paths_arg);

  sub new {
      my ( $class, %args ) = @_;
      my $paths = require_paths_arg(%args);
      return bless { paths => $paths }, $class;
  }

=head1 DESCRIPTION

Provides C<require_paths_arg>, the single home for a guard that used to be
written out identically (or near-identically) in seven modules' own
C<new()>.

=head1 PURPOSE

This module exists to give the codebase one place to check that a
constructor was handed a paths registry, instead of repeating the same
C<$args{paths} || die 'Missing paths registry'> line at every constructor.

=head1 WHY IT EXISTS

Seven modules under C<lib/> hand-rolled the same constructor guard
(DD-785): C<Collector.pm>, C<Doctor.pm>, C<IndicatorStore.pm> and
C<PageStore.pm> had byte-identical bodies; C<Housekeeper.pm> differed only
by a trailing comma; C<FileRegistry.pm> and C<Prompt.pm> needed the same
guard plus extra fields of their own. A future change to the die wording,
or to what counts as a valid paths registry, would have had to find every
copy by hand.

This ticket scoped itself to these seven constructors deliberately, after
finding during research that the same literal die string also appears 24
more times across four other files (C<CLI/Paths.pm>, C<CLI/Which.pm>,
C<InternalCLI.pm>, C<CLI/SeededPages.pm>) inside per-function C<%args>
guards for CLI action handlers - a different call shape (several required
keys, not one) with a much larger blast radius. Those are a related but
separate finding, not folded into this extraction.

=head1 WHEN TO USE

Use C<require_paths_arg> inside any constructor whose sole or partial job
is to require a C<paths> key in its argument hash and bless it (or store
it alongside other fields) - never as a general-purpose "get me an
argument or die" helper for unrelated keys.

=head1 HOW TO USE

Call it with the constructor's own C<%args> hash and use its return value
exactly as the former inline guard's C<$paths> variable was used:

  sub new {
      my ( $class, %args ) = @_;
      my $paths = require_paths_arg(%args);
      return bless { paths => $paths, extra_field => $args{extra_field} }, $class;
  }

It never inspects or requires any key other than C<paths>, so callers that
need additional mandatory fields (C<FileRegistry>, C<Prompt>) keep their
own separate guards for those.

=head1 WHAT USES IT

C<Developer::Dashboard::Collector>, C<Developer::Dashboard::Doctor>,
C<Developer::Dashboard::IndicatorStore>, C<Developer::Dashboard::PageStore>,
C<Developer::Dashboard::Housekeeper>, C<Developer::Dashboard::FileRegistry>
and C<Developer::Dashboard::Prompt> all call it in place of their own
former copies of the same guard.

=head1 EXAMPLES

Example 1:

  require_paths_arg( paths => $registry );

Returns C<$registry>.

Example 2:

  require_paths_arg();

Dies with C<Missing paths registry>.

=cut
