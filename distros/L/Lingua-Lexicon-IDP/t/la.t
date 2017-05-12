use Test::More;
plan tests => 5;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new();

isa_ok($idp,"Lingua::Lexicon::IDP");

cmp_ok($idp->lang(),"eq","en","Language is English");

ok(UNIVERSAL::can($idp,"la"),"Can translate into Latin");

# Note the dot. I have not studied Latin
# so I don't know what's up with that...
cmp_ok(($idp->la("dog."))[0],"eq","canis","The word 'dog' in Latin is 'canis'");

# $Id: la.t,v 1.1 2003/02/04 14:04:01 asc Exp $
