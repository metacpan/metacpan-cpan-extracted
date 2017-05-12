#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Parsers::CSV;

=head1 NAME

Parsers::CSV - Parses CSV into a data structure.

=head1 SYNOPSIS

    use CSV;

    my $csv = CSV->new();

    $csv->parse(@data);

=head1 DESCRIPTION

This module parses CSV documents into a data structure. This structure is an array of arrays.

=over

=cut

use Carp qw(croak);
use Text::CSV;

=item new()

Returns an instance of the Parsers::CSV class.

=cut

sub new {
    my $class = shift;
    my $self = { quote_char => '"',
                 sep_char => ',' };
    bless $self, $class;
    return $self;
}

=item parse(@data)

Takes a CSV as an array of lines and outputs an array reference 
to an array of arrays.

=cut 

sub parse {
    my($self, @data) = @_;

    ref($self) or croak "instance variable needed";

    my @rows;
    my $i;
    my $csv = Text::CSV->new( {binary => 1, 
                               quote_char => $self->{quote_char},
                               sep_char => $self->{sep_char} 
                            } );
    
    for my $row (@data) {
        if ($csv->parse($row)) {
            my @fields = $csv->fields();
            $rows[$i++] = \@fields;
        } else {
            croak "unable to parse row: " . $csv->error_input . "\n".
                  "Are you sure this is CSV data?";
        }
    }

    return \@rows;
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
