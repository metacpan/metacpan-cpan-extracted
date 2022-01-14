use strict;
use warnings;
use ExtUtils::MakeMaker 6.64;	# 6.64 for TEST_REQUIRES
use Devel::CheckBin;

check_bin('/usr/sbin/sendmail');
# unless((-f '/usr/sbin/sendmail') && (-x '/usr/sbin/sendmail')) {
	# print STDERR "NA: sendmail not installed\n";
	# exit(0);
# }

WriteMakefile(
    NAME                => 'Log::Dispatch::Email::Sendmail',
    AUTHOR              => q{Nigel Horne <njh@bandsman.co.uk>},
    VERSION_FROM        => 'lib/Log/Dispatch/Email/Sendmail.pm',
    ABSTRACT_FROM        => 'lib/Log/Dispatch/Email/Sendmail.pm',
    ((defined($ExtUtils::MakeMaker::VERSION) &&
     ($ExtUtils::MakeMaker::VERSION >= 6.3002))
      ? ('LICENSE'=> 'GPL')
      : ()),
    PL_FILES            => {},
    BUILD_REQUIRES => {
    	'Devel::CheckBin' => 0,
    }, PREREQ_PM => {
	'Log::Dispatch' => 0,
	'Sys::Hostname' => 0,
    }, TEST_REQUIRES => {
	'Test::Most' => 0,
	'Test::NoWarnings' => 0,
	'Test::Requires' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Log-Dispatch-Email-Sendmail-*' },
    META_MERGE => {	# https://perldoc.perl.org/CPAN::Meta::Spec
    	'meta-spec' => { version => 2 },
    	resources => {
    		repository => {
			type => 'git',
			url => 'git://github.com/nigelhorne/Log-Dispatch-Email-Sendmail.git',
			web => 'https://github.com/nigelhorne/Log-Dispatch-Email-Sendmail',
			repisitory => 'https://github.com/nigelhorne/Log-Dispatch-Email-Sendmail',
    		}, bugtracker => {
			# web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Log-Dispatch-Email-Sendmail',
			web => 'https://github.com/nigelhorne/Log-Dispatch-Email-Sendmail/issues',
			url => 'https://github.com/nigelhorne/Log-Dispatch-Email-Sendmail/issues',
			mailto => 'bug-Log-Dispatch-Email-Sendmail@rt.cpan.org'
		}
	},
    },
    MIN_PERL_VERSION	=> '5.6.2'	# Probably would work, but never tested on earlier versions than this
);
