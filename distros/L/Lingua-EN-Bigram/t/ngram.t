use strict;
use Test::Exception;
use Test::More tests => 28;

# ngram.t - regression texts for Lingua::EN::Bigram

# Eric Lease Morgan <eric_morgan@infomotions.com>
# June   18, 2009 - first cut
# June   19, 2009 - made more complete
# August 23, 2010 - updated for versions 0.02 and 0.03; included Test::Exception


# use 
use_ok( 'Lingua::EN::Bigram' );

# constructor
my $ngrams = Lingua::EN::Bigram->new;
isa_ok( $ngrams, 'Lingua::EN::Bigram' );

# slurp up test data
my $text = do { local $/; <DATA> };

# set/get text
$ngrams->text( $text );
like( $ngrams->text, qr/^                                     350 BC/, 'set/get text' );

# individual words
my @words = $ngrams->words;
is( scalar( @words ), 10887, 'words in an array of 10887 items' );
is( $words[ 1 ], 'bc', 'element number 1 of words is "bc"' );

# individual word count
my $word_count = $ngrams->word_count;
is( ref( $word_count ), 'HASH', 'word_count is a hash' );
is( $$word_count{ 'something' }, 15, '"something" occurs 15 times' );

# bi-grams
my @bigrams = $ngrams->bigrams;
is( scalar( @bigrams ), 10886, 'bigrams is an array of 10886 items' );
is( $bigrams[ 1 ], 'bc metaphysics', 'element number 1 of bigrams is "bc metaphysics"' );

# bi-gram_count
my $bigram_count = $ngrams->bigram_count;
is( ref( $bigram_count ), 'HASH', 'bigram_count is a hash' );
is ( $$bigram_count{ 'something else' }, 3, '"something else" occurs 3 times' );

# tscore
my $tscore = $ngrams->tscore;
is( ref( $tscore ), 'HASH', 'tscore is a hash' );
is( $$tscore{ 'something else' }, 1.72489160059353, '"something else: has a tscore of 1.72489160059353' );

# trigrams
my @trigrams = $ngrams->trigrams;
is( scalar( @trigrams ), 10886, 'trigrams is an array of 10886 items' );
is( $trigrams[ 1 ], 'bc metaphysics by', 'element number 1 of bigrams is "bc metaphysics by"' );

# trigram_count
my $trigram_count = $ngrams->trigram_count;
is( ref( $trigram_count ), 'HASH', 'trigram_count is a hash' );
is ( $$trigram_count{ 'bc metaphysics by' }, 1, '"bc metaphysics by" occurs 1 time' );

# quadgrams
my @quadgrams = $ngrams->quadgrams;
is( scalar( @quadgrams ), 10886, 'quadgrams is an array of 10886 items' );
is( $quadgrams[ 1 ], 'bc metaphysics by aristotle', 'element number 1 of bigrams is "bc metaphysics by aristotle"' );

# quadgram_count
my $quadgram_count = $ngrams->quadgram_count;
is( ref( $quadgram_count ), 'HASH', 'quadgram_count is a hash' );
is ( $$quadgram_count{ 'bc metaphysics by aristotle' }, 1, '"bc metaphysics by aristotle" occurs 1 time' );

# ngram
my @ngrams = $ngrams->ngram( 4 );
is( scalar( @quadgrams ), 10886, 'quadgrams is an array of 10886 items' );
is( $quadgrams[ 1 ], 'bc metaphysics by aristotle', 'element number 1 of bigrams is "bc metaphysics by aristotle"' );

# ngram_count
my $ngram_count = $ngrams->ngram_count( \@ngrams );
is( ref( $quadgram_count ), 'HASH', 'ngram_count is a hash' );
is ( $$quadgram_count{ 'bc metaphysics by aristotle' }, 1, '"bc metaphysics by aristotle" occurs 1 time' );

# ngram & ngram_count sanity checks
dies_ok { $ngrams->ngram } 'trapped not passing an argument to ngram';
dies_ok { $ngrams->ngram( 5.5 ) } 'trapped need to pass an integer to ngram';
dies_ok { $ngrams->ngram_count( 'foo' )} 'trapped need to pass ngram_count an array reference';

# done, whew!
exit;


# sample data
__DATA__
                                     350 BC

                                  METAPHYSICS

                                  by Aristotle

                            translated by W. D. Ross

                                Book I

                                   1

    ALL men by nature desire to know. An indication of this is the
delight we take in our senses; for even apart from their usefulness
they are loved for themselves; and above all others the sense of
sight. For not only with a view to action, but even when we are not
going to do anything, we prefer seeing (one might say) to everything
else. The reason is that this, most of all the senses, makes us know
and brings to light many differences between things.

    By nature animals are born with the faculty of sensation, and from
sensation memory is produced in some of them, though not in others.
And therefore the former are more intelligent and apt at learning than
those which cannot remember; those which are incapable of hearing
sounds are intelligent though they cannot be taught, e.g. the bee, and
any other race of animals that may be like it; and those which besides
memory have this sense of hearing can be taught.

    The animals other than man live by appearances and memories, and
have but little of connected experience; but the human race lives also
by art and reasonings. Now from memory experience is produced in
men; for the several memories of the same thing produce finally the
capacity for a single experience. And experience seems pretty much
like science and art, but really science and art come to men through
experience; for 'experience made art', as Polus says, 'but
inexperience luck.' Now art arises when from many notions gained by
experience one universal judgement about a class of objects is
produced. For to have a judgement that when Callias was ill of this
disease this did him good, and similarly in the case of Socrates and
in many individual cases, is a matter of experience; but to judge that
it has done good to all persons of a certain constitution, marked
off in one class, when they were ill of this disease, e.g. to
phlegmatic or bilious people when burning with fevers-this is a matter
of art.

    With a view to action experience seems in no respect inferior to
