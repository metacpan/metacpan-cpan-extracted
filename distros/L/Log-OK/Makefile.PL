use ExtUtils::MakeMaker;
WriteMakefile(
	NAME              => 'Log::OK',
	VERSION_FROM      => 'lib/Log/OK.pm',
	PREREQ_PM         => {
		"constant::more"=>"v0.2.0"
	}, 
	ABSTRACT_FROM     => 'lib/Log/OK.pod', # retrieve abstract from module
	AUTHOR            => 'Ruben Westerberg <drclaw@mac.com>',
	LICENSE           => 'mit',
	MIN_PERL_VERSION => "v5.24",
	META_ADD => {
		"meta-spec" => {
			version => 2
		},
		resources=> {
			repository =>{
				type => "git",
				url => "git://github.com/drclaw1394/perl-log-ok.git",
				web => "http://github.com/drclaw1394/perl-log-ok",
			}
		},
		bugtracker => {
			web => 'https://github.com/drclaw1394/perl-log-ok/issues'
    },
	}

);
