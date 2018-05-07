use warnings;
use strict;

use Test::More;

use Lingua::EN::Inflexion;

# Nominative pronouns...

for my $pronoun_3rd (qw< she he it >) {
    is noun($pronoun_3rd)->singular,      $pronoun_3rd   => "$pronoun_3rd ---> $pronoun_3rd";
    is noun($pronoun_3rd)->singular(1),   "I"            => "$pronoun_3rd -1-> I";
    is noun($pronoun_3rd)->singular(2),   "you"          => "$pronoun_3rd -2-> you";
    is noun($pronoun_3rd)->singular(3),   $pronoun_3rd   => "$pronoun_3rd -3-> $pronoun_3rd";
}

for my $pronoun (qw< I you >) {
    is noun($pronoun)->singular,      $pronoun  => "$pronoun ---> $pronoun";
    is noun($pronoun)->singular(1),   "I"       => "$pronoun -1-> I";
    is noun($pronoun)->singular(2),   "you"     => "$pronoun -2-> you";
    is noun($pronoun)->singular(3),   "it"      => "$pronoun -3-> it";
}

is noun('we')->singular,      "I"     => 'we ---> it';
is noun('we')->singular(1),   "I"     => 'we -1-> I';
is noun('we')->singular(2),   "you"   => 'we -2-> you';
is noun('we')->singular(3),   "it"    => 'we -3-> it';

is noun('they')->singular,      "it"    => 'they ---> it';
is noun('they')->singular(1),   "I"     => 'they -1-> I';
is noun('they')->singular(2),   "you"   => 'they -2-> you';
is noun('they')->singular(3),   "it"    => 'they -3-> it';


# Accusative pronouns...

for my $pronoun (qw< me >) {
    is noun($pronoun)->singular,      $pronoun  => "$pronoun ---> $pronoun";
    is noun($pronoun)->singular(1),   "me"      => "$pronoun -1-> me";
    is noun($pronoun)->singular(2),   "you"     => "$pronoun -2-> you";
    is noun($pronoun)->singular(3),   "it"      => "$pronoun -3-> it";

    is noun('to ' . $pronoun)->singular,      'to ' . $pronoun  => "to $pronoun ---> to $pronoun";
    is noun('to ' . $pronoun)->singular(1),   "to me"           => "to $pronoun -1-> to me";
    is noun('to ' . $pronoun)->singular(2),   "to you"          => "to $pronoun -2-> to you";
    is noun('to ' . $pronoun)->singular(3),   "to it"           => "to $pronoun -3-> to it";
}

for my $pronoun_3rd (qw< her him >) {
    is noun($pronoun_3rd)->singular,            $pronoun_3rd   => "$pronoun_3rd ---> $pronoun_3rd";
    is noun(uc $pronoun_3rd)->singular(1),      "ME"           => "$pronoun_3rd -1-> ME";
    is noun(ucfirst $pronoun_3rd)->singular(2), "You"          => "$pronoun_3rd -2-> You";
    is noun($pronoun_3rd)->singular(3),         $pronoun_3rd   => "$pronoun_3rd -3-> $pronoun_3rd";

    is noun('AT ' . $pronoun_3rd)->singular,            'AT ' . $pronoun_3rd   => "AT $pronoun_3rd ---> AT $pronoun_3rd";
    is noun('AT ' . uc $pronoun_3rd)->singular(1),      'AT ' . "ME"           => "AT $pronoun_3rd -1-> AT ME";
    is noun('AT ' . ucfirst $pronoun_3rd)->singular(2), 'AT ' . "You"          => "AT $pronoun_3rd -2-> AT You";
    is noun('AT ' . $pronoun_3rd)->singular(3),         'AT ' . $pronoun_3rd   => "AT $pronoun_3rd -3-> AT $pronoun_3rd";
}


is noun('us')->singular,      "me"    => 'us ---> me';
is noun('us')->singular(1),   "me"    => 'us -1-> me';
is noun('us')->singular(2),   "you"   => 'us -2-> you';
is noun('us')->singular(3),   "it"    => 'us -3-> it';

is noun('them')->singular,      "it"    => 'them ---> it';
is noun('them')->singular(1),   "me"    => 'them -1-> me';
is noun('them')->singular(2),   "you"   => 'them -2-> you';
is noun('them')->singular(3),   "it"    => 'them -3-> it';


# Possessive pronouns...

