use warnings;
use strict;

use Test::More 'no_plan'; 

use Lingua::EN::Inflexion;

my @words;

# Four words...
@words = qw(apple banana carrot tomato);

is wordlist(@words),
  "apple, banana, carrot, and tomato"
   => 'plain 4 words';

is wordlist(@words, {final_sep=>''}),
  "apple, banana, carrot and tomato"
   => '4 words, no final sep';

is wordlist(@words, {final_sep=>'...'}),
  "apple, banana, carrot... and tomato"
   => '4 words, different final sep';

is wordlist(@words, {final_sep=>'...', conj=>''}),
  "apple, banana, carrot... tomato"
   => '4 words, different final sep, no conjunction';

is wordlist(@words, {conj=>'or'}),
  "apple, banana, carrot, or tomato"
   => '4 words, different conjunction';

is wordlist(@words, {conj=>'&'}),
  "apple, banana, carrot, & tomato"
   => '4 words, different conjunction';

# Three words...
@words = qw(apple banana carrot);

is wordlist(@words),
   "apple, banana, and carrot"
    => 'plain 3 words';

is wordlist(@words, {final_sep=>''}),
   "apple, banana and carrot"
    => '3 words, no final sep';

is wordlist(@words, {final_sep=>'...'}),
   "apple, banana... and carrot"
    => '3 words, different final sep';

is wordlist(@words, {final_sep=>'...', conj=>''}),
   "apple, banana... carrot"
    => '3 words, different final sep, no conjunction';

is wordlist(@words, {conj=>'or'}),
   "apple, banana, or carrot"
    => '3 words, different conjunction';

is wordlist(@words, {conj=>'&'}),
   "apple, banana, & carrot"
    => '3 words, different conjunction';


# Three words with semicolons...
@words = ('apple,fuji' ,  'banana' , 'carrot');

is wordlist(@words),
   "apple,fuji; banana; and carrot"
    => 'comma-inclusive 3 words';

is wordlist(@words, {final_sep=>''}),
   "apple,fuji; banana and carrot"
    => 'comma-inclusive 3 words, no final sep';

is wordlist(@words, {final_sep=>'...'}),
   "apple,fuji; banana... and carrot"
    => 'comma-inclusive 3 words, different final sep';

is wordlist(@words, {final_sep=>'...', conj=>''}),
   "apple,fuji; banana... carrot"
    => 'comma-inclusive 3 words, different final sep, no conjunction';

is wordlist(@words, {conj=>'or'}),
   "apple,fuji; banana; or carrot"
    => 'comma-inclusive 3 words, different conjunction';

is wordlist(@words, {conj=>'&'}),
   "apple,fuji; banana; & carrot"
    => 'comma-inclusive 3 words, different conjunction';


# Two words...
@words = qw(apple carrot );

is wordlist(@words),
   "apple and carrot"
    => 'plain 2 words';

is wordlist(@words, {final_sep=>''}),
   "apple and carrot"
    => '2 words, no final sep';

is wordlist(@words, {final_sep=>'...'}),
   "apple and carrot"
    => '2 words, different final sep';

is wordlist(@words, {final_sep=>'...', conj=>''}),
   "apple carrot"
    => '2 words, different final sep, no conjunction';

is wordlist(@words, {conj=>'or'}),
   "apple or carrot"
    => '2 words, different conjunction';

is wordlist(@words, {conj=>'&'}),
   "apple & carrot"
    => '2 words, different conjunction';


# One word...
@words = qw(carrot );

is wordlist(@words),
   "carrot"
    => 'plain 1 word';

is wordlist(@words, {final_sep=>''}),
   "carrot"
    => '1 word, no final sep';

is wordlist(@words, {final_sep=>'...'}),
   "carrot"
    => '1 word, different final sep';

is wordlist(@words, {final_sep=>'...', conj=>''}),
   "carrot"
    => '1 word, different final sep, no conjunction';

is wordlist(@words, {conj=>'or'}),
   "carrot"
    => '1 word, different conjunction';



done_testing();

