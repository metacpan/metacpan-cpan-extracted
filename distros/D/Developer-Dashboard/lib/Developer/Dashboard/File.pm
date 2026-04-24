package Developer::Dashboard::File;

use strict;
use warnings;

our $VERSION = '3.09';

use File::Spec;

our %ALIASES;

# configure(%args)
# Configures file alias mappings for older bookmark compatibility.
# Input: aliases hash.
# Output: true value.
sub configure {
    my ( $class, %args ) = @_;
    %ALIASES = %{ $args{aliases} || {} };
    return 1;
}

# read($file)
# Reads a file by absolute path or configured alias.
# Input: file path or alias.
# Output: file contents string or undef.
sub read {
    my ( $class, $file ) = @_;
    $file = $ALIASES{$file} if exists $ALIASES{$file};
    return if !defined $file || !-f $file;
    open my $fh, '<', $file or die "Unable to read $file: $!";
    local $/;
    return <$fh>;
}

# write($file, $content)
# Writes full content to a file path or alias.
# Input: file path or alias and content string.
# Output: file path string.
sub write {
    my ( $class, $file, $content ) = @_;
    $file = $ALIASES{$file} if exists $ALIASES{$file};
    die 'Missing file path' if !defined $file || $file eq '';
    open my $fh, '>', $file or die "Unable to write $file: $!";
    print {$fh} defined $content ? $content : '';
    close $fh;
    return $file;
}

1;

__END__

=head1 NAME

Developer::Dashboard::File - older file compatibility wrapper

=head1 SYNOPSIS

  File->configure(aliases => { output => '/tmp/output.txt' });
  File->write(output => "ok\n");

=head1 DESCRIPTION

This module provides a minimal compatibility wrapper for older bookmark code
that references a C<File> package directly.

=head1 METHODS

=head2 configure, read, write

Configure and read or write compatibility files.

=for comment FULL-POD-DOC START

=head1 PURPOSE

This module is the narrow compatibility wrapper for older bookmark code that still expects a top-level C<File> package with alias-aware C<read> and C<write> methods. It maps friendly aliases to real paths and then performs the requested file operation.

=head1 WHY IT EXISTS

It exists to keep older bookmark snippets working while the rest of the runtime uses newer namespaced modules. The compatibility surface is intentionally tiny so the old API does not leak further into new code.

=head1 WHEN TO USE

Use this file when a compatibility bookmark or test still relies on C<File-E<gt>read>, C<File-E<gt>write>, or C<File-E<gt>configure>, or when you need to tighten the behavior of that old alias mechanism without breaking the compatibility contract.

=head1 HOW TO USE

Call C<configure> once with any alias map you need, then use C<read> or C<write> with either the alias or the concrete path. Treat it as a compatibility shim, not as the main runtime file abstraction.

=head1 WHAT USES IT

It is used by older bookmark code paths, by compatibility tests, and by release documentation that keeps the backward-compatible helper layer visible to maintainers.

=head1 EXAMPLES

Example 1:

  perl -Ilib -MDeveloper::Dashboard::File -e 1

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
