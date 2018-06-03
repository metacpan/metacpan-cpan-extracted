#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

package File::ByLine;
$File::ByLine::VERSION = '1.005';
use v5.10;

# ABSTRACT: Line-by-line file access loops

use strict;
use warnings;
use autodie;

use Carp;
use Fcntl;


#
# Exports
#
require Exporter;
our @ISA = qw(Exporter);

## no critic (Modules::ProhibitAutomaticExportation)
our @EXPORT =
  qw(dolines forlines greplines maplines parallel_dolines parallel_forlines parallel_greplines parallel_maplines readlines);
## use critic

our @EXPORT_OK =
  qw(dolines forlines greplines maplines parallel_dolines parallel_forlines parallel_greplines parallel_maplines readlines);


sub dolines (&$) {
    my ( $code, $file ) = @_;

    return _forlines_chunk( $code, $file, 1, 0 );
}


sub forlines ($&) {
    my ( $file, $code ) = @_;

    return _forlines_chunk( $code, $file, 1, 0 );
}


sub parallel_dolines (&$$) {
    _require_parallel();
    my ( $code, $file, $procs ) = @_;

    if ( !defined($procs) ) {
        croak("Must include number of child processes");
    }

    if ( $procs <= 0 ) { croak("Number of processes must be >= 1"); }

    my $wu = Parallel::WorkUnit->new();
    $wu->asyncs( $procs, sub { return _forlines_chunk( $code, $file, $procs, $_[0] ); } );
    my (@linecounts) = $wu->waitall();

    my $total_lines = 0;
    foreach my $cnt (@linecounts) {
        $total_lines += $cnt;
    }

    return $total_lines;
}


sub parallel_forlines ($$&) {
    _require_parallel();
    my ( $file, $procs, $code ) = @_;

    if ( !defined($procs) ) {
        croak("Must include number of child processes");
    }

    if ( $procs <= 0 ) { croak("Number of processes must be >= 1"); }

    my $wu = Parallel::WorkUnit->new();
    $wu->asyncs( $procs, sub { return _forlines_chunk( $code, $file, $procs, $_[0] ); } );
    my (@linecounts) = $wu->waitall();

    my $total_lines = 0;
    foreach my $cnt (@linecounts) {
        $total_lines += $cnt;
    }

    return $total_lines;
}


sub greplines (&$) {
    my ( $code, $file ) = @_;

    my $lines = _grep_chunk( $code, $file, 1, 0 );
    return @$lines;
}


sub parallel_greplines (&$$) {
    _require_parallel();
    my ( $code, $file, $procs ) = @_;

    if ( !defined($procs) ) {
        croak("Must include number of child processes");
    }

    if ( $procs <= 0 ) { croak("Number of processes must be >= 1"); }

    my $wu = Parallel::WorkUnit->new();
    $wu->asyncs( $procs, sub { return _grep_chunk( $code, $file, $procs, $_[0] ); } );
    return map { @$_ } $wu->waitall();
}


sub maplines (&$) {
    my ( $code, $file ) = @_;

    my $mapped_lines = _map_chunk( $code, $file, 1, 0 );
    return @$mapped_lines;
}


sub parallel_maplines (&$$) {
    my ( $code, $file, $procs ) = @_;

    if ( !defined($procs) ) {
        croak("Must include number of child processes");
    }

    if ( $procs <= 0 ) { croak("Number of processes must be >= 1"); }

    my $wu = Parallel::WorkUnit->new();
    $wu->asyncs( $procs, sub { return _map_chunk( $code, $file, $procs, $_[0] ); } );
    return map { @$_ } $wu->waitall();
}


sub readlines ($) {
    my ($file) = @_;

    my @lines;

    open my $fh, '<', $file or die($!);

    while (<$fh>) {
        chomp;
        push @lines, $_;
    }

    close $fh;

    return @lines;
}

# Internal function to perform a for loop on a single chunk of the file.
#
# Procs should be >= 1.  It represents the number of chunks the file
# has.
#
# Part should be >= 0 and < Procs.  It represents the zero-indexed chunk
# number this invocation is processing.
sub _forlines_chunk {
    my ( $code, $file, $procs, $part ) = @_;

    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my $lineno = 0;
    while (<$fh>) {
        $lineno++;

        chomp;
        $code->($_);

        # If we're reading multi-parts, do we need to end the read?
        if ( ( $end > 0 ) && ( tell($fh) > $end ) ) { last; }
    }

    close $fh;

    return $lineno;
}

