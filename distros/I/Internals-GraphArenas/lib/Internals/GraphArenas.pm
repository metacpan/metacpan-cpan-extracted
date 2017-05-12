package Internals::GraphArenas;

use strict;
use warnings;

use 5.007_003;

use XSLoader ();

BEGIN {
    our $VERSION = '0.01';
    XSLoader::load('Internals::GraphArenas', $VERSION);
}

1;
__DATA__
=head1 NAME

Internals::GraphArenas - chart a map of where perl locates data

=head1 SYNOPSIS

In your-script.pl

  #!perl
  use Internals::GraphArenas;
  Internals::GraphArenas::graph_arenas(); # Prints many C pointers to STDOUT

Pipe it to chart-memory:

  $ ./your-script.pl | chart-memory

Open the output:

  $ open memory-0.png

=head DESCRIPTION

Charts your perl's arenas memory as described at
L<http://use.perl.org/~jjore/journal/39604> and reproduced below

=head1 BLOG POST

At work, I've got a problem on the back burner which is kind of
interesting. We've got some mod_perl processes with big data sets. The
processes fork and then serve requests. I've heard from Operations
that they're not using Linux's Copy-on-Write feature to the extent
desired so I'm trying to understand just what's being shared and not
shared.

To that end, I wanted to map out where perl put its data. I made a
picture (L<http://diotalevi.isa-geek.net/~josh/090909/memory-0.png>, a
strip, showing the visible linear memory layout from C<0x3042e0> at
the top to C<0x8b2990> at the bottom. The left edge shows where arenas
are. The really clustered lines to the middle show the pointers from
the arenas to the SV heads. The really splayed lines from the middle
to the right show the C<SvANY()> pointer from the SV heads to the SV
bodies.

I kind of now suspect that maybe the CoW unshared pages containing SV
heads because of reference counting are maybe compact or sparse. They
sure seem to be highly clustered so maybe it's a-ok to go get a bunch
of values between two forked processes and not worry about reference
counts. Sure, the SV head pages are going to be unshared but maybe
those pages are just full of other SV heads and it's not a big
deal. If SV heads weren't clustered then reference count changes could
have affected lots of other pages.

Anyway, there's a nice little set of pics at
L<http://diotalevi.isa-geek.net/~josh/090909/. I started truncating
precision by powers of two to get things to visually chunk up more. So
when you look at
L<http://diotalevi.isa-geek.net/~josh/090909/memory-0.png>, there's no
chunking but when you look at
L<http://diotalevi.isa-geek.net/~josh/090909/memory-4.png>, the bottom
4 bits were zeroed out.

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  Imager

=head1 COPYRIGHT & LICENSE

Copyright 2009 Joshua ben Jore, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SOURCE AVAILABILITY

This source is in Github: L<git://github.com/jbenjore/internals-dumparenas.git>

=head1 AUTHOR

Written by Josh ben Jore with inspiration from Spoon's L<http://netjam.org/spoon/viz/>
