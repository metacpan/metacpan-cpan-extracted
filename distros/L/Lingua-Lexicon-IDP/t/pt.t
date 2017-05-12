use Test::More;
plan tests => 5;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new();

isa_ok($idp,"Lingua::Lexicon::IDP");

cmp_ok($idp->lang(),"eq","en","Language is English");

ok(UNIVERSAL::can($idp,"pt"),"Can translate into Portugese");

cmp_ok(($idp->pt("dog"))[1],"eq","ca~o[Noun]","One word for 'dog' in Portugese is 'ca~[Noun]'");

# $Id: pt.t,v 1.1 2003/02/04 14:04:01 asc Exp $
