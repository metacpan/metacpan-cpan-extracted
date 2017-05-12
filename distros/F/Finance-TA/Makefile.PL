use strict;
use warnings;
use ExtUtils::MakeMaker;

my $libs = $ENV{TALIB_LIBS};
my $cflags = $ENV{TALIB_CFLAGS};

eval { require Alien::TALib };
if ( !$@ ) {
  warn "Using ta-lib via Alien::TALib\n";
  my $alien = Alien::TALib->new;
  $libs   = $alien->libs   if !defined $libs;
  $cflags = $alien->cflags if !defined $cflags;
}
else {
  warn "Alien::TALib not found, trying ta-lib-config\n";
  if (!defined $libs) {
    $libs = `ta-lib-config --libs`;
    $libs =~ s/[\s\n\r]*$//;
    #XXX-HACK fixing broken ta-lib-config output
    $libs .= " -lta_lib" if $libs && $libs !~ /-lta_lib/;
  }

  if (!defined $cflags) {
   $cflags = `ta-lib-config --cflags`;
   $cflags =~ s/[\s\n\r]*$//;
  }
}

unless ($libs) {
  warn "\nERROR: ta-lib not found on your system!\n\n";
  exit 0;
}

warn "Gonna use\n",
     " cflags: '$cflags'\n",
     " libs:   '$libs'\n";

WriteMakefile(
  NAME         => 'Finance::TA',
  ABSTRACT     => 'Perl wrapper for Technical Analysis Library',
  AUTHOR       => 'Wim Verhaegen <wimv@cpan.org>',
  VERSION      => 'v0.4.3', # has to be changed on 4 places!!!
  LIBS         => [$libs],
  INC          => $cflags,
  OBJECT       => '$(O_FILES)',
  PREREQ_PM    => { 'Test'   => 0 },
  LICENSE      => 'bsd',
  dist         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean        => { FILES => 'Finance-TA-*' },
  META_MERGE   => { 
      provides     => { 'Finance::TA' => { file => 'TA.pm', version => 'v0.4.3'} },
      no_index     => { directory => ['_swig'] },
      resources    => {
          homepage     => 'http://ta-lib.org/',
          repository   => 'https://github.com/kmx/perl-finance-ta',
      },
  },
  # generating ta_libc_wrap.c + TA.pm via swig (needed only when upgrading to the newer version)
  # make ta_libc_wrap.c
  'depend'       => { 
      'ta_libc_wrap.c TA.pm' => "_swig/ta_func.swg _swig/ta_libc.swg _swig/perl.pm\n".
          "\tswig -perl5 -module \"Finance::TA\" -proxy -Fstandard -o ta_libc_wrap.c -I/usr/local/include/ta-lib _swig/ta_libc.swg\n".
	  "\tcat _swig/perl.pm >> TA.pm\n",
  },
);
