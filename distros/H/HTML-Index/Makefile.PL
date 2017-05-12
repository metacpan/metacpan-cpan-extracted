use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTML::Index',
    'VERSION_FROM'	=> 'lib/HTML/Index.pm',
    'PREREQ_PM'		=> {
        BerkeleyDB              => 0,
        Carp                    => 0,
        Carp::Assert            => 0,
        Class::Struct           => 0,
        Compress::Zlib          => 0,
        Data::Dumper            => 0,
        Fcntl                   => 0,
        File::Path              => 0,
        HTML::Entities          => 0,
        Text::Soundex           => 0,
        Lingua::Stem            => 0,
        HTML::TreeBuilder       => 0,
    }, # e.g., Module::Name => 1.1
);
