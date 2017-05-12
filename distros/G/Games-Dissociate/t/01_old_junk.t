require 5;
use strict;
use Test;
BEGIN { plan tests => 7 };
use Games::Dissociate;
ok 1;


my $input = q{

[From the Perl-AI list, http://netizen.com.au/mailman/listinfo/perl-ai/]

From sburke@netadventure.net Sat, 23 Oct 1999 14:59:55 -0600
To: perl-ai@netizen.com.au
Date: Sat, 23 Oct 1999 14:59:55 -0600
From: Sean M. Burke sburke@netadventure.net
Subject: [Perl-AI] parsing NLs, and constructed languages

"Peter Sergeant" <sargie@hotmail.com> said:
>English language is difficult for a computer to understand because its
>not standardised.

I think the experience of the past few decades' worth of protocols shows
that standardization (even if everyone follows it) doesn't equate to
intelligibility.  Example: last I heard, IETF-Languages was still puzzling
over what "Content-Language: en-US, es" means -- do you need to understand
BOTH en-US (US English) and Spanish to understand the document, or just one
or the other.  And does "es" mean "a dialect of Spanish intelligible to the
average Spanish-speaker of whatever dialect" or "a form of Spanish not
identifiable/identified as belonging to any particular dialect"?  But don't
get me started.

And moreover, standards bodies like the Academie Francaise seem never to
consider the problems in their languages that make them hard to parse by
machines.

But Don Blaheta <dpb@cs.brown.edu> hit the nail on the head:
>The real problem with Eo as a computer interaction language is that all
>the same natural language problems are present, like PP attachment ("I
>saw the man with the telescope"), adj-noun modification ("pretty little
>girls school"), not to mention homography and even the occasional idiom.
>The problems it solves make it great as a human auxlang, not so good for
>computers.

Yes, I've always thought Esperanto to be passable at the problems it
deliberately tackles -- improving learnability by regularizing verb
paradigms where most other Romance languages have no end of irregularity.
But I am quite disappointed with the other parts of Esperanto:  parsability
(as pointed out above), choice of tenses (suppose that instead of
past-present-future, it were realis-irrealis, or stative-factual, or
prefect-imperfect, or any mix of these), or a better treatment of the
internal semantics of compounds beyond the feeble and unimaginative
derivational suffixes the languagae has.  Granted, the initial developers
of Esperanto were working with mid-19th century ideas about linguistics,
and nothing more; considering that, they did okay.  However, Esperanto is,
as constructed languages go, a blinding glimpse of the merely obvious.

It is ironic that the early Esperantists apparently never saw a grammar of
any of the Romance-based creoles, or they'd have found that many of their
goals had already been cleverly acheived -- by illiterate slaves, no less!
And all without the sort of ouija-board phonotaxis one sees some of in
Esperanto, lots of in Lojban.


Now Lojban is the only artificial language that I know of (along with
Loglan, which I hear is basically a variant) that was deliberately designed
to be syntactically regular and parseable by machines, while still useable
by humans.  (This is as oppposed to some formalism useful for computer
interaction but never meant to be used as a human language.)

However, I can recall my impressions of it, as a linguist, altho one
without much background in NLP:
A year or two ago, I tried and tried to make sense of some grammars of
Lojban, such as the one at http://www.animal.helsinki.fi/lojban/
Unfortunately, much of it eludes me, and I may have since forgotten some of
the points that I was able to make out.

But I do recall Lojban having features that made quite clear the syntactic
constituency of any sentence, such as would disambiguate the two ways to
parse "pretty girls' school".  (I don't recall rigorously demonstrating to
myself that these features would disambiguate ALL kinds of ambiguities of
synactic ambiguity, but I took the author's word for it.)  I vaguely recall
the features being something like asserting that default attachment should
always be as low as possible in the syntax tree, but then providing ways to
specify higher attachment.

However, as I read the description of these features, I had the very strong
impression that while one could propose/hypothesize a language with these
features, the result would not be something anyone could learn.  I.e., I
felt sure that if I had to produce a sentence involving attachment, I'd
always have to stop and picture a syntax tree, and then I'd have to
carefully picture where attachment would go, and then trying to remember
how it is I'd need to specify that kind of attachment.  I could imagine
being able to do it, but /never/ being able to do it unconsciously, i.e.,
"naturally".

This led me to come up with a conjecture, in the spirit of mathematical
conjectures -- i.e., maybe "I don't see why this has to be true, but I
can't prove it's not", or maybe "I think this MUST be true, but I can't see
any way to prove it".  I call it the "Ambiguity Conjecture" -- or, in case
there's any other different like-named conjectures out there, "Burke's
Ambiguity Conjecture":


Burke's Ambiguity Conjecture
----------------------------

Natural languages exhibit many phenomena which make them very hard for them
to be parsed by machines.  These phenomena may include polysemy/homophony
of words (e.g., "bank" meaning either a place where your money is kept, or
the side of a river) or other morphemes (e.g.: that the subject marker and
the object marker in a given language, ususally distinct, may be
homophonous in some situation), or that a given surface form of a word can
represent more than one part of speech ("flies" as a noun, or verb; ditto
"saw").  Complex morphophology may also complicate parsing.  However, the
difficulty of these phenomena vary from language to language, and from
language type or language type.  A phenomenon that poses a significant
parseability obstacle in one language may be totally unproblematic or even
absent in others.

But I think that one problem area is common to all languages: syntactic
ambiguity.  This is the problem underlying the classic phrase "pretty
girls' school" -- where the sense and part of speech of all the words is
clear, but where it's unclear whether this should be parsed as 1 or as 2:

1) [[pretty girls]' school]  (the school for/with girls who are pretty)
2) [pretty [girls' school]]  (the school for/with girls which is pretty)

Agreement systems (as in the English paraphrases) in some languages might
disambiguate this particular case (i.e., if "pretty" showed agreement with
"school" or with "girls"), but such systems are not a general solution.  In
the languages I've read grammars of, I've never found anything approaching
a general solution to this.  So I conject:

Burke's Ambiguity Conjecture:
* All natural languages are subject to syntactic ambiguity.

And a corollary:
* Artificial languages constructed to make syntactic ambiguity impossible
will be so unnatural as to be unlearnable by humans.  (I.e., that aspect of
the language will be unlearnable.  The rest of the language might well be
quite learnable.)


Another way to say this is: the mechanism that the brain uses to generate
synactic sentences is /incapable of reliably recognizing/ (or learning to
reliably recognize) when it has produced a synactic structure that contains
ambiguity.  Or: that it's incapable of distinguishing the kinds of
high-versus-low attachment that are the sources of these kinds of ambiguity.

Formally speaking, this conjecture has problems -- but hey, it's just a
conjecture.  Most notably, it's basically asserting a negative: nowhere
does (nor could there) there exist a natural language is free of syntactic
ambiguity.  I don't think it can be /proven/ true, because no-one can
examine all existing or potential natural languages, nor can anyone prove
that there's /no/ way to naturally teach someone a language free of
synactic ambiguity.
However, it can be /disproven/ to various degrees: one could simply point
out a natural language (such as I've just happened never to come across)
that does distinguish low-versus-high attachment.  Hopefully such a
mechanism wouldn't be idiosyncratic to attachment in a particular
structure, but would be general to much or all of the language's syntax.



Now, suppose this conjecture is true.
Back in the real world, one way to get around it in NLP is to have the
interface to the user /refuse/ any sentences which it finds to be
syntactically ambiguous.  This might make interaction in natural English
impossible; but interaction in some constructed language designed to
minimize (if not eliminate) ambiguity might still be feasible.
Another way, not so different, is that when ambiguous sentences are
encountered, the computer should ask the user for disambiguation.

--
Sean M. Burke sburke@netadventure.net http://www.netadventure.net/~sburke/

};

ok dissociate( $input ), '/\w/';
ok dissociate( $input ), '/\w/';
ok dissociate( $input ), '/\w/';
ok dissociate( $input ), '/\w/';
ok dissociate( $input ), '/\w/';

print "# Okay, that's that.\n";
ok 1;

