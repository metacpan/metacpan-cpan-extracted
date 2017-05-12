use Test::More;
plan tests => 5;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new();

isa_ok($idp,"Lingua::Lexicon::IDP");

cmp_ok($idp->lang(),"eq","en","Language is English");

ok(UNIVERSAL::can($idp,"es"),"Can translate into Spanish");

cmp_ok(($idp->es("dog"))[0],"eq","el perro","One word for 'dog' in Spanish is 'el perro'");
