#!perl -T

use Test::More tests => 18;

BEGIN {
    my @modules = qw(
Lingua::HPSG
Lingua::HPSG::Feature
Lingua::HPSG::Feature::Agreement
Lingua::HPSG::Feature::Expression
Lingua::HPSG::Feature::Valance
Lingua::HPSG::FeatureStructure
Lingua::HPSG::FeatureStructure::Expression
Lingua::HPSG::FeatureStructure::Expression::Agreement
Lingua::HPSG::FeatureStructure::Expression::Phrase
Lingua::HPSG::FeatureStructure::Expression::Valance
Lingua::HPSG::FeatureStructure::Expression::Word
Lingua::HPSG::FeatureStructure::PartOfSpeech
Lingua::HPSG::FeatureStructure::PartOfSpeech::Adjective
Lingua::HPSG::FeatureStructure::PartOfSpeech::Conjunction
Lingua::HPSG::FeatureStructure::PartOfSpeech::Determiner
Lingua::HPSG::FeatureStructure::PartOfSpeech::Noun
Lingua::HPSG::FeatureStructure::PartOfSpeech::Preposition
Lingua::HPSG::FeatureStructure::PartOfSpeech::Verb
);

    foreach my $module ( @modules ){
	use_ok( $module );
    }
}

diag( "Testing Lingua::HPSG $Lingua::HPSG::VERSION, Perl $], $^X" );
