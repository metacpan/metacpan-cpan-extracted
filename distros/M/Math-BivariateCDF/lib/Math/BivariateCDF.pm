package Math::BivariateCDF;

use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Math::BivariateCDF ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
    'all' => [qw(
            bivnor
            )]);

our @EXPORT_OK = (@{$EXPORT_TAGS{'all'}});

our @EXPORT = qw(

);

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Math::BivariateCDF', $VERSION);

# Preloaded methods go here.

1;
__END__

=head1 NAME

Math::BivariateCDF - Perl extension for Bivariate CDF functions.

=head1 SYNOPSIS

  use Math::BivariateCDF qw(bivnor);

  my $cdf = Math::BivariateCDF::bivnor( 0.036412293026205, 0.0708220179920969, 0.734208757779421 );

  print $cdf; #0.359905409368831

=head1 DESCRIPTION

This is a Perl wrapper for TOMS462 C library which evaluates the upper right tail of the bivariate normal distribution.
Wikipedia: https://en.wikipedia.org/wiki/Multivariate_normal_distribution#Bivariate_case .

=head2 EXPORT


=head2 Exportable functions

  double bivnor ( double ah, double ak, double r )



=head1 SEE ALSO

https://people.sc.fsu.edu/~jburkardt/c_src/toms462/toms462.html

=head1 AUTHOR

binary.com, E<lt>support@binary.com<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by binary.com.

This module are distributed under the GNU LGPL license.


=cut
