use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Finance::Currency::Convert',
    'VERSION_FROM' => 'Convert.pm', # finds $VERSION
	'PREREQ_PM' => { 'Test::NoWarnings' => 0 },
	'ABSTRACT_FROM' => 'Convert.pm', # retrieve abstract from module
	'AUTHOR' => 'Jan Willamowius <jan@willamowius.de>',
	'LICENSE' => 'perl',
	'MIN_PERL_VERSION' => '5.5.5',
    'META_MERGE' => {
        'meta-spec' => { 'version' => 2 },
         'resources' => {
             'repository' => {
                 'type' => 'git',
                 'url'  => 'https://github.com/willamowius/perl-finance-currency-convert.git',
                 'web'  => 'https://github.com/willamowius/perl-finance-currency-convert',
             },
             'bugtracker' => {
                 'web' => 'https://github.com/willamowius/perl-finance-currency-convert/issues',
             },
        },
    },
);

sub MY::postamble {
	return <<'END';
readme:
	pod2markdown Convert.pm > README.md

dist: readme
END
}
