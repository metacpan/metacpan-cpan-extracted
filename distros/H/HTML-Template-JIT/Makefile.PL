use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME		=> 'HTML::Template::JIT',
    VERSION_FROM	=> 'JIT.pm',
    PREREQ_PM		=> {
			    Inline::C      => 0,
			    Inline         => 0.43,
			    File::Spec     => 0,
			    File::Path     => 0,
			    Digest::MD5    => 0,
			    Test::More     => 0,
                            HTML::Template => 2.8,
			   },
);
