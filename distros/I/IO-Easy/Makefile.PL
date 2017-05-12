use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "IO::Easy",
	VERSION_FROM => "lib/IO/Easy.pm",
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	AUTHOR => 'Ivan Baktsheev <dot.and.thing@gmail.com>',
	META_MERGE      => {
		resources => {
			license     =>      'http://dev.perl.org/licenses/',
			homepage    =>      'http://perlhug.com',
			bugtracker  =>      'http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO-Easy',
			repository  =>      'git://web-app.git.sourceforge.net/gitroot/perl-easy/perl-easy',
#			MailingList =>      'makemaker@perl.org',
		},
	},
	PREREQ_PM => {
		'Class::Easy' => '0.15',
		'Encode'      => 0,
		'File::Spec'  => 0,
	}
);
