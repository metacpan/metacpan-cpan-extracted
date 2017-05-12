package Lingua::EN::StopWordList;

use 5.008;
use strict;
use warnings;

our $VERSION = '1.02';

# -----------------------------------------------

sub new
{
	my($class) = @_;

	return bless {}, $class;

}	# End of new.

# -----------------------------------------------

sub words
{
	my($self) = @_;

	return [qw/
a
able
about
above
abroad
according
accordingly
across
actually
adj
after
afterwards
again
against
ago
ahead
ain't
all
allow
allows
almost
alone
along
alongside
already
also
although
always
am
amid
amidst
among
amongst
an
and
another
any
anybody
anyhow
anyone
anything
anyway
anyways
anywhere
apart
appear
appreciate
appropriate
are
aren't
around
a's
as
aside
ask
asking
associated
at
available
away
awfully
b
back
backward
backwards
be
became
because
become
becomes
becoming
been
before
beforehand
begin
behind
being
believe
below
beside
besides
best
better
between
beyond
both
brief
but
by
c
came
can
cannot
can't
cant
caption
cause
causes
certain
certainly
changes
clearly
c'mon
co.
co
com
come
comes
concerning
consequently
consider
considering
contain
containing
contains
corresponding
could
couldn't
course
c's
currently
d
dare
daren't
definitely
described
despite
did
didn't
different
directly
do
does
doesn't
doing
done
don't
down
downwards
during
e
each
edu
eg
eight
eighty
either
else
elsewhere
end
ending
enough
entirely
especially
et
etc
even
ever
evermore
every
everybody
everyone
everything
everywhere
ex
exactly
example
except
f
fairly
far
farther
few
fewer
fifth
first
five
followed
following
follows
for
forever
former
formerly
forth
forward
found
four
from
further
furthermore
g
get
gets
getting
given
gives
go
goes
going
gone
got
gotten
greetings
h
had
hadn't
half
happens
hardly
has
hasn't
have
haven't
having
he
he'd
he'll
hello
help
hence
her
here
hereafter
hereby
herein
here's
hereupon
hers
herself
he's
hi
him
himself
his
hither
hopefully
how
howbeit
however
hundred
i
i'd
ie
if
ignored
i'll
i'm
immediate
in
inasmuch
inc.
inc
indeed
indicate
indicated
indicates
inner
inside
insofar
instead
into
inward
is
isn't
it
it'd
it'll
it's
its
itself
i've
j
just
k
keep
keeps
kept
know
known
knows
l
last
lately
later
latter
latterly
least
less
lest
let
let's
like
liked
likely
likewise
little
look
looking
looks
low
lower
ltd
m
made
mainly
make
makes
many
may
maybe
mayn't
me
mean
meantime
meanwhile
merely
might
mightn't
mine
minus
miss
more
moreover
most
mostly
mr
mrs
much
must
mustn't
my
myself
n
name
namely
nd
near
nearly
necessary
need
needn't
needs
neither
never
neverf
neverless
nevertheless
new
next
nine
ninety
no
nobody
non
none
nonetheless
no-one
noone
nor
normally
not
nothing
notwithstanding
novel
now
nowhere
o
obviously
of
off
often
oh
ok
okay
old
on
once
one
one's
ones
only
onto
opposite
or
other
others
otherwise
ought
oughtn't
our
ours
ourselves
out
outside
over
overall
own
p
particular
particularly
past
per
perhaps
placed
please
plus
possible
presumably
probably
provided
provides
q
que
quite
qv
r
rather
rd
re
really
reasonably
recent
recently
regarding
regardless
regards
relatively
respectively
right
round
s
said
same
saw
say
saying
says
second
secondly
see
seeing
seem
seemed
seeming
seems
seen
self
selves
sensible
sent
serious
seriously
seven
several
shall
shan't
she
she'd
she'll
she's
should
shouldn't
since
six
so
some
somebody
someday
somehow
someone
something
sometime
sometimes
somewhat
somewhere
soon
sorry
specified
specify
specifying
still
sub
such
sup
sure
t
take
taken
taking
tell
tends
th
than
thank
thanks
thanx
that
that'll
that's
thats
that've
the
their
theirs
them
themselves
then
thence
there
thereafter
thereby
there'd
therefore
therein
there'll
there're
there's
theres
thereupon
there've
these
they
they'd
they'll
they're
they've
thing
things
think
third
thirty
this
thorough
thoroughly
those
though
three
through
throughout
thru
thus
till
to
together
too
took
toward
towards
tried
tries
truly
try
trying
t's
twice
two
u
un
under
underneath
undoing
unfortunately
unless
unlike
unlikely
until
unto
up
upon
upwards
us
use
used
useful
uses
using
usually
v
value
various
versus
very
via
viz
vs
w
want
wants
was
wasn't
way
we
we'd
welcome
we'll
well
went
we're
were
weren't
we've
what
whatever
what'll
what's
what've
when
whence
whenever
where
whereafter
whereas
whereby
wherein
where's
whereupon
wherever
whether
which
whichever
while
whilst
whither
who
who'd
whoever
whole
who'll
whom
whomever
who's
whose
why
will
willing
wish
with
within
without
wonder
won't
would
wouldn't
x
y
yes
yet
you
you'd
you'll
your
you're
yours
yourself
yourselves
you've
z
zero
/];


} # End of words.

