use Test::More;
plan tests => 5;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new();

isa_ok($idp,"Lingua::Lexicon::IDP");

cmp_ok($idp->lang(),"eq","en","Language is English");

ok(UNIVERSAL::can($idp,"fr"),"Can translate into French");

cmp_ok(($idp->fr("dog"))[0],"eq","chien/ne[Noun]","The word 'dog' in French is 'chien/ne[Noun]'");

# $Id: fr.t,v 1.1 2003/02/04 14:04:01 asc Exp $
