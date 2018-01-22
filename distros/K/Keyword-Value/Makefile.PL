use v5.20;

use ExtUtils::MakeMaker;

WriteMakefile
(
    NAME            => 'Keyword::Value',
    VERSION_FROM	=> 'lib/Keyword/Value.pm',
    ABSTRACT_FROM   => 'lib/Keyword/Value.pm',
    PREREQ_PM       =>
    {
		# Test::More & rest are for testing only.

		qw
        (
			Carp            	0
			Keyword::Declare	0
            Data::Lock          0

            Test::More      	0
            Test::Deep          0
            File::Basename      0
			ExtUtils::MakeMaker	0
        )
    },
);

__END__
