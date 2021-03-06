use ExtUtils::MakeMaker;
use strict;
use warnings;

# Call 'perldoc ExtUtils::MakeMaker' for details of how to influence
# the contents of the Makefile that is written.

my %WriteMakefileArgs = (
    NAME                => 'Google::Chat::WebHooks',
    VERSION_FROM        => 'lib/Google/Chat/WebHooks.pm',
    AUTHOR              => 'I Gibbs (igibbs@cpan.org)',
    ABSTRACT            => 'Send notifications to Google Chat Rooms',
    INSTALLDIRS         => ($] < 5.011 ? 'perl' : 'site'),
    PREREQ_PM           => {
        'LWP::UserAgent' => 0,
        'Class::Tiny' => 0,
        'JSON' => 0,
        'Try::Tiny' => 0,
        'Data::Validate::URI' => 0
    },
    TEST_REQUIRES		=> {
		'Test2::Bundle::More' => 0,
		'Test2::Tools::Class' => 0,
		'Test2::Tools::Exception' => 0,
		'Test2::Tools::ClassicCompare' => 0,
		'Test::HTTP::MockServer' => 0,
		'Data::Dump' => 0,
		'Encode' => 0
	},
    ( eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () : ( META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        #resources => {
        #    homepage    => undef,
        #    repository  => {
        #        url         => undef,
        #        web         => undef,
        #        type        => undef,
        #    },
        #    bugtracker => {
        #        web         => undef,
        #    },
        #},
    })),
);

WriteMakefile(%WriteMakefileArgs);
