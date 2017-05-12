#---------------------------------------------------------------------
package MARC::Utils::MARC2MARC_in_JSON;

use 5.008002;
use strict;
use warnings;
use Carp;

our $VERSION = '0.05';

our (@ISA, @EXPORT_OK);
BEGIN {
    require Exporter;
    @ISA = qw(Exporter);
    @EXPORT_OK = qw( marc2marc_in_json marc_in_json2marc each_record );
}

use MARC::Record;
use JSON;  # decode_json()

#---------------------------------------------------------------------
sub marc2marc_in_json {
    my( $marc_record ) = @_;

    my %marc_in_json;

    for my $leader ( $marc_record->leader() ) {
        $marc_in_json{'leader'} = $leader;
    }

    for my $field ( $marc_record->fields() ) {

        my $ftag = $field->tag();

        if( $field->is_control_field() ) {
            push @{$marc_in_json{'fields'}}, { $ftag => $field->data() };
        }

        else {
            my $fdata;

            for my $i ( 1, 2 ) {
                $fdata->{"ind$i"} = $field->indicator( $i )
            }

            for my $subfield ( $field->subfields ) {
                push @{$fdata->{'subfields'}}, { $subfield->[0] => $subfield->[1] };
            }

            push @{$marc_in_json{'fields'}}, { $ftag => $fdata };
        }
    }

    \%marc_in_json;  # returned
}

#---------------------------------------------------------------------
sub marc_in_json2marc {
    my( $marc_in_json ) = @_;

    my $marc_record = MARC::Record->new();

    for my $leader ( $marc_in_json->{'leader'} ) {
        $marc_record->leader( $leader );
    }

    for my $field ( @{$marc_in_json->{'fields'}} ) {
        my( $ftag, $fdata ) = %$field;

        if( ref $fdata ) {
            my @subfields;
            for my $subfield ( @{$fdata->{'subfields'}} ) {
                my( $sftag, $sfdata ) = %$subfield;
                push @subfields, $sftag, $sfdata;
            }
            $marc_record->append_fields( MARC::Field->new(
                $ftag, $fdata->{'ind1'}, $fdata->{'ind2'}, @subfields ) );
        }

        # control field
        else {
            $marc_record->append_fields( MARC::Field->new( $ftag, $fdata ) );
        }
    }

    $marc_record;  #returned
}

#---------------------------------------------------------------------
sub each_record {
    my( $filename, $declared_filetype ) = @_;
    
    open my $fh, '<', $filename or croak "Can't open $filename: $!";

    # examine beginning of file to determine its type

    my $first_line = <$fh>;
    my( $filetype, $recsep );

    for( $first_line ) {
        if( /^\[/ ) {
            $filetype = 'collection';
            if( /^\[\n$/ ) {
                my $second_line = <$fh>;
                if( $second_line eq "\n" ) {
                    $filetype = 'collection-delimited';
                    $recsep = "\n\n";
                }
            }
        }
        elsif( /^{/ )  #vi}
        {
            if( $declared_filetype and
                $declared_filetype eq 'ndj' ) {  # newline delimited json
                $filetype = $declared_filetype;
                $recsep   = "\n";
            }
            else {
                $filetype = 'object';
            }
        }
        else {
            $filetype = 'delimited';
            $recsep = "\n$_";
        }
    }

    croak "File doesn't match file type: $filename, $declared_filetype vs. $filetype"
        if $declared_filetype and $declared_filetype ne $filetype;

    if( $filetype =~ /^object|collection$/ ) {

        seek $fh, 0, 0;  # rewind to top
        local $/;

        my $json_items = decode_json( <$fh> );  # slurp
        $json_items = [$json_items] if $filetype eq 'object';
        my $index = 0;

        # "get_next" closure
        return sub {
            return if $index > $#$json_items;
            return $json_items->[ $index ++ ];
        };

    }

    elsif( $filetype =~ /delimited$/ ) {

        # "get_next" closure
        return sub {
            local $/ = $recsep;
            my $text = <$fh>;
            return unless defined $text;
            return unless $text =~ /^\s*{/;
            chomp $text;
            $text =~ s/,\s*$//;
            return decode_json $text;
        };

    }

    elsif( $filetype eq 'ndj' ) {

        seek $fh, 0, 0;  # rewind to top

        # "get_next" closure
        return sub {
            local $/ = $recsep;
            my $text = <$fh>;
            return unless defined $text;
            return unless $text =~ /^\s*{/;
            chomp $text;
            $text =~ s/,\s*$//;  # just in case
            return decode_json $text;
        };

    }

    else {
        croak "Unrecognized file type: $filename";
    }

}

1;

__END__

=head1 NAME

MARC::Utils::MARC2MARC_in_JSON - Perl module that provides routines to
convert from a MARC::Record object to a MARC-in-JSON hash structure.

=head1 SYNOPSIS

    use MARC::Utils::MARC2MARC_in_JSON qw( marc2marc_in_json marc_in_json2marc each_record);

    $marc_in_json = marc2marc_in_json( $marc_record );
    $marc_record  = marc_in_json2marc( $marc_in_json );

    my $get_next = each_record( "marc.json" );
    while( my $record = $get_next->() ) {
        print get_title( $record );  # you write get_title()
    }

=head1 DESCRIPTION

MARC::Utils::MARC2MARC_in_JSON - Perl module that provides routines to
convert from a MARC::Record object to a MARC-in-JSON hash structure as
described here:

http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/

Note that I did I<not> say we were converting to JSON (though the name
may seem to imply that).  Instead, we are converting to a hash
structure that is the same as you would get if you deserialized JSON
text (in MARC-in-JSON format) to perl.

If you indeed want JSON, then you can simply use the JSON module to
convert the hash.

The each_record() subroutine returns a closure that itself returns
a MARC_in_JSON structure each time it's called.  It is designed to
be a proof-of-concept for my JSON Document Streaming proposal:

http://en.wikipedia.org/wiki/User:Baxter.brad/Drafts/JSON_Document_Streaming_Proposal

=head1 SEE ALSO

MARC::Record
JSON

=head1 AUTHOR

Brad Baxter, E<lt>bbaxter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Brad Baxter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