# Internal function to perform a grep on a single chunk of the file.
#
# Procs should be >= 1.  It represents the number of chunks the file
# has.
#
# Part should be >= 0 and < Procs.  It represents the zero-indexed chunk
# number this invocation is processing.
sub _grep_chunk {
    my ( $code, $file, $procs, $part ) = @_;

    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my @lines;
    while (<$fh>) {
        chomp;

        if ( $code->($_) ) {
            push @lines, $_;
        }

        # If we're reading multi-parts, do we need to end the read?
        if ( ( $end > 0 ) && ( tell($fh) > $end ) ) { last; }
    }

    close $fh;
    return \@lines;
}

# Internal function to perform a map on a single chunk of the file.
#
# Procs should be >= 1.  It represents the number of chunks the file
# has.
#
# Part should be >= 0 and < Procs.  It represents the zero-indexed chunk
# number this invocation is processing.
sub _map_chunk {
    my ( $code, $file, $procs, $part ) = @_;

    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my @mapped_lines;
    while (<$fh>) {
        chomp;
        push @mapped_lines, $code->($_);

        # If we're reading multi-parts, do we need to end the read?
        if ( ( $end > 0 ) && ( tell($fh) > $end ) ) { last; }
    }

    close $fh;
    return \@mapped_lines;
}

# Internal function to facilitate reading a file in chunks.
#
# If parts == 1, this basically just opens the file (and returns -1 for
# end, to be discussed later)
#
# If parts > 1, then this divides the file (by byte count) into that
# many parts, and then seeks to the first character at the start of a
# new line in that part (lines are attributed to the part in which they
# end).
#
# It also returns an end position - no line starting *after* the end
# position is in the relevant chunk.
#
# part_number is zero indexed.
#
# For part_number >= 1, the first valid character is actually start + 1
# If a line actually starts at the first position, we treat it as
# part of the previous chunk.
#
# If no lines would start in a given chunk, this seeks to the end of the
# file (so it gives an EOF on the first read)
sub _open_and_seek {
    my ( $file, $parts, $part_number ) = @_;

    if ( !defined($parts) )       { $parts       = 1; }
    if ( !defined($part_number) ) { $part_number = 0; }

    if ( $parts <= $part_number ) {
        confess("Part Number must be greater than number of parts");
    }
    if ( $parts <= 0 ) {
        confess("Number of parts must be > 0");
    }
    if ( $part_number < 0 ) {
        confess("Part Number must be greater or equal to 0");
    }

    open my $fh, '<', $file or die($!);

    # If this is a single part request, we are done here.
    # We use -1, not size, because it's possible the read is from a
    # terminal or pipe or something else that can grow.
    if ( $parts == 0 ) {
        return ( $fh, -1 );
    }

    # This is a request for part of a multi-part document.  How big is
    # it?
    seek( $fh, 0, Fcntl::SEEK_END );
    my $size = tell($fh);

    # Special case - more threads than needed.
    if ( $parts > $size ) {
        if ( $part_number > $size ) { return ( $fh, -1 ) }

        # We want each part to be one byte, basically.  Not fractiosn of
        # a byte.
        $parts = $size;
    }

    # Figure out start and end size
    my $start = int( $part_number * ( $size / $parts ) );
    my $end = int( $start + ( $size / $parts ) );

    # Seek to start position
    seek( $fh, $start, Fcntl::SEEK_SET );

    # Read and discard junk to the end of line.
    # But ONLY for parts other than the first one.  We basically assume
    # all parts > 1 are starting mid-line.
    if ( $part_number > 0 ) {
        scalar(<$fh>);
    }

    # Special case - allow file to have grown since first read to end
    if ( ( $parts - 1 ) == $part_number ) {
        return ( $fh, -1 );
    }

    # Another special case...  If we're already past the end, seek to
    # the end.
    if ( tell($fh) > $end ) {
        seek( $fh, 0, Fcntl::SEEK_END );
    }

    # We return the file at this position.
    return ( $fh, $end );
}

