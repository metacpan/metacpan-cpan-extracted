package MARC::Parser::XML;

use strict;
use warnings;
use 5.008_005;
our $VERSION = '0.03';

use Carp qw(croak);
use XML::LibXML::Reader;

sub new {
    my ( $class, $input ) = @_;

    my $self = bless { input => $input, rec_number => 0, }, $class;

    # check for file or filehandle
    my $ishandle = eval { fileno($input); };
    if ( !$@ && defined $ishandle ) {
        binmode $input;    # drop all PerlIO layers, as required by libxml2
        my $reader = XML::LibXML::Reader->new( IO => $input )
            or croak "cannot read from filehandle $input\n";
        $self->{xml_reader} = $reader;
    }
    elsif ( defined $input && $input !~ /\n/ && -e $input ) {
        my $reader = XML::LibXML::Reader->new( location => $input )
            or croak "cannot read from file $input\n";
        $self->{xml_reader} = $reader;
    }
    elsif ( defined $input && length $input > 0 ) {
        $input = ${$input} if ( ref($input) // '' eq 'SCALAR' );
        my $reader = XML::LibXML::Reader->new( string => $input )
            or croak "cannot read XML string $input\n";
        $self->{xml_reader} = $reader;
    }
    else {
        croak "file, filehande or string $input does not exists";
    }
    return $self;
}

sub next {
    my ($self) = @_;

    return
        unless $self->{xml_reader}
        ->nextElement( 'record', 'http://www.loc.gov/MARC21/slim' );

    if ( my $record = $self->_decode() ) {
        return $record;
    }
    else {
        return $self->next;
    }

    return;
}

sub _decode {
    my ($self) = @_;
    my @record;

    foreach my $field_node (
        $self->{xml_reader}->copyCurrentNode(1)->getChildrenByTagName('*') )
    {

        if ( $field_node->localName =~ m/leader/ ) {
            push @record,
                [ 'LDR', undef, undef, '_', $field_node->textContent ];
        }
        elsif ( $field_node->localName =~ m/controlfield/ ) {
            push @record,
                [
                $field_node->getAttribute('tag'), undef,
                undef,                            '_',
                $field_node->textContent
                ];
        }
        elsif ( $field_node->localName eq 'datafield' ) {
            push @record,
                [
                $field_node->getAttribute('tag'),
                $field_node->getAttribute('ind1') // '',
                $field_node->getAttribute('ind2') // '',
                map { $_->getAttribute('code'), $_->textContent }
                    $field_node->getChildrenByTagName('*')
                ];
        }
    }
    return \@record;
}

1;
__END__

=encoding utf-8

=head1 NAME

MARC::Parser::XML - Parser for MARC XML records

=begin markdown
 
[![Build Status](https://travis-ci.org/jorol/MARC-Parser-XML.png)](https://travis-ci.org/jorol/MARC-Parser-XML)
[![Coverage Status](https://coveralls.io/repos/github/jorol/MARC-Parser-XML/badge.png?branch=devel)](https://coveralls.io/github/jorol/MARC-Parser-XML?branch=devel)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/MARC-Parser-XML.png)](http://cpants.cpanauthors.org/dist/MARC-Parser-XML)
 
=end markdown

=head1 SYNOPSIS

    use MARC::Parser::XML;

    my $parser = MARC::Parser::XML->new( 't/marc.xml' );

    while ( my $record = $parser->next() ) { 
        # do something ...
    }

=head1 DESCRIPTION

MARC::Parser::XML is a lightweight, fault tolerant parser for MARC XML records. Tags, indicators and subfield codes are not validated against the MARC standard. The resulting data structure is optimized for usage with the Catmandu data tool kit.

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
 
=head2 new($file|$fh|$xml)

=head3 Configuration
 
=over
 
=item C<file>
  
Path to file with MARC XML records.
 
=item C<fh>
 
Open filehandle for MARC XML records.
 
=item C<xml>
 
XML string.
 
=back

=head2 next()
 
Reads the next record from MARC input.

=head2 _decode($record)
 
Deserialize a raw MARC record to an ARRAY of ARRAYs.

=head1 AUTHOR

Johann Rolschewski E<lt>jorol@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2016- Johann Rolschewski

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
