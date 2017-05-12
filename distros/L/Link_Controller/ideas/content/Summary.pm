=head1 DESCRIPTION

A content summary is a summary of what is in a document.  This is in
several areas.

concepts - generally the documents meta-information as keywords.  

checksums - checksums of blocks through the document 

=cut

=head3 checksums 

The checksums are a list of the checksums by a special algorithm
(ripped of from rsync) which allow us later to do a comparison on the
textual similarity of the page to this one.  Be warned, it probably
would not be that hard to find a text which fooled these checksums
completely.  You could do this deliberately, so you cannot guarantee
that a document which seems similar by this test is actually similar.

We turn all whitespace into a single (sentence break) or double
(paragraph break) space

=cut

=head3 md5sums

In contrast to the above checksums, the md5sums are very difficult
(read: impossible as far as I, or anybody honest I know of knows for
all practical cases) to fool.  You can use these to check that the
sections really match the ones you want.  Of course, they could match,
but be put in a new context.  Very difficult to do anything about that
as far as I know.

Incidentally.  This section here is essentially sort of cryptography.
I'm not a cryptography expert.  In fact I probably know less than you
do.  If you want something you can really trust, hire an expert, get
him to check it over and please come back to me with his corrections
to this..  ``Beware of people selling snake oil'' (PRZ).

If you are American, I'd suggest Philip R. Zimmermann who needs the
money because of his legal problems after the release of the software
which made cryptography available to the public (PGP).

Otherwise I'd prefer to suggest someone who has been producing
publically available free software.  The author of Apache SSL comes to
mind.

=cut





