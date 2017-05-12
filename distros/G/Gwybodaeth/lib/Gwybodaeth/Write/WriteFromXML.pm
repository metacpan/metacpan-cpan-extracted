#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Write::WriteFromXML;

=head1 NAME

Write::WriteFromXML - Writes data into RDF/XML which was in XML.

=head1 SYNOPSIS

    use WriteFromXML;

    my $w = WriteFromCSV->new();

    $w->write_rdf($map_data,$data);

=head1 DESCRIPTION

This module is subclassed from Write::Write and applies mapping to XML data.

=over

=item new()

Returns an instance of WriteFromXML;

=cut

use base qw(Gwybodaeth::Write);

use Carp qw(croak);

=item write_rdf($mapping_data,$data)

Applies $mapping_data to the array reference $data outputting RDF/XML.
$mapping_data is expected to be the output form Parsers::N3.

=cut

sub new {
    my $class = shift;
    my $self = { ids => {}, Data => qq{}};
    $self->{XML} = XML::Twig->new(pretty_print => 'nice');
    bless $self, $class;
    return $self;
}

sub write_rdf {
    ref(my $self = shift) 
        or croak "instance variable needed";
    my $triple_data = shift;
    my $data = shift;

    $self->_check_data($triple_data,$data,'XML::Twig');

    my $triples = $triple_data->[0]; 
    my $functions = $triple_data->[1];

    $self->_write_meta_data();
    for my $child ($data->root->children) {
        $self->_write_triples($child, $triple_data);
    }

    $self->_print2str("</rdf:RDF>\n");

    my $xml = $self->_structurize();

    $xml->print();

    return 1;
}

sub _write_triples {
    my($self, $row, $triple_data) = @_;

    my($triples, $functions) = @{ $triple_data };

    $self->_really_write_triples($row, $triples);

    for my $key (%{ $functions }) {
        $self->_really_write_triples($row, $functions->{$key},$key);
    }
    return 1;
}

# This is a subclass from Write.pm
sub _cat_field {
    my $self = shift;
    my $data = shift;
    my $field = shift;
    $field =~ s/Ex:/
                # substitute with an empty string
               /x;

    my $string = qq{};
    my $texts = [];

    my @values = split /\+/x, $field;

    for my $val (@values) {
        # Extract ${tag} variables from the data
        if ($val =~ m/\$    # $ sign
                    (       # start keyword scope
                    [\:\w]+ # multiple word or colon characters
                    \/?     # possible forward slash
                    [\:\w]* # any number of word or colon characters
                    )       # end keyword scope
                    /x) {
            push @{ $texts }, $self->_get_field($data,$1);
        }
        # Put a space; 
        elsif ($val =~ m/\'     # open single quote
                        \s*     # any number of whitespace chars
                        \'      # close single quote
                        /x) {
            push @{ $texts }, qq{ };
        } 
        # Print a literal
        else {
            push @{ $texts }, $val;
        }
    }
    return join q{}, @{ $texts };
}

sub _split_field {
    my($self, $data, $field) = @_;

    my @strings;
    
    if ($field =~ m/\@Split # on the split grammar
                    \(Ex:
                    \$      # $ sign - variable prefix
                    (       # begin keyword scope
                    [\:\w]+ # multiple word characters or colons 
                    \/?     # a possible forward slash
                    \w*     # any number of word chars
                    )       # end keyword scope
                    ,
                    "(.)"   # any character in quotes - the delimeter
                    \)/x) {
        my $keyword = $1;
        my $delimeter = $2;
        for my $node ($data->findnodes("$keyword")) {
            if (defined($node->text())) {
                push @strings, split /$delimeter/x,  $node->text();
            }
        }
        return \@strings;
    }

    return $field;
}

sub _get_field {
    my($self, $data, $keyword,$opt) = @_;

    my $texts = [];

    if (not defined($opt)) { $opt = qq{}; }

    for my $node ($data->findnodes("$keyword")) {
        if (defined($node->text())) {
            push @{ $texts }, $node->text().$opt;
        }
    }
    return $texts;
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
