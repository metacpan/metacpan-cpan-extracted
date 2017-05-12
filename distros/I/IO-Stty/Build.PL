use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'IO::Stty',
    author              => 'Austin Schutz <auschutz@cpan.org>',
    dist_version_from   => 'lib/IO/Stty.pm',
    abstract_from       => 'lib/IO/Stty.pm',
    dist_abstract       => 'lib/IO/Stty.pm',
    license             => 'perl',
    build_requires      => {
	'Test::More'    => '0', 
	'Module::Build' => '0.35',
    },
    add_to_cleanup      => ['IO-Stty-*' ],
    script_files   => ['scripts/stty.pl'],
    meta_merge     => {
      resources => {
        homepage => 'http://github.com/toddr/IO-Stty',
#        bugtracker => 'https://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Stty',
        MailingList => 'mailto:toddr@cpan.org',
        repository  => 'git://github.com/toddr/IO-Stty.git',
      }
    }
);

$builder->create_build_script;

