#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Parsers::XML;

=head1 NAME

Parsers::XML - Base class for parsing XML data.

=head1 SYNOPSIS

    use base qw(XML);

=head1 DESCRIPTION

This module is a base class for XML parsing, and is intended to be subclassed.

=over

=item new()

Returns an instance of the Gwybodaeth::Parsers::XML class;

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
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
