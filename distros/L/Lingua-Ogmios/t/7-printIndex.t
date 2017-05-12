use strict;
use warnings;

use Test::More tests => 6;

use Lingua::Ogmios;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::LogProcessing;

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 'etc/ogmios/nlpplatform.rc');
ok(defined $NLPPlatform);


warn "processing examples/pmid10788508-v4.xml\n";

#$NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
$NLPPlatform->loadDocuments(['examples/pmid10788508-v4.xml']);

ok($NLPPlatform->tokenisation == 0, "tokenization of pmid10788508-v4");

for my $doc (values (%{$NLPPlatform->getDocumentCollection->[0]->getDocuments})) {
    # print "$doc\n";
    ok($doc->getAnnotations->getSectionLevel->printIndex('from', \*STDOUT) == 0, "print Section Index from");
    # print "---\n";
    ok($doc->getAnnotations->getSectionLevel->printIndex('to', \*STDOUT) == 0, "print Section Index to");
#     $doc->getAnnotations->getTokenLevel->printIndex('id');
    # print "---\n";
}

for my $doc (values (%{$NLPPlatform->getDocumentCollection->[0]->getDocuments})) {
    # print "$doc\n";
    ok($doc->getAnnotations->getTokenLevel->printIndex('from', \*STDOUT) == 0, "print Token Index from");
    # print "---\n";
    ok($doc->getAnnotations->getTokenLevel->printIndex('to', \*STDOUT) == 0, "print Token Index from");
#     $doc->getAnnotations->getTokenLevel->printIndex('id');
    # print "---\n";
}

#print STDERR $NLPPlatform->XMLout;

# $NLPPlatform->linguisticProcessing;

#print STDERR $NLPPlatform->XMLout;



