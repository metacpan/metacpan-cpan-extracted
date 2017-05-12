package Lingua::PTD::More;
use Exporter 'import';

use 5.006;
use strict;
use warnings;

use Lingua::PTD;

our @EXPORT_OK = qw(pss pssml);

=head1 NAME

Lingua::PTD::More - more things to do with PTD

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Lingua::PTD;
    use Lingua::PTD::More qw/pss pssml/;

    my $ptdA = Lingua::PTD->new('ptd.en-pt.sqlite');
    my $ptdB = Lingua::PTD->new('ptd.en-pt.sqlite');

    my %pss = pss($ptdA, $ptdB, $term);
    my %pssml = pssml($ptdA, $ptdB, $term);

=head1 EXPORT

=head2 pss

Create a Probabilistic Synonymous Set (PSS) given a PTD pair and a term.
The minimum probability can be passed as an extra argument to this
function.

=cut

sub pss {
  my ($ptdA, $ptdB, $term, $minp) = @_;
  $minp = 0.2 unless $minp;

  my %pss;
  my %trans = $ptdA->transHash($term);
  foreach (keys %trans) {
    $pss{$_} = $trans{$_} if $trans{$_} >= $minp;
    my %transI = $ptdB->transHash($_);
    foreach my $j (keys %transI) {
      $pss{$j} = $transI{$j} if $transI{$j} >= $minp;
    }
  }

  return %pss;
}

=head2 pssml

Same as C<pss> function, but doesn't add translations to the PSS.

=cut

sub pssml {
  my ($ptdA, $ptdB, $term, $minp) = @_;
  $minp = 0.2 unless $minp;

  my %pssml;
  my %trans = $ptdA->transHash($term);
  foreach (keys %trans) {
    my %transI = $ptdB->transHash($_);
    foreach my $j (keys %transI) {
      $pssml{$j} = $transI{$j} if $transI{$j} >= $minp;
    }
  }

  return %pssml;
}

=head1 AUTHOR

Nuno Carvalho, C<< <smash at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-ptd-pss at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-PTD-More>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::PTD::More


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-PTD-More>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-PTD-More>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-PTD-More>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-PTD-More/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 by Project Natura <natura@natura.di.uminho.pt>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

1; # End of Lingua::PTD::More
