#!/usr/bin/env perl

use warnings;
use strict;

use Gwybodaeth::NamespaceManager;
use Gwybodaeth::Triples;
use Gwybodaeth::Tokenize;

package Gwybodaeth::Parsers::N3;

=head1 NAME

Parsers::N3 - Parses N3 into a data structure.

=head1 SYNOPSIS

    use N3;

    my $n3 = N3->new();

    $n3->parse(@data);

=head1 DESCRIPTION

This module converts N3 data into a data structure.

=over

=cut

use Carp qw(croak);
use Tie::InsertOrderHash;

=item new()

Returns an instance of the N3 class.

=cut

sub new {
    my $class = shift;
    my $self = { triples => Gwybodaeth::Triples->new() };
    tie my %func => 'Tie::InsertOrderHash';
    $self->{functions} = \%func;
    bless $self, $class;
    return $self;
}

=item parse(@data)

Parses N3 from an array of rows, @data. Returns an array where the 
first item is a reference to a hash of triples and the second item
is a reference to a hash of functions.

=cut

sub parse {
    my($self, @data) = @_;

    ref($self) or croak "instance variable needed";

    my $subject;

    # Record the namespaces
    my $namespace = Gwybodaeth::NamespaceManager->new();
    $namespace->map_namespace(\@data);

    my $tokenizer = Gwybodaeth::Tokenize->new();
    my $tokenized = $tokenizer->tokenize(\@data);

    $self->_parse_n3($tokenized);

    $self->_parse_triplestore($self->{triples}) 
        or croak "function population went wrong";

    return [$self->{triples},$self->{functions}];
}

# Expects a reference to the tokenized data as a parameter
sub _parse_n3 {
    my $self = shift;
    my $data = shift;
    my $index_start = shift || 0;

    for( my $indx = $index_start; $indx <= $#{ $data }; ++$indx ) {

        my $token = ${ $data }[$indx];
        #my $next_token = ${ $data }[$indx+1 % $#{ $data }];
        my $next_token = ${ $data }[$indx+1];

        my $subject;

        if ($token =~ m/
                        # whole string matches @prefix
                        ^\@prefix$/x) {
            # logic
            next;
        }

        if ($token =~ m/
                        # whole string matches @base
                        ^\@base$/x) {
            #logic
            next;
        }

        # Shorthands for common predicates
        if ($token =~ m/
                        # whole string matches: a
                        ^a$/x) {
            # Should return a reference to a Triples type
            $self->_parse_triple($data, $indx);
            next;
        }

        if ($token =~ m/
                        # whole string matches only: =
                        ^\=$/x) {
            #logic
            next;
        }

        if ($token =~ m/
                        # whole string matches only: <=
                        ^\<\=$/x) {
            # logic
            next;
        }

        if ($token =~ m/
                        # whole string matches only: =>
                        ^\=\>$/x) {
            #logic
            next;
        }
        # end of predicate shorthands

        if ($token =~ m/\<  # open angle bracket
                        \s* # any number of whitespace chars
                        Ex: #
                        .*  # any number of any char except '\n'
                        \>  # close angle bracket/x) {
            # record the next block as a 'function'
            if ($next_token =~ m/[.;] # either a period or comma/x) {
                # This is the call to the function
                # not its defenition
                next;
            } else {
                $self->_record_func($data, $indx);
                while((my $tok=$self->_next_token($data,$indx)) =~ /
                                            [^\.]   # isn't a period
                                            /x) {
                    ++$indx;
                } 
                return $self->_parse_n3($data,$indx);
            }
        }        

        if ($token =~ m/\[ # matches [ /x) {
            if ($token =~ m/
                            \[\]    # matches []
                            /x) {
                #logic specific to 'something' bracket operator
                next;
            }
            # logic
            while((my $tok=$self->_next_token($data,$indx)) =~ /
                                        # any character which is not
                                        # a right square brace
                                                [^\]]
                                                /x) {
                ++$indx;
            } 
            $indx = $self->_parse_n3($data,$indx);
            next;
        }

        if ($token =~ m/\]/x) {
            # logic
            return $indx;
        }

        if ($token =~ m/^\.$/x) {
            #logic
            next;
        }

        if ($token =~ m/^\;$/x) {
            #logic
            next;
        }

    }
    return $self->{triples};
}

