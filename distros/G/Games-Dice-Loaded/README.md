Last night I read [Keith Schwarz's
article](http://www.keithschwarz.com/darts-dice-coins/) about Vose's *alias
method* for simulating rolls of a loaded die. It's worth reading the whole
thing, but here's the tl;dr: draw a bar chart of the probabilities of landing
on the various sides, then throw darts at it (by picking X and Y coordinates
uniformly at random). If you hit a bar with your dart, choose that side. That
works OK, but has very bad worst-case behaviour; fortunately, it's possible to
cut up the taller bars and stack them on top of the shorter bars in such a way
that the area covered is exactly a (1/n) \* n rectangle. Constructing this
rectangular "dartboard" can be done in O(n) time; thereafter, simulating a
die roll can be done in O(1) time (generate the dart's coordinates; which
vertical slice did the dart land in, and is it in the shorter bar on the bottom
or the "alias" that's been stacked above it?).

"Gosh," I thought, "what an elegant and efficient algorithm! I wonder if anyone
has put an implementation of it on CPAN?"

So I looked. And, as far as I can tell, they haven't.

So I wrote this implementation on the bus this morning.

You're welcome.
