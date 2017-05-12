use ExtUtils::MakeMaker qw(prompt WriteMakefile);

# must make sure mpopd.conf gets backed up by install!
# must make sure mpopd_trusted and mpopd-allow_deny get preserved by install!

#--- Make the Makefile.
WriteMakefile(
        'NAME' => 'Mail::POP3',
        'DISTNAME' => "Mail-POP3",
        'VERSION_FROM' => 'lib/Mail/POP3.pm',
	PREREQ_PM => {
	    'HTTP::Cookies' => 0,
	    'HTML::Form' => 0,
	    'Email::MIME' => 0,
	    'HTML::FormatText' => 0,
	},
        'dist' => {
                COMPRESS => "gzip -9f",
                SUFFIX => "gz",
        },
        DIR => [qw(scripts)],
#        PMLIBDIRS => [qw(lib)],
);
