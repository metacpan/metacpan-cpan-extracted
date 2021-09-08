#!/usr/bin/perl
package HTML::HTML5::Parser::Charset::WebLatin1;
## skip Test::Tabs
use strict;
use warnings;
our $VERSION='0.992';

## NOTE: This module does not expect that its standalone uses.
## See Message::Charset::Info for how it is used.

require Encode::Encoding;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-latin1/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F\xA0-\xFF]+)//) {
      return Encode::encode ('iso-8859-1', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F\xA0-\xFF]/?/g;
    return Encode::encode ('iso-8859-1', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F\xA0-\xFF]+)//) {
        $r .= $1;
      #} elsif ($_[1] =~ s/^([\x80\x82-\x8C\x8E\x91-\x9C\x9E\x9F])//) {
      #  my $v = $1;
      #  $v =~ tr/\x80-\x9F/\x{20AC}\x{FFFD}\x{201A}\x{0192}\x{201E}\x{2026}\x{2020}\x{2021}\x{02C6}\x{2030}\x{0160}\x{2039}\x{0152}\x{FFFD}\x{017D}\x{FFFD}\x{FFFD}\x{2018}\x{2019}\x{201C}\x{201D}\x{2022}\x{2013}\x{2014}\x{02DC}\x{2122}\x{0161}\x{203A}\x{0153}\x{FFFD}\x{017E}\x{0178}/;
      #  $r .= $v;
      } else {
        return $r;
      }
    }
  } else {
    my $r = $_[1];
    $r =~ tr/\x80-\x9F/\x{20AC}\x{FFFD}\x{201A}\x{0192}\x{201E}\x{2026}\x{2020}\x{2021}\x{02C6}\x{2030}\x{0160}\x{2039}\x{0152}\x{FFFD}\x{017D}\x{FFFD}\x{FFFD}\x{2018}\x{2019}\x{201C}\x{201D}\x{2022}\x{2013}\x{2014}\x{02DC}\x{2122}\x{0161}\x{203A}\x{0153}\x{FFFD}\x{017E}\x{0178}/;
    return $r;
  }
} # decode

package HTML::HTML5::Parser::Charset::USASCII;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-latin1-us-ascii/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F]+)//) {
      return Encode::encode ('iso-8859-1', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F]/?/g;
    return Encode::encode ('iso-8859-1', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F]+)//) {
        $r .= $1;
      #} elsif ($_[1] =~ s/^([\x80\x82-\x8C\x8E\x91-\x9C\x9E\x9F-\xFF])//) {
      #  my $v = $1;
      #  $v =~ tr/\x80-\xFF/\x{20AC}\x{FFFD}\x{201A}\x{0192}\x{201E}\x{2026}\x{2020}\x{2021}\x{02C6}\x{2030}\x{0160}\x{2039}\x{0152}\x{FFFD}\x{017D}\x{FFFD}\x{FFFD}\x{2018}\x{2019}\x{201C}\x{201D}\x{2022}\x{2013}\x{2014}\x{02DC}\x{2122}\x{0161}\x{203A}\x{0153}\x{FFFD}\x{017E}\x{0178}\xA0-\xFF/;
      #  $r .= $v;
      } else {
        return $r;
      }
    }
  } else {
    my $r = $_[1];
    $r =~ tr/\x80-\xFF/\x{20AC}\x{FFFD}\x{201A}\x{0192}\x{201E}\x{2026}\x{2020}\x{2021}\x{02C6}\x{2030}\x{0160}\x{2039}\x{0152}\x{FFFD}\x{017D}\x{FFFD}\x{FFFD}\x{2018}\x{2019}\x{201C}\x{201D}\x{2022}\x{2013}\x{2014}\x{02DC}\x{2122}\x{0161}\x{203A}\x{0153}\x{FFFD}\x{017E}\x{0178}\xA0-\xFF/;
    return $r;
  }
} # decode

package HTML::HTML5::Parser::Charset::WebLatin5;
push our @ISA, 'Encode::Encoding';
__PACKAGE__->Define (qw/web-latin5/);

sub encode ($$;$) {
  # $self, $str, $chk
  if ($_[2]) {
    if ($_[1] =~ s/^([\x00-\x7F]+)//) {
      return Encode::encode ('iso-8859-9', $1);
    } else {
      return '';
    }
  } else {
    my $r = $_[1];
    $r =~ s/[^\x00-\x7F]/?/g;
    return Encode::encode ('iso-8859-9', $r);
  }
} # encode

sub decode ($$;$) {
  # $self, $s, $chk
  if ($_[2]) {
    my $r = '';
    while (1) {
      if ($_[1] =~ s/^([\x00-\x7F\xA0-\xFF]+)//) {
        $r .= Encode::decode ('windows-1254', $1);
      #} elsif ($_[1] =~ s/^([\x80\x82-\x8C\x91-\x9C\x9F])//) {
      #  my $v = $1;
      #  $v =~ tr/\x80-\x9F/\x{20AC}\x{FFFD}\x{201A}\x{0192}\x{201E}\x{2026}\x{2020}\x{2021}\x{02C6}\x{2030}\x{0160}\x{2039}\x{0152}\x{FFFD}\x{FFFD}\x{FFFD}\x{FFFD}\x{2018}\x{2019}\x{201C}\x{201D}\x{2022}\x{2013}\x{2014}\x{02DC}\x{2122}\x{0161}\x{203A}\x{0153}\x{FFFD}\x{FFFD}\x{0178}/;
      #  $r .= $v;
      } else {
        return $r;
      }
    }
  } else {
    my $r = Encode::decode ('windows-1254', $_[1]);
    return $r;
  }
} # decode

1;
## $Date: 2008/09/10 10:27:09 $
