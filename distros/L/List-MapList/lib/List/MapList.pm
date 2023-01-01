use strict;
use warnings;
package List::MapList 1.124;
# ABSTRACT: map lists through a list of subs, not just one

use Exporter 5.57 'import';
our @EXPORT = qw(mapcycle maplist); ## no critic

#pod =head1 SYNOPSIS
#pod
#pod Contrived heterogenous transform
#pod
#pod  use List::MapList;
#pod
#pod  my $code = [
#pod    sub { $_ + 1 },
#pod    sub { $_ + 2 },
#pod    sub { $_ + 3 },
#pod    sub { $_ + 4 }
#pod  ];
#pod
#pod  my @mapped_1 = maplist( $code, qw(1 2 3 4 5 6 7 8 9));
#pod  # @mapped_1 is qw(2 4 6 8)
#pod
#pod  my @mapped_2 = mapcycle( $code, qw(1 2 3 4 5 6 7 8 9));
#pod  # @mapped_2 is qw(2 4 6 8 6 8 10 12 13)
#pod
#pod Ultra-secure partial rot13:
#pod
#pod  my $rotsome = [
#pod   sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
#pod   sub { tr/a-zA-Z/n-za-mN-ZA-M/; $_ },
#pod   sub { $_ },
#pod  ];
#pod
#pod  my $plaintext  = "Too many secrets.";
#pod  my $cyphertext = join '', mapcycle($rotsome, split //, $plaintext);
#pod
#pod =head1 DESCRIPTION
#pod
#pod List::MapList provides methods to map a list through a list of transformations,
#pod instead of just one.  The transformations are not chained together on each
#pod element; only one is used, alternating sequentially.
#pod
#pod Here's a contrived example: given the transformations C<{ $_ = 0 }> and C<{ $_
#pod = 1 }>, the list C<(1, 2, 3, "Good morning", undef)> would become C<(0, 1, 0, 1,
#pod 0)> or, without cycling, C<(0, 1)>.;
#pod
#pod (I use this code to process a part number in which each digit maps to a set of
#pod product attributes.)
#pod
#pod =func maplist
#pod
#pod   my @results = maplist(\@coderefs, LIST);
#pod
#pod This routine acts much like a normal C<map>, but uses the list of code
#pod references in C<$coderefs> in parallel with the list members.  First first code
#pod reference is used for the first list member, the next for the second, and so
#pod on.  Once the last code reference has been used, all further elements will be
#pod mapped to C<()>.
#pod
#pod =cut

sub maplist {
  my ($subs, $current) = (shift, 0);
  my $code = sub { $subs->[$current++] || sub { () }; };
  map { $code->()->() } @_;
}

#pod =func mapcycle
#pod
#pod   my @results = mapcycle($coderefs, LIST);
#pod
#pod This routine is identical to C<maplist>, but will cycle through the passed
#pod coderefs over and over as needed.
#pod
#pod =cut

sub mapcycle {
  my ($subs, $current) = (shift, 0);
  my $code = sub { $subs->[$current++ % @$subs]; };
  map { $code->()->() } @_;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

List::MapList - map lists through a list of subs, not just one

=head1 VERSION

version 1.124

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

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

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

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo SIGNES Signes

=over 4

=item *

Ricardo SIGNES <rjbs@codesimply.com>

=item *

Ricardo Signes <rjbs@semiotic.systems>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
