package List::NSect;
use strict;
use warnings;
use base qw{Exporter};
use List::MoreUtils qw{part};

our $VERSION    = '0.07';
our @EXPORT     = qw(nsect);
our @EXPORT_OK  = qw(spart deal);

=head1 NAME

List::NSect - Cuts or divides a list into N equal parts.

=head1 SYNOPSIS

  use List::NSect;
  my @sections=nsect(5 => "a" .. "z");
  foreach my $section (@sections) {
    print join(",", @$section), "\n";
  }

Output

  a,b,c,d,e,f
  g,h,i,j,k
  l,m,n,o,p
  q,r,s,t,u
  v,w,x,y,z

=head1 DESCRIPTION

List::NSect is an L<Exporter> that exports the function "nsect".

=head2 nsect like bisect not mosquito

I had a hard time deciding on a function name that was distinct and succinct.  When I searched the Internet for "divide into equal parts", "bisect - to divide into two equal parts" was one of the top hits.  I then tried to find a synonym for "divide into N equal parts".  I soon realized that there is no single English word for the concept: thus "nsect".  

Other function names that I was contemplating are "chunk" (to cut, break, or form into chunks), "allot" (to divide or distribute by share or portion) and "apportion" (to distribute or allocate proportionally; divide and assign according to some rule of proportional distribution).  None of these names implies the need for exactly N sections instead of some other distribution.

I use this capability all of the time which is a specific implementation of List::MoreUtils::part.  You may ask `why not just use "part" directly from L<List::MoreUtils>?`  Well, there are many edge cases.  Please, take a look at the code; This is Perl!

=head1 USAGE

  use List::NSect;
  my @sections=nsect($n => @list); #returns ([...], [...], [...], ...); #$n count of arrray references

  use List::NSect qw{spart};
  my @batches=spart($n => @list); #returns ([...], [...], [...], ...);  #array reference of $n size

=head1 FUNCTION

=head2 nsect

Cuts or divides a list into N equal or nearly equal parts.

Returns an array of array references given a scalar number of sections and a list.

  my @sections=nsect(4, 1 .. 17); #returns ([1,2,3,4,5],[6,7,8,9],[10,11,12,13],[14,15,16,17]);
  my $sections=nsect(4, 1 .. 17); #returns [[1,2,3,4,5],[6,7,8,9],[10,11,12,13],[14,15,16,17]];

=cut

sub nsect {
  my $n        = shift || 0;
  my $count    = scalar(@_);
  my @sections = ();
  #undef, 0 or empty array returns nothing as requested
  if ($n > 0 and $count > 0) {
    $n=$count if $n > $count;
    my $i=0;
    @sections=part {int($i++ * $n / $count)} @_; #Each partition created is a reference to an array.
  }
  return wantarray ? @sections : \@sections;
}

=head2 spart (not exported by default)

Cut or divides a list into parts each of size N.

Returns an array of array references given a scalar size and a list.

  my @parts=spart(4, 1 .. 17); #returns ([1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16],[17]);
  my $parts=spart(4, 1 .. 17); #returns [[1,2,3,4],[5,6,7,8],[9,10,11,12],[13,14,15,16],[17]];

Note: The last array reference may be short.

=cut

sub spart {
  my $parts = shift || 0;
  my @deck  = ();
  #undef, 0 or empty array returns nothing as requested
  if ($parts > 0) {
    my $i = 0;
    @deck = part {int($i++ / $parts)} @_; #/#Each partition created is a reference to an array.
  }
  return wantarray ? @deck : \@deck;
}

=head2 deal (not exported by default)

Deals a list into hands

Returns an array of array references given a scalar size and a list.

  my @hands=deal(4, 1 .. 17); #returns ([1,5,9,13,17],[2,6,10,14],[3,7,11,15],[4,8,12,16]);

=cut

sub deal {
  my $hands = shift || 0;
  my @deck  = ();
  #undef, 0 or empty array returns nothing as requested
  if ($hands > 0) {
    my $hand = 0;
    @deck=part {$hand=0 if $hand>=$hands; $hand++;} @_;
  }
  return wantarray ? @deck : \@deck;
}

=head1 LIMITATIONS

  my @sections=nsect($n => @list);

The nsect function will ALWAYS return an array (array reference in scalar context). So, that you can always pass the return directly into a foreach loop without the need to test for edge cases.  However, I made the executive decision that if $n > scalar(@list) the returned array, @sections, is not $n in size but rather scalar(@list) in size.

  my @sections=nsect(100, "a", "b", "c"); #scalar(@sections) == 3 != 100;

=head1 BUGS

Please open an issue on GitHub

=head1 AUTHOR

  Michael R. Davis

=head1 COPYRIGHT

MIT License

Copyright (c) 2022 Michael R. Davis

=head1 SEE ALSO

L<List::MoreUtils> part and natatime, L<Array::Group>, L<List::UtilsBy> bundle_by, L<http://www.perlmonks.org/?no^de_id=516499>, L<http://www.perlmonks.org/?node_id=861938>, L<Parallel::ForkManager>

=cut

1;
