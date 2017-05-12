use ExtUtils::MakeMaker;
WriteMakefile(
              NAME            => 'Encoding::BER',
              VERSION_FROM    => 'lib/Encoding/BER.pm',
              ABSTRACT_FROM   => 'lib/Encoding/BER.pm',
              AUTHOR          => 'Jeff Weisberg <http://www.tcp4me.com/>',

	      PREREQ_PM		=> { Carp  => 0,
				   # POSIX => 0, # optional
				 },


);
