use strict;
use warnings;
use ExtUtils::MakeMaker;
use 5.010001;

our %REQUIRED = ( 'Attribute::Handlers' => '0' );
our %META_MERGE = ();

my $MM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(

    NAME                => 'Foreign::Sort',
    AUTHOR              => q[Marty O'Brien <mob@cpan.org>],       #'],
    VERSION_FROM        => 'lib/Foreign/Sort.pm',
    ABSTRACT_FROM       => 'lib/Foreign/Sort.pm',
    PL_FILES            => {},
    PREREQ_PM		=> \%REQUIRED,

    ($MM_VERSION >= 6.46   ? ('META_MERGE' => \%META_MERGE ) : ()),
    ($MM_VERSION >= 6.3002 ? ('LICENSE'    => 'perl')        : ()),

    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => "Foreign-Sort-*" },

    );

