use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'IO::Pager',
    'VERSION_FROM'      => 'lib/IO/Pager.pm', # finds $VERSION
    'BUILD_REQUIRES'    => {
       'Test::More'     => 0.88,
       'Config'         => 0,
       'Env'            => 0,
       'Exporter'       => 0,
       'File::Temp'     => 0,
       'bignum'         => 0,
    },
    'PREREQ_PM'         => {
       'base'           => 0,
       'Env'            => 0,
       'File::Spec'     => 0,
       'File::Which'    => 0,
       'IO::Handle'     => 0,
       'PerlIO'         => 0,
       'SelectSaver'    => 0,
       'Symbol'         => 0,
       'Term::ReadKey'  => 0,
       'Text::Wrap'     => 0,
       'Tie::Handle'    => 0,
    },
    META_MERGE => {
		   "meta-spec" => { version => 2 },
		    runtime => {
				recommends => {
#				    #Since Term::Pager is unmodern
#					       'Term::ReadKey' => 0,
					      },
			       },
		  },
    ($] >= 5.005 ?  # Add these new keywords supported since 5.005
       (
        ABSTRACT_FROM    => 'lib/IO/Pager.pm', # retrieve abstract from module
        AUTHOR           => 'Jerrad Pierce <jpierce@cpan.org>, Florent Angly <florent.angly@gmail.com>',
       ) : ()),
);