art, and men of experience succeed even better than those who have
theory without experience. (The reason is that experience is knowledge
of individuals, art of universals, and actions and productions are all
concerned with the individual; for the physician does not cure man,
except in an incidental way, but Callias or Socrates or some other
called by some such individual name, who happens to be a man. If,
then, a man has the theory without the experience, and recognizes
the universal but does not know the individual included in this, he
will often fail to cure; for it is the individual that is to be
cured.) But yet we think that knowledge and understanding belong to
art rather than to experience, and we suppose artists to be wiser than
men of experience (which implies that Wisdom depends in all cases
rather on knowledge); and this because the former know the cause,
but the latter do not. For men of experience know that the thing is
so, but do not know why, while the others know the 'why' and the
cause. Hence we think also that the masterworkers in each craft are
more honourable and know in a truer sense and are wiser than the
manual workers, because they know the causes of the things that are
done (we think the manual workers are like certain lifeless things
which act indeed, but act without knowing what they do, as fire
burns,-but while the lifeless things perform each of their functions
by a natural tendency, the labourers perform them through habit); thus
we view them as being wiser not in virtue of being able to act, but of
having the theory for themselves and knowing the causes. And in
general it is a sign of the man who knows and of the man who does
not know, that the former can teach, and therefore we think art more
truly knowledge than experience is; for artists can teach, and men
of mere experience cannot.

    Again, we do not regard any of the senses as Wisdom; yet surely
these give the most authoritative knowledge of particulars. But they
do not tell us the 'why' of anything-e.g. why fire is hot; they only
say that it is hot.

    At first he who invented any art whatever that went beyond the
common perceptions of man was naturally admired by men, not only
because there was something useful in the inventions, but because he
was thought wise and superior to the rest. But as more arts were
invented, and some were directed to the necessities of life, others to
recreation, the inventors of the latter were naturally always regarded
as wiser than the inventors of the former, because their branches of
knowledge did not aim at utility. Hence when all such inventions
were already established, the sciences which do not aim at giving
pleasure or at the necessities of life were discovered, and first in
the places where men first began to have leisure. This is why the
mathematical arts were founded in Egypt; for there the priestly
caste was allowed to be at leisure.

    We have said in the Ethics what the difference is between art
and science and the other kindred faculties; but the point of our
present discussion is this, that all men suppose what is called Wisdom
to deal with the first causes and the principles of things; so that,
as has been said before, the man of experience is thought to be
wiser than the possessors of any sense-perception whatever, the artist
wiser than the men of experience, the masterworker than the
mechanic, and the theoretical kinds of knowledge to be more of the
nature of Wisdom than the productive. Clearly then Wisdom is knowledge
about certain principles and causes.

                                   2

    Since we are seeking this knowledge, we must inquire of what
kind are the causes and the principles, the knowledge of which is
Wisdom. If one were to take the notions we have about the wise man,
this might perhaps make the answer more evident. We suppose first,
then, that the wise man knows all things, as far as possible, although
he has not knowledge of each of them in detail; secondly, that he
who can learn things that are difficult, and not easy for man to know,
is wise (sense-perception is common to all, and therefore easy and
no mark of Wisdom); again, that he who is more exact and more
capable of teaching the causes is wiser, in every branch of knowledge;
and that of the sciences, also, that which is desirable on its own
account and for the sake of knowing it is more of the nature of Wisdom
than that which is desirable on account of its results, and the
superior science is more of the nature of Wisdom than the ancillary;
for the wise man must not be ordered but must order, and he must not
obey another, but the less wise must obey him.

    Such and so many are the notions, then, which we have about Wisdom
and the wise. Now of these characteristics that of knowing all
things must belong to him who has in the highest degree universal
knowledge; for he knows in a sense all the instances that fall under
the universal. And these things, the most universal, are on the
whole the hardest for men to know; for they are farthest from the
senses. And the most exact of the sciences are those which deal most
with first principles; for those which involve fewer principles are
more exact than those which involve additional principles, e.g.
arithmetic than geometry. But the science which investigates causes is
also instructive, in a higher degree, for the people who instruct us
are those who tell the causes of each thing. And understanding and
knowledge pursued for their own sake are found most in the knowledge
of that which is most knowable (for he who chooses to know for the
sake of knowing will choose most readily that which is most truly
knowledge, and such is the knowledge of that which is most
knowable); and the first principles and the causes are most
knowable; for by reason of these, and from these, all other things
come to be known, and not these by means of the things subordinate
to them. And the science which knows to what end each thing must be
done is the most authoritative of the sciences, and more authoritative
than any ancillary science; and this end is the good of that thing,
and in general the supreme good in the whole of nature. Judged by
all the tests we have mentioned, then, the name in question falls to
the same science; this must be a science that investigates the first
principles and causes; for the good, i.e. the end, is one of the
causes.

    That it is not a science of production is clear even from the
history of the earliest philosophers. For it is owing to their
wonder that men both now begin and at first began to philosophize;
they wondered originally at the obvious difficulties, then advanced
little by little and stated difficulties about the greater matters,
e.g. about the phenomena of the moon and those of the sun and of the
stars, and about the genesis of the universe. And a man who is puzzled
and wonders thinks himself ignorant (whence even the lover of myth
is in a sense a lover of Wisdom, for the myth is composed of wonders);
therefore since they philosophized order to escape from ignorance,
evidently they were pursuing science in order to know, and not for any
utilitarian end. And this is confirmed by the facts; for it was when
almost all the necessities of life and the things that make for
comfort and recreation had been secured, that such knowledge began
to be sought. Evidently then we do not seek it for the sake of any
other advantage; but as the man is free, we say, who exists for his
own sake and not for another's, so we pursue this as the only free
science, for it alone exists for its own sake.

    Hence also the possession of it might be justly regarded as beyond
