package MARC::Parser::RAW;

use strict;
use warnings;
use utf8;

our $VERSION = "0.05";

use charnames qw< :full >;
use Carp qw(croak carp);
use Encode qw(find_encoding);
use English;
use Readonly;

Readonly my $LEADER_LEN         => 24;
Readonly my $SUBFIELD_INDICATOR => qq{\N{INFORMATION SEPARATOR ONE}};
Readonly my $END_OF_FIELD       => qq{\N{INFORMATION SEPARATOR TWO}};
Readonly my $END_OF_RECORD      => qq{\N{INFORMATION SEPARATOR THREE}};

=head1 NAME

MARC::Parser::RAW - Parser for ISO 2709 encoded MARC records

=begin markdown

[![Build Status](https://travis-ci.org/jorol/MARC-Parser-RAW.png)](https://travis-ci.org/jorol/MARC-Parser-RAW)
[![Coverage Status](https://coveralls.io/repos/jorol/MARC-Parser-RAW/badge.png?branch=devel)](https://coveralls.io/r/jorol/MARC-Parser-RAW?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/MARC-Parser-RAW.png)](http://cpants.cpanauthors.org/dist/MARC-Parser-RAW)

=end markdown

=head1 SYNOPSIS

    use MARC::Parser::RAW;

    my $parser = MARC::Parser::RAW->new( $file );

    while ( my $record = $parser->next() ) {
        # do something        
    }

=head1 DESCRIPTION

L<MARC::Parser::RAW> is a lightweight, fault tolerant parser for ISO 2709 
encoded MARC records. Tags, indicators and subfield codes are not validated 
against the MARC standard. Record length from leader and field lengths from 
the directory are ignored. Records with a faulty structure will be skipped 
with a warning. The resulting data structure is optimized for usage with the 
L<Catmandu> data tool kit.    

L<MARC::Parser::RAW> expects UTF-8 encoded files as input. Otherwise provide 
a filehande with a specified I/O layer or specify encoding.

=head1 MARC

The MARC record is parsed into an ARRAY of ARRAYs:

    $record = [
            [ 'LDR', undef, undef, '_', '00661nam  22002538a 4500' ],
            [ '001', undef, undef, '_', 'fol05865967 ' ],
            ...
            [   '245', '1', '0', 'a', 'Programming Perl /',
                'c', 'Larry Wall, Tom Christiansen & Jon Orwant.'
            ],
            ...
        ];


=head1 METHODS

=head2 new($file|$fh|$scalarref [, $encoding])

=head3 Configuration

=over

=item C<file>
 
Path to file with raw MARC records.

=item C<fh>

Open filehandle for raw MARC records.

=item C<scalarref>

Reference to scalar with raw MARC records.

=item C<encoding>

Set encoding. Default: UTF-8. Optional.

=back

=cut

sub new {
    my ( $class, $file, $encoding ) = @_;

    $file or croak "first argument must be a file or filehandle";

    if ($encoding) {
        find_encoding($encoding) or croak "encoding \"$_[0]\" not found";
    }

    my $self = {
        file       => undef,
        fh         => undef,
        encoding   => $encoding ? $encoding : 'UTF-8',
        rec_number => 0,
    };

    # check for file or filehandle
    # ToDo: check for scalar ref
    my $ishandle = eval { fileno($file); };
    if ( !$@ && defined $ishandle ) {
        $self->{file} = scalar $file;
        $self->{fh}   = $file;
    }
    elsif ( -e $file || ref($file) eq 'SCALAR' ) {
        open $self->{fh}, "<:encoding($self->{encoding})", $file
            or croak "cannot read from file $file\n";
        $self->{file} = $file;
    }
    else {
        croak "file or filehande $file does not exists";
    }
    return ( bless $self, $class );
}

=head2 next()

Reads the next record from MARC input stream. Returns a Perl hash.

=cut

sub next {
    my $self = shift;
    my $fh   = $self->{fh};
    local $INPUT_RECORD_SEPARATOR = $END_OF_RECORD;
    if ( defined( my $raw = <$fh> ) ) {
        $self->{rec_number}++;

        # remove illegal garbage that sometimes occurs between records
        $raw
            =~ s/^[\N{SPACE}\N{NUL}\N{LINE FEED}\N{CARRIAGE RETURN}\N{SUB}]+//;
        return unless $raw;

        if ( my $marc = $self->_decode($raw) ) {
            return $marc;
        }
        else {
            return $self->next();
        }
    }
    return;
}

=head2 _decode($record)

Deserialize a raw MARC record to an ARRAY of ARRAYs.

=cut

sub _decode {
    my ( $self, $raw ) = @_;
    chop $raw;
    my ( $head, @fields ) = split $END_OF_FIELD, $raw;

    if ( !@fields ) {
        carp "no fields found in record " . $self->{rec_number};
        return;
    }

    # ToDO: better RegEX for leader
    my $leader;
    if ( $head =~ /(.{$LEADER_LEN})/cg ) {
        $leader = $1;
    }
    else {
        carp "no valid record leader found in record " . $self->{rec_number};
        return;
    }

    my @tags = $head =~ /\G(\d{3})\d{9}/cg;

    if ( scalar @tags != scalar @fields ) {
        carp "different number of tags and fields in record "
            . $self->{rec_number};
        return;
    }

    if ( $head !~ /\G$/cg ) {
        carp "incomplete directory entry in record " . $self->{rec_number};
        return;
    }

    return [
        [ 'LDR', undef, undef, '_', $leader ],
        map [ shift(@tags), $self->_field($_) ],
        @fields
    ];
}

=head2 _field($field)

Split MARC field string in individual components.

=cut

sub _field {
    my ( $self, $field ) = @_;
    my @chunks = split( /$SUBFIELD_INDICATOR(.)/, $field );
    return ( undef, undef, '_', @chunks ) if @chunks == 1;
    my @subfields;
    my ( $indicator1, $indicator2 ) = ( split //, shift @chunks );
    while (@chunks) {
        push @subfields, ( splice @chunks, 0, 2 );
    }
    return ( $indicator1, $indicator2, @subfields );
}

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEEALSO

L<Catmandu>, L<Catmandu::Importer::MARC>.

=head1 ACKNOWLEDGEMENT

The parser methods are adapted from Marc Chantreux's L<MARC::MIR> module.

=cut

1;    # End of MARC::Parser::RAW

