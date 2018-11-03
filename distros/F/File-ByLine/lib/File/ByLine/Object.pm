#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

package File::ByLine::Object;
$File::ByLine::Object::VERSION = '1.183060';
use v5.10;

# ABSTRACT: Internal object used by File::ByLine

use strict;
use warnings;
use autodie;

use Carp;
use Fcntl;
use Scalar::Util qw(blessed reftype);

# We do this intentionally:
## no critic (Subroutines::ProhibitBuiltinHomonyms)

# Attributes and their accessors & defaults, used by the constructor
# Each attribute name is the key of the hash, with the value being a
# hashref of two values: accessor and default value.
my (%ATTRIBUTE) = (
    file             => [ \&file,             undef, ['f'] ],
    extended_info    => [ \&extended_info,    undef, ['ei'] ],
    header_all_files => [ \&header_all_files, undef, ['haf'] ],
    header_handler   => [ \&header_handler,   undef, ['hh'] ],
    header_skip      => [ \&header_skip,      undef, ['hs'] ],
    processes        => [ \&processes,        1,     ['p'] ],
    skip_unreadable  => [ \&skip_unreadable,  undef, ['su'] ],
);


#
# Attribute Accessor - file
#
sub f { goto &file }

sub file {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{file};
    } elsif ( scalar(@_) == 1 ) {
        my $file = shift;
        if ( !defined($file) ) { confess("Must pass a file or array ref as a file attribute") }
        return $self->{file} = $file;
    } else {
        return $self->{file} = [@_];
    }
}

#
# Attribute Accessor - extended_info
#
# Do we pass an extended information hash to the user process?
sub ei { goto &extended_info }