human power; for in many ways human nature is in bondage, so that
according to Simonides 'God alone can have this privilege', and it
is unfitting that man should not be content to seek the knowledge that
is suited to him. If, then, there is something in what the poets
say, and jealousy is natural to the divine power, it would probably
occur in this case above all, and all who excelled in this knowledge
would be unfortunate. But the divine power cannot be jealous (nay,
according to the proverb, 'bards tell a lie'), nor should any other
science be thought more honourable than one of this sort. For the most
divine science is also most honourable; and this science alone must
be, in two ways, most divine. For the science which it would be most
meet for God to have is a divine science, and so is any science that
deals with divine objects; and this science alone has both these
qualities; for (1) God is thought to be among the causes of all things
and to be a first principle, and (2) such a science either God alone
can have, or God above all others. All the sciences, indeed, are
more necessary than this, but none is better.

    Yet the acquisition of it must in a sense end in something which
is the opposite of our original inquiries. For all men begin, as we
said, by wondering that things are as they are, as they do about
self-moving marionettes, or about the solstices or the
incommensurability of the diagonal of a square with the side; for it
seems wonderful to all who have not yet seen the reason, that there is
a thing which cannot be measured even by the smallest unit. But we
must end in the contrary and, according to the proverb, the better
state, as is the case in these instances too when men learn the cause;
for there is nothing which would surprise a geometer so much as if the
diagonal turned out to be commensurable.

    We have stated, then, what is the nature of the science we are
searching for, and what is the mark which our search and our whole
investigation must reach.

                                   3

    Evidently we have to acquire knowledge of the original causes (for
we say we know each thing only when we think we recognize its first
cause), and causes are spoken of in four senses. In one of these we
mean the substance, i.e. the essence (for the 'why' is reducible
finally to the definition, and the ultimate 'why' is a cause and
principle); in another the matter or substratum, in a third the source
of the change, and in a fourth the cause opposed to this, the
purpose and the good (for this is the end of all generation and
change). We have studied these causes sufficiently in our work on
nature, but yet let us call to our aid those who have attacked the
investigation of being and philosophized about reality before us.
For obviously they too speak of certain principles and causes; to go
over their views, then, will be of profit to the present inquiry,
for we shall either find another kind of cause, or be more convinced
of the correctness of those which we now maintain.

    Of the first philosophers, then, most thought the principles which
were of the nature of matter were the only principles of all things.
That of which all things that are consist, the first from which they
come to be, the last into which they are resolved (the substance
remaining, but changing in its modifications), this they say is the
element and this the principle of things, and therefore they think
nothing is either generated or destroyed, since this sort of entity is
always conserved, as we say Socrates neither comes to be absolutely
when he comes to be beautiful or musical, nor ceases to be when
loses these characteristics, because the substratum, Socrates
himself remains. just so they say nothing else comes to be or ceases
to be; for there must be some entity-either one or more than
one-from which all other things come to be, it being conserved.

    Yet they do not all agree as to the number and the nature of these
principles. Thales, the founder of this type of philosophy, says the
principle is water (for which reason he declared that the earth
rests on water), getting the notion perhaps from seeing that the
nutriment of all things is moist, and that heat itself is generated
from the moist and kept alive by it (and that from which they come
to be is a principle of all things). He got his notion from this fact,
and from the fact that the seeds of all things have a moist nature,
and that water is the origin of the nature of moist things.

    Some think that even the ancients who lived long before the
present generation, and first framed accounts of the gods, had a
similar view of nature; for they made Ocean and Tethys the parents
of creation, and described the oath of the gods as being by water,
to which they give the name of Styx; for what is oldest is most
honourable, and the most honourable thing is that by which one swears.
It may perhaps be uncertain whether this opinion about nature is
primitive and ancient, but Thales at any rate is said to have declared
himself thus about the first cause. Hippo no one would think fit to
include among these thinkers, because of the paltriness of his
thought.

    Anaximenes and Diogenes make air prior to water, and the most
primary of the simple bodies, while Hippasus of Metapontium and
Heraclitus of Ephesus say this of fire, and Empedocles says it of
the four elements (adding a fourth-earth-to those which have been
named); for these, he says, always remain and do not come to be,
except that they come to be more or fewer, being aggregated into one
and segregated out of one.

    Anaxagoras of Clazomenae, who, though older than Empedocles, was
later in his philosophical activity, says the principles are
infinite in number; for he says almost all the things that are made of
parts like themselves, in the manner of water or fire, are generated
and destroyed in this way, only by aggregation and segregation, and
are not in any other sense generated or destroyed, but remain
eternally.

    From these facts one might think that the only cause is the
