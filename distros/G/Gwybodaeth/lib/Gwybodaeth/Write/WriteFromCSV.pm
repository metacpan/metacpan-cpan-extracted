#!/usr/bin/env perl

use warnings;
use strict;

use lib q{.};

package Gwybodaeth::Write::WriteFromCSV;

=head1 NAME

Write::WriteFromCSV - Write data into RDF/XML which was in CSV.

=head1 SYNOPSIS

    use WriteFromCSV;

    my $w = WriteFromCSV->new();

    $w->write_rdf($triples_data,$data);

=head1 DESCRIPTION

This module is subclassed from Write::Write and applies mapping to CSV data.

=over

=item new()

Returns an instance of WriteFromCSV.

=cut

use base 'Gwybodaeth::Write';

use Carp qw(croak);

sub new {
    my $class = shift;
    my $self = { ids => {}, Data => qq{}};
    $self->{XML} = XML::Twig->new(pretty_print => 'nice' );
    bless $self, $class;
    return $self;
}

=item write_rdf($mapping_data, $data)

Applies $mapping_data to the array reference $data outputting RDF/XML.
$mapping_data is expected to be the output from Parsers::N3.

=cut

sub write_rdf {
    ref(my $self = shift) or croak "instance variable needed";
    my $triple_data = shift;
    my $data = shift;

    # Check cleanliness of input data types 
    $self->_check_data($triple_data,$data,'ARRAY');

    my $triples = ${ $triple_data }[0];
    my $functions = ${ $triple_data }[1]; 

    my @pure_data;
    my($start,$end);

    $start = 1;
    $end   = $#{ $data };

    # Record any start end end point we are given.
    # This allows the interpreter to skip unwanted rows.
    for my $row (0..$#{ $data }) {
        if (@{$data}[$row]->[0] =~ m/start\s+row/mix) {
            $start = int @{$data}[$row]->[1] - 1;       # Subtract 1 because
                                                        # arrays start at 0.
        }
        if (@{ $data }[$row]->[0] =~ m/end\s+row/mix) {
            $end = int @{ $data }[$row]->[1] - 1;       # Subtract 1 because
                                                        # arrays start at 0.
            last;
        }
    }       

    for ($start..$end) {
        push @pure_data, @{ $data }[$_];
    }

    $self->_write_meta_data();

    for my $row (@pure_data) {
        $self->_really_write_triples($row,$triples);
    }

    my %ids;

    # The %functions hash is tied to InsertOrderHash so the keys will be
    # given in the order they entered the hash. This gives the correct
    # precedence ordering. 
    for my $key ( keys %{ $functions }) {
        for my $row (@pure_data) {
            my $id = $self->_extract_field($row,$key);
            next if (exists $ids{$id});
            $ids{$id} = qq{};
            $self->_really_write_triples($row, $functions->{$key},$key);
        }
    }

    $self->_print2str("</rdf:RDF>");

    my $twig = $self->_structurize;
    $twig->print();

    return 1;
}

sub _get_field {
    my($self, $row, $field, $opt) = @_;

    if (not defined($opt)) { $opt = qq{}; }

    # We subtract 1 as arrays start at 0, and spreadsheets at 1
    return @{ $row }[$field - 1] . $opt;
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
