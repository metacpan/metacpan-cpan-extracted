package Lingua::JA::Halfwidth;

use warnings;
use strict;
use Carp;
use base qw(Exporter);

our $VERSION = '0.0.6';

our @EXPORT = qw(is_japanese_halfwidth);

sub is_japanese_halfwidth {
    my $str = shift;
    if ( $str =~ /[\x{FF61}-\x{FF9F}]/ ) {
        return 1;    
    }
    else {
        return 0;
    }
}

1;

__END__

=encoding utf-8

=head1 NAME

Lingua::JA::Halfwidth - judge given single character is japanese halfwidth or not

=head1 SYNOPSIS

  use strict;
  use warnings;
  use Lingua::JA::Halfwidth;
  use Encode qw(encode_utf8);
  use utf8;
  
  my $string = qw/aあｳ９波ｦ/;
  for (split //, $string) {
      print encode_utf8($_), ": ";
      print is_japanese_halfwidth($_), "\n";
  }
    
  # a: 0
  # あ: 0
  # ｳ: 1
  # ９: 0
  # 波: 0
  # ｦ: 1

=head1 DESCRIPTION

This module is aimed to check easily whether given single character is japanese halfwidth or not.

Target characters are japanese halfwidth katakana, punctuation, voice marks and bracket.
(See also t/01.is_japanese_halfwidth.t)

Unicode block is very useful. 
When judging japanese halfwidth katakana and character used japanese halfwidth, we use \p{InHalfwidthAndFullwidthForms}.
But, this unicode block contains fullwidth number and so on...

So, I made this module :-)

=head1 METHODS

=head2 is_japanese_halfwidth
  
  is_japanese_halfwidth($str);

This method can judge given single character is japanese halfwidth or not.
Return value is 1 (japanese halfwidth) or 0 (not japanese halfwidth).

=head1 AUTHOR

sasata299  C<< <sasata299@livedoor.com> >>

http://blog.livedoor.jp/sasata299/

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, sasata299 C<< <sasata299@livedoor.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
