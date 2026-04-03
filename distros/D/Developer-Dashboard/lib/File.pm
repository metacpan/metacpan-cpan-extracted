package File;

use strict;
use warnings;

our $VERSION = '1.33';

use File::Spec;

our %ALIASES;

# configure(%args)
# Configures file alias mappings for legacy bookmark compatibility.
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

File - legacy file compatibility wrapper

=head1 SYNOPSIS

  File->configure(aliases => { output => '/tmp/output.txt' });
  File->write(output => "ok\n");

=head1 DESCRIPTION

This module provides a minimal compatibility wrapper for older bookmark code
that references a C<File> package directly.

=head1 METHODS

=head2 configure, read, write

Configure and read or write compatibility files.

=cut
