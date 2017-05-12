use strict;
use warnings;

use Test::More tests => 3;

use Lingua::Ogmios;
use Lingua::Ogmios::LearningDataSet;
use Lingua::Ogmios::LearningDataSet::Attribute;
use Lingua::Ogmios::LearningDataSet::Data;

my $LDS = Lingua::Ogmios::LearningDataSet->new();


# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
ok(defined $LDS, 'Creation of the learning dataset works');

$LDS->parseARFF("examples/Output-Learning-AttrSelect.arff");

ok($LDS->countValAttr > 0, 'Parsing ARFF works');

# print STDERR "\n\nRelation:\n";
# $LDS->printRelation(\*STDERR);
# print STDERR "\n\nList of atttributes:\n";
# $LDS->printAttributes(\*STDERR);
# print STDERR "\n\nDataset:\n";
# $LDS->printDataset(\*STDERR);

my $svm = $LDS->getSVM;

ok(defined $svm, 'generating SVM output');

# print STDERR "\nSVN Format";
# print STDERR "\n$svm\n";
