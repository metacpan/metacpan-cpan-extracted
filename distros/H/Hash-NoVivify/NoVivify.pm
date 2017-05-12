package Hash::NoVivify;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
		Exists
		Defined
	    );
$VERSION = '0.01';

bootstrap Hash::NoVivify $VERSION;


1;
__END__

=head1 NAME

Hash::NoVivify - Perl extension for non-vivifying exists and defined functions

=head1 SYNOPSIS

  use Hash::NoVivify qw(Defined Exists);

  ...

  if (Exists(\%hash, qw(key1 key2 ... keyn ))) {
      ...
  }

  if (Defined(\%hash, qw(key1 key2 ... keyn))) {
      ...
  }

=head1 DESCRIPTION

When used on a hash, the exists() and defined() functions will create
entries in a hash in order to evaluate the function.

For instance, the code:


    %a = (a => 1, b=> 2);
    print "Doesn't exist\n" unless exists($a{c});
    print "Also Doesn't exist\n" unless exists($a{c}->{d});
    print "Oh, my, not good\n" if exists($a{c});

will print out:

    Doesn't exist
    Also Doesn't exist
    Oh, my, not good

The Hash::NoVivify module provides two functions, Defined() and
Exists(), which avoid this, at the cost of a slightly convoluted
syntax. Both functions take a reference to a hash, followed by a list
of descending keys defining the hash entry to be investigated.

=head1 AUTHOR

Brent B. Powers (B2Pi), Powers@B2Pi.com

Copyright(c) 1999 Brent B. Powers. All rights reserved. This program
is free software, you may redistribute it and/or modify it under the
same terms as Perl itself.

=head1 SEE ALSO

perl(1), perlfunc(1).

=cut
