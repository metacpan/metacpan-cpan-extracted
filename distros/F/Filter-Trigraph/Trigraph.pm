package Filter::Trigraph;
use strict;
$Filter::Trigraph::VERSION = '0.02';

my %tri = (
  '=' => '#', '-' => '~', "'" => '^',
  '(' => '[', ')' => ']', '!' => '|',
  '<' => '{', '>' => '}', '/' => '\\',
);
my $tri = qr#\?\?([-='()<>!/])#;

use Filter::Simple sub{ s/$tri/$tri{$1}/go };

1;

=head1 NAME

Filter::Trigraph - understand ANSI C trigraphs in Perl source.

=head1 SYNOPSIS

  use Filter::Trigraph;

  my $x = shift??!??!"testing";
  if($ENV??<BIGVOWELS??>)??<
    ??= uppercase all vowels in $x
    $x=??-s/(??(aeiou??))/??/u$1/g;
  ??>else??<
    ??= uppercase all non-vowels in $x
    $x=??-s/(??(??'aeiou??))/??/u$1/g;
  ??>
  $??!=1;
  print "$x??/n";

=head1 DESCRIPTION

Now that Perl supports Unicode, we should also support ISO 646-1983.

ISO 646 is a character set very like ASCII, but with 9 of you favourite
characters removed.

ANSI C supports this limited character set using a wonderful system
called "trigraphs" that replace the 9 missing essential characters with
sequences of two question marks and another symbol.

Using this module you can now write Perl using only the characters found
in ISO 646.

=head1 SEE ALSO

Search for B<brain-damage> in your local GNU C documentation.

=head1 AUTHOR

Marty Pauley E<lt>marty@kasei.comE<gt>

=head1 COPYRIGHT

Copyright (C) 2001  Marty Pauley.

This program is free software; you can redistribute it and/or modify it under
the terms of either:

a) the GNU General Public License as published by the Free Software Foundation;
   either version 2 of the License, or (at your option) any later version.
b) the Perl Artistic License.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

=cut