so-called material cause; but as men thus advanced, the very facts
opened the way for them and joined in forcing them to investigate
the subject. However true it may be that all generation and
destruction proceed from some one or (for that matter) from more
elements, why does this happen and what is the cause? For at least the
substratum itself does not make itself change; e.g. neither the wood
nor the bronze causes the change of either of them, nor does the
wood manufacture a bed and the bronze a statue, but something else
is the cause of the change. And to seek this is to seek the second
cause, as we should say,-that from which comes the beginning of the
movement. Now those who at the very beginning set themselves to this
kind of inquiry, and said the substratum was one, were not at all
dissatisfied with themselves; but some at least of those who
maintain it to be one-as though defeated by this search for the second
cause-say the one and nature as a whole is unchangeable not only in
respect of generation and destruction (for this is a primitive belief,
and all agreed in it), but also of all other change; and this view
is peculiar to them. Of those who said the universe was one, then none
succeeded in discovering a cause of this sort, except perhaps
Parmenides, and he only inasmuch as he supposes that there is not only
one but also in some sense two causes. But for those who make more
elements it is more possible to state the second cause, e.g. for those
who make hot and cold, or fire and earth, the elements; for they treat
fire as having a nature which fits it to move things, and water and
earth and such things they treat in the contrary way.

    When these men and the principles of this kind had had their
day, as the latter were found inadequate to generate the nature of
things men were again forced by the truth itself, as we said, to
inquire into the next kind of cause. For it is not likely either
that fire or earth or any such element should be the reason why things
manifest goodness and, beauty both in their being and in their
coming to be, or that those thinkers should have supposed it was;
nor again could it be right to entrust so great a matter to
spontaneity and chance. When one man said, then, that reason was
present-as in animals, so throughout nature-as the cause of order
and of all arrangement, he seemed like a sober man in contrast with
the random talk of his predecessors. We know that Anaxagoras certainly
adopted these views, but Hermotimus of Clazomenae is credited with
expressing them earlier. Those who thought thus stated that there is a
principle of things which is at the same time the cause of beauty, and
that sort of cause from which things acquire movement.

                                   4

    One might suspect that Hesiod was the first to look for such a
thing-or some one else who put love or desire among existing things as
a principle, as Parmenides, too, does; for he, in constructing the
genesis of the universe, says:-

          Love first of all the Gods she planned.

    And Hesiod says:-

          First of all things was chaos made, and then

          Broad-breasted earth...

          And love, 'mid all the gods pre-eminent,

  which implies that among existing things there must be from the
first a cause which will move things and bring them together. How
these thinkers should be arranged with regard to priority of discovery
let us be allowed to decide later; but since the contraries of the
various forms of good were also perceived to be present in
nature-not only order and the beautiful, but also disorder and the
ugly, and bad things in greater number than good, and ignoble things
than beautiful-therefore another thinker introduced friendship and
strife, each of the two the cause of one of these two sets of
qualities. For if we were to follow out the view of Empedocles, and
interpret it according to its meaning and not to its lisping
expression, we should find that friendship is the cause of good
things, and strife of bad. Therefore, if we said that Empedocles in
a sense both mentions, and is the first to mention, the bad and the
good as principles, we should perhaps be right, since the cause of all
goods is the good itself.

    These thinkers, as we say, evidently grasped, and to this
extent, two of the causes which we distinguished in our work on
nature-the matter and the source of the movement-vaguely, however, and
with no clearness, but as untrained men behave in fights; for they
go round their opponents and often strike fine blows, but they do
not fight on scientific principles, and so too these thinkers do not
seem to know what they say; for it is evident that, as a rule, they
make no use of their causes except to a small extent. For Anaxagoras
uses reason as a deus ex machina for the making of the world, and when
he is at a loss to tell from what cause something necessarily is, then
he drags reason in, but in all other cases ascribes events to anything
rather than to reason. And Empedocles, though he uses the causes to
a greater extent than this, neither does so sufficiently nor attains
consistency in their use. At least, in many cases he makes love
segregate things, and strife aggregate them. For whenever the universe
is dissolved into its elements by strife, fire is aggregated into one,
and so is each of the other elements; but whenever again under the
influence of love they come together into one, the parts must again be
segregated out of each element.

    Empedocles, then, in contrast with his precessors, was the first
to introduce the dividing of this cause, not positing one source of
movement, but different and contrary sources. Again, he was the
first to speak of four material elements; yet he does not use four,
but treats them as two only; he treats fire by itself, and its
opposite-earth, air, and water-as one kind of thing. We may learn this
by study of his verses.

    This philosopher then, as we say, has spoken of the principles
in this way, and made them of this number. Leucippus and his associate
Democritus say that the full and the empty are the elements, calling
the one being and the other non-being-the full and solid being
being, the empty non-being (whence they say being no more is than
non-being, because the solid no more is than the empty); and they make
these the material causes of things. And as those who make the
underlying substance one generate all other things by its
modifications, supposing the rare and the dense to be the sources of
the modifications, in the same way these philosophers say the
differences in the elements are the causes of all other qualities.
These differences, they say, are three-shape and order and position.
For they say the real is differentiated only by 'rhythm and
'inter-contact' and 'turning'; and of these rhythm is shape,
inter-contact is order, and turning is position; for A differs from
N in shape, AN from NA in order, M from W in position. The question of
movement-whence or how it is to belong to things-these thinkers,
like the others, lazily neglected.

    Regarding the two causes, then, as we say, the inquiry seems to
have been pushed thus far by the early philosophers.

                                   5

    Contemporaneously with these philosophers and before them, the
