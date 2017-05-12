package Math::Int64::C_API::Sample;

our $VERSION = '0.09';

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT = qw(some_int64 uint64_sqr int64_addmul uint64_rand sv_seti64 sv_setu64);


require XSLoader;
XSLoader::load('Math::Int64::C_API::Sample', $VERSION);


1;
__END__

=head1 NAME

Math::Int64::C_API::Sample - C API Usage sample for Math::Int64

=head1 SYNOPSIS

  use Math::Int64::C_API::Sample;

=head1 DESCRIPTION

This is a sample module, look at its source!

=head2 EXPORT

The sample subroutines available from this module are:

  some_int64()
  uint64_sqr(u64)
  int64_addmul(acu, mul1, mul2)

=head1 SEE ALSO

L<Math::Int64>

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

The contents of this package are on the public domain.

=cut
