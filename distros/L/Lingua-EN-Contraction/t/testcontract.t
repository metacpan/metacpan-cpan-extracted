use Test;

BEGIN { plan tests => 15}	
use lib "lib";

use Lingua::EN::Contraction qw( contraction contract_n_t contract_other );
use Data::Dumper;

#ordinary contractions:

ok(contraction("I would, it is, you are, let us"), 
	"I'd, it's, you're, let's");

ok(contraction("cannot, can not, would not, will not"), 
	"can't, can't, wouldn't, won't");

ok(contraction("I have, I had, it has, we have"), 
	"I've, I'd, it's, we've");


#upper-case, sentance case, lower case, mixed case
ok(contraction("THEY ARE, They Are, they are, ThEy ArE"),  "THEY'RE, They're, they're, ThEy'rE");

ok(contraction("You Are, They Were Not, He Was Not, There Are, There Are Not"), "You're, They Weren't, He Wasn't, There Are, There Aren't"); 

ok(contraction("Are You Not, Were We Not, I am not, There are not, Would Not, Shall Not"), 
	       "Aren't You, Weren't We, I'm not, There aren't, Wouldn't, Shall Not");



# contract n_t before contracting verbs:

ok(contraction("you are not happy"), 
	"you aren't happy");

ok(contraction("he is not walking"), 
	"he isn't walking");

ok(contraction("I could not have been walking"), 
	"I couldn't have been walking");



#n_t only, verbs only
ok(contract_other("he is not walking"), 
	"he's not walking");

ok(contract_n_t("he is not walking"), 
	"he isn't walking");



# question word order, negated question word order

ok(contraction("should I not have been walking"), 
	"shouldn't I have been walking");

ok(contraction("is it not nice?"), 
	"isn't it nice?");

ok(contraction("Is he not aware that she is here?"), "Isn't he aware that she's here?");

ok(contraction("are you not amused?"), 
	"aren't you amused?");
