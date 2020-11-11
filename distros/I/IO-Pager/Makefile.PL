use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my @WINANSI = $^O =~ /MSWin/ ? ('Win32::Console::ANSI'=>0) : ();

WriteMakefile(
    'MIN_PERL_VERSION'  => 5.8.0,
    'NAME'              => 'IO::Pager',
    'VERSION_FROM'      => 'lib/IO/Pager.pm', # finds $VERSION
    'BUILD_REQUIRES'    => {
       'Test::More'     => 0.88,
       'Config'         => 0,
       'Env'            => 0,
       'Exporter'       => 0,
       'File::Temp'     => 0,
       'bignum'         => 0
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
    EXE_FILES  => [ 'lib/IO/Pager/tp' ],
    META_MERGE => {
		   "meta-spec" => { version => 2 },
		    runtime => {
				recommends => {
					       @WINANSI
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
