use strict;
use warnings;

use Test::More tests => 9;

use Lingua::Ogmios;
use Lingua::Ogmios::Annotations::Token;
use Lingua::Ogmios::Annotations::LogProcessing;

# warn "Log Processing\n";
my $logp = Lingua::Ogmios::Annotations::LogProcessing-> new(
    {'log_id' => 'log_processing1', 
     'software_name' => "testsoftware",
     'command_line' => "no comandline"
    });
ok(defined $logp  && ref $logp eq 'Lingua::Ogmios::Annotations::LogProcessing', 'LogProcessing->new works');
# print  "Print LogProcessing content\n";
ok ($logp->print(\*STDOUT) == 0, "print logs");

# warn "Token\n";
my $token = Lingua::Ogmios::Annotations::Token-> new(
    {'id' => "token1",
     'content' => "content",
     'type' => "alpha",
     'from' => 40,
     'to' => 50
    });
ok(defined $token  && ref $token eq 'Lingua::Ogmios::Annotations::Token', 'Token->new works');
# print "Print Token content\n";
ok($token->print(\*STDOUT) == 0, "print element(token)");
# print "Print Token content as XML\n";
ok(ref($token->XMLout(['id', 'type', 'content', 'from', 'to'])) eq "", "return element(token) in XML format");

my $NLPPlatform = Lingua::Ogmios->new('rcfile' => 'etc/ogmios/nlpplatform-test.rc');

# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
# ok(defined $NLPPlatform);

# $NLPPlatform->loadDocuments(['examples/InputDocument3.xml']);
# ok(defined $NLPPlatform);

$NLPPlatform->loadDocuments(['examples/pmid10788508-v3.xml']);

ok($NLPPlatform->tokenisation == 0, "tokenization of pmid10788508-v3");

ok(ref($NLPPlatform->XMLout) eq "", "return Full XML output for pmid10788508-v3");

# warn "\nprocessing examples/pmid10788508-v4.xml\n";

$NLPPlatform->loadDocuments(['examples/pmid10788508-v4.xml']);

ok($NLPPlatform->tokenisation == 0, "tokenization of pmid10788508-v4");
ok(ref($NLPPlatform->XMLout) eq "", "return Full XML output for pmid10788508-v4");

# print $NLPPlatform->XMLout;


