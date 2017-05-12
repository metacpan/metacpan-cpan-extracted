use ExtUtils::MakeMaker;
WriteMakefile(
	NAME           => 'HTTP::Response::CGI',
	VERSION_FROM   => 'lib/HTTP/Response/CGI.pm',
	PREREQ_PM      => { 'HTTP::Response' },
	AUTHOR         => 'Ken Dreyer <ktdreyer@ktdreyer.com>',
	ABSTRACT_FROM  => 'lib/HTTP/Response/CGI.pm',
	LICENSE        => 'perl',
	( $ExtUtils::MakeMaker::VERSION >= 6.46 ? (
		'META_MERGE' => {
			resources => {
				license        => 'http://dev.perl.org/licenses/',
				homepage       => 'http://www.ktdreyer.com',
			},
		} ) : ()
	),

);
