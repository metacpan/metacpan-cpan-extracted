#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

package File::ByLine::Object;
$File::ByLine::Object::VERSION = '1.181861';
use v5.10;

# ABSTRACT: Internal object used by File::ByLine

use strict;
use warnings;
use autodie;

use Carp;
use Fcntl;
use Scalar::Util qw(reftype);

# We do this intentionally:
## no critic (Subroutines::ProhibitBuiltinHomonyms)


#
# Attribute Accessor - file
#
# The file we operate on (most methods accept a file parameter - this is
# only used if one is not set)
sub file {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{file};
    } elsif ( scalar(@_) == 1 ) {
        my $file = shift;
        return $self->{file} = $file;
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - processes
#
# This is the degree of parallism we will attempt for most methods (the
# exception is "lines()")
sub processes {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{processes};
    } elsif ( scalar(@_) == 1 ) {
        my $procs = shift;
        if ( $procs < 1 ) {
            confess("Process count must be >= 1");
        }
        if ( $procs > 1 ) {
            $self->_require_parallel();
        }
        return $self->{processes} = $procs;
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - header_handler
#
# This is the code that handles the headder line
sub header_handler {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{header_handler};
    } elsif ( scalar(@_) == 1 ) {
        my $code = shift;
        if ( defined( $_[0] ) ) {
            if ( !_codelike( $code ) ) {
                confess("header_handler must be a code reference");
            }
            if ( $self->{header_skip} ) {
                confess("Must unset header_skip before setting a header_handler");
            }
        }
        return $self->{header_handler} = $code;
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - header_skip
#
# If set to one, skip the header line
sub header_skip {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{header_skip};
    } elsif ( scalar(@_) == 1 ) {
        if ( $_[0] && $self->{header_handler} ) {
            confess("Must undefine header_handler before setting header_skip");
        }
        return $self->{header_skip} = $_[0];
    } else {
        confess("Invalid call");
    }
}

#
# Constructor
#
sub new {
    my $class = shift;

    my $self = {};
    $self->{header_handler} = undef;
    $self->{header_skip}    = undef;
    $self->{processes}      = 1;

    bless $self, $class;

    return $self;
}

#
# Method - do
#
# Executes the provided code on every line.
#
sub do {
    if (scalar(@_) < 2) { confess "Invalid call"; }
    my ( $self, $code, $file ) = @_;

    if (!defined($file)) { $file = $self->{file} };
    if (!defined($file)) { confess "Must provide filename"; }

    if ( defined( $self->{header_handler} ) ) {
        my $header = $_ = $self->_read_header($file);
        if ( defined($header) ) {
            $self->{header_handler}($header);
        }
    }

    if ( $self->{processes} == 1 ) {
        return $self->_forlines_chunk( $code, $file, 0 );
    } else {
        my $wu = Parallel::WorkUnit->new();
        $wu->asyncs( $self->{processes},
            sub { return $self->_forlines_chunk( $code, $file, $_[0] ); } );
        my (@linecounts) = $wu->waitall();

        my $total_lines = 0;
        foreach my $cnt (@linecounts) {
            $total_lines += $cnt;
        }

        return $total_lines;
    }
}

#
# Method - grep
#
# Finds and returns matching lines
sub grep {
    if (scalar(@_) < 2) { confess "Invalid call"; }
    my ( $self, $code, $file ) = @_;

    if (!defined($file)) { $file = $self->{file} };
    if (!defined($file)) { confess "Must provide filename"; }

    if ( defined( $self->{header_handler} ) ) {
        my $header = $_ = $self->_read_header($file);
        if ( defined($header) ) {
            $self->{header_handler}($header);
        }
    }

    my $procs = $self->{processes};

    if ($procs > 1) {
        my $wu = Parallel::WorkUnit->new();

        $wu->asyncs( $procs, sub { return $self->_grep_chunk( $code, $file, $procs, $_[0] ); } );

        return map { @$_ } $wu->waitall();
    } else {
        my $lines = $self->_grep_chunk( $code, $file, 1, 0 );

        return @$lines;
    }
}

#
# Method - map
#
# Applies function to each entry and returns that result
sub map {
    if (scalar(@_) < 2) { confess "Invalid call"; }
    my ( $self, $code, $file ) = @_;

    if (!defined($file)) { $file = $self->{file} };
    if (!defined($file)) { confess "Must provide filename"; }

    if ( defined( $self->{header_handler} ) ) {
        my $header = $_ = $self->_read_header($file);
        if ( defined($header) ) {
            $self->{header_handler}($header);
        }
    }

    my $procs = $self->{processes};

    if ($procs > 1) {
        my $wu = Parallel::WorkUnit->new();

        $wu->asyncs( $procs, sub { return $self->_map_chunk( $code, $file, $procs, $_[0] ); } );

        return map { @$_ } $wu->waitall();
    } else {
        my $mapped_lines = $self->_map_chunk( $code, $file, 1, 0 );

        return @$mapped_lines;
    }
}

#
# Method - lines
#
# Returns all lines in the file
sub lines {
    if (scalar(@_) < 1) { confess "Invalid call"; }
    my ($self, $file) = @_;

    if (!defined($file)) { $file = $self->{file} };
    if (!defined($file)) { confess "Must provide filename"; }

    my @lines;

    open my $fh, '<', $file or die($!);

    my $lineno;
    while (<$fh>) {
        $lineno++;
        chomp;

        if ( ($lineno == 1) && defined( $self->{header_handler} ) ) {
            $self->{header_handler}($_);
        } elsif ( ($lineno == 1) && $self->{header_skip} ) {
            # Do nothing;
        } else {
            push @lines, $_;
        }
    }

    close $fh;

    return @lines;
}

# Internal function to read header line
sub _read_header {
    my ($self, $file) = @_;

    my ( $fh, undef ) = _open_and_seek( $file, 1, 0 );
    my $line = <$fh>;
    close $fh;

    chomp($line) if defined $line;
    return $line;
}

# Internal function to perform a for loop on a single chunk of the file.
#
# Procs should be >= 1.  It represents the number of chunks the file
# has.
#
# Part should be >= 0 and < Procs.  It represents the zero-indexed chunk
# number this invocation is processing.
sub _forlines_chunk {
    my ( $self, $code, $file, $part ) = @_;

    my $procs = $self->{processes};
    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my $lineno = 0;
    while (<$fh>) {
        $lineno++;

        chomp;

        # Handle header option
        if ( ( !$part ) && ( $lineno == 1 ) && ( defined( $self->{header_handler} ) ) ) {
            # Do nothing, we're skipping the header.
        } elsif ( ( !$part ) && ( $lineno == 1 ) && ( $self->{header_skip} ) ) {
            # Do nothing, we're skipping the header.
        } else {
            $code->($_);
        }

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
    my ( $self, $code, $file, $procs, $part ) = @_;

    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my @lines;
    my $lineno = 0;
    while (<$fh>) {
        $lineno++;

        chomp;

        if ( (!$part) && ( $lineno == 1 ) && ( defined( $self->{header_handler} ) ) ) {
            $self->{header_handler}($_);
        } elsif ( (!$part) && ( $lineno == 1 ) && ( $self->{header_skip} ) ) {
            # Do nothing, we're skipping the header.
        } else {
            if ( $code->($_) ) {
                push @lines, $_;
            }
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
    my ( $self, $code, $file, $procs, $part ) = @_;

    my ( $fh, $end ) = _open_and_seek( $file, $procs, $part );

    my @mapped_lines;
    my $lineno = 0;
    while (<$fh>) {
        $lineno++;

        chomp;

        if ( (!$part) && ( $lineno == 1 ) && ( defined( $self->{header_handler} ) ) ) {
            $self->{header_handler}($_);
        } elsif ( (!$part) && ( $lineno == 1 ) && ( $self->{header_skip} ) ) {
            # Do nothing, we're skipping the header.
        } else {
            push @mapped_lines, $code->($_);
        }

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
        confess("Part Number must be less than number of parts");
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
    if ( scalar(@_) != 1 ) { confess 'invalid call'; }
    my $self = shift;

    require Parallel::WorkUnit
      or die("You must install Parallel::WorkUnit to use the parallel_* methods");

    if ( $Parallel::WorkUnit::VERSION < 1.117 ) {
        die( "Parallel::WorkUnit version 1.117 or newer required. You have "
              . $Parallel::WorkUnit::Version );
    }

    return;
}

# Validate something is code like
#
# Borrowed from Params::Util (written by Adam Kennedy)
sub _codelike {
    if ( scalar(@_) != 1 ) { confess 'invalid call' }
    my $thing = shift;

    if ( reftype($thing) ) { return 1; }
    if ( blessed($thing) & overload::Method( $thing, '()' ) ) { return 1; }

    return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ByLine::Object - Internal object used by File::ByLine

=head1 VERSION

version 1.181861

=head1 SEE File::ByLine

Please consult File::ByLine for user-level documentation.  This interface is
documented there.

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