so-called Pythagoreans, who were the first to take up mathematics, not
only advanced this study, but also having been brought up in it they
thought its principles were the principles of all things. Since of
these principles numbers are by nature the first, and in numbers
they seemed to see many resemblances to the things that exist and come
into being-more than in fire and earth and water (such and such a
modification of numbers being justice, another being soul and
reason, another being opportunity-and similarly almost all other
things being numerically expressible); since, again, they saw that the
modifications and the ratios of the musical scales were expressible in
numbers;-since, then, all other things seemed in their whole nature to
be modelled on numbers, and numbers seemed to be the first things in
the whole of nature, they supposed the elements of numbers to be the
elements of all things, and the whole heaven to be a musical scale and
a number. And all the properties of numbers and scales which they
could show to agree with the attributes and parts and the whole
arrangement of the heavens, they collected and fitted into their
scheme; and if there was a gap anywhere, they readily made additions
so as to make their whole theory coherent. E.g. as the number 10 is
thought to be perfect and to comprise the whole nature of numbers,
they say that the bodies which move through the heavens are ten, but
as the visible bodies are only nine, to meet this they invent a
tenth--the 'counter-earth'. We have discussed these matters more
exactly elsewhere.

    But the object of our review is that we may learn from these
philosophers also what they suppose to be the principles and how these
fall under the causes we have named. Evidently, then, these thinkers
also consider that number is the principle both as matter for things
and as forming both their modifications and their permanent states,
and hold that the elements of number are the even and the odd, and
that of these the latter is limited, and the former unlimited; and
that the One proceeds from both of these (for it is both even and
odd), and number from the One; and that the whole heaven, as has
been said, is numbers.

    Other members of this same school say there are ten principles,
which they arrange in two columns of cognates-limit and unlimited, odd
and even, one and plurality, right and left, male and female,
resting and moving, straight and curved, light and darkness, good
and bad, square and oblong. In this way Alcmaeon of Croton seems
also to have conceived the matter, and either he got this view from
them or they got it from him; for he expressed himself similarly to
them. For he says most human affairs go in pairs, meaning not definite
contrarieties such as the Pythagoreans speak of, but any chance
contrarieties, e.g. white and black, sweet and bitter, good and bad,
great and small. He threw out indefinite suggestions about the other
contrarieties, but the Pythagoreans declared both how many and which
their contraricties are.

    From both these schools, then, we can learn this much, that the
contraries are the principles of things; and how many these principles
are and which they are, we can learn from one of the two schools.
But how these principles can be brought together under the causes we
have named has not been clearly and articulately stated by them;
they seem, however, to range the elements under the head of matter;
for out of these as immanent parts they say substance is composed
and moulded.

    From these facts we may sufficiently perceive the meaning of the
ancients who said the elements of nature were more than one; but there
are some who spoke of the universe as if it were one entity, though
they were not all alike either in the excellence of their statement or
in its conformity to the facts of nature. The discussion of them is in
no way appropriate to our present investigation of causes, for. they
do not, like some of the natural philosophers, assume being to be
one and yet generate it out of the one as out of matter, but they
speak in another way; those others add change, since they generate the
universe, but these thinkers say the universe is unchangeable. Yet
this much is germane to the present inquiry: Parmenides seems to
fasten on that which is one in definition, Melissus on that which is
one in matter, for which reason the former says that it is limited,
the latter that it is unlimited; while Xenophanes, the first of
these partisans of the One (for Parmenides is said to have been his
pupil), gave no clear statement, nor does he seem to have grasped
the nature of either of these causes, but with reference to the
whole material universe he says the One is God. Now these thinkers, as
we said, must be neglected for the purposes of the present inquiry-two
of them entirely, as being a little too naive, viz. Xenophanes and
Melissus; but Parmenides seems in places to speak with more insight.
For, claiming that, besides the existent, nothing non-existent exists,
he thinks that of necessity one thing exists, viz. the existent and
nothing else (on this we have spoken more clearly in our work on
nature), but being forced to follow the observed facts, and
supposing the existence of that which is one in definition, but more
than one according to our sensations, he now posits two causes and two
principles, calling them hot and cold, i.e. fire and earth; and of
these he ranges the hot with the existent, and the other with the
non-existent.

    From what has been said, then, and from the wise men who have
now sat in council with us, we have got thus much-on the one hand from
the earliest philosophers, who regard the first principle as corporeal
(for water and fire and such things are bodies), and of whom some
suppose that there is one corporeal principle, others that there are
more than one, but both put these under the head of matter; and on the
other hand from some who posit both this cause and besides this the
source of movement, which we have got from some as single and from
others as twofold.

    Down to the Italian school, then, and apart from it,
philosophers have treated these subjects rather obscurely, except
that, as we said, they have in fact used two kinds of cause, and one
of these-the source of movement-some treat as one and others as two.
But the Pythagoreans have said in the same way that there are two
principles, but added this much, which is peculiar to them, that
they thought that finitude and infinity were not attributes of certain
other things, e.g. of fire or earth or anything else of this kind, but
that infinity itself and unity itself were the substance of the things
of which they are predicated. This is why number was the substance
of all things. On this subject, then, they expressed themselves
thus; and regarding the question of essence they began to make
statements and definitions, but treated the matter too simply. For
they both defined superficially and thought that the first subject
of which a given definition was predicable was the substance of the
thing defined, as if one supposed that 'double' and '2' were the same,
because 2 is the first thing of which 'double' is predicable. But
surely to be double and to be 2 are not the same; if they are, one
thing will be many-a consequence which they actually drew. From the
earlier philosophers, then, and from their successors we can learn
thus much.

                                   6

    After the systems we have named came the philosophy of Plato,
