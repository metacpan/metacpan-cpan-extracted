use strict;
use warnings;
use ExtUtils::MakeMaker;
use v5.8.2;               # PadWalker 1.5 not available for <v5.8.2

my $TESTS = "t/*.t t/ppi/*.t";
unless (eval 'use PPI;1') {
  print q[
This distribution comes with a PPI-based module.
Install the PPI distribution on your system
to make use of it.

];
  $TESTS = "t/*.t t/ppi/00-load.t";
}

# no index instructions for PAUSE
my $NO_INDEX =
  { 'package' =>
    ['Text::Shorten',
     'Devel::DumpTrace::Const',
     'Devel::DumpTrace::CachedDisplayedArray',
     'Devel::DumpTrace::CachedDisplayedHash',
     'Devel::DumpTrace::noPPI'] };

WriteMakefile(
    NAME                => 'Devel::DumpTrace',
    AUTHOR              => q{Marty O'Brien <mob@cpan.org>},
    VERSION_FROM        => 'lib/Devel/DumpTrace.pm',
    ABSTRACT_FROM       => 'lib/Devel/DumpTrace.pm',
    (eval $ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    (eval $ExtUtils::MakeMaker::VERSION >= 6.46
      ? ('META_MERGE'   => { no_index => $NO_INDEX })
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'File::Temp' => 0,
	'Hash::SafeKeys' => '0.01',   # RT#77673
	'PadWalker' => 1.5,
        'Scalar::Util' => '1.14',     # 1.14 has improved reftype()
    },
    LICENSE             => 'perl_5',
    MIN_PERL_VERSION    => '5.008001',
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-DumpTrace-* t/*.out.* MYMETA.*' },
    test                => { TESTS => $TESTS },
);
