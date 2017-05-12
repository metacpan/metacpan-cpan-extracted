package Encode::DoubleEncodedUTF8;

use strict;
use base qw( Encode::Encoding );
use Encode 2.12 ();

our $VERSION = '0.05';

__PACKAGE__->Define('utf-8-de');

my $latin1_as_utf8 = "[\xC2\xC3][\x80-\xBF]";

# (Taken from Test::utf8 module)
# A Regexp string to match valid UTF8 bytes
# this info comes from page 78 of "The Unicode Standard 4.0"
# published by the Unicode Consortium
my $valid_utf8_regexp = <<'.' ;
        [\x{00}-\x{7f}]
      | [\x{c2}-\x{df}][\x{80}-\x{bf}]
      |         \x{e0} [\x{a0}-\x{bf}][\x{80}-\x{bf}]
      | [\x{e1}-\x{ec}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{ed} [\x{80}-\x{9f}][\x{80}-\x{bf}]
      | [\x{ee}-\x{ef}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{f0} [\x{90}-\x{bf}][\x{80}-\x{bf}]
      | [\x{f1}-\x{f3}][\x{80}-\x{bf}][\x{80}-\x{bf}][\x{80}-\x{bf}]
      |         \x{f4} [\x{80}-\x{8f}][\x{80}-\x{bf}][\x{80}-\x{bf}]
.

sub decode {
    my($obj, $buf, $chk) = @_;

    $buf =~ s{((?:$latin1_as_utf8){2,3})}{ _check_utf8_bytes($1) }ego;
    $_[1] = '' if $chk; # this is what in-place edit means

    Encode::decode_utf8($buf);
}

sub _check_utf8_bytes {
    my $bytes = shift;
    my $copy  = $bytes;

    my $possible_utf8 = '';
    while ($copy =~ s/^(.)(.)//) {
        $possible_utf8 .= chr( (ord($1) << 6 & 0xff) | ord($2) )
    }

    $possible_utf8 =~ /$valid_utf8_regexp/xo ? $possible_utf8 : $bytes;
}

sub encode {
    use Carp;
    Carp::croak("utf-8-de doesn't support encode() ... Why do you want to do that?");
}

1;
__END__

=for stopwords utf-8 UTF-8

=head1 NAME

Encode::DoubleEncodedUTF8 - Fix double encoded UTF-8 bytes to the correct one

=head1 SYNOPSIS

  use Encode;
  use Encode::DoubleEncodedUTF8;

  my $dodgy_utf8 = "Some byte strings from the web/DB with double-encoded UTF-8 bytes";
  my $fixed = decode("utf-8-de", $dodgy_utf8); # Fix it

=head1 WARNINGS

Use this module B<only> for testing, debugging, data recovery and
working around with buggy software you I<can't> fix.

B<Do not> use this module in your production code just to I<work
around> bugs in the code you I<can> fix. This module is slow, and not
perfect and may break the encodings if you run against correctly
encoded strings. See L<perlunitut> for more details.

=head1 DESCRIPTION

Encode::DoubleEncodedUTF8 adds a new encoding C<utf-8-de> and fixes
double encoded utf-8 bytes found in the original bytes to the correct
Unicode entity.

The double encoded utf-8 frequently happens when strings with UTF-8
flag and without are concatenated, for instance:

  my $string = "L\x{e9}on";   # latin-1
  utf8::upgrade($string);
  my $bytes  = "L\xc3\xa9on"; # utf-8

  my $dodgy_utf8 = encode_utf8($string . " " . $bytes); # $bytes is now double encoded

  my $fixed = decode("utf-8-de", $dodgy_utf8); # "L\x{e9}on L\x{e9}on";

See L<encoding::warnings> for more details.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<encoding::warnings>, L<Test::utf8>

=cut
