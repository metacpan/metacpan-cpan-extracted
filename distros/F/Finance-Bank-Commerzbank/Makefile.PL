use ExtUtils::MakeMaker;



WriteMakefile(
PREREQ_PM=>{"WWW::Mechanize","WWW::Mechanize::FormFiller","HTML::TableContentParser"},
	NAME=>'Finance::Bank::Commerzbank',
	VERSION_FROM=>'lib/Finance/Bank/Commerzbank.pm');
