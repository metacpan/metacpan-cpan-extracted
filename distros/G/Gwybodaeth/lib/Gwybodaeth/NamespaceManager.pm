#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::NamespaceManager;

=head1 NAME

NamespaceManager - parses and stores namespaces for gwybodaeth

=head1 SYNOPSIS

    use NamespaceManager;

    my $nm = NamespaceManager->new();

    $nm->map_namespace($data);
    $nm->get_namspace_hash();

=head1 DESCRIPTION

This module stores namespace data and makes these available as a hash.

=over

=cut 

use Carp qw(croak);

# A hash to store all the namespaces
my %namespace;
# Default for $base set to an empty string.
# This will be interpreted as 'this document'.
my $base = "";

=item new()

Returns an instance of the NamespaceManager class.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item map_namespace($data)

Takes an array reference $data, and maps any namespaces declared into a hash.
Returns a refence to this hash. It also stores any @base elements found.

=cut

sub map_namespace {
    ref(my $self = shift) or croak "instance variable needed";
    my $data = shift;   # A referece to the data

    # Clear what may already be in %namespace from a previous run
    for (keys %namespace) { delete $namespace{$_}; };
    # Clear what may have been in $base from a previous run
    $base = "";

    for my $line (@{ $data }) {
        if ($line =~ m/^\@prefix    # string begins with a @prefix grammar
                        \s+
                        (\S*:)      # zero or more non whitespace chars
                                    # followed by a colon - namespace key
                        \s+
                        <           # open angle bracket
                        (\S+)       # one or more non whitepace chars
                                    # - namespace value
                        >           # close angle bracket  
                        \s+
                        .
                        /x) {
            $namespace{$1} = $2;
        }
        if ($line =~ m/^\@base      # string begins with a @base grammar
                        \s+
                        <([^>]*)>   # angle brackets enclosed by any non
                                    # closing angle bracket chars - base
                        \s+
                        .           # any non \n char
                        \s*
                        $/x) {
            $base = $1;
        }
    }
    return $self->get_namespace_hash();
}

=item get_namespace_hash()

Returns a hash reference to a hash containing mapped namespaces.

=cut

sub get_namespace_hash {
    ref(my $self = shift) or croak "instance variable needed";

    return \%namespace;
}

=item get_base()

Returns a reference to the base of the document.

=cut

sub get_base {
    ref(my $self = shift) or croak "instance variable needed";

    return \$base;
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
