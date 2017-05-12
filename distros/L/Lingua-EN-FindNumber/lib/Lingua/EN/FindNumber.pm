package Lingua::EN::FindNumber;
$Lingua::EN::FindNumber::VERSION = '1.32';
use 5.006;
use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw( extract_numbers $number_re numify );

use Lingua::EN::Words2Nums;

# This is from Lingua::EN::Words2Nums, after being thrown through
# Regex::PreSuf
my $numbers =
	qr/((?:b(?:akers?dozen|illi(?:ard|on))|centillion|d(?:ecilli(?:ard|on)|ozen|u(?:o(?:decilli(?:ard|on)|vigintillion)|vigintillion))|e(?:ight(?:een|ieth|[yh])?|leven(?:ty(?:first|one))?|s)|f(?:i(?:ft(?:een|ieth|[yh])|rst|ve)|o(?:rt(?:ieth|y)|ur(?:t(?:ieth|[yh]))?))|g(?:oogol(?:plex)?|ross)|hundred|mi(?:l(?:ion|li(?:ard|on))|nus)|n(?:aught|egative|in(?:et(?:ieth|y)|t(?:een|[yh])|e)|o(?:nilli(?:ard|on)|ught|vem(?:dec|vigint)illion))|o(?:ct(?:illi(?:ard|on)|o(?:dec|vigint)illion)|ne)|qu(?:a(?:drilli(?:ard|on)|ttuor(?:decilli(?:ard|on)|vigintillion))|in(?:decilli(?:ard|on)|tilli(?:ard|on)|vigintillion))|s(?:core|e(?:cond|pt(?:en(?:dec|vigint)illion|illi(?:ard|on))|ven(?:t(?:ieth|y))?|x(?:decillion|tilli(?:ard|on)|vigintillion))|ix(?:t(?:ieth|y))?)|t(?:ee?n|h(?:ir(?:t(?:een|ieth|y)|d)|ousand|ree)|r(?:e(?:decilli(?:ard|on)|vigintillion)|i(?:gintillion|lli(?:ard|on)))|w(?:e(?:l(?:fth|ve)|nt(?:ieth|y))|o)|h)|un(?:decilli(?:ard|on)|vigintillion)|vigintillion|zero|s))/i;

my $ok_words  = qr/\b(and|a|of)\b/;
my $ok_things = qr/[^A-Za-z0-9.]/;
our $number_re = qr/\b(($numbers($ok_words|$ok_things)*)+)\b/i;

sub extract_numbers {
	my $text = shift;
	my @numbers;
	push @numbers, $1 while $text =~ /$number_re/g;
	s/\s+$// for @numbers;
	return @numbers;
}

sub numify {
	my $text = shift;
	$text =~ s/$number_re/words2nums($1). ($1 =~ m{(\s+)$} ? $1 :"")/eg;
	return $text;
}

1;
__END__

=head1 NAME

Lingua::EN::FindNumber - Locate (written) numbers in English text 

=head1 SYNOPSIS

  use Lingua::EN::FindNumber;
  my $text = "Fourscore and seven years ago, our four fathers...";

  numify($text); # "87 years ago, our 4 fathers..."

  @numbers = extract_numbers($text); # "Fourscore and seven", "four"

  while ($text =~ /$number_re/g) { # Build your own iterator


=head1 DESCRIPTION

This module provides a regular expression for finding numbers in English
text. It also provides functions for extracting and manipulating such
numbers.

=head1 EXPORTED METHODS

=head2 extract_numbers / numify / $number_re

  numify($text); # "87 years ago, our 4 fathers..."

  @numbers = extract_numbers($text); # "Fourscore and seven", "four"

  while ($text =~ /$number_re/g) { # Build your own iterator


=head1 SEE ALSO

This module was written for the Natural Languages chapter of the second
edition of Advanced Perl Programming.

This module works rather well in conjunction with
L<Lingua::EN::Words2Nums>, which is a very cool module anyway.
(And Simon stole some of this module's code from it. Thanks, Joey!)
It may also be involved with L<Lingua::EN::NamedEntity> in the future,
so check that one out too.


=head1 REPOSITORY

L<https://github.com/neilb/Lingua-EN-FindNumber>


=head1 AUTHOR

This module was originally written by Simon Cozens.
It was then maintained from 2004 to 2005 by Tony Bowden.
Since 2014 it has been maintained by Neil Bowers.


=head1 BUGS and QUERIES

Please direct all correspondence regarding this module to:
  bug-Lingua-EN-Number@rt.cpan.org

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2005 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
