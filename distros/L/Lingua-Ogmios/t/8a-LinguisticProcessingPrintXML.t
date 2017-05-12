use strict;
use warnings;

use Test::More tests => 4;

use Lingua::Ogmios;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::LogProcessing;

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 't/etc/nlpplatform.rc');


# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/InputDocument3.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/pmid10788508-v3.xml']);

# $NLPPlatform->tokenisation;

# print STDERR $NLPPlatform->XMLout;

# ok(defined $NLPPlatform);

warn "processing examples/pmid10788508-v4.xml\n";


#$NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
$NLPPlatform->loadDocuments(['examples/pmid10788508-v4.xml']);

ok($NLPPlatform->tokenisation == 0, "tokenization");

#print STDERR $NLPPlatform->XMLout;

ok($NLPPlatform->linguisticProcessing == 0, "Linguistic processing");;

ok(ref($NLPPlatform->XMLout) eq "", "get XML output");


ok(defined $NLPPlatform);