sub extended_info {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{extended_info};
    } elsif ( scalar(@_) == 1 ) {
        return $self->{extended_info} = !!$_[0];    # !! to convert to fast boolean
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - processes
#
# This is the degree of parallism we will attempt for most methods (the
# exception is "lines()")
sub p { goto &processes }

sub processes {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{processes};
    } elsif ( scalar(@_) == 1 ) {
        my $procs = shift;

        if ( !_is_number($procs) ) {
            confess("processes only accepts integer values");
        }

        if ( $procs < 1 ) {
            confess("Process count must be >= 1");
        }
        if ( $procs > 1 ) {
            # Ensure we have the right packages installed
            $self->_require_parallel();
        }
        return $self->{processes} = $procs;
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - header_all_files
#
# If set to one, process all files for headers
sub haf { goto &header_all_files }

sub header_all_files {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{header_all_files};
    } elsif ( scalar(@_) == 1 ) {
        return $self->{header_all_files} = $_[0];
    } else {
        confess("Invalid call");
    }
}

#
# Attribute Accessor - header_handler
#
# This is the code that handles the header line
sub hh { goto &header_handler }

sub header_handler {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{header_handler};
    } elsif ( scalar(@_) == 1 ) {
        my $code = shift;
        if ( defined($code) ) {
            if ( !_codelike($code) ) {
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
sub hs { goto &header_skip }

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
# Attribute Accessor - skip_unreadable
#
sub su { goto &skip_unreadable; }

sub skip_unreadable {
    my ($self) = shift;
    if ( scalar(@_) == 0 ) {
        return $self->{skip_unreadable};
    } elsif ( scalar(@_) == 1 ) {
        return $self->{skip_unreadable} = !!$_[0];    # !! to convert to fast boolean
    } else {
        confess("Invalid call");
    }
}

#
# Constructor
#
sub new {
    my $class = shift;

    my %options;
    if ( scalar(@_) == 1 ) {
        # We assume this to be a hashref of options
        %options = %{ $_[0] };
    } elsif ( scalar(@_) > 1 ) {
        if ( scalar(@_) % 2 ) {
            confess("Must pass options in key/value form or as a hashref");
        } else {
            %options = (@_);
        }
    }

    # Set defaults
    my $self = {};
    foreach my $attr ( keys %ATTRIBUTE ) {
        $self->{$attr} = $ATTRIBUTE{$attr}->[1];    # Default avlue
    }

    bless $self, $class;

    # Build abbreviation list
    my (%attr_short);
    foreach my $attr ( keys %ATTRIBUTE ) {
        foreach my $abbr ( @{ $ATTRIBUTE{$attr}->[2] } ) {
            $attr_short{$abbr} = $attr;             # Default avlue
        }
    }

    # Set attributes.  We use the accessor so we don't duplicate type
    # checks.
    my %set;    # Track set attributes
    foreach my $key ( sort keys %options ) {    # Sort for consistent tests
        if ( exists( $ATTRIBUTE{$key} ) ) {
            if ( exists( $set{$key} ) ) {
                confess("Duplicate attribute in constructor detected: $key");
            }

            my $value = $options{$key};

            # Call the accessor
            $ATTRIBUTE{$key}->[0]( $self, $value );
            $set{$key} = 1;                     # Mark as set
        } elsif ( exists( $attr_short{$key} ) ) {
            my $cannonical = $attr_short{$key};

            if ( exists( $set{$key} ) ) {
                confess("Duplicate attribute in constructor detected: $key");
            }

            my $value = $options{$key};

            # Call the accessor
            $ATTRIBUTE{$cannonical}->[0]( $self, $value );
            $set{$key} = 1;                     # Mark as set
        } else {
            confess("Invalid attribute: $key");
        }
    }

    return $self;
}

#
# Method - do
#
# Executes the provided code on every line.
#
sub do {
    if ( scalar(@_) < 2 ) { confess "Invalid call"; }
    my ( $self, $code, $file ) = @_;

    if ( !defined($file) )   { $file = $self->{file} }
    if ( !defined($file) )   { confess "Must provide filename"; }
    if ( !_listlike($file) ) { $file = [$file] }

    if ( defined( $self->{header_handler} ) ) {
        my $fileno = 0;
        for my $f (@$file) {
            $self->_read_header( $f, $fileno );
            $fileno++;
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
    if ( scalar(@_) < 2 ) { confess "Invalid call, too few arguments"; }
    if ( scalar(@_) > 3 ) { confess "Invalid call, too many arguments"; }
    my ( $self, $code, $file ) = @_;

    return $self->_grepmap( 'grep', $code, $file );
}

#
# Method - map
#
# Applies function to each entry and returns that result
sub map {
    if ( scalar(@_) < 2 ) { confess "Invalid call, too few arguments"; }
    if ( scalar(@_) > 3 ) { confess "Invalid call, too many arguments"; }
    my ( $self, $code, $file ) = @_;

    return $self->_grepmap( 'map', $code, $file );
}

# Does the actual processing for map/grep
sub _grepmap {
    if ( scalar(@_) < 3 ) { confess "Invalid call, too few arguments"; }
    if ( scalar(@_) > 4 ) { confess "Invalid call, too many arguments"; }
    my ( $self, $type, $code, $file ) = @_;

    if ( !defined($file) )   { $file = $self->{file} }
    if ( !defined($file) )   { confess "Must provide filename"; }
    if ( !_listlike($file) ) { $file = [$file] }

    if ( defined( $self->{header_handler} ) ) {
        my $fileno = 0;
        for my $f (@$file) {
            $self->_read_header( $f, $fileno );
            $fileno++;
        }
    }

    my $procs = $self->{processes};

    # Is this a MAP or a GREP?
    my $isgrep;
    if ( $type eq 'grep' ) {
        $isgrep = 1;
    } elsif ( $type eq 'map' ) {
        $isgrep = 0;
    } else {
        confess("Invalid type passed to _grepmap: $type");
    }

    if ( $procs > 1 ) {
        my $wu = Parallel::WorkUnit->new();

        $wu->asyncs( $procs,
            sub { return $self->_grepmap_chunk( $code, $file, $isgrep, $procs, $_[0] ); } );

        my @async_output = $wu->waitall();

        my @file_output;
        for ( my $i = 0; $i < scalar(@$file); $i++ ) {
            push @file_output, map { $_->[$i] } @async_output;
        }
        return map { @$_ } @file_output;
    } else {
        my $mapped_lines = $self->_grepmap_chunk( $code, $file, $isgrep, 1, 0 );

        return map { @$_ } @$mapped_lines;
    }

}

#
# Method - lines
#
# Returns all lines in the file
sub lines {
    if ( scalar(@_) < 1 ) { confess "Invalid call"; }
    my ( $self, $file ) = @_;

    if ( !defined($file) )   { $file = $self->{file} }
    if ( !defined($file) )   { confess "Must provide filename"; }
    if ( !_listlike($file) ) { $file = [$file] }

    my @lines;
    my $fileno = 0;
    my $lineno = 0;

    for my $f (@$file) {
        $fileno++;

        my $fh = $self->_open($f);
        if ( !defined($fh) ) { next; }    # Next file

        while (<$fh>) {
            $lineno++;
            chomp;

            if ( $lineno == 1 ) {
                if ( $self->_handle_header( $f, $_, 0, $fileno - 1 ) ) {
                    next;
                }
            }

            push @lines, $_;
        }

        close $fh;
    }

    return @lines;
}

# Internal function to read header line (if we need to)
sub _read_header {
    my ( $self, $file, $fileno ) = @_;

    my ( $fh, undef ) = $self->_open_and_seek( $file, 1, 0 );
    if ( !defined($fh) ) { return; }
    my $line = <$fh>;
    close $fh;

    if ( defined($line) ) {
        chomp($line);
        $self->_handle_header( $file, $line, 0, $fileno );
    }

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

    my $fileno        = 0;
    my $lineno        = 0;
    my $extended_info = $self->{extended_info};

    for my $f (@$file) {
        $fileno++;

        my $extended = $self->_extended( $f, $part );

        my $procs = $self->{processes};
        my ( $fh, $end ) = $self->_open_and_seek( $f, $procs, $part );
        if ( !defined($fh) ) { next; }    # Next file

        while (<$fh>) {
            $lineno++;

            chomp;

            if ( $lineno == 1 && $self->_handle_header( $f, $_, $part, $fileno - 1 ) ) {
                # Do nothing, we handled the header.
            } else {
                if ($extended_info) {
                    $code->( $_, $extended );
                } else {
                    $code->($_);
                }
            }

            # If we're reading multi-parts, do we need to end the read?
            if ( ( $end > 0 ) && ( tell($fh) > $end ) ) { last; }
        }

        close $fh;
    }

    return $lineno;
}

# Internal function to perform a map/grep on a single chunk of the file.
#
# Procs should be >= 1.  It represents the number of chunks the file
# has.
#
# Part should be >= 0 and < Procs.  It represents the zero-indexed chunk
# number this invocation is processing.
#
# isgrep = true if we want to just apply the code as a grep, not as a
# map.
sub _grepmap_chunk {
    my ( $self, $code, $file, $isgrep, $procs, $part ) = @_;

    my @mapped_lines;
    my $fileno        = 0;
    my $lineno        = 0;
    my $extended_info = $self->{extended_info};

    for my $f (@$file) {
        $fileno++;

        my $extended = $self->_extended( $f, $part );

        my ( $fh, $end ) = $self->_open_and_seek( $f, $procs, $part );
        if ( !defined($fh) ) { push @mapped_lines, []; next; }
        ;    # Go to next loop

        my @filelines;
        while (<$fh>) {
            $lineno++;

            chomp;

            if ( $lineno == 1 && $self->_handle_header( $f, $_, $part, $fileno - 1 ) ) {
                # Do nothing, we handled the header.
            } elsif ( ( !$part )
                && ( $fileno == 1 )
                && ( $lineno == 1 )
                && ( $self->{header_skip} ) )
            {
                # Do nothing, we're skipping the header.
            } else {
                if ($isgrep) {
                    if ($extended_info) {
                        if ( $code->( $_, $extended ) ) {
                            push @filelines, $_;
                        }
                    } else {
                        if ( $code->($_) ) {
                            push @filelines, $_;
                        }
                    }
                } else {
                    # We are doing a map
                    if ($extended_info) {
                        push @filelines, $code->( $_, $extended );
                    } else {
                        push @filelines, $code->($_);
                    }
                }
            }

            # If we're reading multi-parts, do we need to end the read?
            if ( ( $end > 0 ) && ( tell($fh) > $end ) ) { last; }
        }
        push @mapped_lines, \@filelines;

        close $fh;
    }

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
    if ( scalar(@_) != 4 ) { confess 'invalid call' }
    my ( $self, $file, $parts, $part_number ) = @_;

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

    my $fh = $self->_open($file);
    if ( !defined($fh) ) { return ( $fh, 0 ); }

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

sub _open {
    if ( scalar(@_) != 2 ) { confess 'invalid call'; }
    my ( $self, $file ) = @_;

    if ( ( !-r $file ) && $self->{skip_unreadable} ) {
        return;    # We don't give an error if skip_unreadable
    } elsif ( !-e _ ) {    # _ is file handle from last stat() call
        confess("File does not exist: $file");
    } elsif ( !-r _ ) {
        confess("File is unreadable: $file");
    }
    open my $fh, '<', $file or die $!;

    return $fh;
}

sub _require_parallel {
    if ( scalar(@_) != 1 ) { confess 'invalid call'; }
    my $self = shift;

    require Parallel::WorkUnit
      or die("You must install Parallel::WorkUnit to use the parallel_* methods");

    if ( $Parallel::WorkUnit::VERSION < 2.181850 ) {
        die( "Parallel::WorkUnit version 2.181850 or newer required. You have "
              . $Parallel::WorkUnit::Version );
    }

    return;
}

# Validate something is code like
#
# Borrowed/modified from Params::Util (written by Adam Kennedy)
sub _codelike {
    if ( scalar(@_) != 1 ) { confess 'invalid call' }
    my $thing = shift;

    if ( defined( reftype($thing) ) && ( reftype($thing) eq 'CODE' ) ) { return 1; }
    if ( blessed($thing) && overload::Method( $thing, '&{}' ) ) { return 1; }

    return;
}

sub _listlike {
    if ( scalar(@_) != 1 ) { confess 'invalid call' }
    my $thing = shift;

    if ( reftype($thing) ) { return 1; }
    if ( defined( blessed($thing) ) && overload::Method( $thing, '[]' ) ) { return 1; }

    return;
}

# Takes a hashref, key, and default value
# If the hashref item exists, returns the corresponding value.  If the hashref
# item does not exist, returns the default value.
sub _option_helper {
    if ( scalar(@_) != 3 ) { confess 'invalid call' }
    my ( $hash, $key, $default ) = @_;

    if ( exists( $hash->{$key} ) ) {
        return $hash->{$key};
    } else {
        return $default;
    }
}

sub _is_number {
    if ( scalar(@_) != 1 ) { confess 'invalid call' }
    my $val = shift;

    if ( !defined($val) ) { return; }

    return $val =~ /
            \A              # Start of string
            [0-9]+          # ASCII digit
            (?: \. 0+)?     # Optional .0 or .000 or .00000 etc
            \z              # End of string
        /sx;
}

# Returns an extended info object
sub _extended {
    if ( scalar(@_) != 3 ) { confess 'invalid call' }
    my ( $self, $filename, $process_number ) = @_;

    return {
        filename       => $filename,
        object         => $self,
        process_number => $process_number,
    };
}

# Executes the header_handler function when required, or skipps headers.
#
# This returns TRUE if there is a header to process.  FALSE otherwise
#
# This takes several parameters:
#   $self - This is an object method of course.
#   $filename = The filename being processed
#   $line - The line to process
#   $part - Which "part" is calling this (we always return FALSE and
#           refuse to process the header if $part > 0)
#   $fileno - Which file number are we on (start at zero)
#
# If header_skip is FALSE and header_handler is unset, this ALWAYS
# returns false.
#
# This should never be called except for the first line of a file
sub _handle_header {
    if ( scalar(@_) != 5 ) { confess 'invalid call' }
    my ( $self, $filename, $line, $part, $fileno ) = @_;

    if ($part) { return; }

    if ( ( !$self->header_skip() ) && ( !defined( $self->header_handler() ) ) ) {
        return;
    }

    if ( $fileno && ( !$self->header_all_files() ) ) {
        return;
    }

    # We have a header to process.
    if ( defined( $self->header_handler() ) ) {
        local $_ = $line;

        if ( $self->{extended_info} ) {
            my $extended = $self->_extended( $filename, $part );
            $self->{header_handler}( $line, $extended );
        } else {
            $self->{header_handler}($line);
        }
    }
    return 1;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ByLine::Object - Internal object used by File::ByLine

=head1 VERSION

version 1.183060

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
