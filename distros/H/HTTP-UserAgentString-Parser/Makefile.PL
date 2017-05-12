use ExtUtils::MakeMaker;

WriteMakefile(
   NAME            => 'HTTP::UserAgentString::Parser',
   VERSION_FROM    => 'lib/HTTP/UserAgentString/Parser.pm',
   ABSTRACT     => 'User agent string parser',
   AUTHOR       => 'Nicolas Moldavsky <nico_cpan@e-planning.net>',

        PREREQ_PM    => {
		'LWP::UserAgent' => 2.0,
		'File::Spec' => 1,
		'Digest::MD5' => 2.12,
                'Test::More'       => 0.18,
	}
);
