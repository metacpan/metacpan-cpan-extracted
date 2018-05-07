use warnings;
use strict;

use Test::More;

use Lingua::EN::Inflexion;

# Nominative pronouns...

for my $pronoun_3rd (qw< she he it they >) {
    is noun($pronoun_3rd)->plural,      "they"  => "$pronoun_3rd ---> they";
    is noun($pronoun_3rd)->plural(1),   "we"    => "$pronoun_3rd -1-> we";
    is noun($pronoun_3rd)->plural(2),   "you"   => "$pronoun_3rd -2-> you";
    is noun($pronoun_3rd)->plural(3),   "they"  => "$pronoun_3rd -3-> they";
}

for my $pronoun (qw< I we >) {
    is noun($pronoun)->plural,      "we"     => "$pronoun ---> we";
    is noun($pronoun)->plural(1),   "we"     => "$pronoun -1-> we";
    is noun($pronoun)->plural(2),   "you"    => "$pronoun -2-> you";
    is noun($pronoun)->plural(3),   "they"   => "$pronoun -3-> they";
}

is noun('you')->plural,      "you"   => 'you ---> you';
is noun('you')->plural(1),   "we"    => 'you -1-> we';
is noun('you')->plural(2),   "you"   => 'you -2-> you';
is noun('you')->plural(3),   "they"  => 'you -3-> they';

# Accusative pronouns...

for my $pronoun (qw< me us >) {
    is noun($pronoun)->plural,      "us"     => "$pronoun ---> us";
    is noun($pronoun)->plural(1),   "us"     => "$pronoun -1-> us";
    is noun($pronoun)->plural(2),   "you"    => "$pronoun -2-> you";
    is noun($pronoun)->plural(3),   "them"   => "$pronoun -3-> them";

    is noun("to $pronoun")->plural,      "to us"     => "to $pronoun ---> to us";
    is noun("to $pronoun")->plural(1),   "to us"     => "to $pronoun -1-> to us";
    is noun("to $pronoun")->plural(2),   "to you"    => "to $pronoun -2-> to you";
    is noun("to $pronoun")->plural(3),   "to them"   => "to $pronoun -3-> to them";
}

for my $pronoun_3rd (qw< her him them >) {
    is noun($pronoun_3rd)->plural,            "them"   => "$pronoun_3rd ---> them";
    is noun(uc $pronoun_3rd)->plural(1),      "US"     => "$pronoun_3rd -1-> US";
    is noun(ucfirst $pronoun_3rd)->plural(2), "You"    => "$pronoun_3rd -2-> You";
    is noun($pronoun_3rd)->plural(3),         "them"   => "$pronoun_3rd -3-> them";

    is noun('with '  . $pronoun_3rd)->plural,            "with them"   => "with $pronoun_3rd ---> with them";
    is noun('from '  . uc $pronoun_3rd)->plural(1),      "from US"     => "from $pronoun_3rd -1-> from US";
    is noun('OVER '  . ucfirst $pronoun_3rd)->plural(2), "OVER You"    => "OVER $pronoun_3rd -2-> OVER You";
    is noun('About ' . $pronoun_3rd)->plural(3),         "About them"  => "About$pronoun_3rd -3-> Aboutthem";
}


is noun('of you')->plural,      "of you"   => 'of you ---> of you';
is noun('of you')->plural(1),   "of us"    => 'of you -1-> of us';
is noun('of you')->plural(2),   "of you"   => 'of you -2-> of you';
is noun('of you')->plural(3),   "of them"  => 'of you -3-> of them';

is noun('of it')->plural,      "of them"  => 'of it ---> of them';
is noun('of it')->plural(1),   "of us"    => 'of it -1-> of us';
is noun('of it')->plural(2),   "of you"   => 'of it -2-> of you';
is noun('of it')->plural(3),   "of them"  => 'of it -3-> of them';


# Possessive pronouns...

