package Lingua::IN::TGC;

our $VERSION = '1.03';

use 5.022002;
use Moose;
with 'Lingua::IN::R::TGC';

1;

__END__

=encoding utf-8
=head1 NAME

Lingua::IN::TGC - Perl extension for tailored grapheme clusters for indian languages

=head1 SYNOPSIS

  use Lingua::IN::TGC;
  my $t = Lingua::IN::TGC->new();
  my @res = $t->TGC(string => "రాజ్కుమార్రెడ్డి");
  print join("\n", @res);

=head1 DESCRIPTION

Supported Scripts are telugu, devanagari, kannada, tamil, bengali, oria, punjabi, malayalam, gujarati.
Provides only one function 'TGC', it takes a string and returns an array.
You need minimum perl version 5.22

To learn more about tgc's goto  http://unicode.org/reports/tr29/

=head1 AUTHOR

Rajkumar Reddy

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Rajkumar Reddy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.22.2 or,
at your option, any later version of Perl 5 you may have available.

=cut