which in most respects followed these thinkers, but had
pecullarities that distinguished it from the philosophy of the
Italians. For, having in his youth first become familiar with Cratylus
and with the Heraclitean doctrines (that all sensible things are
ever in a state of flux and there is no knowledge about them), these
views he held even in later years. Socrates, however, was busying
himself about ethical matters and neglecting the world of nature as
a whole but seeking the universal in these ethical matters, and
fixed thought for the first time on definitions; Plato accepted his
teaching, but held that the problem applied not to sensible things but
to entities of another kind-for this reason, that the common
definition could not be a definition of any sensible thing, as they
were always changing. Things of this other sort, then, he called
Ideas, and sensible things, he said, were all named after these, and
in virtue of a relation to these; for the many existed by
participation in the Ideas that have the same name as they. Only the
name 'participation' was new; for the Pythagoreans say that things
exist by 'imitation' of numbers, and Plato says they exist by
participation, changing the name. But what the participation or the
imitation of the Forms could be they left an open question.

    Further, besides sensible things and Forms he says there are the
objects of mathematics, which occupy an intermediate position,
differing from sensible things in being eternal and unchangeable, from
Forms in that there are many alike, while the Form itself is in each
case unique.

    Since the Forms were the causes of all other things, he thought
their elements were the elements of all things. As matter, the great
and the small were principles; as essential reality, the One; for from
the great and the small, by participation in the One, come the
Numbers.

    But he agreed with the Pythagoreans in saying that the One is
substance and not a predicate of something else; and in saying that
the Numbers are the causes of the reality of other things he agreed
with them; but positing a dyad and constructing the infinite out of
great and small, instead of treating the infinite as one, is
peculiar to him; and so is his view that the Numbers exist apart
from sensible things, while they say that the things themselves are
Numbers, and do not place the objects of mathematics between Forms and
sensible things. His divergence from the Pythagoreans in making the
One and the Numbers separate from things, and his introduction of
the Forms, were due to his inquiries in the region of definitions (for
the earlier thinkers had no tincture of dialectic), and his making the
other entity besides the One a dyad was due to the belief that the
numbers, except those which were prime, could be neatly produced out
of the dyad as out of some plastic material. Yet what happens is the
contrary; the theory is not a reasonable one. For they make many
things out of the matter, and the form generates only once, but what
we observe is that one table is made from one matter, while the man
who applies the form, though he is one, makes many tables. And the
relation of the male to the female is similar; for the latter is
impregnated by one copulation, but the male impregnates many
females; yet these are analogues of those first principles.

    Plato, then, declared himself thus on the points in question; it
is evident from what has been said that he has used only two causes,
that of the essence and the material cause (for the Forms are the
causes of the essence of all other things, and the One is the cause of
the essence of the Forms); and it is evident what the underlying
matter is, of which the Forms are predicated in the case of sensible
things, and the One in the case of Forms, viz. that this is a dyad,
the great and the small. Further, he has assigned the cause of good
and that of evil to the elements, one to each of the two, as we say
some of his predecessors sought to do, e.g. Empedocles and Anaxagoras.

                                   7

    Our review of those who have spoken about first principles and
reality and of the way in which they have spoken, has been concise and
summary; but yet we have learnt this much from them, that of those who
speak about 'principle' and 'cause' no one has mentioned any principle
except those which have been distinguished in our work on nature,
but all evidently have some inkling of them, though only vaguely.
For some speak of the first principle as matter, whether they
suppose one or more first principles, and whether they suppose this to
be a body or to be incorporeal; e.g. Plato spoke of the great and
the small, the Italians of the infinite, Empedocles of fire, earth,
water, and air, Anaxagoras of the infinity of things composed of
similar parts. These, then, have all had a notion of this kind of
cause, and so have all who speak of air or fire or water, or something
denser than fire and rarer than air; for some have said the prime
element is of this kind.

    These thinkers grasped this cause only; but certain others have
mentioned the source of movement, e.g. those who make friendship and
strife, or reason, or love, a principle.

    The essence, i.e. the substantial reality, no one has expressed
distinctly. It is hinted at chiefly by those who believe in the Forms;
for they do not suppose either that the Forms are the matter of
sensible things, and the One the matter of the Forms, or that they are
the source of movement (for they say these are causes rather of
immobility and of being at rest), but they furnish the Forms as the
essence of every other thing, and the One as the essence of the Forms.

    That for whose sake actions and changes and movements take
place, they assert to be a cause in a way, but not in this way, i.e.
not in the way in which it is its nature to be a cause. For those
who speak of reason or friendship class these causes as goods; they do
not speak, however, as if anything that exists either existed or
came into being for the sake of these, but as if movements started
from these. In the same way those who say the One or the existent is
the good, say that it is the cause of substance, but not that
substance either is or comes to be for the sake of this. Therefore
it turns out that in a sense they both say and do not say the good
is a cause; for they do not call it a cause qua good but only
incidentally.

    All these thinkers then, as they cannot pitch on another cause,
seem to testify that we have determined rightly both how many and of
what sort the causes are. Besides this it is plain that when the
causes are being looked for, either all four must be sought thus or
they must be sought in one of these four ways. Let us next discuss the
possible difficulties with regard to the way in which each of these
thinkers has spoken, and with regard to his situation relatively to
the first principles.

                                   8

    Those, then, who say the universe is one and posit one kind of
