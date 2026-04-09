package Developer::Dashboard::File;

use strict;
use warnings;

our $VERSION = '2.02';

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

Perl module in the Developer Dashboard codebase. This file provides reusable file-system helpers for reading, writing, and normalizing runtime files.
Open this file when you need the implementation, regression coverage, or runtime entrypoint for that responsibility rather than guessing which part of the tree owns it.

=head1 WHY IT EXISTS

It exists to keep this responsibility in reusable Perl code instead of hiding it in the thin C<dashboard> switchboard, bookmark text, or duplicated helper scripts. That separation makes the runtime easier to test, safer to change, and easier for contributors to navigate.

=head1 WHEN TO USE

Use this file when you are changing the underlying runtime behaviour it owns, when you need to call its routines from another part of the project, or when a failing test points at this module as the real owner of the bug.

=head1 HOW TO USE

Load C<Developer::Dashboard::File> from Perl code under C<lib/> or from a focused test, then use the public routines documented in the inline function comments and existing SYNOPSIS/METHODS sections. This file is not a standalone executable.

=head1 WHAT USES IT

This file is used by whichever runtime path owns this responsibility: the public C<dashboard> entrypoint, staged private helper scripts under C<share/private-cli/>, the web runtime, update flows, and the focused regression tests under C<t/>.

=head1 EXAMPLES

  perl -Ilib -MDeveloper::Dashboard::File -e 'print qq{loaded\n}'

That example is only a quick load check. For real usage, follow the public routines already described in the inline code comments and any existing SYNOPSIS section.

=for comment FULL-POD-DOC END

=cut
