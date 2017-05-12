#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Write::WriteFromUsgsXML;

=head1 NAME

Gwybodaeth::Write::WriteFromUsgsXML - Writes data into RDF/XML from USGS XML
feeds.

=head1 SYNOPSIS

    use Gwybodaeth::Write::WriteFromeUsgsXML;

    my $w = Gwybodaeth::Write::WriteFromUsgsXML;
    
    $w->write_rdf($map_data,$data);

=head1 DESCRIPTION

This module is subclassed from Gwybodaeth::Write::WriteFromXML and applies
mapping to USGS XML feed data.

=over
=cut
use base qw(Gwybodaeth::Write::WriteFromXML);

use Carp qw(croak);

=item write_rdf($mapping_data, $data)

Applies $mapping_data to the array reference $data outputting RDF/XML.
$mapping_data is expected to be the output form Parsers::N3.

=cut

sub write_rdf {
    ref(my $self = shift) or croak "instance variable needed";
    my $triple_data = shift;
    my $data = shift;

    $self->_check_data($triple_data,$data,'XML::Twig');

    my $triples = $triple_data->[0]; 
    my $functions = $triple_data->[1];

    eval { $data->isa('XML::Twig'); }
        or croak "The input data is not XML";

    $self->_write_meta_data();
    for my $child ($data->root->children('entry')) {
        $self->_write_triples($child, $triple_data);
    }

    $self->_print2str("</rdf:RDF>\n");

    my $xml = $self->_structurize();

    $xml->print();

    return 1;
}
1;
__END__

=back

=head1 AUTHOR

Iestyn Pryce, <imp25@cam.ac.uk>

=head1 ACKNOWLEDGEMENTS

I'd like to thank the Ensemble project (L<www.ensemble.ac.uk>) for funding me to work on this project in the summer of 2009.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Iestyn Pryce <imp25@cam.ac.uk>

This library is free software; you can redistribute it and/or modify it under
the terms of the BSD license.
