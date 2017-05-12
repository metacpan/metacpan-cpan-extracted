package Digest::DJB32;
BEGIN {
  $Digest::DJB32::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Digest::DJB fixed to 32bit
$Digest::DJB32::VERSION = '0.002';
use strict;
use warnings;

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw( djb );

our @EXPORT    = qw( );

bootstrap Digest::DJB32 $Digest::DJB32::VERSION;

# Preloaded methods go here.

1;

__END__

=pod

=head1 NAME

Digest::DJB32 - Digest::DJB fixed to 32bit

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Digest::DJB32 qw(djb32);
  
  my $hash = djb32("abc123");

=head1 DESCRIPTION

C<Digest::DJB32> is an implementation of D. J. Bernstein's hash which returns
a 32-bit unsigned value for any variable-length input string.

=head1 SEE ALSO

L<Digest::DJB>

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
