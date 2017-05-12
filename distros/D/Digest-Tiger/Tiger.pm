package Digest::Tiger;

# Digest::Tiger perl module written by Clinton Wong.
# This program is free software; you can redistribute it and/or 
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.02';

bootstrap Digest::Tiger $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Digest::Tiger - a module that implements the tiger hash

=head1 SYNOPSIS

 use Digest::Tiger;

 # hash() returns a 192 bit hash
 my $hash = Digest::Tiger::hash('Tiger')

 # hexhash() returns a hex representation of the 192 bits...
 # $hexhash should be 'DD00230799F5009FEC6DEBC838BB6A27DF2B9D6F110C7937'
 my $hexhash = Digest::Tiger::hexhash('Tiger')

=head1 DESCRIPTION

A perl module that implements the tiger hash, which is believed
to be secure and runs quickly on 64-bit processors.

=head1 AUTHOR

Perl interface by Clinton Wong, reference C code used by
Digest::Tiger supplied by Ross Anderson and Eli Biham.

This module is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.  

=head1 NOTE

As of version 0.02, hexhash() returns a hex digest starting
with the least significant byte first.  For example:

 Hash of "Tiger":
  0             7  8            15 16            23
 DD00230799F5009F EC6DEBC838BB6A27 DF2B9D6F110C7937

 Instead of:
  7             0 15             8 23            16
 9F00F599072300DD 276ABB38C8EB6DEC 37790C116F9D2BDF

The print order issue was brought up by Gordon Mohr; Eli Biham clarifies with:
"The testtiger.c was intended to allow easy testing of the code,
rather than to define any particular print order.
...using a standard printing method, like the one for MD5 or SHA-1,
the DD should probably should be printed first [for the example above]".

=head1 SEE ALSO

 http://www.cs.technion.ac.il/~biham/Reports/Tiger/

=cut

