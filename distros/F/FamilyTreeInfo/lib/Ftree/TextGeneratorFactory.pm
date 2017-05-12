package Ftree::TextGeneratorFactory;
use strict;
use warnings;

use Sub::Exporter -setup =>
  { exports => [qw(init getTextGenerator get_reverse_name)] };

use v5.10.1;
use experimental 'smartmatch';
use version; our $VERSION = qv('2.3.41');

my $language   = "gb";
my %langToPict = (
	hungarian => "hu",
	english   => "gb",
	german    => "de",

	#    spanish => "es",
	italian  => "it",
	french   => "fr",
	polish   => "pl",
	romanian => "ro",
	russian  => "ru",

	#    slovenian => "si",
	#    japanese => "jp",
	#    chinese => "cn",
);
my $reverse_name = 0;

sub init {
	($language) = @_;
}

sub getLangToPict {
	return %langToPict;
}

sub get_reverse_name {
	return $reverse_name;
}

sub getTextGenerator {
	for ($language) {
		when (/hu/) {
			$reverse_name = 1;
			require Ftree::TextGenerators::HungarianTextGenerator;
			return HungarianTextGenerator->new();
		}
		when (/gb/) {
			require Ftree::TextGenerators::EnglishTextGenerator;
			return EnglishTextGenerator->new();
		}
		when (/de/) {
			require Ftree::TextGenerators::GermanTextGenerator;
			return GermanTextGenerator->new();
		}
		when (/fr/) {
			require Ftree::TextGenerators::FrenchTextGenerator;
			return FrenchTextGenerator->new();
		}
		when (/pl/) {
			require Ftree::TextGenerators::PolishTextGenerator;
			return PolishTextGenerator->new();
		}
		when (/it/) {
			require Ftree::TextGenerators::ItalianTextGenerator;
			return ItalianTextGenerator->new();
		}
		when (/ro/) {
			require Ftree::TextGenerators::RomanianTextGenerator;
			return RomanianTextGenerator->new();
		}
		when (/ru/) {
			require Ftree::TextGenerators::RussianTextGenerator;
			return RussianTextGenerator->new();
		}
		default {
			require Ftree::TextGenerators::EnglishTextGenerator;
			EnglishTextGenerator->new();
		}
	}
}

1;
