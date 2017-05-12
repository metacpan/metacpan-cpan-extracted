# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use v5.20;

use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Keyword::TreeFold',
    VERSION_FROM	=> 'lib/Keyword/TreeFold.pm',
    ABSTRACT_FROM   => 'lib/Keyword/TreeFold.pm',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.
		#
		# Test::More & rest are for testing only.

		qw
        (
			Carp            	0
			Keyword::Declare	0

            Test::More      	0
			Digest::SHA 		0
			Benchmark			0
			File::Basename		0
			FindBin::libs		0
        )
    },
);

__END__
