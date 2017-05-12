package Hash::Tally;

use strict;
use warnings;
use base qw( Exporter );
use List::Util;
use List::MoreUtils qw( uniq );

our $VERSION = '0.02';

our @EXPORT_OK = qw( tally );

=head1 NAME

Hash::Tally - Compute the tallies of hash values

=head1 SYNOPSIS
    
    
    use Hash::Tally qw( tally );
    
    my $data = {
        Shipping => {
            English => {
                 Canada         => 8,
                'United States' => 13,
            },
            French => {
                 Canada         => 26,
                'United States' => 3,
            },
        },
        Receiving => {
            English => 56,
            French  => {
                 Canada         => 12,
                'United States' => 5,
            },
        },
    };
    
    
    tally( $data );
    
    
    # $data now has the following value:
    $data = {
        Shipping => {
            English => {
                 Canada         => 8,
                'United States' => 13,
                 tally          => 21,
            },
            French => {
                 Canada         => 26,
                'United States' => 3,
                 tally          => 29,
            },
            tally => {
                 Canada         => 34,
                'United States' => 16,
                 tally          => 50,
            },
        },
        Receiving => {
            English => 56,
            French  => {
                 Canada         => 12,
                'United States' => 5,
                 tally          => 17,
            },
            tally => 73,
        },
        tally => {
            English => 77,
            French  => {
                 Canada         => 38,
                'United States' => 8,
                 tally          => 46,
            },
            tally => 123,
        },
    };
    
    
=head1 DESCRIPTION

=head2 tally ( @data )

A method designed to calculate the tallies of hashes. It was originally
designed for reporting and statistical purposes.

=cut

sub tally {
    my @data    = grep { defined $_ } @_;
    my @hashes  = grep { ref $_ eq 'HASH' } @data;
    my @scalars = grep { ref $_ eq ''     } @data;
    
    # this will be the key within the given hashes where the sub-tallies will be stored
    # TODO: make this value configurable
    #
    my $tally_field = 'tally';
    
    # in the case of scalars, we merely sum them together as would any numeric values
    if (@scalars == @data) {
        return List::Util::sum( @scalars );
    }
    
    # we must be provided either hash references or scalars
    unless (@hashes + @scalars == @data) {
        die 'Data must be scalar or hash reference';
    }
    
    # list all the unique keys found across all hash references
    my @names = uniq( grep { $_ ne $tally_field } map { keys %$_ } @hashes );
    
    # compute the hash tallies
    for my $hash (@hashes) {
        $hash->{$tally_field} = tally( grep { defined $_ } map { $hash->{$_} } @names ) || 0;
    }
    
    # compute the current tally using the previously calculated hash tallies
    my %tally = ( $tally_field => tally( map { $_->{$tally_field} } @hashes ) );
    for my $name (@names) {
        $tally{$name} = tally( map { $_->{$name} } @hashes );
    }
    
    # if we have scalars, we cannot return a hash because the data's
    # granularity only goes as far as this iteration.
    #
    if (@scalars) {
        my $tally = $tally{$tally_field};
        $tally = $tally->{$tally_field} while ref $tally eq 'HASH';
        return List::Util::sum( @scalars ) + $tally;
    }
    else {
        return \%tally;
    }
}

=head1 AUTHOR

Adam Paynter E<lt>adapay@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Adam Paynter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;