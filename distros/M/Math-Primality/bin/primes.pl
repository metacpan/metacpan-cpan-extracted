#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Math::Primality qw/is_prime next_prime/;
use Math::GMPz;
$|++;

# PODNAME: primes.pl
# ABSTRACT: Print all primes between the two integers

my ($start, $end) = @ARGV;
die "USAGE:$0 start end\n" unless (@ARGV == 2);

die "$start isn't a positive integer" if $start =~ tr/0123456789//c;
die "$end isn't a positive integer" if $end =~ tr/0123456789//c;

$start = Math::GMPz->new("$start");
$end   = Math::GMPz->new("$end");
$start = next_prime($start) unless is_prime($start);
while ($start <= $end) {
    print "$start\n";
    $start = next_prime($start);
}

__END__

=pod

=head1 NAME

primes.pl - Print all primes between the two integers

=head1 VERSION

version 0.08

=head1 AUTHOR

Jonathan "Duke" Leto <jonathan@leto.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Leto Labs LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
