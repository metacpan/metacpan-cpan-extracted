package Digest::OAT;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

our @EXPORT_OK = ('oat');

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('Digest::OAT', $VERSION);


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Digest::OAT - Bob Jenkin's One-at-a-Time hash function

=head1 SYNOPSIS

  use Digest::OAT qw(oat);
  my $hashed_key = oat('key');

=head1 DESCRIPTION

Bob Jenkin's One at a Time hash function implemented in C.
This hash function is quick and has excellent Avalanche Test behavior.
It is not used for crytography, instead it is use for building int 
values for hash tables or for use in Consistent Hashing implementations.

=head2 EXPORT

None by default.

=head1 AUTHOR

Marlon Bailey, E<lt>mbailey at cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Marlon Bailey

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