thing as matter, and as corporeal matter which has spatial
magnitude, evidently go astray in many ways. For they posit the
elements of bodies only, not of incorporeal things, though there are
also incorporeal things. And in trying to state the causes of
generation and destruction, and in giving a physical account of all
things, they do away with the cause of movement. Further, they err
in not positing the substance, i.e. the essence, as the cause of
anything, and besides this in lightly calling any of the simple bodies
except earth the first principle, without inquiring how they are
produced out of one anothers-I mean fire, water, earth, and air. For
some things are produced out of each other by combination, others by
separation, and this makes the greatest difference to their priority
and posteriority. For (1) in a way the property of being most
elementary of all would seem to belong to the first thing from which
they are produced by combination, and this property would belong to
the most fine-grained and subtle of bodies. For this reason those
who make fire the principle would be most in agreement with this
argument. But each of the other thinkers agrees that the element of
corporeal things is of this sort. At least none of those who named one
element claimed that earth was the element, evidently because of the
coarseness of its grain. (Of the other three elements each has found
some judge on its side; for some maintain that fire, others that
water, others that air is the element. Yet why, after all, do they not
name earth also, as most men do? For people say all things are earth
Hesiod says earth was produced first of corporeal things; so primitive
and popular has the opinion been.) According to this argument, then,
no one would be right who either says the first principle is any of
the elements other than fire, or supposes it to be denser than air but
rarer than water. But (2) if that which is later in generation is
prior in nature, and that which is concocted and compounded is later
in generation, the contrary of what we have been saying must be
true,-water must be prior to air, and earth to water.

    So much, then, for those who posit one cause such as we mentioned;
but the same is true if one supposes more of these, as Empedocles says
matter of things is four bodies. For he too is confronted by
consequences some of which are the same as have been mentioned,
while others are peculiar to him. For we see these bodies produced
from one another, which implies that the same body does not always
remain fire or earth (we have spoken about this in our works on
nature); and regarding the cause of movement and the question
whether we must posit one or two, he must be thought to have spoken
neither correctly nor altogether plausibly. And in general, change
of quality is necessarily done away with for those who speak thus, for
on their view cold will not come from hot nor hot from cold. For if it
did there would be something that accepted the contraries
themselves, and there would be some one entity that became fire and
water, which Empedocles denies.

    As regards Anaxagoras, if one were to suppose that he said there
were two elements, the supposition would accord thoroughly with an
argument which Anaxagoras himself did not state articulately, but
which he must have accepted if any one had led him on to it. True,
to say that in the beginning all things were mixed is absurd both on
other grounds and because it follows that they must have existed
before in an unmixed form, and because nature does not allow any
chance thing to be mixed with any chance thing, and also because on
this view modifications and accidents could be separated from
substances (for the same things which are mixed can be separated); yet
if one were to follow him up, piecing together what he means, he would
perhaps be seen to be somewhat modern in his views. For when nothing
was separated out, evidently nothing could be truly asserted of the
substance that then existed. I mean, e.g. that it was neither white
nor black, nor grey nor any other colour, but of necessity colourless;
for if it had been coloured, it would have had one of these colours.
And similarly, by this same argument, it was flavourless, nor had it
any similar attribute; for it could not be either of any quality or of
any size, nor could it be any definite kind of thing. For if it
were, one of the particular forms would have belonged to it, and
this is impossible, since all were mixed together; for the
particular form would necessarily have been already separated out, but
he all were mixed except reason, and this alone was unmixed and
pure. From this it follows, then, that he must say the principles
are the One (for this is simple and unmixed) and the Other, which is
of such a nature as we suppose the indefinite to be before it is
defined and partakes of some form. Therefore, while expressing himself
neither rightly nor clearly, he means something like what the later
thinkers say and what is now more clearly seen to be the case.

    But these thinkers are, after all, at home only in arguments about
generation and destruction and movement; for it is practically only of
this sort of substance that they seek the principles and the causes.
But those who extend their vision to all things that exist, and of
existing things suppose some to be perceptible and others not
perceptible, evidently study both classes, which is all the more
reason why one should devote some time to seeing what is good in their
views and what bad from the standpoint of the inquiry we have now
before us.

    The 'Pythagoreans' treat of principles and elements stranger
than those of the physical philosophers (the reason is that they got
the principles from non-sensible things, for the objects of
mathematics, except those of astronomy, are of the class of things
without movement); yet their discussions and investigations are all
about nature; for they generate the heavens, and with regard to
their parts and attributes and functions they observe the phenomena,
and use up the principles and the causes in explaining these, which
implies that they agree with the others, the physical philosophers,
that the real is just all that which is perceptible and contained by
the so-called 'heavens'. But the causes and the principles which
they mention are, as we said, sufficient to act as steps even up to
the higher realms of reality, and are more suited to these than to
theories about nature. They do not tell us at all, however, how
there can be movement if limit and unlimited and odd and even are
the only things assumed, or how without movement and change there
can be generation and destruction, or the bodies that move through the
heavens can do what they do.

    Further, if one either granted them that spatial magnitude
consists of these elements, or this were proved, still how would
some bodies be light and others have weight? To judge from what they
assume and maintain they are speaking no more of mathematical bodies
than of perceptible; hence they have said nothing whatever about
fire or earth or the other bodies of this sort, I suppose because they
have nothing to say which applies peculiarly to perceptible things.

    Further, how are we to combine the beliefs that the attributes
of number, and number itself, are causes of what exists and happens in
the heavens both from the beginning and now, and that there is no
other number than this number out of which the world is composed? When
in one particular region they place opinion and opportunity, and, a
little above or below, injustice and decision or mixture, and
allege, as proof, that each of these is a number, and that there
happens to be already in this place a plurality of the extended bodies
composed of numbers, because these attributes of number attach to
the various places,-this being so, is this number, which we must
suppose each of these abstractions to be, the same number which is
exhibited in the material universe, or is it another than this?
Plato says it is different; yet even he thinks that both these
bodies and their causes are numbers, but that the intelligible numbers
are causes, while the others are sensible.

                                   9

    Let us leave the Pythagoreans for the present; for it is enough to