sub _require_parallel {
    if ( scalar(@_) != 0 ) { confess 'invalid call'; }

    require Parallel::WorkUnit
      or die("You must install Parallel::WorkUnit to use the parallel_* methods");

    if ( $Parallel::WorkUnit::VERSION < 1.117 ) {
        die( "Parallel::WorkUnit version 1.117 or newer required. You have "
              . $Parallel::WorkUnit::Version );
    }

    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ByLine - Line-by-line file access loops

=head1 VERSION

version 1.005

=head1 SYNOPSIS

  use File::ByLine;

  #
  # Execute a routine for each line of a file
  #
  dolines { say "Line: $_" } "file.txt";
  forlines "file.txt", { say "Line: $_" };

  #
  # Grep (match) lines of a file
  #
  my (@result) = greplines { m/foo/ } "file.txt";

  #
  # Apply a function to each line and return result
  #
  my (@result) = maplines { lc($_) } "file.txt";

  #
  # Parallelized forlines/dolines routines
  # (Note: Requires Parallel::WorkUnit to be installed)
  #
  parallel_dolines { foo($_) } "file.txt", 10;
  parallel_forlines "file.txt", 10, { foo($_); };

  #
  # Parallelized maplines and greplines
  #
  my (@result) = parallel_greplines { m/foo/ } "file.txt", 10;
  my (@result) = parallel_maplines  { lc($_) } "file.txt", 10;

  #
  # Read an entire file, split into lines
  #
  my (@result) = readlines "file.txt";

=head1 DESCRIPTION

Finding myself writing the same trivial loops to read files, or relying on
modules like C<Perl6::Slurp> that didn't quite do what I needed (abstracting
the loop), it was clear something easy, simple, and sufficiently Perl-ish was
needed.

=head1 FUNCTIONS

=head2 dolines

  dolines { say "Line: $_" } "file.txt";
  dolines \&func, "file.txt";

This function calls a coderef once for each line in the file.  The file is read
line-by-line, removes the newline character(s), and then executes the coderef.

Each line (without newline) is passed to the coderef as the first parameter and
only parameter to the coderef.  It is also placed into C<$_>.

This function returns the number of lines in the file.

This is similar to C<forlines()>, except for order of arguments.  The author
recommends this form for short code blocks - I.E. a coderef that fits on
one line.  For longer, multi-line code blocks, the author recommends
the C<forlines()> syntax.

=head2 forlines

  forlines "file.txt", { say "Line: $_" };
  forlines "file.txt", \&func;

This function calls a coderef once for each line in the file.  The file is read
line-by-line, removes the newline character(s), and then executes the coderef.

Each line (without newline) is passed to the coderef as the first parameter and
only parameter to the coderef.  It is also placed into C<$_>.

This function returns the number of lines in the file.

This is similar to C<dolines()>, except for order of arguments.  The author
recommends this when using longer, multi-line code blocks, even though it is
not orthogonal with the C<maplines()>/C<greplines()> routines.

=head2 parallel_dolines

  my (@result) = parallel_dolines { foo($_) } "file.txt", 10;

Requires L<Parallel::WorkUnit> to be installed.

Three parameters are requied: a codref, a filename, and number of simultanious
child threads to use.

This function performs similar to C<dolines()>, except that it does its'
operations in parallel using C<fork()> and L<Parallel::WorkUnit>.  Because
the code in the coderef is executed in a child process, any changes it makes
to variables in high scopes will not be visible outside that single child.
In general, it will be safest to not modify anything that belongs outside
this scope.

Note that the file will be read in several chunks, with each chunk being
processed in a different thread.  This means that the child threads may be
operating on very different sections of the file simultaniously and no specific
order of execution of the coderef should be expected!

Because of the mechanism used to split the file into chunks for processing,
each thread may process a somewhat different number of lines.  This is
particularly true if there are a mix of very long and very short lines.  The
splitting routine splits the file into roughly equal size chunks by byte
count, not line count.

Otherwise, this function is identical to C<dolines()>.  See the documentation
for C<dolines()> or C<forlines()> for information about how this might differ
from C<parallel_forlines()>.

=head2 parallel_forlines

  my (@result) = parallel_forlines "file.txt", 10, { foo($_) };

Requires L<Parallel::WorkUnit> to be installed.

Three parameters are requied: a filename, a codref, and number of simultanious
child threads to use.

This function performs similar to C<forlines()>, except that it does its'
operations in parallel using C<fork()> and L<Parallel::WorkUnit>.  Because
the code in the coderef is executed in a child process, any changes it makes
to variables in high scopes will not be visible outside that single child.
In general, it will be safest to not modify anything that belongs outside
this scope.

Note that the file will be read in several chunks, with each chunk being
processed in a different thread.  This means that the child threads may be
operating on very different sections of the file simultaniously and no specific
order of execution of the coderef should be expected!

Because of the mechanism used to split the file into chunks for processing,
each thread may process a somewhat different number of lines.  This is
particularly true if there are a mix of very long and very short lines.  The
splitting routine splits the file into roughly equal size chunks by byte
count, not line count.

