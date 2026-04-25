package Developer::Dashboard::DataHelper;

use strict;
use warnings;

our $VERSION = '3.14';

use Exporter 'import';

use Developer::Dashboard::JSON qw(json_decode json_encode);

our @EXPORT = qw(j je);

# j($value)
# Encodes a Perl value to canonical JSON text.
# Input: any JSON-encodable Perl value.
# Output: JSON string.
sub j {
    return json_encode( $_[0] );
}

# je($text)
# Decodes JSON text to a Perl value.
# Input: JSON string.
# Output: decoded Perl value.
sub je {
    return json_decode( $_[0] // '' );
}

1;

__END__

=head1 NAME

Developer::Dashboard::DataHelper - older JSON helper compatibility functions

=head1 SYNOPSIS

  use Developer::Dashboard::DataHelper qw(j je);
  my $json = j({ ok => 1 });

=head1 DESCRIPTION

This module provides the small older JSON helper functions used by older
bookmark code blocks.

=head1 FUNCTIONS

=head2 j, je

Encode and decode JSON values.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module keeps the tiny C<j()> and C<je()> compatibility helpers used by older bookmark code blocks. It maps those short names onto the project-standard JSON::XS encoder and decoder so older bookmark snippets can keep working without dragging a larger helper layer into the page runtime.

=head1 WHY IT EXISTS

It exists because some bookmark code still expects the older helper names. Preserving them in one compatibility module lets the runtime stay backward-compatible without letting old helper naming spread through new code.

=head1 WHEN TO USE

Use this file when you are touching older bookmark snippets that call C<j()> or C<je()>, or when the project-wide JSON behavior changes and the compatibility layer has to stay in sync.

=head1 HOW TO USE

Import C<j> and C<je> in the bookmark or compatibility path that needs them. Newer runtime code should normally prefer C<Developer::Dashboard::JSON>, but this module remains the right place for the short historical helper names that old bookmark snippets still call.

=head1 WHAT USES IT

It is used by older bookmark code, by compatibility-oriented tests, and by release metadata that keeps the shipped compatibility surface explicit.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::DataHelper -e 1

Do a direct compile-and-load check against the module from a source checkout.

Example 2:

  prove -lv t/21-refactor-coverage.t t/00-load.t

Run the focused regression tests that most directly exercise this module's behavior.

Example 3:

  HARNESS_PERL_SWITCHES=-MDevel::Cover prove -lr t

Recheck the module under the repository coverage gate rather than relying on a load-only probe.

Example 4:

  prove -lr t

Put any module-level change back through the entire repository suite before release.


=for comment FULL-POD-DOC END

=cut
