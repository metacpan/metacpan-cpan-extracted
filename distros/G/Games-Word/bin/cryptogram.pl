#!/usr/bin/env perl
use strict;
use warnings;
use Games::Word qw/random_permutation/;
# PODNAME: cryptogram.pl

my $alphabet = 'abcdefghijklmnopqrstuvwxyz';
my $key = random_permutation $alphabet;
print "KEY: $key\n";
print "MESSAGE:\n";
my $text = join ' ', @ARGV;
eval "\$text =~ tr/$alphabet/$key/";
print $text, "\n";

__END__
=pod

=head1 NAME

cryptogram.pl

=head1 VERSION

version 0.06

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