for my $pronoun (qw< mine yours its >) {
    is noun($pronoun)->singular,      $pronoun  => "$pronoun ---> $pronoun";
    is noun($pronoun)->singular(1),   "mine"    => "$pronoun -1-> mine";
    is noun($pronoun)->singular(2),   "yours"   => "$pronoun -2-> yours";
    is noun($pronoun)->singular(3),   "its"     => "$pronoun -3-> its";

    is noun('of ' . $pronoun)->singular,      'of ' . $pronoun  => "of $pronoun ---> of $pronoun";
    is noun('of ' . $pronoun)->singular(1),   'of ' . "mine"    => "of $pronoun -1-> of mine";
    is noun('of ' . $pronoun)->singular(2),   'of ' . "yours"   => "of $pronoun -2-> of yours";
    is noun('of ' . $pronoun)->singular(3),   'of ' . "its"     => "of $pronoun -3-> of its";
}

is noun('ours')->singular,      "mine"   => 'ours ---> mine';
is noun('ours')->singular(1),   "mine"   => 'ours -1-> mine';
is noun('ours')->singular(2),   "yours"  => 'ours -2-> yours';
is noun('ours')->singular(3),   "its"    => 'ours -3-> its';

is noun('onto ours')->singular,      "onto mine"   => 'onto ours ---> onto mine';
is noun('onto ours')->singular(1),   "onto mine"   => 'onto ours -1-> onto mine';
is noun('onto ours')->singular(2),   "onto yours"  => 'onto ours -2-> onto yours';
is noun('onto ours')->singular(3),   "onto its"    => 'onto ours -3-> onto its';

is noun('theirs')->singular,      "its"    => 'theirs ---> its';
is noun('theirs')->singular(1),   "mine"   => 'theirs -1-> mine';
is noun('Theirs')->singular(2),   "Yours"  => 'Theirs -2-> Yours';
is noun('THEIRS')->singular(3),   "ITS"    => 'THEIRS -3-> ITS';

is noun('after theirs')->singular,      "after its"    => 'after theirs ---> after its';
is noun('after theirs')->singular(1),   "after mine"   => 'after theirs -1-> after mine';
is noun('after Theirs')->singular(2),   "after Yours"  => 'after Theirs -2-> after Yours';
is noun('after THEIRS')->singular(3),   "after ITS"    => 'after THEIRS -3-> after ITS';


# Verbs, especially "to be"...

is verb('am')->singular,       "am"    => 'am ---> am';
is verb('am')->singular(1),    "am"    => 'am -1-> am';
is verb('am')->singular(2),    "are"   => 'am -2-> are';
is verb('am')->singular(3),    "is"    => 'am -3-> is';

is verb('are')->singular,      "are"   => 'are ---> are';
is verb('is')->singular,       "is"    => 'is  ---> is';

is verb('eat')->singular,       "eats"  => 'eat ---> eats';
is verb('eat')->singular(1),    "eat"   => 'eat -1-> eat';
is verb('eat')->singular(2),    "eat"   => 'eat -2-> eat';
is verb('eat')->singular(3),    "eats"  => 'eat -3-> eats';

is verb('eats')->singular,       "eats"  => 'eats ---> eats';
is verb('eats')->singular(1),    "eat"   => 'eats -1-> eat';
is verb('eats')->singular(2),    "eat"   => 'eats -2-> eat';
is verb('eats')->singular(3),    "eats"  => 'eats -3-> eats';


# Possessive adjectives...

for my $adj (qw< my your >) {
    is adj($adj)->singular,      $adj      => "$adj ---> $adj";
    is adj($adj)->singular(1),   "my"      => "$adj -1-> my";
    is adj($adj)->singular(2),   "your"    => "$adj -2-> your";
    is adj($adj)->singular(3),   "its"     => "$adj -3-> its";
}

is adj('our')->singular,      "my"    => 'our ---> my';
is adj('our')->singular(1),   "my"    => 'our -1-> my';
is adj('our')->singular(2),   "your"  => 'our -2-> your';
is adj('our')->singular(3),   "its"   => 'our -3-> its';

is adj('their')->singular,      "its"    => 'theirs ---> its';
is adj('their')->singular(1),   "my"     => 'theirs -1-> my';
is adj('Their')->singular(2),   "Your"   => 'Theirs -2-> Your';
is adj('THEIR')->singular(3),   "ITS"    => 'THEIRS -3-> ITS';


done_testing();

