use strict;
use warnings;
package List::MapList;
{
  $List::MapList::VERSION = '1.123';
}
# ABSTRACT: map lists through a list of subs, not just one

use Exporter 5.57 'import';
our @EXPORT = qw(mapcycle maplist); ## no critic


sub maplist {
	my ($subs, $current) = (shift, 0);
	my $code = sub { $subs->[$current++] || sub { () }; };
	map { $code->()->() } @_;
}


sub mapcycle {
	my ($subs, $current) = (shift, 0);
	my $code = sub { $subs->[$current++ % @$subs]; };
	map { $code->()->() } @_;
}

1;

__END__

=pod

=head1 NAME

List::MapList - map lists through a list of subs, not just one

=head1 VERSION

version 1.123

=head1 SYNOPSIS

Contrived heterogenous transform

 use List::MapList;

 my $code = [
   sub { $_ + 1 },
   sub { $_ + 2 },
   sub { $_ + 3 },
   sub { $_ + 4 }
 ];

 my @mapped_1 = maplist( $code, qw(1 2 3 4 5 6 7 8 9));
 # @mapped_1 is qw(2 4 6 8)

 my @mapped_2 = mapcycle( $code, qw(1 2 3 4 5 6 7 8 9));
 # @mapped_2 is qw(2 4 6 8 6 8 10 12 13)

Ultra-secure partial rot13:

 my $rotsome = [
  sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
  sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
  sub { $_ },
 ];

 my $plaintext  = "Too many secrets.";
 my $cyphertext = join '', mapcycle($rotsome, split //, $plaintext);

=head1 DESCRIPTION

List::MapList provides methods to map a list through a list of transformations,
instead of just one.  The transformations are not chained together on each
element; only one is used, alternating sequentially.

Here's a contrived example: given the transformations C<{ $_ = 0 }> and C<{ $_
= 1 }>, the list C<(1, 2, 3, "Good morning", undef)> would become C<(0, 1, 0, 1,
0)> or, without cycling, C<(0, 1)>.;

(I use this code to process a part number in which each digit maps to a set of
product attributes.)

=head1 FUNCTIONS

=head2 maplist

  my @results = maplist(\@coderefs, LIST);

This routine acts much like a normal C<map>, but uses the list of code
references in C<$coderefs> in parallel with the list members.  First first code
reference is used for the first list member, the next for the second, and so
on.  Once the last code reference has been used, all further elements will be
mapped to C<()>.

=head2 mapcycle

  my @results = mapcycle($coderefs, LIST);

This routine is identical to C<maplist>, but will cycle through the passed
coderefs over and over as needed.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
