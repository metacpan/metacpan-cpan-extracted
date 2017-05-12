use 5.008007;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Coder::HostIP',
    VERSION_FROM      => 'lib/Geo/Coder/HostIP.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Carp'           => 0,
                            'LWP::UserAgent' => 0,
                            'strict'         => 0,
                            'warnings'       => 0,
                         },
    META_MERGE => {
        dynamic_config => 0,
        resources => {
            repository => 'https://github.com/neilb/Geo-Coder-HostIP',
        },
    },
    LICENSE      => 'perl',
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Coder/HostIP.pm', # retrieve abstract from module
       AUTHOR         => 'root <root@>') : ()),

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

);
