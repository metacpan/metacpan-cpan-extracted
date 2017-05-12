use Test::More;
plan tests => 5;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new();

isa_ok($idp,"Lingua::Lexicon::IDP");

cmp_ok($idp->lang(),"eq","en","Language is English");

ok(UNIVERSAL::can($idp,"de"),"Can translate into German");

cmp_ok(($idp->de("dog"))[1],"eq","hund","One word for 'dog' in German is 'hund'");

# $Id: de.t,v 1.1 2003/02/04 14:04:01 asc Exp $
