package Digest::Pearson::PurePerl;

use strict;
use Exporter;

@Digest::Pearson::PurePerl::ISA       = qw(Exporter);

@Digest::Pearson::PurePerl::EXPORT_OK = qw(pearson);

@Digest::Pearson::PurePerl::EXPORT    = qw( );

$Digest::Pearson::PurePerl::VERSION   = "1.00";

my @p_tbl = (
  251,175,119,215, 81, 14, 79,191,103, 49,181,143,186,157,  0,232,
   31, 32, 55, 60,152, 58, 17,237,174, 70,160,144,220, 90, 57,223,
   59,  3, 18,140,111,166,203,196,134,243,124, 95,222,179,197, 65,
  180, 48, 36, 15,107, 46,233,130,165, 30,123,161,209, 23, 97, 16,
   40, 91,219, 61,100, 10,210,109,250,127, 22,138, 29,108,244, 67,
  207,  9,178,204, 74, 98,126,249,167,116, 34, 77,193,200,121,  5,
   20,113, 71, 35,128, 13,182, 94, 25,226,227,199, 75, 27, 41,245,
  230,224, 43,225,177, 26,155,150,212,142,218,115,241, 73, 88,105,
   39,114, 62,255,192,201,145,214,168,158,221,148,154,122, 12, 84,
   82,163, 44,139,228,236,205,242,217, 11,187,146,159, 64, 86,239,
  195, 42,106,198,118,112,184,172, 87,  2,173,117,176,229,247,253,
  137,185, 99,164,102,147, 45, 66,231, 52,141,211,194,206,246,238,
   56,110, 78,248, 63,240,189, 93, 92, 51, 53,183, 19,171, 72, 50,
   33,104,101, 69,  8,252, 83,120, 76,135, 85, 54,202,125,188,213,
   96,235,136,208,162,129,190,132,156, 38, 47,  1,  7,254, 24,  4,
  216,131, 89, 21, 28,133, 37,153,149, 80,170, 68,  6,169,234, 151
);



sub pearson
{
    my @message = unpack("C*", shift);
    my $pos     = @message;
    my $hash    = @message & 0xFF;

    while ($pos > 0) {
        $hash = $p_tbl[$hash ^ $message[--$pos]];
    }

    return $hash;
}

1;
__END__

=head1 NAME

Digest::Pearson::PurePerl - Pure Perl interface to Pearson hash

=head1 SYNOPSIS

  use Digest::Pearson::PurePerl qw(pearson);

  my $hash = pearson("abcdef012345");  # 0 <= $hash < 256

=head1 DESCRIPTION

B<Digest::Pearson::PurePerl> is an implementation of Peter K. Pearson's hash algorithm
presented in "Fast Hashing of Variable Length Text Strings" - ACM 1990.
This hashing technique yields good distribution of hashed results for variable
length input strings on the range 0-255, and thus, it is well suited for data
load balancing.

If you prefer a fast implementation, you might want to consider L<Digest::Pearson> instead.

This module does not export anything by default. To use this hash function,
do either of the following.

B<use Digest::Pearson qw(pearson);>

B<Digest::Pearson::pearson($string)>

=head1 ACKNOWLEDGEMENTS

The implementation is derived from RFC 3074 - DHC Load Balancing Algorithm.

=head1 SEE ALSO

L<Digest::Pearson>, L<Digest::FNV>, L<Digest::DJB>.

=head1 BUGS

If you find any inaccurate or missing information, please send your comments to L<tnguyen@cpan.org>. Your effort is certainly appreciated!

=cut
