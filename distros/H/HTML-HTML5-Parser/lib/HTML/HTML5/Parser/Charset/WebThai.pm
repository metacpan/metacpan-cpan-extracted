#!/usr/bin/perl
package HTML::HTML5::Parser::Charset::WebThai;
## skip Test::Tabs
use strict;
our $VERSION='0.301';

## NOTE: This module does not expect that its standalone uses.
## See Message::Charset::Info for how it is used.

require Encode::Encoding;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-thai/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F\xA0\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]+)//) {
      return Encode::encode ('iso-8859-11', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F\xA0\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]/?/g;
    return Encode::encode ('iso-8859-11', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F\xA0-\xDA\xDF-\xFB]+)//) {
        $r .= Encode::decode ('iso-8859-11', $1);
      } else {
        return $r;
      }
    }
  } else {
    return Encode::decode ('windows-874', $_[1]);
  }
} # decode

package HTML::HTML5::Parser::Charset::WebThai::WebTIS620;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-tis-620/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]+)//) {
      return Encode::encode ('tis-620', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F\x{0E01}-\x{0E3A}\x{0E3F}-\x{0E5B}]/?/g;
    return Encode::encode ('tis-620', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F\xA1-\xDA\xDF-\xFB]+)//) {
        $r .= Encode::decode ('tis-620', $1);
      } else {
        return $r;
      }
    }
  } else {
    return Encode::decode ('windows-874', $_[1]);
  }
} # decode

1;
## $Date: 2008/09/10 10:27:09 $