Otherwise, this function is identical to C<forlines()>.  See the documentation
for C<forlines()> or C<dolines()> for information about how this might differ
from C<parallel_dolines()>.

=head2 greplines

  my (@result) = greplines { m/foo/ } "file.txt";

Requires L<Parallel::WorkUnit> to be installed.

This function calls a coderef once for each line in the file, and, based on
the return value of that coderef, returns only the lines where the coderef
evaluates to true.  This is similar to the C<grep> built-in function, except
operating on file input rather than array input.

Each line (without newline) is passed to the coderef as the first parameter and
only parameter to the coderef.  It is also placed into C<$_>.

This function returns the lines for which the coderef evaluates as true.

=head2 parallel_greplines

  my (@result) = parallel_greplines { m/foo/ } "file.txt", 10;

Three parameters are requied: a coderef, filename, and number of simultanious
child threads to use.

This function performs similar to C<greplines()>, except that it does its'
operations in parallel using C<fork()> and L<Parallel::WorkUnit>.  Because
the code in the coderef is executed in a child process, any changes it makes
to variables in high scopes will not be visible outside that single child.
In general, it will be safest to not modify anything that belongs outside
this scope.

If a large amount of data is returned, the overhead of passing the data
from child to parents may exceed the benefit of parallelization.  However,
if there is substantial line-by-line processing, there likely will be a speedup,
but trivial loops will not speed up.

Note that the file will be read in several chunks, with each chunk being
processed in a different thread.  This means that the child threads may be
operating on very different sections of the file simultaniously and no specific
order of execution of the coderef should be expected!  However, the results
will be returned in the same order as C<greplines()> would return them.

Because of the mechanism used to split the file into chunks for processing,
each thread may process a somewhat different number of lines.  This is
particularly true if there are a mix of very long and very short lines.  The
splitting routine splits the file into roughly equal size chunks by byte
count, not line count.

Otherwise, this function is identical to C<greplines()>.

=head2 maplines

  my (@result) = maplines { lc($_) } "file.txt";

This function calls a coderef once for each line in the file, and, returns
an array of return values from those calls.  This follows normal Perl rules -
basically if the coderef returns a list, all elements of that list are added
as distinct elements to the return value array.  If the coderef returns an
empty list, no elements are added.

Each line (without newline) is passed to the coderef as the first parameter and
only parameter to the coderef.  It is also placed into C<$_>.

This is meant to be similar to the built-in C<map> function.

Because of the mechanism used to split the file into chunks for processing,
each thread may process a somewhat different number of lines.  This is
particularly true if there are a mix of very long and very short lines.  The
splitting routine splits the file into roughly equal size chunks by byte
count, not line count.

This function returns the lines for which the coderef evaluates as true.

=head2 parallel_maplines

  my (@result) = parallel_maplines { lc($_) } "file.txt", 10;

Three parameters are requied: a coderef, filename, and number of simultanious
child threads to use.

This function performs similar to C<maplines()>, except that it does its'
operations in parallel using C<fork()> and L<Parallel::WorkUnit>.  Because
the code in the coderef is executed in a child process, any changes it makes
to variables in high scopes will not be visible outside that single child.
In general, it will be safest to not modify anything that belongs outside
this scope.

If a large amount of data is returned, the overhead of passing the data
from child to parents may exceed the benefit of parallelization.  However,
if there is substantial line-by-line processing, there likely will be a speedup,
but trivial loops will not speed up.

Note that the file will be read in several chunks, with each chunk being
processed in a different thread.  This means that the child threads may be
operating on very different sections of the file simultaniously and no specific
order of execution of the coderef should be expected!  However, the results
will be returned in the same order as C<maplines()> would return them.

Otherwise, this function is identical to C<maplines()>.

=head2 readlines

  my (@result) = readlines "file.txt";

This function simply returns an array of lines (without newlines) read from
a file.

=head1 SUGGESTED DEPENDENCY

The L<Parallel::WorkUnit> module is a recommended dependency.  It is required
to use the C<parallel_*> functions - all other functionality works fine without
it.

Some CPAN clients will automatically try to install recommended dependency, but
others won't (L<cpan> often, but not always, will; L<cpanm> will not by
default).  In the cases where it is not automatically installed, you need to
install L<Parallel::WorkUnit> to get this functionality.

=head1 AUTHOR

Joelle Maslak <jmaslak@antelope.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Joelle Maslak.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
