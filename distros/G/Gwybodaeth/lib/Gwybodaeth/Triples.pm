#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Triples;

=head1 NAME

Triples - Stores triples as hashes keyed by subject.

=head1 SYNOPSIS

    use Triples;

    my $t = Triples->new();

    $t->store_triple($subject,$predicate,$object);

=head1 DESCRIPTION

This module provides a data structure which stores triples. The structure is a
hash keyed by the $subject:

$subject = {
            obj         => [],
            predicate   => []
           }

=over

=cut

use Carp qw(croak);
{

=item new()

Returns an instance of the class.

=cut

    sub new {
        my $class = shift;
        my $self = {};
        bless $self, $class;
        return $self;
    }

    # Stores the triple and returns a reference to itself    
    # Expects ($sbject, $predicate, $object) as parameters

=item store_triple($subject,$prediate,$object)

Stores $subject, $predicate and $object in the triples data structure. Returns
a refenece the data structure.

=cut

    sub store_triple {
        ref(my $self    = shift) or croak "instance variable needed";

        defined(my $subject     = shift) or croak "must pass a subject";
        defined(my $predicate   = shift) or croak "must pass a predicate";
        defined(my $object      = shift) or croak "must pass an object"; 

        # If this is the first time we've come accross $subject
        # we create a new hash key for it
        if (not defined($self->{$subject})) {
            $self->{$subject} = {
                                'obj' => [],
                                'predicate' => [],
                                };
        }

        push @{ $self->{$subject}{'obj'} }, $object;
        push @{ $self->{$subject}{'predicate'} }, $predicate;

        return $self;
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
