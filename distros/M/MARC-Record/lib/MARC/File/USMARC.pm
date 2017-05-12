package MARC::File::USMARC;

=head1 NAME

MARC::File::USMARC - USMARC-specific file handling

=cut

use strict;
use warnings;
use integer;

use vars qw( $ERROR );
use MARC::File::Encode qw( marc_to_utf8 );

use MARC::File;
use vars qw( @ISA ); @ISA = qw( MARC::File );

use MARC::Record qw( LEADER_LEN );
use MARC::Field;
use constant SUBFIELD_INDICATOR     => "\x1F";
use constant END_OF_FIELD           => "\x1E";
use constant END_OF_RECORD          => "\x1D";
use constant DIRECTORY_ENTRY_LEN    => 12;

=head1 SYNOPSIS

    use MARC::File::USMARC;

    my $file = MARC::File::USMARC->in( $filename );

    while ( my $marc = $file->next() ) {
        # Do something
    }
    $file->close();
    undef $file;

=head1 EXPORT

None.

=head1 METHODS

=cut

sub _next {
    my $self = shift;
    my $fh = $self->{fh};

    my $reclen;
    return if eof($fh);

    local $/ = END_OF_RECORD;
    my $usmarc = <$fh>;

    # remove illegal garbage that sometimes occurs between records
    $usmarc =~ s/^[ \x00\x0a\x0d\x1a]+//;

    return $usmarc;
}

=head2 decode( $string [, \&filter_func ] )

Constructor for handling data from a USMARC file.  This function takes care of
all the tag directory parsing & mangling.

Any warnings or coercions can be checked in the C<warnings()> function.

The C<$filter_func> is an optional reference to a user-supplied function
that determines on a tag-by-tag basis if you want the tag passed to it
to be put into the MARC record.  The function is passed the tag number
and the raw tag data, and must return a boolean.  The return of a true
value tells MARC::File::USMARC::decode that the tag should get put into
the resulting MARC record.

For example, if you only want title and subject tags in your MARC record,
try this:

    sub filter {
        my ($tagno,$tagdata) = @_;

        return ($tagno == 245) || ($tagno >= 600 && $tagno <= 699);
    }

    my $marc = MARC::File::USMARC->decode( $string, \&filter );

Why would you want to do such a thing?  The big reason is that creating
fields is processor-intensive, and if your program is doing read-only
data analysis and needs to be as fast as possible, you can save time by
not creating fields that you'll be ignoring anyway.

Another possible use is if you're only interested in printing certain
tags from the record, then you can filter them when you read from disc
and not have to delete unwanted tags yourself.

=cut

sub decode {

    my $text;
    my $location = '';

    ## decode can be called in a variety of ways
    ## $object->decode( $string )
    ## MARC::File::USMARC->decode( $string )
    ## MARC::File::USMARC::decode( $string )
    ## this bit of code covers all three

    my $self = shift;
    if ( ref($self) =~ /^MARC::File/ ) {
        $location = 'in record '.$self->{recnum};
        $text = shift;
    } else {
        $location = 'in record 1';
        $text = $self=~/MARC::File/ ? shift : $self;
    }
    my $filter_func = shift;

    # ok this the empty shell we will fill
    my $marc = MARC::Record->new();

    # Check for an all-numeric record length
    ($text =~ /^(\d{5})/)
        or return $marc->_warn( "Record length \"", substr( $text, 0, 5 ), "\" is not numeric $location" );

    my $reclen = $1;
    my $realLength = bytes::length( $text );
    $marc->_warn( "Invalid record length $location: Leader says $reclen " . 
        "bytes but it's actually $realLength" ) unless $reclen == $realLength;

    (substr($text, -1, 1) eq END_OF_RECORD)
        or $marc->_warn( "Invalid record terminator $location" );

    $marc->leader( substr( $text, 0, LEADER_LEN ) );

    # bytes 12 - 16 of leader give offset to the body of the record
    my $data_start = 0 + bytes::substr( $text, 12, 5 );

    # immediately after the leader comes the directory (no separator)
    my $dir = substr( $text, LEADER_LEN, $data_start - LEADER_LEN - 1 );  # -1 to allow for \x1e at end of directory

    # character after the directory must be \x1e
    (substr($text, $data_start-1, 1) eq END_OF_FIELD)
        or $marc->_warn( "No directory found $location" );

    # all directory entries 12 bytes long, so length % 12 must be 0
    (length($dir) % DIRECTORY_ENTRY_LEN == 0)
        or $marc->_warn( "Invalid directory length $location" );


    # go through all the fields
    my $nfields = length($dir)/DIRECTORY_ENTRY_LEN;
    for ( my $n = 0; $n < $nfields; $n++ ) {
        my ( $tagno, $len, $offset ) = unpack( "A3 A4 A5", substr($dir, $n*DIRECTORY_ENTRY_LEN, DIRECTORY_ENTRY_LEN) );

        # Check directory validity
        ($tagno =~ /^[0-9A-Za-z]{3}$/)
            or $marc->_warn( "Invalid tag in directory $location: \"$tagno\"" );

        ($len =~ /^\d{4}$/)
            or $marc->_warn( "Invalid length in directory $location tag $tagno: \"$len\"" );

        ($offset =~ /^\d{5}$/)
            or $marc->_warn( "Invalid offset in directory $location tag $tagno: \"$offset\"" );

        ($offset + $len <= $reclen)
            or $marc->_warn( "Directory entry $location runs off the end of the record tag $tagno" );

        my $tagdata = bytes::substr( $text, $data_start+$offset, $len ); 

        # if utf8 the we encode the string as utf8
        if ( $marc->encoding() eq 'UTF-8' ) {
            $tagdata = marc_to_utf8( $tagdata );
        }

        $marc->_warn( "Invalid length in directory for tag $tagno $location" )
            unless ( $len == bytes::length($tagdata) );

        if ( substr($tagdata, -1, 1) eq END_OF_FIELD ) {
            # get rid of the end-of-tag character
            chop $tagdata;
            --$len;
        } else {
            $marc->_warn( "field does not end in end of field character in tag $tagno $location" );
        }

        warn "Specs: ", join( "|", $tagno, $len, $offset, $tagdata ), "\n" if $MARC::Record::DEBUG;

        if ( $filter_func ) {
            next unless $filter_func->( $tagno, $tagdata );
        }

        if ( MARC::Field->is_controlfield_tag($tagno) ) {
            $marc->append_fields( MARC::Field->new( $tagno, $tagdata ) );
        } else {
            my @subfields = split( SUBFIELD_INDICATOR, $tagdata );
            my $indicators = shift @subfields;
            my ($ind1, $ind2);

            if ( length( $indicators ) > 2 or length( $indicators ) == 0 ) {
                $marc->_warn( "Invalid indicators \"$indicators\" forced to blanks $location for tag $tagno\n" );
                ($ind1,$ind2) = (" ", " ");
            } else {
                $ind1 = substr( $indicators,0, 1 );
                $ind2 = substr( $indicators,1, 1 );
            }

            # Split the subfield data into subfield name and data pairs
            my @subfield_data;
            for ( @subfields ) {
                if ( length > 0 ) {
                    push( @subfield_data, substr($_,0,1),substr($_,1) );
                } else {
                    $marc->_warn( "Entirely empty subfield found in tag $tagno" );
                }
            }

            if ( !@subfield_data ) {
                $marc->_warn( "no subfield data found $location for tag $tagno" );
                next;
            }

            my $field = MARC::Field->new($tagno, $ind1, $ind2, @subfield_data );
            if ( $field->warnings() ) {
                $marc->_warn( $field->warnings() );
            }
            $marc->append_fields( $field );
        }
    } # looping through all the fields


    return $marc;
}

