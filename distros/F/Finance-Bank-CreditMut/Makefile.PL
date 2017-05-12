use ExtUtils::MakeMaker;
WriteMakefile(
	NAME          => 'Finance::Bank::CreditMut',
	VERSION_FROM  => 'lib/Finance/Bank/CreditMut.pm',
	PREREQ_PM     => { 
            'WWW::Mechanize'    => 0.44,
            'HTML::TableExtract' => 1.08,
	},
	ABSTRACT_FROM => 'lib/Finance/Bank/CreditMut.pm',
	AUTHOR        => 'Cédric Bouvier <cbouvi@cpan.org>',
);
