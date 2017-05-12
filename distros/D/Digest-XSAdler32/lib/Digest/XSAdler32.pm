package Digest::XSAdler32;

use 5.010000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Digest::XSAdler32 ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

require XSLoader;
XSLoader::load('Digest::XSAdler32', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Digest::XSAdler32 - Implementation of the Adler32 checksum algorithm using XS

=head1 SYNOPSIS

  use Digest::XSAdler32;
  Digest::XSAdler32::updateAdler32(*FP, $offset, $size);

=head1 DESCRIPTION

Digest::XSAdler32 is an implementation of the Adler32 checksum algorithm. Unlike Digest::Adler
(http://search.cpan.org/~gaas/Digest-Adler32-0.03/lib/Digest/Adler32.pm) the algorithm is implemented
in C and linked using XS rather than in native Perl. This makes it significantly faster.

Unless you *really* need the additional speed, I would urge you to use Digest::Adler32 instead of this 
module.  

=head1 SEE ALSO

Digest::Adler32

=head1 AUTHOR

Aditya, E<lt>aditya@wasudeo.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
