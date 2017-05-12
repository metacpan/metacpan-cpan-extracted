#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Parsers::GeoNamesXML;

=head1 NAME

Parsers::GeoNamesXML - Parses XML from GeoNames.org into a data structure.

=head1 SYNOPSIS

    use GeoNamesXML;

    my $g = GeoNamesXML->new();

    $g->parse(@data);

=head1 DESCRIPTION

This module parses XML data from GeoNames.org into an XMLTwig data structure.

=over

=cut

use Carp qw{croak};
use XML::Twig;

# Inherit from Gwybodaeth::Parsers::XML class
use base 'Gwybodaeth::Parsers::XML';

=item parse(@data)

Parses an array of lines from @data returning a XMLTwig instance.

=cut

sub parse {
    my($self, @data) = @_;
   
    ref($self) or croak "instance variable expected";

    my $xml = XML::Twig->new();

    my $string;
    for my $line (@data) {
        $string .= $line;
    }

    if($xml->safe_parse($string)) {
        return $xml;
    }

    # if we've reached here something has gone wrong, return a fail
    return 0;
}
1;
__END__

=back

=head2 Inherited from Parsers::XML

=over

=item new()

    Returns an instance of the class.

=back

=head1 AUTHOR

Iestyn Pryce, <imp25@cam.ac.uk>

=head1 ACKNOWLEDGEMENTS

I'd like to thank the Ensemble project (L<www.ensemble.ac.uk>) for funding me to work on this project in the summer of 2009.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Iestyn Pryce <imp25@cam.ac.uk>

This library is free software; you can redistribute it and/or modify it under
the terms of the BSD license.
