package Image::WordCloud::StopWords::EN;

use strict;
use warnings;

use base qw(Exporter);

our @EXPORT_OK = qw( %STOP_WORDS );

our %STOP_WORDS = map { $_ => 1 } qw(
a
about
after
all
almost
among
an
and
any
are
as
at
be
been
before
being
but
by
can
come
did
do
even
ever
every
for
from
get
go
had
has
have
he
her
him
himself
his
i
if
in
into
is
it
its
last
like
long
made
may
me
might
more
more
most
much
must
my
no
not
now
of
on
one
only
or
other
out
own
said
same
say
see
she
should
so
some
still
than
that
that
the
their
them
then
there
these
they
this
those
thou
three
through
to
two
up
upon
was
were
what
when
where
which
while
who
who
will
with
would
you
your
);

1;

__END__

=pod

=head1 NAME

Image::WordCloud::StopWords::EN - Exports hash of English "stop" words, words we should not
include in any word clouds.

=head1 EXPORTS

=head2 %STOP_WORS

Hash of English stop words

	our %STOP_WORDS = map { $_ => 1 } qw(
		a
		about
		after
		all
		almost
		# ...
	);

=head1 COPYRIGHT & LICENSE

Copyright 2012 Brian Hann, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<Image::WordCloud>

=cut