have touched on them as much as we have done. But as for those who
posit the Ideas as causes, firstly, in seeking to grasp the causes
of the things around us, they introduced others equal in number to
these, as if a man who wanted to count things thought he would not
be able to do it while they were few, but tried to count them when
he had added to their number. For the Forms are practically equal
to-or not fewer than-the things, in trying to explain which these
thinkers proceeded from them to the Forms. For to each thing there
answers an entity which has the same name and exists apart from the
substances, and so also in the case of all other groups there is a one
over many, whether the many are in this world or are eternal.

    Further, of the ways in which we prove that the Forms exist,
none is convincing; for from some no inference necessarily follows,
and from some arise Forms even of things of which we think there are
no Forms. For according to the arguments from the existence of the
sciences there will be Forms of all things of which there are sciences
and according to the 'one over many' argument there will be Forms even
of negations, and according to the argument that there is an object
for thought even when the thing has perished, there will be Forms of
perishable things; for we have an image of these. Further, of the more
accurate arguments, some lead to Ideas of relations, of which we say
there is no independent class, and others introduce the 'third man'.

    And in general the arguments for the Forms destroy the things
for whose existence we are more zealous than for the existence of
the Ideas; for it follows that not the dyad but number is first,
i.e. that the relative is prior to the absolute,-besides all the other
points on which certain people by following out the opinions held
about the Ideas have come into conflict with the principles of the
theory.

    Further, according to the assumption on which our belief in the
Ideas rests, there will be Forms not only of substances but also of
many other things (for the concept is single not only in the case of
substances but also in the other cases, and there are sciences not
only of substance but also of other things, and a thousand other
such difficulties confront them). But according to the necessities
of the case and the opinions held about the Forms, if Forms can be
shared in there must be Ideas of substances only. For they are not
shared in incidentally, but a thing must share in its Form as in
something not predicated of a subject (by 'being shared in
incidentally' I mean that e.g. if a thing shares in 'double itself',
it shares also in 'eternal', but incidentally; for 'eternal' happens
to be predicable of the 'double'). Therefore the Forms will be
substance; but the same terms indicate substance in this and in the
ideal world (or what will be the meaning of saying that there is
something apart from the particulars-the one over many?). And if the
Ideas and the particulars that share in them have the same form, there
will be something common to these; for why should '2' be one and the
same in the perishable 2's or in those which are many but eternal, and
not the same in the '2' itself' as in the particular 2? But if they
have not the same form, they must have only the name in common, and it
is as if one were to call both Callias and a wooden image a 'man',
without observing any community between them.

    Above all one might discuss the question what on earth the Forms
contribute to sensible things, either to those that are eternal or
to those that come into being and cease to be. For they cause
neither movement nor any change in them. But again they help in no
wise either towards the knowledge of the other things (for they are
not even the substance of these, else they would have been in them),
or towards their being, if they are not in the particulars which share
in them; though if they were, they might be thought to be causes, as
white causes whiteness in a white object by entering into its
composition. But this argument, which first Anaxagoras and later
Eudoxus and certain others used, is very easily upset; for it is not
difficult to collect many insuperable objections to such a view.

    But, further, all other things cannot come from the Forms in any
of the usual senses of 'from'. And to say that they are patterns and
the other things share in them is to use empty words and poetical
metaphors. For what is it that works, looking to the Ideas? And
anything can either be, or become, like another without being copied
from it, so that whether Socrates or not a man Socrates like might
come to be; and evidently this might be so even if Socrates were
eternal. And there will be several patterns of the same thing, and
therefore several Forms; e.g. 'animal' and 'two-footed' and also
'man himself' will be Forms of man. Again, the Forms are patterns
not only sensible things, but of Forms themselves also; i.e. the
genus, as genus of various species, will be so; therefore the same
thing will be pattern and copy.

    Again, it would seem impossible that the substance and that of
which it is the substance should exist apart; how, therefore, could
the Ideas, being the substances of things, exist apart? In the Phaedo'
the case is stated in this way-that the Forms are causes both of being
and of becoming; yet when the Forms exist, still the things that share
in them do not come into being, unless there is something to originate
movement; and many other things come into being (e.g. a house or a
ring) of which we say there are no Forms. Clearly, therefore, even the
other things can both be and come into being owing to such causes as
produce the things just mentioned.

    Again, if the Forms are numbers, how can they be causes? Is it
because existing things are other numbers, e.g. one number is man,
another is Socrates, another Callias? Why then are the one set of
numbers causes of the other set? It will not make any difference
even if the former are eternal and the latter are not. But if it is
because things in this sensible world (e.g. harmony) are ratios of
numbers, evidently the things between which they are ratios are some
one class of things. If, then, this--the matter--is some definite
thing, evidently the numbers themselves too will be ratios of
something to something else. E.g. if Callias is a numerical ratio
between fire and earth and water and air, his Idea also will be a
number of certain other underlying things; and man himself, whether it
is a number in a sense or not, will still be a numerical ratio of
certain things and not a number proper, nor will it be a of number
merely because it is a numerical ratio.

    Again, from many numbers one number is produced, but how can one
Form come from many Forms? And if the number comes not from the many
numbers themselves but from the units in them, e.g. in 10,000, how
is it with the units? If they are specifically alike, numerous
absurdities will follow, and also if they are not alike (neither the
units in one number being themselves like one another nor those in
other numbers being all like to all); for in what will they differ, as
they are without quality? This is not a plausible view, nor is it
consistent with our thought on the matter.

    Further, they must set up a second kind of number (with which
arithmetic deals), and all the objects which are called 'intermediate'
by some thinkers; and how do these exist or from what principles do
they proceed? Or why must they be intermediate between the things in
this sensible world and the things-themselves?...
