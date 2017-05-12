use strict;
use warnings;

use Test::More tests => 1;

use Lingua::Ogmios;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::LogProcessing;

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 'etc/ogmios/nlpplatform.rc');


# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/InputDocument3.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/pmid10788508-v3.xml']);

# $NLPPlatform->tokenisation;

# print STDERR $NLPPlatform->XMLout;

# ok(defined $NLPPlatform);

warn "processing examples/twodocs.xml\n";


#$NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
$NLPPlatform->loadDocuments(['examples/twodocs.xml']);

$NLPPlatform->tokenisation;

#print STDERR $NLPPlatform->XMLout;

$NLPPlatform->linguisticProcessing;

#print STDERR $NLPPlatform->XMLout;


ok(defined $NLPPlatform);