sub _next_token {
    my $self = shift;
    my $data = shift;
    my $index = shift;
    my $offset = shift || 1;

    return ${ $data }[$index+$offset];
}

# Takes a reference to the data and pointer to the start
# of relevent data as a parameter
sub _parse_triple {
    my $self  = shift;
    my $data  = shift;
    my $index = shift;

    ++$index;

    my $subject = ${ $data }[$index];

    if ($self->_next_token($data, $index) eq ';') {
        $index = $self->_get_verb_and_object($data, $index, 
                                             $subject, $self->{triples}, 
                                            )
    }
    return $index;
}

sub _get_verb_and_object {
    my($self, $data, $index, $subject, $triple) = @_;

    my $verb;
    my $object;
    my $next_token;

    while (defined($self->_next_token($data,$index))) {

        ++$index; # to get past the ';' char

        $verb = ${ $data }[++$index];
        $object = $self->_get_object($data, ++$index);

        if (defined($object) and defined($verb)) {
            if ($object =~ /^[\;\]]$ # any string consisting of
                                     # one comma or right square 
                                     # brace
                            /x ) { next };

            $triple->store_triple($subject, $verb, $object);
        } else { next; }

        if (eval {$object->isa('Gwybodaeth::Triples')}) {
            #while ($self->_next_token($data,$index) =~ /[^\]]/) {
                #++$index;
            #}
            next;
        }

        $next_token = $self->_next_token($data, $index);

        if ($next_token eq ';') {
            next;
        } elsif ( $next_token eq '.' or $next_token eq ']') {
            # end of section;
            ++$index;
            last;
        }
    }
    return $index;
}

sub _get_object {
    my($self, $data, $index) = @_;

    unless (defined(${ $data }[$index])) {
        return;
    }

    if ((${ $data }[$index] eq '[') 
        and
        ($self->_next_token($data, $index) eq 'a')) 
    {
        return $self->_get_nested_triple($data, $index);
    } else {
        return ${ $data }[$index];
    }
}

sub _get_nested_triple {
    my($self, $data, $index) = @_;

    ++$index; # to get over the ';' and 'a'

    my $nest_triple = Gwybodaeth::Triples->new();

    my $subject = ${ $data }[++$index];

    my $next_token = $self->_next_token($data, $index);

    if ($next_token eq ';') {
        $self->_get_verb_and_object($data, 
                                    $index, 
                                    $subject, 
                                    $nest_triple);
    }
    return $nest_triple;
}

# Store a defined function in a hash
sub _record_func {
    my($self, $data, $index) = @_;

    my $func_name = ${ $data }[$index];

    my $func_triple = $self->_get_nested_triple($data, $index);

    $self->{functions}->{$func_name} = $func_triple;
    return $index;
}

# Parse the main triples hash so that functions are
# placed where they are called.
sub _parse_triplestore {
    my $self = shift;
    my $triple = shift;

    if (defined($self->{functions})) {
        $self->_parse_functions($self->{functions}) 
            or croak "Unable to parse functions";
    }

    return $self->_populate_func($triple);
}

# Interface to _populate_func for the hash of functions
sub _parse_functions {
    my $self = shift;
    my $func_hash = shift; # a reference to the function hash

    for my $key (%{ $func_hash }) {
        $self->_populate_func($func_hash->{$key});
    }
    return 1;
}

# Populate any function calls with the triple store they define.
sub _populate_func {
    my $self = shift;
    my $triple = shift;

    for my $tkey (keys %{ $triple }) {
        for my $fkey ( keys %{ $self->{functions} } ) {
            for my $i (0..$#{ $triple->{$tkey}{'obj'} }) {
                my $obj = $triple->{$tkey}{'obj'}[$i];
                if ($obj eq $fkey) {
                    #$triple->{$tkey}{'obj'}[$i] = $self->{functions}->{$fkey};
                    #$self->_populate_func($triple);
                }
            }
        }
    }
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
