#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Tokenize;

=head1 NAME

Tokenize - Split up data on whitespace into tokens.

=head1 SYNOPSIS

    use Tokenize;

    my $t = Tokenize->new();

    $t->tokenize($data);

=head1 DESCRIPTION

This module tokenizes data, where a token is delimited by whitespace.

=over

=item new()

Reterns an instance of the class.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=item tokenize($data)

Tokenizes the data supplied in the array reference $data.

=cut

# Takes a reference to the input data as a parameter.
sub tokenize {
    my($self, $data) = @_;

    my @tokenized;

    for (@{ $data }) {
        for (split /\s+/x) {
            next if /
                    # string is entirly whitespace or empty
                    ^\s*$/x;
            push @tokenized, $_;
        }
    }

    return $self->_tokenize_clean(\@tokenized);
}

# Takes a reference to the data which needs to be cleaned
sub _tokenize_clean {
    my($self, $data) = @_;

    for my $i (0..$#{ $data }) {
        
        next if (not defined ${ $data }[$i]);
        
            # If a token begins with '<' but doesn't end with '>'
            # then the token has been split up.
        if ((${$data}[$i] =~ /^\< # line begins with a opening square bracket/x 
                && 
            ${$data}[$i] =~ /[^\>]$ # line doesn't end with a closing square
                                    # bracket
                            /x)
            ||
            # If the token begins but doesn't end with " the token may
            # have been split up 
            (${$data}[$i] =~ /^\" # line begins with a double quote/x 
                && 
             ${$data}[$i] =~ /
                            [^\"]$ # line doesn't end with a double quote
                             /x)) 
            {
            # Concatinate the next line to the current
            # partial token. We add a space inbetween to repair from
            # the split operation. 
            ${ $data }[$i] .= " ${ $data }[$i+1]";

            # Re-index the token list to take into account the last
            # concatination.
            for my $j (($i+1)..($#{ $data }-1)) {
                ${ $data }[$j] = ${ $data }[$j + 1];
            }
            
            # The last data element should now be deleted
            # as the data has been shifted up one in the 
            # list.
            delete ${ $data }[$#{ $data }];

            redo; # try again in case the token is split onto more than 2 lines
        }
    }
    return $data;
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
