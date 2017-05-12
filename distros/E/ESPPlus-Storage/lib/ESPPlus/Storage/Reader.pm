package ESPPlus::Storage::Reader;
use 5.006;
use strict;
use warnings;
use Carp 'confess';
use ESPPlus::Storage::Util;

use vars qw($COMPRESS_MAGIC_NUMBER
	    $BLOCK_SIZE
	    $MAX_BUFFER_SIZE
	    $MIN_BUFFER_SIZE);

$COMPRESS_MAGIC_NUMBER = "\037\235";

#our $BASE_RECORD =
#    q[(?x:
#       \\A # Start at the beginning
#
#       ((?xs:.+?))
#       # Capture the .Z binary record. It is known to be $L characters 
#       # uncompressed so I'm using 0 -> $L as the size restriction.    
#
#       # Insert a tail condition here. Either match the next header or 
#       # the end of string if the buffer and file are exhausted.       
#       )];
#
#our $CONTINUED_RECORD =
#    do {
#	use re 'eval';
#	qr( $BASE_RECORD
#	    # Find the header for the next section but don't remove it.
#	    H=(\d+);
#	    # The number after H indicates how many bytes the header is. The
#	    # expression should now look for $+ - length("H=$+;") characters
#	    # that match [[:print:]] followed by a .Z magic number or the
#	    # end of the string if the source filehandle is at eof().
#	    
#	    (??{ "(?s:.{".($+ - length "H=$+;")."})$COMPRESS_MAGIC_NUMBER" })
#	    )x;
#    };
#
#our $LAST_RECORD = qr[$BASE_RECORD\z];

$BLOCK_SIZE = 2 ** 13;
$MAX_BUFFER_SIZE = 128 * $BLOCK_SIZE;
$MIN_BUFFER_SIZE = 8 * $BLOCK_SIZE;


BEGIN {
    for (qw(handle
	    record_number)) {
	attribute_builder( $_, 'read only' );
    }
    
    attribute_builder( 'uncompress_function' );
}

sub new {
    my $class = shift;
    my $p     = shift;
    my $self  = bless {}, $class;
    
    $self->{'record_number'} = 0;
    my $_buffer = '';
    $self->{'_buffer'} = \ $_buffer;

    for my $param (qw[uncompress_function
		      handle]) {
	unless ( exists $p->{$param} ) {
	    confess "Required parameter $param wasn't provided";
	}
	
	$self->{$param} = delete $p->{$param};
    }
    
    return $self;
}

sub buffer {
    my $self = shift;
    my $handle = $self->{'handle'};
    my $buffer = $self->{'_buffer'};

    if ( eof $handle and not length $$buffer ) {
	return;
    }
    
    if (length $$buffer < $MIN_BUFFER_SIZE) {
	my $read_bytes = int
	    ( ($MAX_BUFFER_SIZE - length($$buffer))
	      / $BLOCK_SIZE ) * $BLOCK_SIZE;
	
	read( $handle,
	      $$buffer,
	      $read_bytes,
	      length $$buffer );
    }
    
    return $buffer;
}

sub next_record_body {
    my $self = shift;

    my $record = $self->next_record;
    
    return $record->body if $record;
    return;
}

sub next_record {
    my $self = shift;
    my $buffer = $self->buffer;
    my $rec_num = ++$self->{'record_number'};
    
    return unless $buffer;
    unless ($$buffer =~ m/^H=(?>\d+);/) {
	confess
	    "$rec_num was missing the header prefix m/^H=\\d+;/: $$buffer";
    }
    
    my $header_length = substr $$buffer, 2, $+[0]-3;
    
    # Remove the header
    my $header_text = substr $$buffer, 0, $header_length, '';
    
    my $record_body;
    if ( $$buffer =~ /H=(?>\d+);/ and
	 $COMPRESS_MAGIC_NUMBER eq
	 substr( $$buffer,
		 $-[0] + substr($$buffer,$-[0]+2,$+[0]-$-[0]-3),
		 length($COMPRESS_MAGIC_NUMBER) ) ) {
	
	# Capture everything before the first header-looking thing.
	$record_body = substr $$buffer, 0, $-[0], '';
    } elsif ( eof $self->{'handle'} ) {
	
	# Since a header wasn't found, I'm expecting that the database is
	# at the end.
	$record_body = $$buffer;
	$$buffer = '';
    } else {
	
	confess("Er!");
    }
    
    return
	ESPPlus::Storage::Record->new
	( { header_text         => \ $header_text,
	    compressed          => \ $record_body,
	    uncompress_function =>   $self->{'uncompress_function'},
	    record_number       =>   $rec_num } );
}

1;

__END__

=head1 NAME

ESPPlus::Storage::Reader - Reads ESP+ Storage repository files

=head1 SYNOPSIS

 use ESPPlus::Storage;
 my $st = ESPPlus::Storage->new
     ( { filename => $Repository,
         uncompress_function => \&uncompress } );
 my $rd = $st->reader;
 
 local *RC;
 while ( my $record = $rd->next_record_body ) {
     my $filename = $rd->record_number() . ".met";
     open RC, ">", $filename or die "Couldn't open $filename for writing: $!";
     print RC $$record;
     close RC;
 }

=head1 DESCRIPTION

C<ESPPlus::Storage::Reader> provides some methods for reading an ESP+ Storage
.REP repository database. In general the expectation is that you will read
the database serially - start with the first record and continue pulling
until there are no more records left. You can alter this by seeking on the
internal C<handle> and changing the C<record_number>.

Please also see L<ESPPlus::Storage> for a sample C<uncompress> wrapper
function.

L<ESPPlus::Storage::Reader::Tie> provides an alternate and even easier
reader interface.

=head1 CONSTRUCTOR

=over 4

=item new

 $rd = ESPPlus::Storage::Reader->new(
     { uncompress_function => \&uncompress,
       handle              => $io_file_handle } );

The new() method has exactly two parameters, both of which are required. In
normal operation the C<ESPPlus::Storage::Reader->new> method is only used
internally by C<ESPPlus::Storage> objects.

C<uncompress_function> (as noted on L<ESPPlus::Storage>) is a reference to
a function which is expected to receive a reference to a .Z compressed string
and should return a reference to an uncompressed string.

C<handle> is an already opened L<IO::File> object.

=back

=head1 METHODS / PROPERTIES

=over 4

=item next_record

This is the primary focus of this module. It returns a
C<ESPPlus::Storage::Record> object for the next record in the ESP+ Storage
.REP repository. You should call this method every time you need the next
object.

 while( my $rc_obj = $d->next_record ) {
     # ...
 }

=item next_record_body

This returns a reference to the uncompressed content of the next record. In
contrast to C<next_record>, this doesn't return a C<ESPPlus::Storage::Record>
object.

 while( my $rc = $d->next_record_body ) {
     # ...
 }

=item handle

This returns the internal C<IO::Handle>. If you seek or read from the handle
be sure to set the reader object's C<record_number> value appropriately and
flush the internal buffer in C<-E<gt>{'_buffer'}>. If you do that, you are
responsible for ensuring that both _buffer and the IO::Handle are correctly
set.

=item record_number

Returns the current record number.

=item uncompress_function

Returns the .Z uncompress function. See the L<ESPPlus::Storage> page for a
sample function you can use.

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2003, Joshua b. Jore. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

a) the GNU General Public License as published by the Free Software
   Foundation; version 2, or

b) the "Artistic License" which comes with Perl.

=head1 SEE ALSO

L<ESPPlus::Storage::Reader::Tie>
L<ESPPlus::Storage>
L<ESPPlus::Storage::Record>

=cut
