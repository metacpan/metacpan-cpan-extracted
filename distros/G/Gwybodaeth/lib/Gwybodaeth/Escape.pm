#!/usr/bin/env perl

use strict;
use warnings;

package Gwybodaeth::Escape;

=head1 NAME

Escape - Escape characters with XML escapes

=head1 SYNOPSIS

    use Escape;

    my $e = Escape->new();

    $e->escape($string);

=head1 DESCRIPTION

This module escapes strings in preperation for putting in XML.

=over

=cut

use Carp qw(croak);
{

=item new()
    Returns an instance of the Escape class.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item escape()
    Escapes strings with XML escapes.

=cut

sub escape {
    ref(my $self = shift) or croak "instance variable needed";
    my $string = shift;

    # escape '&' chars.
    $string =~ s/&amp;
                # an ampersand
                /\&/xg;
    $string =~ s/
                # an ampersand
                \&
                /&amp;/xg; 
    
    chomp($string);

    return $string;
}

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
