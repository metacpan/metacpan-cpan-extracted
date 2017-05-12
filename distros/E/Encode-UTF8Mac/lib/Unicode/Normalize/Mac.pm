package Unicode::Normalize::Mac;
use strict;
use warnings;
use Unicode::Normalize ();
use Exporter 'import';
our @EXPORT_OK = qw( NFC_mac NFD_mac );

# http://developer.apple.com/library/mac/#qa/qa2001/qa1173.html
my $decompose = qr/([^\x{2000}-\x{2FFF}\x{F900}-\x{FAFF}\x{2F800}-\x{2FAFF}]*)/;

sub NFC_mac {
    my ($unicode) = @_;
    return unless defined $unicode;
    $unicode =~ s/$decompose/Unicode::Normalize::NFC($1)/eg;
    $unicode;
}

sub NFD_mac {
    my ($unicode) = @_;
    return unless defined $unicode;
    $unicode =~ s/$decompose/Unicode::Normalize::NFD($1)/eg;
    $unicode;
}

{
    no warnings 'once';
    *NFC = \&NFC_mac;
    *NFD = \&NFD_mac;
}

1;
__END__

=encoding utf-8

=for stopwords utf-8-mac

=head1 NAME

Unicode::Normalize::Mac - Unicode normalization same way used in OSX file system

=head1 SYNOPSIS

  use Unicode::Normalize::Mac qw/NFC_mac/;
  
  my $text = NFC_mac("\x{FA1B}\x{2F872}\x{305F}\x{3099}");
  #    => "\x{FA1B}\x{2F872}\x{3060}"
  # Note: "\x{798F}\x{5BFF}\x{3060}" standard NFC

=head1 DESCRIPTION

This module provides Unicode normalization functions same as Mac OSX file system.
Specifically, the following ranges are not decomposed.

  U+2000-U+2FFF
  U+F900-U+FAFF
  U+2F800-U+2FAFF

L<http://developer.apple.com/library/mac/#qa/qa2001/qa1173.html>

=head1 FUNCTIONS

=over 4

=item NFC(), NFD()

  my $text = Unicode::Normalize::Mac::NFC($text);

Same as L<Unicode::Normalize>::NFC() / NFD(), except some characters.

=back

=head1 EXPORTS

None by default.

=over 4

=item NFC_mac(), NFD_mac()
  
  use Unicode::Normalize::Mac qw/NFC_mac/;
  my $text = NFC_mac($text);

These exportable functions are alias to Unicode::Normalize::Mac::NFC() / NFD().

=back

=head1 SEE ALSO

L<Unicode::Normalize>

L<Encode::UTF8Mac> - provides "utf-8-mac" encoding using this module.

=head1 AUTHOR

Naoki Tomita E<lt>tomita@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
