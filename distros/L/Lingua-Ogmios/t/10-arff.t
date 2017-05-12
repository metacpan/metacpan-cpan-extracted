use strict;
use warnings;

use Test::More tests => 16;

use Lingua::Ogmios;
use Lingua::Ogmios::LearningDataSet;
use Lingua::Ogmios::LearningDataSet::Attribute;
use Lingua::Ogmios::LearningDataSet::Data;

my $LDS = Lingua::Ogmios::LearningDataSet->new();


# $NLPPlatform->loadDocuments(['examples/FrenchText.xml']);
ok(defined $LDS, 'Creation of the learning dataset works');

$LDS->relation('IRIS');

$LDS->classes(['Iris-setosa1','Iris-setosa2']);

$LDS->addComment('test comment');

ok($LDS->relation eq 'IRIS', 'relation works');

my $attr1 = Lingua::Ogmios::LearningDataSet::Attribute->new(
    {"name" => 'sepallength',
     "type" => 'NUMERIC',
    }
    );

ok(defined $attr1, 'Creation attribute 1 works');
ok($attr1->name eq "sepallength", 'Name attribute');
ok($attr1->type eq "NUMERIC", 'Type attribute');

my $attr2 = Lingua::Ogmios::LearningDataSet::Attribute->new();
$attr2->name('sepalwidth');
$attr2->type('NUMERIC');

ok(defined $attr2, 'Creation attribute 2 works');

$LDS->addAttribute($attr1);
$LDS->addAttribute($attr2);

ok(scalar(@{$LDS->attributes}) == 2, "add attributes");

my $data1 = Lingua::Ogmios::LearningDataSet::Data->new();

ok(defined $data1, 'Creation data');
$data1->values([5.1,3.5,1.4,0.2]);
$data1->class('Iris-setosa1');

ok(scalar(@{$data1->values}) == 4, 'add values1');
ok(defined($data1->class), 'add class');

$LDS->addData($data1);

ok(scalar(@{$LDS->dataset}) == 1, 'add data1');

my $data2 = Lingua::Ogmios::LearningDataSet::Data->new({type => "sparse", 'countVal' => 4});

$data2->value(1, '3.0');
$data2->value(3, '0.2');
$data2->class("Iris-setosa2");


ok(scalar(@{$data2->values}) <= 4, 'add values2');
ok(defined($data2->class), 'add class');

$LDS->addData($data2);
ok(scalar(@{$LDS->dataset}) == 2, 'add data2');


my $data3 = Lingua::Ogmios::LearningDataSet::Data->new({type => "normal", 'countVal' => 4});

$data3->values([5.1,3.5,1.4,0.2]);
# $data3->value(1, '3.1');
# $data3->value(3, '0.5');
$LDS->addData($data3);


my $arff = $LDS->getARFF;

ok(defined $arff, 'generating ARFF output');

# print STDERR "\nARFF Format";
# print STDERR "\n$arff\n";

my $svm = $LDS->getSVM;

ok(defined $svm, 'generating SVM output');

# print STDERR "\nSVN Format";
# print STDERR "\n$svm\n";
