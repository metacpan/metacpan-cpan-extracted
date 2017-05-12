package ESPPlus::Storage;
use 5.006;
use strict;
use warnings;
use Carp 'confess';
use IO::File ();
use ESPPlus::Storage::Util;
use ESPPlus::Storage::Record;
use ESPPlus::Storage::Reader;
use ESPPlus::Storage::Writer;

use vars qw($VERSION);

$VERSION = '0.01';

BEGIN {
    for (qw(compress_function
	    uncompress_function
	    filename)) {
	attribute_builder( $_ );
    }
}

sub new {
    my $class = shift;
    my $p = shift;
    
    my $self = bless {}, $class;
    
    for my $param (qw(compress_function
		      uncompress_function
		      filename
		      handle)) {
	next unless exists $p->{$param};
	$self->{$param} = delete $p->{$param};
    }
    
    if (%$p) {
	confess "Invalid parameters " . join(', ', sort keys %$p)
	    . " to $class->new";
    }
    
    unless ($self->{'filename'} or $self->{'handle'}) {
	confess "You must provide either a filename or filehandle to "
	    . "$class->new";
    }
    
    # Be sure to kick off the file open if necessary
    $self->handle;

    return $self;
}

sub handle {
    my $self = shift;
    
    if (@_) {
	$self->{'handle'} = shift;
    }

    unless (exists $self->{'handle'}) {
	$self->{'handle'} = IO::File->new( $self->filename, 'r' );
    }
    
    return $self->{'handle'};
}

sub reader {
    my $self = shift;
    
    my $class = "${\ref $self}::Reader";
    
    return $class->new( { uncompress_function => $self->{'uncompress_function'},
			  handle => $self->handle } );
}

sub writer {
    my $self = shift;
    my $class = "${\ref $self}::Writer";
    
    return $class->new( { compress_function => $self->{'compress_function'},
			  handle => $self->handle } );
}


1;

__END__

=head1 NAME

ESPPlus::Storage - An interface to ESP+ Storage repository files

=head1 SYNOPSIS

  use ESPPlus::Storage;
  my $st = ESPPlus::Storage->new
      ( { filename => $Repository,
          uncompress_function => \&uncompress } );

=head1 DESCRIPTION

This module provides an interface to the ESP+ Storage repository files. It
allows you to read a .REP file as a series of original records. See 
L<ESPPlus::Storage::Reader::Tie> for an especially easy interface for reading
databases.

For an even easier interface, see L<ESPPlus::Storage::Reader::Tie>. It wraps
the interface described below and in L<ESPPlus::Storage::Reader> and
L<ESPPlus::Storage::Record>.

=head1 CONSTRUCTOR

=over 4

=item new

 $db = ESPPlus::Storage->new( { compress_function   => \ &compress,
                                uncompress_function => \ &uncompress,
                                ( $handle ? ( handle   => $handle ) :
                                            ( filename => $filename ) )
                            } )

This is the class constructor and it takes four optional arguments, two of
them contradictory. It returns a new C<ESPPlus::Storage> object. All of the
arguments are passed in data in a hash reference.

The C<compress_function> and C<uncompress_function> parameters both expect
code references. C<uncompress_function> is expected to accept a reference to
a .Z compressed string and is expected to return a reference to an uncompressed
string. This is required for reading .REP repository records.

C<compress_function> is the exact opposite, it is needed for writing to .REP
repositories, accepts a reference to uncompressed data and returns a reference
to .Z compressed data.

Currently there is no LZW implementation on L<www.cpan.org> so the current
expectation is that you will write a wrapper over /usr/bin/uncompress. A
sample wrapper is included farther down in the documentation.

The two parameters C<filename> and C<handle> are complementary. If you supply
only a filename then it will be opened for you otherwise pass in an already
opened handle to a .REP file via C<handle>.

=back

=head1 METHODS / PROPERTIES

=over 4

=item compress_function

When called without arguments it returns the C<ESPPlus::Storage> object's
stored C<compress_function> code reference. When called with a value, it saves
that as the new value.

 my $c = $db->compress_function;
 $db->compress_function( $new_c );

=item uncompress_function

When called without arguments it returns the C<ESPPlus::Storage> object's
stored C<uncompress_function> code reference. When called with a value, it
saves that as the new value.

 my $c = $db->uncompress_function;
 $db->uncompress_function( $new_c );

=item filename

When called without arguments it returns the C<ESPPlus::Storage> object's
stored C<filename>. When called with a value, it saves that as the new value.

 my $f = $db->filename;
 $db->filename( $new_f );

=item handle

When called without arguments it returns a stored C<IO::File> object if there
is one. If there isn't then it attempts to open one by using C<filename>.
When called with a value it saves that as the new value.

 my $h = $db->handle;
 $db->handle( $h );

=item reader

This returns a C<ESPPlus::Storage::Reader> object. This is what reads a .REP
database file.

=item writer

This returns a C<ESPPlus::Storage::Writer> object. This creates .REP database
files.

=back

=head2 UNCOMPRESS WRAPPER

 The following function is a sample implementation of a function suitable
 for passing into <uncompress_function>.

 our $TempFile = `mktemp /tmp/esp.XXX`;
 our $Uncompress = "/usr/bin/uncompress";
 sub uncompress {
     my $compressed = shift;
 
     {
         my $out = IO::File->new;
         sysopen $out, $TempFile, O_WRONLY
             or die "Couldn't open $TempFile: $!";
         flock $out, LOCK_EX
             or die "Couldn't get an exclusive lock on $TempFile: $!";
         truncate $out, 0
             or die "Couldn't truncate $TempFile: $!";
         binmode $out
             or die "Could binmode $TempFile: $!";
         print $out $$compressed
             or die "Couldnt write to $TempFile: $!";
         close $out
             or die "Couldn't close $TempFile: $!";
     }
 
     # add error processing as above
     my $in = IO::Handle->new;
     {
         my $sleep_count = 0;
         my $pid = open $in, "-|", $Uncompress, '-c', $TempFile
             or die "Can't exec $Uncompress: $!";
         unless (defined $pid) {
             warn "Cannot fork: $!";
             die "Bailing out" if $sleep_count++ > 6;
             sleep 10;
             redo;
         }
     }
 
     local $/;
     binmode $in or die "Couldn't binmode \$in: $!";
     my $uncompressed = <$in>;
     close $in or warn "$Uncompress exited $?";
 
     return \ $uncompressed;
 }

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SEE ALSO

L<ESPPlus::Storage::Reader>
L<ESPPlus::Storage::Reader::Tie>
L<ESPPlus::Storage::Writer>
L<ESPPlus::Storage::Record>

=cut
