require 5.005;			## This is the earliest version of Perl that we
						## will consider supporting.
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'				=> 'Exporter::Cluster',
    'VERSION_FROM'		=> 'Cluster.pm',
    'PREREQ_PM'			=> {},	## No additional modules are required to
								## make Exporter::Cluster work.
    ($] >= 5.005 ?		## We need to section this off for it to work with
						## older versions of Perl.
      ( ABSTRACT_FROM	=> 'Cluster.pm',
        AUTHOR			=> 'D. Hageman <dhageman@dracken.com>') : ()),
);
