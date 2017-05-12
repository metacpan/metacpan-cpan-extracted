# Integer::Partition.pm
#
# Copyright (c) 2007-2013 David Landgren
# All rights reserved

package Integer::Partition;
use strict;
use warnings;

use vars qw/$VERSION/;
$VERSION = '0.05';

=head1 NAME

Integer::Partition - Generate all integer partitions of an integer

=head1 VERSION

This document describes version 0.05 of Integer::Partition, released
2013-06-23.

=head1 SYNOPSIS

  use Integer::Partition;

  my $i = Integer::Partition->new(4);
  while (my $p = $i->next) {
    print join( ' ', @$p ), $/;
  }
  # produces
  4
  3 1
  2 2
  2 1 1
  1 1 1 1

  my $j = Integer::Partition->new(5, {lexicographic => 1});
  while (my $p = $j->next) {
    print join( ' ', @$p ), $/;
  }
  # produces
  1 1 1 1 1
  2 1 1 1
  2 2 1
  3 1 1
  3 2
  4 1
  5

=head1 DESCRIPTION

C<Integer::Partition> takes an integer number and produces an object
that can be used to generate all possible integer partitions of the
original number in either forward or reverse lexicographic order.

=head1 METHODS

=over 8

=item new

Creates a new C<Integer::Partition> object. Takes an integer as a
parameter. By default, the partitions appear in reverse order, as
the algorithm is slightly faster. Forward ordering uses a different,
slightly slower algorithm (which is nonetheless much faster than
any existing algorithm).

=cut

sub new {
    my $class = shift;
    my $n     = shift;
    if (!defined $n) {
        require Carp;
        Carp::croak("missing or undefined input");
    }
    elsif ($n =~ /\D/ or $n < 1) {
        require Carp;
        Carp::croak("$n is not a positive integer");
    }
    elsif ($n != int($n)) {
        require Carp;
        Carp::croak("$n is not an integer");
    }
    my $arg = shift;

    my $forward = 0;
    if (defined $arg and ref($arg) eq 'HASH' and exists $arg->{lexicographic}) {
        $forward = $arg->{lexicographic};
    }

    my @x;
    if ($forward) {
        @x = (1) x ($n+1);
        $x[0] = -1;
    }
    else {
        @x = (1) x $n;
        $x[0] = $n;
    }

    my $self = {
        n => $n,
        x => \@x,
        h => $forward ?      1 : 0,
        m => $forward ? $n - 1 : 0,
        count => 0,
        forward => $forward,
    };
    return bless $self, $class;
}

=item next

Returns the partition, or C<undef> when all partitions have been
generated.

=cut

sub next {
    my $self = shift;
    if ($self->{forward}) {
        if (++$self->{count} == 1) {
            return [@{$self->{x}}[1..$self->{n}]];
        }
        elsif ($self->{x}[1] == $self->{n}) {
            return;
        }
        elsif ($self->{count} == 2) {
            $self->{x}[1] = 2;
            return [@{$self->{x}}[1..$self->{n}-1]];
        }
        else {
            if ($self->{m} - $self->{h} > 1) {
                $self->{x}[++$self->{h}] = 2;
                --$self->{m};
            }
            else {
                my $j = $self->{m} - 2;
                while ($self->{x}[$j] == $self->{x}[$self->{m}-1]) {
                    $self->{x}[$j--] = 1;
                }
                $self->{h} = $j + 1;
                $self->{x}[$self->{h}] = $self->{x}[$self->{m}-1] + 1;
                my $r = $self->{x}[$self->{m}]
                    + $self->{x}[$self->{m} - 1] * ($self->{m} - $self->{h} - 1);
                $self->{x}[$self->{m}]   = 1;
                $self->{x}[$self->{m}-1] = 1 if $self->{m} - $self->{h} > 1;
                $self->{m} = $self->{h} + $r - 1;
            }
            return [@{$self->{x}}[1..$self->{m}]];
        }
    }

    return [$self->{n}] unless $self->{count}++;
    return if $self->{x}[0] == 1;

    if ($self->{x}[$self->{h}] == 2) {
        ++$self->{m};
        $self->{x}[$self->{h}--] = 1;
    }
    else {
        my $r = $self->{x}[$self->{h}] - 1;
        $self->{x}[$self->{h}] = $r;

        my $t = $self->{m} - $self->{h} + 1;
        while ($t >= $r) {
            $self->{x}[++$self->{h}] = $r;
            $t -= $r;
        }
        $self->{m} = $self->{h} + ($t ? 1 : 0);
        $t > 1 and $self->{x}[++$self->{h}] = $t;
    }
    return [@{$self->{x}}[0..$self->{m}]];
}

=item reset

Resets the object, which causes it to enumerate the arrangements from the
beginning.

  $p->reset; # begin again

=cut

sub reset {
    my $self = shift;
    my $n    = $self->{n};
    my @x;
    if ($self->{forward}) {
        @x = (1) x ($n+1);
        $x[0] = -1;
    }
    else {
        @x = (1) x $n;
        $x[0] = $n;
    }
    $self->{x} = \@x;
    $self->{m} = $self->{forward} ? $n - 1 : 0,
    $self->{h} = $self->{forward} ?      1 : 0,
    $self->{count} = 0;
    return $self;
}

=back

=head1 DIAGNOSTICS

=head2 missing or undefined input

The C<new()> method was called without an input parameter, which
should be a positive integer.

=head2 C<n> is not a positive integer

The C<new()> method was called with zero or a negative integer.

=head2 C<n> is not an integer

The C<new()> method was called with a number containing a decimal
component. Use C<int> or C<sprintf '%d'> on the input if necessary.

=head1 NOTES

This module implements the Zoghbi and Stojmenovic ZS1 and ZS2
algorithms for generating integer partitions. See
L<http://www.site.uottawa.ca/~ivan/F49-int-part.pdf> for more
information. These algorithms have been proven to have constant
average delay, that is, the amount of effort it takes to produce
the next result in the series.

They are the fastest known algorithms known for generating integer
partitions (with the ZS1 reverse lexicographic order algorithm being
slightly faster than the ZS2 lexicographic order algorithm).

=head1 SEE ALSO

=over 8

=item *

L<http://en.wikipedia.org/wiki/Integer_partition>

The Wikipedia entry on integer partitions

=item *

L<http://www.site.uottawa.ca/~ivan/F49-int-part.pdf> 

The original 1998 paper written by Zoghbi and Stojmenovic.

=back

=head1 BUGS

None known.

Please report all bugs at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Integer-Partition|rt.cpan.org>

Make sure you include the output from the following two commands:

  perl -MInteger::Partition -le 'print $Integer::Partition::VERSION'
  perl -V

Pull requests on Github may be issued at
L<https://github.com/dland/Integer-Partition>.

=head1 ACKNOWLEDGEMENTS

Thanks to Antoine Zoghbi and Ivan Stojmenovic, for sharing their
discovery with the world on the internet, and not hiding it in
behind some sort of pay-wall.

=head1 AUTHOR

David Landgren, copyright (C) 2007-2013. All rights reserved.

http://www.landgren.net/perl/

If you (find a) use this module, I'd love to hear about it. If you
want to be informed of updates, send me a note. You know my first
name, you know my domain. Can you guess my e-mail address?

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

'The Lusty Decadent Delights of Imperial Pompeii';
__END__
