
require 5.008;
use ExtUtils::MakeMaker;
WriteMakefile(
	NAME		=> 'Mail::SendVarious',
	DISTNAME	=> 'Mail-SendVarious',
	VERSION_FROM	=> 'lib/Mail/SendVarious.pm',
	dist		=> { COMPRESS => 'gzip', SUFFIX => 'gz' },
	PREREQ_PM	=> {
		'Net::SMTP'	=> 0,
		'IO::Pipe'	=> 0,
	},
	BUILD_REQUIRES => {
		'Test::SharedFork'	=> 0,
		'Test::More'		=> 0,
		'Net::SMTP::Receive'	=> 0,
		'File::Slurp'		=> 0,
		'autodie'		=> 0,
		'YAML'			=> 0,
		'Test::Deep'		=> 0,
		'Time::HiRes'		=> 0,
		'List::Util'		=> 0,
	},
	($] >= 5.005 
		?	
			(
				ABSTRACT	=> 'Send mail via SMTP, fall back to sendmail',
				AUTHOR		=> 'David Muir Sharnoff <cpan@dave.sharnoff.org>',
				META_MERGE     => {
					resources  => {
						repository => 'http://github.com/muir/Mail-SendVarious',
					},
				},
			) 
		: ()
	),
);

package MY;

sub postamble {
    <<'END_OF_POSTAMBLE';

pm_to_blib: README

README: lib/Mail/SendVarious.pod
	pod2text  lib/Mail/SendVarious.pod >README

END_OF_POSTAMBLE
}
