package Lido::XML;

our $VERSION = '0.07';

use Moo;
use Lido::XML::LIDO_1_0;
use Lido::XML::Error;
use XML::Compile;
use XML::Compile::Cache;
use XML::Compile::Schema;
use XML::Compile::Util 'pack_type';
use Try::Tiny;

has 'namespace' => (is => 'ro' , default => sub {'http://www.lido-schema.org'});
has 'root'      => (is => 'ro' , default => sub {'lido'});
has 'prefixes'  => (is => 'ro' , default => sub {
                      [
                        'lido' => 'http://www.lido-schema.org',
                        'doc' => 'http://www.mda.org.uk/spectrumXML/Documentation',
                        'gml' => 'http://www.opengis.net/gml',
                        'xsd' => 'http://www.w3.org/2001/XMLSchema',
                        'xml' => 'http://www.w3.org/XML/1998/namespace'
                      ]
                    });

has 'reader'    => (is => 'ro');
has 'writer'    => (is => 'ro');

sub BUILD {
    my ($self) = @_;

    my @schemes = Lido::XML::LIDO_1_0->new->content;
    my $schema  = XML::Compile::Cache->new(\@schemes);
    my $type    = pack_type $self->namespace, $self->root;

    $self->{reader} = $schema->compile(READER => $type);
    $self->{writer} = $schema->compile(WRITER => $type, ( prefixes => $self->prefixes ) );

    $schema = undef;
}

sub parse {
    my ($self,$input) = @_;
    my $perl;
    try {
        $perl = $self->reader->($input);
    } catch {;
        Lido::XML::Error->throw(sprintf('%s', $_));
    };
    $perl;
}

sub to_xml {
    my ($self,$data) = @_;
    my $doc    = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $xml;
    try {
        $xml    = $self->writer->($doc, $data);
    } catch {
        Lido::XML::Error->throw(sprintf('%s', $_));
    };
    $doc->setDocumentElement($xml);
    $doc->toString(1);
}

1;

__END__

=head1 NAME

Lido::XML - A Lido XML parser and writer

=begin markdown

# Status

[![Build Status](https://travis-ci.org/LibreCat/Lido-XML.png)](https://travis-ci.org/LibreCat/Lido-XML)
[![Coverage Status](https://coveralls.io/repos/LibreCat/Lido-XML/badge.png)](https://coveralls.io/r/LibreCat/Lido-XML)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/Lido-XML.png)](http://cpants.cpanauthors.org/dist/Lido-XML)

=end markdown

=head1 SYNOPSIS

    use Lido::XML

    my $lido = Lido::XML->new;

    my $perl = $lido->parse($xml_file);

    my $xml  = $lido->to_xml($perl);

=head1 DESCRIPTION

LIDO is an XML Schema for Contributing Content to Cultural Heritage Repositories.
The Lido::XML parser is a software tool that understands the Lido Schema and can
parse the content of Lido XML files into a Perl hash and back.

=head1 DISCLAIMER

 * I'm not a LIDO expert.
 * This project was created as part of the L<Catmandu> project as an example how to create a XML parser based on a known XSD Schema.
 * All the heavy work is done by the excellent L<XML::Compile> package.
 * I invite other developers to contribute to this code.

=head1 CONFIGURATION

=over

=item new

Create a new Lido processor

=back

=head1 METHODS

=over

=item parse( $file | $string )

Create a Perl hash out of a Lido input.

=item to_xml( $perl );

Transform a Perl hash back into a Lido XML record

=back

=head1 AUTHORS

Patrick Hochstenbach, C<< patrick.hochstenbach at ugent.be >>

=head1 CONTRIBUTORS

Matthias Vandermaesen

Pieter De Praetere

=head1 COPYRIGHT AND LICENSE

The Perl software is copyright (c) 2016 by Patrick Hochstenbach.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

All included LIDO schemas carry an Open Geospacial Group OGC license:

Copyright (c) 2016 Open Geospatial Consortium, Inc. All Rights Reserved L<http://www.opengeospatial.org/ogc/Document>.

=encoding utf8

=cut
