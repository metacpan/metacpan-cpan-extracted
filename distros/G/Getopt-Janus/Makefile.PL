require 5.004;
use ExtUtils::MakeMaker;
# Time-stamp: "2003-05-10 20:48:31 AHDT"

WriteMakefile(
    'NAME'         => 'Getopt-Janus',
    # 'VERSION'      => '3.08',
    'VERSION_FROM' => 'lib/Getopt/Janus.pm', # finds $VERSION
    'PREREQ_PM'    => {
                         'Tk' => 0,
                        # Actually not totally necessary --
                        # but then only the command-line modes
                        # will work
                      },
    'AUTHOR'   => 'Sean M. Burke (sburke@cpan.org)',
    'ABSTRACT' => 'get program options via command line or GUI',
    'dist'     => { COMPRESS => 'gzip -6f', SUFFIX => 'gz', },
);

__END__
