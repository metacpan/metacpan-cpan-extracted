package MIME::DecodeText;

use 5.006;
use strict;

use MIME::Base64;
use MIME::QuotedPrint;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw(
	decode_text
);
our $VERSION = '0.01';



sub decode_text($) {
  my $s = shift;
  my $ret = '';
  local ($/) = undef;
  
  my @ar = split ' ', $s;
  foreach my $substr (@ar) {
    $ret .= __decode($substr);
  }

  return $ret;
}

sub __decode($) {
  my $s = shift;
  my $ret = $s;
  local ($/) = undef;

  $s =~ /=\?(.+)?\?(.)\?/;
  my ($encoding,$type) = ($1,$2);
  
  $s =~ s/=\?.+?\?$type\?(.*)\?=/$1/g;

  if		( $type eq 'q' ) {
    $s =~ s/_/ /g;
    $ret = decode_qp($s);
  } elsif	( $type eq 'B' ) {
    $ret = decode_base64($s);
  } else {
    $ret = "$s ";
  }

  return $ret;
}

1;
__END__

=head1 NAME

MIME::DecodeText - Decode any multipart encoded text.

=head1 SYNOPSIS

  use MIME::DecodeText;

  my $decoded_text = decode_text($encoded_text);

=head1 DESCRIPTION

Decode any multipart differently encoded text.

Now distinguishes Base64, QuotedPrintable encoded and plain text parts
of the space-separated text string.

Usage sample is decoding of message subjects which were encoded in various ways by
different mail agents with non-US locale applied.

=head2 EXPORT

  decode_text

=head1 AUTHOR

Vlad Danego, E<lt>vlad@al.lg.uaE<gt>

=head1 SEE ALSO

L<MIME::Base64>, L<MIME::QuotedPrint>.

=cut
