#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Math::Primality qw/is_strong_pseudoprime is_prime/;
$|++;

# PODNAME: strong_pseudoprimes.pl
# ABSTRACT: Print all strong pseudoprimes between two integers

my ($base, $start, $end) = @ARGV;
die "USAGE:$0 base start end\n" unless ($base && $start >= 0 && $end > $start);

my $i=$start;

print "Generating spsp($base)\n";
while ( $i++ < $end ){
    print "$i\n" if is_strong_pseudoprime($i,$base) && !is_prime($i);
}

__END__

=pod

=head1 NAME

strong_pseudoprimes.pl - Print all strong pseudoprimes between two integers

=head1 VERSION

version 0.08

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leto Labs LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
