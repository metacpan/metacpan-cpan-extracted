use Test::More;
use File::Basename;

plan tests => 8;

use_ok("Lingua::Lexicon::IDP");

my $idp = Lingua::Lexicon::IDP->new("en");
isa_ok($idp,"Lingua::Lexicon::IDP");

foreach my $lang (@{$idp->translations()}) {
  $idp->$lang("dog");
  cmp_ok(basename($idp->{'__datafile'}),"eq","en_$lang.txt","$lang: $idp->{'__datafile'}");
}

# $Id: datafile.t,v 1.1 2003/02/04 14:04:01 asc Exp $