for my $pronoun (qw< mine ours >) {
    is noun($pronoun)->plural,      "ours"    => "$pronoun ---> ours";
    is noun($pronoun)->plural(1),   "ours"    => "$pronoun -1-> ours";
    is noun($pronoun)->plural(2),   "yours"   => "$pronoun -2-> yours";
    is noun($pronoun)->plural(3),   "theirs"  => "$pronoun -3-> theirs";

    is noun('upon ' . $pronoun)->plural,      "upon ours"    => "upon $pronoun ---> upon ours";
    is noun('upon ' . $pronoun)->plural(1),   "upon ours"    => "upon $pronoun -1-> upon ours";
    is noun('upon ' . $pronoun)->plural(2),   "upon yours"   => "upon $pronoun -2-> upon yours";
    is noun('upon ' . $pronoun)->plural(3),   "upon theirs"  => "upon $pronoun -3-> upon theirs";
}

for my $pronoun (qw< its hers his theirs >) {
    is noun($pronoun)->plural,      "theirs"  => "$pronoun ---> theirs";
    is noun($pronoun)->plural(1),   "ours"    => "$pronoun -1-> ours";
    is noun($pronoun)->plural(2),   "yours"   => "$pronoun -2-> yours";
    is noun($pronoun)->plural(3),   "theirs"  => "$pronoun -3-> theirs";

    is noun('at ' . $pronoun)->plural,      "at theirs"  => "at $pronoun ---> at theirs";
    is noun('at ' . $pronoun)->plural(1),   "at ours"    => "at $pronoun -1-> at ours";
    is noun('at ' . $pronoun)->plural(2),   "at yours"   => "at $pronoun -2-> at yours";
    is noun('at ' . $pronoun)->plural(3),   "at theirs"  => "at $pronoun -3-> at theirs";
}

is noun('yours')->plural,      "yours"   => 'yours ---> yours';
is noun('yours')->plural(1),   "ours"    => 'yours -1-> ours';
is noun('yours')->plural(2),   "yours"   => 'yours -2-> yours';
is noun('yours')->plural(3),   "theirs"  => 'yours -3-> theirs';

is noun('within yours')->plural,      "within yours"   => 'within yours ---> within yours';
is noun('within yours')->plural(1),   "within ours"    => 'within yours -1-> within ours';
is noun('within yours')->plural(2),   "within yours"   => 'within yours -2-> within yours';
is noun('within yours')->plural(3),   "within theirs"  => 'within yours -3-> within theirs';


# Verbs, especially "to be"...

is verb('am')->plural,       "are"    => 'am ---> are';
is verb('am')->plural(1),    "are"    => 'am -1-> are';
is verb('am')->plural(2),    "are"    => 'am -2-> are';
is verb('am')->plural(3),    "are"    => 'am -3-> are';

is verb('are')->plural,      "are"    => 'are ---> are';
is verb('is')->plural,       "are"    => 'is  ---> are';

is verb('eat')->plural,       "eat"   => 'eat ---> eat';
is verb('eat')->plural(1),    "eat"   => 'eat -1-> eat';
is verb('eat')->plural(2),    "eat"   => 'eat -2-> eat';
is verb('eat')->plural(3),    "eat"   => 'eat -3-> eat';

is verb('eats')->plural,       "eat"   => 'eats ---> eat';
is verb('eats')->plural(1),    "eat"   => 'eats -1-> eat';
is verb('eats')->plural(2),    "eat"   => 'eats -2-> eat';
is verb('eats')->plural(3),    "eat"   => 'eats -3-> eat';


# Possessive adjectives...

for my $adj (qw< my our >) {
    is adj($adj)->plural,      "our"     => "$adj ---> our";
    is adj($adj)->plural(1),   "our"     => "$adj -1-> our";
    is adj($adj)->plural(2),   "your"    => "$adj -2-> your";
    is adj($adj)->plural(3),   "their"   => "$adj -3-> their";
}

for my $adj (qw< its her his their >) {
    is adj($adj)->plural,      "their"   => "$adj ---> their";
    is adj($adj)->plural(1),   "our"     => "$adj -1-> our";
    is adj($adj)->plural(2),   "your"    => "$adj -2-> your";
    is adj($adj)->plural(3),   "their"   => "$adj -3-> their";
}

is adj('your')->plural,      "your"      => 'your ---> your';
is adj('your')->plural(1),   "our"       => 'your -1-> our';
is adj('Your')->plural(2),   "Your"      => 'Your -2-> Your';
is adj('YOUR')->plural(3),   "THEIR"     => 'YOUR -3-> THEIR';


done_testing();


