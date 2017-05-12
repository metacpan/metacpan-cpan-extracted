BEGIN {
	require 5.008004; # spurious warnings under 5.8.3, notably those
	                  # involving folded constants in void context
}

use ExtUtils::MakeMaker;

my %prq = (
         Carp                        => 1.01, # @CARP_NOT
	 constant               => 1.03, # multiple
        'Date::Parse' => 0,
         Encode     => 2.08, # ‘decode_utf8 "\xef\xbb", FB_CROAK’
         Exporter   => 5.57,
        'List::Util' => 0,
         re       => .02, # eval
         POSIX => 0,
#        'Scalar::Util' => 1.1, # looks_like_number
         strict => 0,
        'Time::Local' => 0,
        'Time::Zone' => 0,
         warnings => 0,
 # for tests only:
        'Scalar::Util' => 1.14, # refaddr and ties
        'Test::More'   => 0,
         utf8   => 0,
    );

eval { require Hash::Util::FieldHash } or $prq{'Tie::RefHash::Weak'} = 0;

WriteMakefile(
    NAME                => 'JE',
    AUTHOR              => 'Father Chrysostomos <sprout @ cpan . org>',
    VERSION_FROM        => 'lib/JE.pm',
    ABSTRACT_FROM       => 'lib/JE.pm',
    PL_FILES            => {},
    PREREQ_PM           => \%prq,
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'JE-*' },
);
