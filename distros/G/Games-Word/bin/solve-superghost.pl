#!/usr/bin/env perl
use strict;
use warnings;
use Games::Word::Wordlist;
# PODNAME: solve-superghost.pl

die "Usage: $0 <subword>\n" unless @ARGV;
my $wl = Games::Word::Wordlist->new('/usr/share/dict/words');
print "$_\n" for $wl->words_like(qr/\Q$ARGV[0]/i);

__END__
=pod

=head1 NAME

solve-superghost.pl

=head1 VERSION

version 0.06

=head1 AUTHOR

Jesse Luehrs <doy at tozt dot net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Jesse Luehrs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

