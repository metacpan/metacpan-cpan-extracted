package Digest::Pearson;

require  5.006_00;

use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::Pearson ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT_OK = qw(pearson);

our @EXPORT    = qw();

our $VERSION   = "1.00";

bootstrap Digest::Pearson $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Digest::Pearson - Perl interface to Pearson hash 

=head1 SYNOPSIS

  use Digest::Pearson qw(pearson);
  
  my $hash = pearson("abcdef012345");  # 0 <= $hash < 256

=head1 DESCRIPTION

B<Digest::Pearson> is an implementation of Peter K. Pearson's hash algorithm
presented in "Fast Hashing of Variable Length Text Strings" - ACM 1990.
This hashing technique yields good distribution of hashed results for variable
length input strings on the range 0-255, and thus, it is well suited for data
load balancing. 

The implementation is in C, so it is fast. If you prefer a pure Perl version
and can tolerate slower speed, you might want to consider L<Digest::Pearson::PurePerl> instead. 

This module does not export anything by default. To use this hash function,
do either of the following.

B<use Digest::Pearson qw(pearson);> 

B<Digest::Pearson::pearson($string)>

=head1 ACKNOWLEDGEMENTS

The implementation is derived from RFC 3074 - DHC Load Balancing Algorithm.

=head1 SEE ALSO

L<Digest::FNV>, L<Digest::DJB>, L<Digest::Pearson::PurePerl>.

=head1 BUGS

If you find any inaccurate or missing information, please send your comments to L<tnguyen@cpan.org>. Your effort is certainly appreciated!


=cut
