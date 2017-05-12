use strict;
use warnings;
use Test::More;
use Decaptcha::TextCaptcha;

ok defined &decaptcha, 'decaptcha() is exported';

is decaptcha(undef), undef, undef;
while (my $line = <DATA>) {
    chomp $line;
    next unless $line;
    my ($q, $a) = split '\|', $line, 2;
    $a = undef if not length $a;
    is decaptcha($q), $a, $q;
}

done_testing;

__DATA__
Which WORD in this sentence is all in capitals?|word
"bodacious" has how many letters?|9
How many letters in "robustness"?|10
The word in capitals from constrict, GINORMOUS, nail or slunk is?|ginormous
Which of LIBERALIZES, fact, viol, entrusts or dram is in capitals?|liberalizes
Which word is all in capitals: CANNIBAL, flatlets, bemoans or transfixed?|cannibal
Which word starts with "h" from the list: hoodlums, quack, cacti?|hoodlums
Which word from list "knack, historical, bakers" has "h" as a first letter?|historical
What word from "budge, livings, proclaim" begins with "l"?|livings
Brassy, fairy, pumpkin: the word starting with "p" is?|pumpkin
Which word contains "f" from the list: tile, mudflaps, armpit?|mudflaps
Egoist, schlep, inbound: the word containing the letter "n" is?|inbound
What word from "quoting, gulch, glee" contains the letter "e"?|glee
Which word from list "emulate, teethe, barb" contains the letter "r"?|barb
The word "presence" starts with which letter?|p
The letter at the beginning of the word "blacklist" is?|b
The word "allowed" has which letter at the start?|a
The last letter of word "sexy" is?|y
The final letter of word "wank" is?|k
The word "journalese" has which letter at the end?|e
The 2nd letter in "alphabetical" is?|l
The word "preps" has which letter in 3rd position?|e
Tomorrow is Monday. If this is true, what day is today?|sunday
If tomorrow is Thursday, what day is today?|wednesday
What day is today, if tomorrow is Wednesday?|tuesday
Yesterday was Monday. If this is true, what day is today?|tuesday
If yesterday was Sunday, what day is today?|monday
What day is today, if yesterday was Monday?|tuesday
Which of these is a day of the week: bank, prison or Friday?|friday
Which of wine, Wednesday, dress or knee is a day of the week?|wednesday
Which of Sunday, sock or toe is the name of a day?|sunday
The day of the week in horse, Monday or chin is?|monday
Ant, fruit, elephant or Wednesday: the day of the week is?|wednesday
Which day from Sunday, Monday or Friday is part of the weekend?|sunday
From days Wednesday, Sunday or Monday, which is part of the weekend?|sunday
Monday, Saturday or Thursday: which day is part of the weekend?|saturday
James' name is?|james
What is James' name?|james
The name of James is?|james
If a person is called James, what is their name?|james
The person's firstname in T-shirt, Mark, shirt, toe, lion or hand is?|mark
Which in this list is the name of a person: cat, dog, Mary or eye?|mary
Ant, pub, nose, Paul or dress: the person's name is?|paul
Which in this list is the name of a person: cake, Jennifer or hospital?|jennifer
Which of arm, head, Mark or ankle is a person's name?|mark
The colour of a blue glove is?|blue
The black T-shirt is what colour?|black
If the cake is purple, what colour is it?|purple
How many colours in the list hand, white, blue, hand, yellow and pink?|4
The list dress, green, monkey and blue contains how many colours?|2
Ant, coat, shark, brown and red: how many colours in the list?|2
Which of these is a colour: hotel, duck, egg, dress, prison or pink?|pink
Which of shirt, trousers or white is a colour?|white
Ankle, fruit, nose, brown or hospital: the colour is?|brown
The colour in the list bread, black or bee is?|black
What is the 3rd colour in the list egg, brown, black and red?|red
What is the 2nd colour in the list soup, pink, white and green?|white
Bank, green, red, black and finger: the 2nd colour is?|red
The number of body parts in the list ankle, pub and eye is?|2
The list ankle, hair, church and mouse contains how many body parts?|2
Bee, pub and hand: how many body parts in the list?|1
The body part in coffee, elbow or cat is?|elbow
Which of these is a body part: chin, ant or jelly?|chin
Which of tooth, cheese, bread, pub or egg is a body part?|tooth
Which of soup, jelly, toe or egg is part of a person?|toe
Wine, tooth, hospital, hotel or monkey: the body part is?|tooth
Which of tooth, ankle or stomach is part of the head?|tooth
Arm, eye, chest, ankle or leg: which is part of the head?|eye
Which of nose, heart or ear is something each person has more than one of?|ear
Chin, nose or tooth: which is something each person has more than one of?|tooth
Which of toe, tongue, ankle, leg or knee is above the waist?|tongue
Ankle, chest or toe: which is above the waist?|chest
Which of tooth, toe, stomach or ear is below the waist?|toe
Ankle, hair, stomach, chin or heart: which is below the waist?|ankle
Enter the number eighty thousand five hundred and nine in digits:|80509
Which digit is 5th in the number 7086895?|8
In the number 9573471, what is the 6th digit?|7
In the number 1712712, what is the 1st digit?|1
The 2nd number from eighteen, fifteen and nineteen is?|15
What is the 4th number in the list 16, twenty eight, 7, forty and 20?|40
What number is 4th in the series 6, thirteen, eighteen and twenty four?|24
10, 31, 17 and twenty three: the 3rd number is?|17
Enter the biggest number of 69, eighteen, forty three or forty one:|69
Of the numbers 21, 34, 53, 44, twenty five or 40, which is the highest?|53
Which of fifty, twenty three or 97 is the largest?|97
13, fifty six, 48, 14 or thirty nine: which of these is the biggest?|56
10, 52, eighty one or seventy four: the highest is?|81
Enter the smallest number of 57, four, thirteen or 27:|4
Of the numbers 52, seventy three or three, which is the lowest?|3
Which of 41, 62, 87, seventy four or 39 is the smallest?|39
Twenty seven, fifty two, 41 or 94: which of these is the lowest?|27
70, eighty four, eighty five, 6, nine or 44: the smallest is?|6
10 plus 4 equals ?|14
1 add 5 is what?|6
10 plus two is what?|12
14 minus 1 = ?|13

|
Which word in this sentence is all in capitals?|
The word in capitals from constrict, ginormous, nail or slunk is?|
Which word starts with "h" from the list: quack, cacti, moon?|
What word from "budge, livings, proclaim" begins with "a"?|
Which word contains "z" from the list: tile, mudflaps, armpit?|
The word "preps" has which letter in 8th position?|
If tomorrow is Fryeday, what day is today?|
If yesterday was Mayday, what day is today?|
Which of these is a day of the week: bank, prison or moon?|
Which day from Monday, Tuesday, or Wednesday is part of the weekend?|
The person's firstname in T-shirt, mark, shirt, toe, lion or hand is?|
How many colours in the list hand, toe, and monkey?|0
Which of these is a colour: hotel, duck, egg, dress or prison?|
What is the 3rd colour in the list egg, sppon and moon?|
The number of body parts in the list book, pub and moon is?|0
The body part in coffee, spoon or cat is?|
Which of toe, ankle or stomach is part of the head?|
Chin, nose or chest which is something each person has more than one of?|
Which of toe, ankle, leg or knee is above the waist?|
Which of tooth, hair, stomach or ear is below the waist?|
In the number 171, what is the 9th digit?|
The 5th number from eighteen, fifteen and nineteen is?|