# -----------------------------------------------

1;

=pod

=head1 NAME

Lingua::EN::StopWordList - A sorted list of English stop words

=head1 Synopsis

	use Lingua::EN::StopWordList;

	my($ara_ref) = Lingua::EN::StopWordList -> new -> words;

Here's a complete program:

	use strict;
	use warnings;
	use Lingua::EN::StopWordList;

	my($count) = 0;

	print map{"@{[++$count]}: $_\n"} @{Lingua::EN::StopWordList -> new -> words};

=head1 Description

C<Lingua::EN::StopWordList> is a pure Perl module.

It returns a sorted arrayref of 659 English stop words.

=head1 Constructor and initialization

new(...) returns an object of type C<Lingua::EN::StopWordList>.

This is the class's contructor.

Usage: C<< Lingua::EN::StopWordList -> new >>.


=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

Install C<Lingua::EN::StopWordList> as you would for any C<Perl> module:

Run:

	cpanm Lingua::EN::StopWordList

or run:

	sudo cpan Lingua::EN::StopWordList

or unpack the distro, and then run one of:

	perl Build.PL
	./Build
	./Build test
	./Build install

or

	perl Makefile.PL
	make (or dmake)
	make test
	make install

See L<http://savage.net.au/Perl-modules.html> for details.

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html> for
help on unpacking and installing.

=head1 Methods

=head2 new()

See L</Constructor and initialization>.

=head2 words()

Returns the sorted arrayref of English stop words.

=head1 FAQ

=head2 Is there a definitive list of stop words?

No, there is no such thing as a definitive list.
For an important discussion, e.g. including 'phrase search', see
L<the Wikipedia discussion of word lists|http://en.wikipedia.org/wiki/Stop_words>.

=head2 Where does the list come from?

I downloaded it from the bottom of this page: L<http://www.translatum.gr/forum/index.php?topic=2476.0>.
It contains 659 words.

=head2 Are there other lists available?

Sure. Try L<http://jmlr.csail.mit.edu/papers/volume5/lewis04a/a11-smart-stop-list/english.stop>.
This list contains 570 words.

Another good place to look is L<http://www.ranks.nl/resources/stopwords.html>, but its English list
only contains 174 words. Since L<Lingua::StopWords> (below) also has 174 words in its Englist list,
perhaps this is where that module got its words from.
Lastly, it has stop word lists for a whole range of languages.

Alternately, just Google for references to various lists. Note however these lists are normally very
short.

=head2 Why another Perl module for stop words?

L<Lingua::StopWords> only has a short list of words (174). And its bug list goes back 3 years.

L<Lingua::EN::StopWords> only has a short list of words (227). Also, this module is part of
L<Lingua::EN::Segmenter>, whose documentation is poor. Even the exact basis of how it splits text
is not documented. Lastly, its bug list goes back 6 years.

I could have offered to take over maintentance of either or both those modules, but there are problems:

=over 4

=item o L<Lingua::StopWords>

It ships with a set of sub-modules, with names like L<Lingua::StopWords::EN>, but I'm not in a position
to support its other languages if I put my module's English list into it.

Nevertheless, the fact that it supports 13 languages is definitely something in favour of this module.

=item o L<Lingua::EN::StopWords>

This is part of text processing stuff which I don't want to get involved with. Also, it has a long
list of pre-reqs (not listed on MetaCPAN until you view the makefile), which may well suit the purposes
of L<Lingua::EN::Segmenter>, but is overkill for just a stop word list.

=back

Several other Perl modules, written for various purposes, either use one of the above, or have their
own very short (as always) lists.

=head2 How can I help?

If you translate the list of stop words in this module into your favourite language and email it to
me, I will include your words in the next release.

It all depends on whether you think this new list is somehow 'better' than the lists in pre-existing
modules. I cannot make that decision on your behalf.

=head1 See Also

L<Benchmark::Featureset::StopwordLists>.

This module includes a comparison of various stopword list modules.

See L<http://savage.net.au/Perl-modules/html/stopwordlists.report.html>.

L<Lingua::EN::StopWords>.

L<Lingua::StopWords>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua::EN::StopWordList>.

=head1 Repository

L<https://github.com/ronsavage/Lingua-EN-StopWordList.git>.

=head1 Author

C<Lingua::EN::StopWordList> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Homepage: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012 Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html


=cut