=head2 update_leader()

If any changes get made to the MARC record, the first 5 bytes of the
leader (the length) will be invalid.  This function updates the
leader with the correct length of the record as it would be if
written out to a file.

=cut

sub update_leader {
        my $self = shift;

        my (undef,undef,$reclen,$baseaddress) = $self->_build_tag_directory();

        $self->_set_leader_lengths( $reclen, $baseaddress );
}

=head2 _build_tag_directory()

Function for internal use only: Builds the tag directory that gets
put in front of the data in a MARC record.

Returns two array references, and two lengths: The tag directory, and the data fields themselves,
the length of all data (including the Leader that we expect will be added),
and the size of the Leader and tag directory.

=cut

sub _build_tag_directory {
        my $marc = shift;
        $marc = shift if (ref($marc)||$marc) =~ /^MARC::File/;
        die "Wanted a MARC::Record but got a ", ref($marc) unless ref($marc) eq "MARC::Record";

        my @fields;
        my @directory;

        my $dataend = 0;
        for my $field ( $marc->fields() ) {
                # Dump data into proper format
                my $str = $field->as_usmarc;
                push( @fields, $str );

                # Create directory entry
                my $len = bytes::length( $str );

                my $direntry = sprintf( "%03s%04d%05d", $field->tag, $len, $dataend );
                push( @directory, $direntry );
                $dataend += $len;
        }

        my $baseaddress =
                LEADER_LEN +    # better be 24
                ( @directory * DIRECTORY_ENTRY_LEN ) +
                                # all the directory entries
                1;              # end-of-field marker


        my $total =
                $baseaddress +  # stuff before first field
                $dataend +      # Length of the fields
                1;              # End-of-record marker



        return (\@fields, \@directory, $total, $baseaddress);
}

=head2 encode()

Returns a string of characters suitable for writing out to a USMARC file,
including the leader, directory and all the fields.

=cut

sub encode {
    my $marc = shift;
    $marc = shift if (ref($marc)||$marc) =~ /^MARC::File/;

    my ($fields,$directory,$reclen,$baseaddress) = _build_tag_directory($marc);
    $marc->set_leader_lengths( $reclen, $baseaddress );

    # Glomp it all together
    return join("",$marc->leader, @$directory, END_OF_FIELD, @$fields, END_OF_RECORD);
}
1;

__END__

=head1 RELATED MODULES

L<MARC::Record>

=head1 TODO

Make some sort of autodispatch so that you don't have to explicitly
specify the MARC::File::X subclass, sort of like how DBI knows to
use DBD::Oracle or DBD::Mysql.

Create a toggle-able option to check inside the field data for
end of field characters.  Presumably it would be good to have
it turned on all the time, but it's nice to be able to opt out
if you don't want to take the performance hit.

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 AUTHOR

Andy Lester, C<< <andy@petdance.com> >>

=cut

