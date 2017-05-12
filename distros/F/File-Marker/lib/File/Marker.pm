use 5.006;
use strict;
use warnings;

package File::Marker;
# ABSTRACT: Set and jump between named position markers on a filehandle
our $VERSION = '0.14'; # VERSION

our @ISA = qw( IO::File );

use Carp;
use IO::File;
use Scalar::Util 1.09 qw( refaddr weaken );

#--------------------------------------------------------------------------#
# Inside-out data storage
#--------------------------------------------------------------------------#

my %MARKS = ();

# Track objects for thread-safety

my %REGISTRY = ();

#--------------------------------------------------------------------------#
# new()
#--------------------------------------------------------------------------#

sub new {
    my $class = shift;
    my $self  = IO::File->new();
    bless $self, $class;
    weaken( $REGISTRY{ refaddr $self } = $self );
    $self->open(@_) if @_;
    return $self;
}

#--------------------------------------------------------------------------#
# open()
#--------------------------------------------------------------------------#

sub open {
    my $self = shift;
    $MARKS{ refaddr $self } = {};
    $self->SUPER::open(@_);
    $MARKS{ refaddr $self }{'LAST'} = $self->getpos;
    return 1;
}

#--------------------------------------------------------------------------#
# set_marker()
#--------------------------------------------------------------------------#

sub set_marker {
    my ( $self, $mark ) = @_;

    croak "Can't set marker on closed filehandle"
      if !$self->opened;

    croak "Can't set special marker 'LAST'"
      if $mark eq 'LAST';

    my $position = $self->getpos;

    croak "Couldn't set marker '$mark': couldn't locate position in file"
      if !defined $position;

    $MARKS{ refaddr $self }{$mark} = $self->getpos;

    return 1;
}

#--------------------------------------------------------------------------#
# goto_marker()
#--------------------------------------------------------------------------#

sub goto_marker {
    my ( $self, $mark ) = @_;

    croak "Can't goto marker on closed filehandle"
      if !$self->opened;

    croak "Unknown file marker '$mark'"
      if !exists $MARKS{ refaddr $self}{$mark};

    my $old_position = $self->getpos; # save for LAST

    my $rc = $self->setpos( $MARKS{ refaddr $self }{$mark} );

    croak "Couldn't goto marker '$mark': could not seek to location in file"
      if !defined $rc;

    $MARKS{ refaddr $self }{'LAST'} = $old_position;

    return 1;
}

#--------------------------------------------------------------------------#
# markers()
#--------------------------------------------------------------------------#

sub markers {
    my $self = shift;
    return keys %{ $MARKS{ refaddr $self } };
}

#--------------------------------------------------------------------------#
# save_markers()
#--------------------------------------------------------------------------#

sub save_markers {
    my ( $self, $filename ) = @_;
    my $outfile = IO::File->new( $filename, "w" )
      or croak "Couldn't open $filename for writing";
    my $markers = $MARKS{ refaddr $self };
    for my $mark ( keys %$markers ) {
        next if $mark eq 'LAST';
        print $outfile "$mark\n";
        print $outfile unpack( "H*", $markers->{$mark} ), "\n";
    }
    close $outfile;
}

#--------------------------------------------------------------------------#
# load_markers()
#--------------------------------------------------------------------------#

sub load_markers {
    my ( $self, $filename ) = @_;
    my $infile = IO::File->new( $filename, "r" )
      or croak "Couldn't open $filename for reading";
    my $markers = $MARKS{ refaddr $self };
    my $mark;
    while ( defined( $mark = <$infile> ) ) {
        chomp $mark;
        my $position = <$infile>;
        chomp $position;
        $position = pack( "H*", $position );
        $markers->{$mark} = $position;
    }
    close $infile;
}

#--------------------------------------------------------------------------#
# DESTROY()
#--------------------------------------------------------------------------#

sub DESTROY {
    my $self = shift;
    delete $MARKS{ refaddr $self };
    delete $REGISTRY{ refaddr $self };

    $self->SUPER::DESTROY;
}

#--------------------------------------------------------------------------#
# CLONE()
#--------------------------------------------------------------------------#

sub CLONE {
    for my $old_id ( keys %REGISTRY ) {

        # look under old_id to find the new, cloned reference
        my $object = $REGISTRY{$old_id};
        my $new_id = refaddr $object;

        # relocate data
        $MARKS{$new_id} = $MARKS{$old_id};
        delete $MARKS{$old_id};

        # update the weak reference to the new, cloned object
        weaken( $REGISTRY{$new_id} = $object );
        delete $REGISTRY{$old_id};
    }

    return;
}

#--------------------------------------------------------------------------#
# _object_count() -- used in test scripts to see if memory is leaking
#--------------------------------------------------------------------------#

sub _object_count {
    return scalar keys %REGISTRY;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Marker - Set and jump between named position markers on a filehandle

=head1 VERSION

version 0.14

=head1 SYNOPSIS

 use File::Marker;

 my $fh = File::Marker->new( 'datafile.txt' );

 my $line1 = <$fh>;           # read a line
 $fh->set_marker( 'line2' );  # mark the current position
 my @rest = <$fh>;            # slurp the remainder
 $fh->goto_marker( 'line2' ); # jump back to the marked position
 my $line2 = <$fh>;           # read another line

=head1 DESCRIPTION

File::Marker allows users to set named markers for the current position in
a filehandle and then later jump back to a marked position.  A
File::Marker object is a subclass of L<IO::File>, providing full filehandle
object functionality.

File::Marker automatically sets a special, reserved marker, 'LAST', when it
jumps to a marker, allowing an easy return to a former position.

This module was written as a demonstration of the inside-out object technique
for the NY Perl Seminar group.  It is intended for teaching purposes and has 
not been tested in production code. 

=head1 USAGE

=head2 new

 my $fh = new();
 my $fh = new( @args );

Creates and returns a File::Marker object.  If arguments are provided, they are
passed to open() before the object is returned.  This mimics the behavior of
IO::File.

=head2 open

 $fh->open( FILENAME [,MODE [,PERMS]] )
 $fh->open( FILENAME, IOLAYERS )

Opens a file for use with the File::Marker object.  Arguments are passed
directly to IO::File->open().  See IO::File for details.  Returns true if
successful and dies on failure.

=head2 set_marker

 $fh->set_marker( $marker_name );

Creates a named marker corresponding to the current position in the file.
Dies if the filehandle is closed, if the position cannot be determined, or
if the reserved marker name 'LAST' is used.  Using the same name as an
existing marker will overwrite the existing marker position.

=head2 goto_marker

 $fh->goto_marker( $marker_name );

Seeks to the position in the file corresponding to the given marker name.
Dies if the filehandle is closed, if the marker name is unknown, or if the
seek fails.  

The reserved marker name 'LAST' corresponds to the location in the file prior
to the most recent call to goto_marker on the object. For example:

 # starts at location X in the file
 $fh->goto_marker( 'one' );  # seek to location Y marked by 'one'
 $fh->goto_marker( 'LAST' ); # seek back to X
 $fh->goto_marker( 'LAST' ); # seek back to Y

If there have been no prior calls to goto_marker, 'LAST' will seek to the 
beginning of the file.

=head2 markers

 @list = $fh->markers();

Returns a list of markers that have been set on the object, including 'LAST'.

=head2 save_markers

 $fh->save_markers( $marker_filename );

Saves the current list of markers (excluding 'LAST') to the given filename.

=head2 load_markers

 $fh = File::Marker->new( 'datafile.txt' );
 $fh->load_markers( $marker_filename );

Loads markers from a previously-saved external file.  Will overwrite any

=head1 LIMITATIONS

As with all inside-out objects, File::Marker is only thread-safe (including
Win32 pseudo-forks) for Perl 5.8 or better, which supports the CLONE subroutine.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/dagolden/File-Marker/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/dagolden/File-Marker>

  git clone https://github.com/dagolden/File-Marker.git

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
