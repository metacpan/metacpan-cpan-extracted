package MARC::File::MicroLIF;

=head1 NAME

MARC::File::MicroLIF - MicroLIF-specific file handling

=cut

use strict;
use warnings;
use integer;
use vars qw( $ERROR );

use MARC::File;
use vars qw( @ISA ); @ISA = qw( MARC::File );

use MARC::Record qw( LEADER_LEN );

=head1 SYNOPSIS

    use MARC::File::MicroLIF;

    my $file = MARC::File::MicroLIF->in( $filename );

    while ( my $marc = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 EXPORT

None.

=cut


=for internal

The buffer must be large enough to handle any valid record because
we don't check for cases like a CR/LF pair or an end-of-record/CR/LF
trio being only partially in the buffer.

The max valid record is the max MARC record size (99999) plus one
or two characters per tag (CR, LF, or CR/LF).  It's hard to say
what the max number of tags is, so here we use 6000.  (6000 tags
can be squeezed into a MARC record only if every tag has only one
subfield containing a maximum of one character, or if data from
multiple tags overlaps in the MARC record body.  We're pretty safe.)

=cut

use constant BUFFER_MIN => (99999 + 6000 * 2);

=head1 METHODS

=head2 in()

Opens a MicroLIF file for reading.

=cut

sub in {
    my $class = shift;
    my $self = $class->SUPER::in( @_ );

    if ( $self ) {
        bless $self, $class;

        $self->{exhaustedfh} = 0;
        $self->{inputbuf} = '';
        $self->{header} = undef;

        # get the MicroLIF header, but handle the case in
        # which it's missing.
        my $header = $self->_get_chunk( 1 );
        if ( defined $header ) {
            if ( $header =~ /^LDR/ ) {
                # header missing, put this back
                $self->_unget_chunk( $header . "\n" );

                # XXX should we warn of a missing header?
            }
            else {
                $self->{header} = $header;
            }
        }
        else {
            # can't read from the file
            undef $self;
        }
    }

    return $self;
} # new


# fill the buffer if we need to
sub _fill_buffer {
    my $self = shift;
    my $ok = 1;

    if ( !$self->{exhaustedfh} && length( $self->{inputbuf} ) < BUFFER_MIN ) {
        # append the next chunk of bytes to the buffer
        my $read = read $self->{fh}, $self->{inputbuf}, BUFFER_MIN, length($self->{inputbuf});
        if ( !defined $read ) {
            # error!
            $ok = undef;
            $MARC::File::ERROR = "error reading from file " . $self->{filename};
        }
        elsif ( $read < 1 ) {
            $self->{exhaustedfh} = 1;
        }
    }

    return $ok;
}


=for internal

Gets the next chunk of data.  If C<$want_line> is true then you get
the next chunk ending with any combination of \r and \n of any length.
If it is false or not passed then you get the next chunk ending with
\x60 followed by any combination of \r and \n of any length.

All trailing \r and \n are stripped.

=cut

sub _get_chunk {
    my $self = shift;
    my $want_line = shift || 0;

    my $chunk = undef;

    if ( $self->_fill_buffer() && length($self->{inputbuf}) > 0 ) {

        # the buffer always has at least one full line in it, so we're
        # guaranteed that if there are no line endings then we're
        # on the last line.

        if ( $want_line ) {
            if ( $self->{inputbuf} =~ /^([^\x0d\x0a]*)([\x0d\x0a]+)/ ) {
                $chunk = $1;
                $self->{inputbuf} = substr( $self->{inputbuf}, length($1)+length($2) );
            }
        }
        else {
            # couldn't figure out how to make this work as a regex
            my $pos = -1;
            while ( !$chunk ) {
                $pos = index( $self->{inputbuf}, '`', $pos+1 );
                last if $pos < 0;
                if ( substr($self->{inputbuf}, $pos+1, 1) eq "\x0d" or substr($self->{inputbuf}, $pos+1, 1) eq "\x0a" ) {
                    $chunk = substr( $self->{inputbuf}, 0, $pos+1 ); # include the '`' but not the newlines
                    while ( substr($self->{inputbuf}, $pos+1, 1) eq "\x0d" or substr($self->{inputbuf}, $pos+1, 1) eq "\x0a" ) {
                        ++$pos;
                    }
                    # $pos now pointing at last newline char
                    $self->{inputbuf} = substr( $self->{inputbuf}, $pos+1 );
                }
            }
        }

        if ( !$chunk ) {
            $chunk = $self->{inputbuf};
            $self->{inputbuf} = '';
            $self->{exhaustedfh} = 1;
        }
    }

    return $chunk;
}


# $chunk is put at the beginning of the buffer exactly as
# passed in.  No line endings are added.
sub _unget_chunk {
    my $self = shift;
    my $chunk = shift;
    $self->{inputbuf} = $chunk . $self->{inputbuf};
    return;
}


sub _next {
    my $self = shift;

    my $lifrec = $self->_get_chunk();

    # for ease, make the newlines match this platform
    $lifrec =~ s/[\x0a\x0d]+/\n/g if defined $lifrec;

    return $lifrec;
}


=head2 header()

If the MicroLIF file has a file header then the header is returned.
If the file has no header or the file has not yet been opened then
C<undef> is returned.

=cut

sub header {
    my $self = shift;
    return $self->{header};
}

=head2 decode()

Decodes a MicroLIF record and returns a USMARC record.

Can be called in one of three different ways:

    $object->decode( $lif )
    MARC::File::MicroLIF->decode( $lif )
    MARC::File::MicroLIF::decode( $lif )

=cut

sub decode {
    my $self = shift;
    my $location = '';
    my $text = '';

    ## decode can be called in a variety of ways
    ## this bit of code covers all three

    if ( ref($self) =~ /^MARC::File/ ) {
        $location = 'in record '.$self->{recnum};
        $text = shift;
    } else {
        $location = 'in record 1';
        $text = $self=~/MARC::File/ ? shift : $self;
    }

    my $marc = MARC::Record->new();

    # for ease, make the newlines match this platform
    $text =~ s/[\x0a\x0d]+/\n/g if defined $text;

    my @lines = split( /\n/, $text );
    for my $line ( @lines ) {

        ($line =~ s/^([0-9A-Za-z]{3})//) or
            $marc->_warn( "Invalid tag number: ".substr( $line, 0, 3 )." $location" );
        my $tagno = $1;

        ($line =~ s/\^`?$//)
            or $marc->_warn( "Tag $tagno $location is missing a trailing caret." );

        if ( $tagno eq "LDR" ) {
            $marc->leader( substr( $line, 0, LEADER_LEN ) );
        } elsif ( $tagno =~ /^\d+$/ and $tagno < 10 ) {
            $marc->add_fields( $tagno, $line );
        } else {
            $line =~ s/^(.)(.)//;
            my ($ind1,$ind2) = ($1,$2);
            my @subfields;
            my @subfield_data_pairs = split( /_(?=[a-z0-9])/, $line );
            if ( scalar @subfield_data_pairs < 2 ) {
                $marc->_warn( "Tag $tagno $location has no subfields--discarded." );
            }
            else {
                shift @subfield_data_pairs; # Leading _ makes an empty pair
                for my $pair ( @subfield_data_pairs ) {
                    my ($subfield,$data) = (substr( $pair, 0, 1 ), substr( $pair, 1 ));
                    push( @subfields, $subfield, $data );
                }
                $marc->add_fields( $tagno, $ind1, $ind2, @subfields );
            }
        }
    } # for

    return $marc;
}

1;

__END__

=head1 TODO

=over 4

=back

=head1 RELATED MODULES

L<MARC::File>

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut

