package Digest::DJB;

use 5.006_00;
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::DJB ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.

our @EXPORT_OK = qw(djb);

our @EXPORT    = qw( );

our $VERSION   = "1.00";

bootstrap Digest::DJB $VERSION;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Digest::DJB - Perl extension to Daniel J. Bernstein's hashing algorithm.

=head1 SYNOPSIS

  use Digest::DJB qw(djb);
  
  my $hash = djb("abc123");

=head1 DESCRIPTION

C<Digest::DJB> is an implementation of D. J. Bernstein's hash which returns
a 32-bit unsigned value for any variable-length input string. An equivalent pure Perl
version is also available L<Digest::DJB::PurePerl>.

=head1 SEE ALSO

L<Digest::DJB::PurePerl>, L<Digest::Pearson>, L<Digest::FNV>.

=head1 BUGS

Please send your comments to L<tnguyen@cpan.org>.

=cut
